//! Cluster tests: a few replicas and a client driven by hand through a
//! tick function that decides which messages get delivered.

use std::cell::RefCell;
use std::collections::VecDeque;
use vsr_rs::{Client, Config, Message, Replica, ReplicaID, Reply, RequestNumber, StateMachine};

#[derive(Clone, Debug)]
enum Op {
    Add(i32),
    Sub(i32),
}

#[derive(Default)]
struct Accumulator {
    value: i32,
}

impl StateMachine for Accumulator {
    type Input = Op;
    type Output = ();

    fn apply(&mut self, op: Op) {
        match op {
            Op::Add(value) => self.value += value,
            Op::Sub(value) => self.value -= value,
        }
    }
}

/// Replicas and one client, with the messages between them held in a queue
/// that the test delivers as it sees fit.
struct Cluster {
    config: Config,
    replicas: Vec<Replica<Accumulator>>,
    client: Client<Op>,
    queue: VecDeque<(ReplicaID, Message<Op>)>,
    replies: Vec<Reply<()>>,
}

impl Cluster {
    fn new(replica_count: usize) -> Cluster {
        Cluster::with_primary_timeout(replica_count, Config::new().primary_timeout())
    }

    /// A cluster whose replicas wait `primary_timeout` idle periods for the
    /// primary, and for a view change to complete.
    fn with_primary_timeout(replica_count: usize, primary_timeout: usize) -> Cluster {
        let _ = env_logger::try_init();
        let mut config = Config::new();
        for _ in 0..replica_count {
            config.add_replica();
        }
        config.set_primary_timeout(primary_timeout);
        let replicas = (0..replica_count)
            .map(|id| Replica::new(id, config.clone(), Accumulator::default()))
            .collect();
        Cluster {
            replicas,
            client: Client::new(0, config.clone()),
            config,
            queue: VecDeque::new(),
            replies: Vec::new(),
        }
    }

    fn request(&mut self, op: Op) -> RequestNumber {
        self.client.on_request(op)
    }

    /// Moves everything the replicas and the client want sent into the
    /// queue, and collects the replies.
    fn collect(&mut self) {
        for replica in &mut self.replicas {
            self.queue.extend(replica.drain_messages());
            self.replies.extend(replica.drain_replies());
        }
        self.queue.extend(self.client.drain());
    }

    /// Delivers every queued message for which `deliver` returns true, and
    /// whatever those deliveries produce, until nothing is left.
    fn tick_with(&mut self, deliver: &dyn Fn(ReplicaID, &Message<Op>) -> bool) {
        loop {
            self.collect();
            if self.queue.is_empty() {
                return;
            }
            for (replica_id, message) in std::mem::take(&mut self.queue) {
                if deliver(replica_id, &message) {
                    self.replicas[replica_id].on_message(message);
                }
            }
        }
    }

    fn tick(&mut self) {
        self.tick_with(&|_, _| true);
    }

    /// Delivers everything except messages to `dead`.
    fn tick_without(&mut self, dead: ReplicaID) {
        self.tick_with(&|replica_id, _| replica_id != dead);
    }

    fn idle(&mut self) {
        for replica in &mut self.replicas {
            replica.on_idle();
        }
    }

    /// One tick of a cluster whose messages take one tick to arrive, in
    /// the simulator's order: every replica gets an idle period, then
    /// everything queued so far is delivered, and what those deliveries
    /// produce waits for the next step. Returns whether the deliveries
    /// produced anything.
    fn step(&mut self) -> bool {
        self.idle();
        self.collect();
        for (replica_id, message) in std::mem::take(&mut self.queue) {
            self.replicas[replica_id].on_message(message);
        }
        self.collect();
        !self.queue.is_empty()
    }

    /// Whether every replica is in normal status in the same view.
    fn settled(&self) -> bool {
        let view = self.replicas[0].view_number();
        self.replicas.iter().all(|replica| {
            replica.status() == vsr_rs::Status::Normal && replica.view_number() == view
        })
    }

    fn take_replies(&mut self) -> Vec<Reply<()>> {
        self.collect();
        std::mem::take(&mut self.replies)
    }

    fn value(&self, replica_id: ReplicaID) -> i32 {
        self.replicas[replica_id].state_machine().value
    }
}

#[test]
fn test_normal_operation() {
    let mut cluster = Cluster::new(3);
    cluster.request(Op::Add(10));
    cluster.tick();
    assert_eq!(10, cluster.value(0));
    cluster.request(Op::Sub(5));
    cluster.tick();
    assert_eq!(5, cluster.value(0));
}

#[test]
fn test_idle() {
    let mut cluster = Cluster::new(3);
    cluster.request(Op::Add(10));
    cluster.tick();
    cluster.idle();
    cluster.tick();
    assert_eq!(10, cluster.value(0));
    cluster.request(Op::Sub(5));
    cluster.tick();
    cluster.idle();
    cluster.tick();
    for id in 0..3 {
        assert_eq!(5, cluster.value(id));
    }
}

/// Replica 1 misses everything about the first op and catches up by state
/// transfer when the second arrives.
#[test]
fn test_recovery() {
    let mut cluster = Cluster::new(3);
    cluster.request(Op::Add(10));
    cluster.tick_without(1);
    assert_eq!(10, cluster.value(0));
    cluster.request(Op::Sub(5));
    cluster.tick();
    assert_eq!(5, cluster.value(0));
    cluster.request(Op::Add(7));
    cluster.tick();
    assert_eq!(12, cluster.value(0));
}

/// Prepare messages to one backup arrive in reverse order. The first
/// one it sees has a gap, so it starts state transfer; the earlier ones
/// then arrive while it is still waiting for `NewState` and must be
/// dropped, otherwise its log moves past the point it asked to be
/// repaired from.
#[test]
fn test_prepare_reordered_during_state_transfer() {
    let mut cluster = Cluster::new(3);
    cluster.request(Op::Add(10));
    cluster.request(Op::Add(20));
    cluster.request(Op::Add(30));
    // Delivers everything, but `Prepare` messages to replica 1 in
    // descending op-number order.
    loop {
        cluster.collect();
        if cluster.queue.is_empty() {
            break;
        }
        let mut batch: Vec<_> = std::mem::take(&mut cluster.queue).into_iter().collect();
        batch.sort_by_key(|(replica_id, message)| match message {
            Message::Prepare { op_number, .. } if *replica_id == 1 => std::cmp::Reverse(*op_number),
            _ => std::cmp::Reverse(0),
        });
        for (replica_id, message) in batch {
            cluster.replicas[replica_id].on_message(message);
        }
    }
    assert_eq!(60, cluster.value(0));
    assert_eq!(3, cluster.replicas[1].op_number());
    // A commit heartbeat lets the backups catch up.
    cluster.idle();
    cluster.tick();
    for id in 0..3 {
        assert_eq!(60, cluster.value(id));
    }
}

/// The acknowledgements for op 1 are lost, but both backups acknowledge
/// op 2. A `PrepareOk` for op n acknowledges n and all earlier ops, so
/// the primary must commit ops 1 and 2, in order, once op 2 reaches a
/// quorum, instead of executing op 2 in op 1's slot.
#[test]
fn test_prepare_ok_quorum_commits_prefix() {
    let mut cluster = Cluster::new(3);
    cluster.request(Op::Add(10));
    cluster.request(Op::Add(20));
    cluster.tick_with(&|_, message| !matches!(message, Message::PrepareOk { op_number: 1, .. }));
    assert_eq!(2, cluster.replicas[0].commit_number());
    assert_eq!(30, cluster.value(0));
    cluster.idle();
    cluster.tick();
    for id in 0..3 {
        assert_eq!(30, cluster.value(id));
    }
}

/// A backup's `GetState` is replayed by the network. The reply to the
/// replayed copy arrives during a later state transfer, when the backup
/// already has more entries than the reply starts at. The stale reply
/// overlaps the backup's log and carries the entries it is missing, so
/// the backup must use the suffix instead of treating the mismatch as
/// a fatal error.
#[test]
fn test_stale_new_state_during_state_transfer() {
    let mut cluster = Cluster::new(3);
    let replayed = RefCell::new(Vec::new());

    // Replica 1 misses op 2, so op 3 makes it ask for state transfer.
    // The network replays its `GetState`; keep the copy for later.
    cluster.request(Op::Add(10));
    cluster.request(Op::Add(20));
    cluster.request(Op::Add(30));
    cluster.tick_with(&|replica_id, message| match message {
        Message::Prepare { op_number: 2, .. } if replica_id == 1 => false,
        Message::GetState { .. } => {
            replayed.borrow_mut().push((replica_id, message.clone()));
            true
        }
        _ => true,
    });
    assert_eq!(3, cluster.replicas[1].op_number());

    // Replica 1 misses op 4, so op 5 makes it ask for state transfer
    // again, but this time the `GetState` is lost.
    cluster.request(Op::Add(40));
    cluster.request(Op::Add(50));
    cluster.tick_with(&|replica_id, message| match message {
        Message::Prepare { op_number: 4, .. } if replica_id == 1 => false,
        Message::GetState { .. } => false,
        _ => true,
    });
    assert_eq!(3, cluster.replicas[1].op_number());

    // The replayed `GetState` from the first transfer now reaches the
    // primary. Its reply starts at op 1 and covers ops 1 to 5, and it
    // reaches replica 1 while it waits for a reply starting at op 3.
    for (replica_id, message) in replayed.borrow_mut().drain(..) {
        cluster.replicas[replica_id].on_message(message);
    }
    cluster.tick();
    assert_eq!(5, cluster.replicas[1].op_number());

    cluster.idle();
    cluster.tick();
    for id in 0..3 {
        assert_eq!(150, cluster.value(id));
    }
}

/// A backup's `GetState` is lost. On the next idle period it must ask
/// again instead of staying in state transfer forever.
#[test]
fn test_get_state_retried_on_idle() {
    let mut cluster = Cluster::new(3);
    cluster.request(Op::Add(10));
    cluster.request(Op::Add(20));
    cluster.request(Op::Add(30));
    cluster.tick_with(&|replica_id, message| match message {
        Message::Prepare { op_number: 2, .. } if replica_id == 1 => false,
        Message::GetState { .. } => false,
        _ => true,
    });
    assert_eq!(1, cluster.replicas[1].op_number());
    cluster.idle();
    cluster.tick();
    assert_eq!(3, cluster.replicas[1].op_number());
    cluster.idle();
    cluster.tick();
    for id in 0..3 {
        assert_eq!(60, cluster.value(id));
    }
}

/// Every `PrepareOk` for the last ops is lost. On the next idle period
/// the primary must re-send the uncommitted `Prepare` messages so the
/// backups acknowledge them again.
#[test]
fn test_prepare_resent_on_idle_when_prepare_ok_lost() {
    let mut cluster = Cluster::new(3);
    cluster.request(Op::Add(10));
    cluster.request(Op::Add(20));
    cluster.tick_with(&|_, message| !matches!(message, Message::PrepareOk { .. }));
    assert_eq!(2, cluster.replicas[1].op_number());
    assert_eq!(2, cluster.replicas[2].op_number());
    assert_eq!(0, cluster.replicas[0].commit_number());
    cluster.idle();
    cluster.tick();
    assert_eq!(2, cluster.replicas[0].commit_number());
    cluster.idle();
    cluster.tick();
    for id in 0..3 {
        assert_eq!(30, cluster.value(id));
    }
}

/// The `Prepare` for the last op never reaches any backup, so no backup
/// can notice a gap. On the next idle period the primary must re-send
/// it.
#[test]
fn test_prepare_resent_on_idle_when_prepare_lost() {
    let mut cluster = Cluster::new(3);
    cluster.request(Op::Add(10));
    cluster.request(Op::Add(20));
    cluster.tick_with(&|_, message| !matches!(message, Message::Prepare { op_number: 2, .. }));
    assert_eq!(1, cluster.replicas[1].op_number());
    assert_eq!(1, cluster.replicas[2].op_number());
    assert_eq!(1, cluster.replicas[0].commit_number());
    cluster.idle();
    cluster.tick();
    assert_eq!(2, cluster.replicas[0].commit_number());
    cluster.idle();
    cluster.tick();
    for id in 0..3 {
        assert_eq!(30, cluster.value(id));
    }
}

/// Four replicas, so a quorum is three. Only one backup receives the
/// `Prepare`, and the network delivers its `PrepareOk` twice. Two acks from
/// the same backup are still one backup, so the primary must not commit
/// until another backup acknowledges.
#[test]
fn test_duplicate_prepare_ok_is_not_a_quorum() {
    let mut cluster = Cluster::new(4);
    cluster.request(Op::Add(10));
    loop {
        cluster.collect();
        if cluster.queue.is_empty() {
            break;
        }
        for (replica_id, message) in std::mem::take(&mut cluster.queue) {
            match message {
                Message::Prepare { .. } if replica_id != 3 => continue,
                Message::PrepareOk { .. } => {
                    cluster.replicas[replica_id].on_message(message.clone());
                    cluster.replicas[replica_id].on_message(message);
                }
                _ => cluster.replicas[replica_id].on_message(message),
            }
        }
    }
    assert_eq!(1, cluster.replicas[3].op_number());
    assert_eq!(0, cluster.replicas[1].op_number());
    assert_eq!(0, cluster.replicas[2].op_number());
    assert_eq!(0, cluster.replicas[0].commit_number());
    // Once the other backups get the re-sent Prepare, it commits.
    cluster.idle();
    cluster.tick();
    assert_eq!(1, cluster.replicas[0].commit_number());
    cluster.idle();
    cluster.tick();
    for id in 0..4 {
        assert_eq!(10, cluster.value(id));
    }
}

/// The same client request reaches the primary twice: once more while it
/// is still being prepared, and once more after it has committed. The
/// primary must execute it once. It drops the duplicate that arrives while
/// the request is in progress, and answers the one that arrives after the
/// commit by re-sending the reply it already has.
#[test]
fn test_duplicate_request_executes_once() {
    let mut cluster = Cluster::new(3);
    cluster.request(Op::Add(10));
    // The request is delivered twice before anything else happens.
    cluster.collect();
    let (replica_id, request) = cluster.queue.pop_front().unwrap();
    assert!(cluster.queue.is_empty());
    cluster.replicas[replica_id].on_message(request.clone());
    cluster.replicas[replica_id].on_message(request.clone());
    cluster.tick();
    assert_eq!(1, cluster.replicas[0].op_number());
    assert_eq!(1, cluster.replicas[0].commit_number());
    assert_eq!(10, cluster.value(0));
    assert_eq!(1, cluster.take_replies().len());
    // The request is delivered once more after it committed: the primary
    // re-sends the reply without running it again.
    cluster.replicas[replica_id].on_message(request);
    cluster.tick();
    assert_eq!(1, cluster.replicas[0].op_number());
    assert_eq!(10, cluster.value(0));
    assert_eq!(1, cluster.take_replies().len());
}

/// The client's request is lost. On its next idle period the client must
/// re-send it, to every replica since the primary may have changed, and
/// backups must ignore it.
#[test]
fn test_lost_request_resent_on_idle() {
    let mut cluster = Cluster::new(3);
    cluster.request(Op::Add(10));
    cluster.tick_with(&|_, message| !matches!(message, Message::Request { .. }));
    assert_eq!(0, cluster.replicas[0].op_number());
    // The idle period must make the client re-send the request.
    cluster.client.on_idle();
    cluster.tick();
    assert_eq!(1, cluster.replicas[0].commit_number());
    assert_eq!(10, cluster.value(0));
    let replies = cluster.take_replies();
    assert_eq!(1, replies.len());
    // Once replied to, the request is not re-sent again.
    assert!(cluster
        .client
        .on_reply(replies[0].request_number, replies[0].view_number));
    cluster.client.on_idle();
    cluster.tick();
    assert_eq!(1, cluster.replicas[0].op_number());
    assert_eq!(0, cluster.take_replies().len());
}

/// The primary crashes with an op prepared on the backups but not yet
/// committed. The backups must notice the silence, move to view 1 with
/// replica 1 as primary, and the new primary must commit the op it found
/// in the logs and reply to the client. The client learns the new view from
/// the reply and sends its next request to the new primary.
#[test]
fn test_view_change_after_primary_crash() {
    let mut cluster = Cluster::new(3);
    // Replica 0 has crashed: it gets nothing and runs no idle logic.
    fn idle_without_0(cluster: &mut Cluster) {
        cluster.replicas[1].on_idle();
        cluster.replicas[2].on_idle();
    }

    // Two ops commit everywhere in view 0.
    cluster.request(Op::Add(10));
    cluster.request(Op::Add(20));
    cluster.tick();
    cluster.idle();
    cluster.tick();
    for id in 0..3 {
        assert_eq!(30, cluster.value(id));
    }
    assert_eq!(2, cluster.take_replies().len());

    // A third op reaches the backups, but the primary crashes before it
    // sees their acknowledgements.
    let request_number = cluster.request(Op::Add(30));
    cluster.tick_with(&|replica_id, message| {
        replica_id != 0 || matches!(message, Message::Request { .. })
    });
    assert_eq!(3, cluster.replicas[1].op_number());
    assert_eq!(3, cluster.replicas[2].op_number());
    assert_eq!(2, cluster.replicas[0].commit_number());

    // The backups stop hearing from the primary and change view.
    for _ in 0..10 {
        idle_without_0(&mut cluster);
        cluster.tick_without(0);
    }
    assert_eq!(1, cluster.replicas[1].view_number());
    assert_eq!(1, cluster.replicas[2].view_number());
    assert!(cluster.replicas[1].is_primary());
    assert!(!cluster.replicas[2].is_primary());
    // The new primary commits the op it found and replies to the client.
    assert_eq!(3, cluster.replicas[1].commit_number());
    assert_eq!(3, cluster.replicas[2].commit_number());
    assert_eq!(60, cluster.value(1));
    assert_eq!(60, cluster.value(2));
    let replies = cluster.take_replies();
    assert_eq!(1, replies.len());
    assert_eq!(request_number, replies[0].request_number);
    assert_eq!(1, replies[0].view_number);

    // The client learns the view from the reply and sends the next request
    // to the new primary.
    cluster
        .client
        .on_reply(replies[0].request_number, replies[0].view_number);
    cluster.request(Op::Add(40));
    cluster.tick_without(0);
    idle_without_0(&mut cluster);
    cluster.tick_without(0);
    assert_eq!(4, cluster.replicas[1].commit_number());
    assert_eq!(4, cluster.replicas[2].commit_number());
    assert_eq!(100, cluster.value(1));
    assert_eq!(100, cluster.value(2));
    assert_eq!(1, cluster.take_replies().len());
    // The crashed primary never moved.
    assert_eq!(0, cluster.replicas[0].view_number());
    assert_eq!(30, cluster.value(0));
}

/// A backup that cannot reach anyone keeps starting view changes. The first
/// waits the primary timeout, and each one after that waits twice as long
/// as the last, otherwise replicas whose timers fire faster than a view
/// change can complete keep interrupting each other forever.
#[test]
fn test_view_change_timeout_backs_off() {
    let mut cluster = Cluster::new(3);
    // Replica 1 is alone: nothing it sends is delivered. Record the idle
    // period at which it first asks for each new view.
    let mut first_asked_at: Vec<usize> = Vec::new();
    for idle_period in 1..=200 {
        cluster.replicas[1].on_idle();
        for (_, message) in cluster.replicas[1].drain_messages() {
            if let Message::StartViewChange { view_number, .. } = message {
                if view_number > first_asked_at.len() {
                    first_asked_at.push(idle_period);
                }
            }
        }
        if first_asked_at.len() == 4 {
            break;
        }
    }
    assert_eq!(
        4,
        first_asked_at.len(),
        "asked for views at {first_asked_at:?}"
    );
    let timeout = Config::new().primary_timeout();
    let gaps: Vec<usize> = first_asked_at.windows(2).map(|w| w[1] - w[0]).collect();
    assert_eq!(
        vec![timeout, 2 * timeout, 4 * timeout],
        gaps,
        "asked for views at {first_asked_at:?}"
    );
}

/// Replica 1 crashes and comes back with no memory. Until it has recovered
/// it must take no part in the protocol: not acknowledge, not vote. Once
/// the others answer its Recovery, it must hold the primary's log and
/// state, and take part again.
#[test]
fn test_recovery_after_reboot() {
    let mut cluster = Cluster::new(3);
    cluster.request(Op::Add(10));
    cluster.request(Op::Add(20));
    cluster.tick();
    cluster.idle();
    cluster.tick();
    for id in 0..3 {
        assert_eq!(30, cluster.value(id));
    }

    // Replica 1 reboots. It last persisted view 0, and picks nonce 42.
    cluster.replicas[1] =
        Replica::recover(1, cluster.config.clone(), Accumulator::default(), 0, 42);
    assert!(cluster.replicas[1].is_recovering());
    assert_eq!(0, cluster.replicas[1].op_number());

    // A new op arrives while it is still recovering: it must not touch it.
    // Nothing it sent has been delivered yet, only the primary's messages.
    cluster.request(Op::Add(30));
    cluster.tick_with(&|_, message| !matches!(message, Message::Recovery { .. }));
    assert!(cluster.replicas[1].is_recovering());
    assert_eq!(0, cluster.replicas[1].op_number());
    assert_eq!(3, cluster.replicas[0].commit_number());
    assert_eq!(60, cluster.value(0));

    // Its Recovery reaches the others, and their responses bring it back.
    cluster.idle();
    cluster.tick();
    assert!(!cluster.replicas[1].is_recovering());
    assert_eq!(3, cluster.replicas[1].op_number());
    assert_eq!(3, cluster.replicas[1].commit_number());
    assert_eq!(60, cluster.value(1));
    assert_eq!(0, cluster.replicas[1].view_number());

    // And it takes part in the next op.
    cluster.request(Op::Add(40));
    cluster.tick_with(&|replica_id, message| {
        replica_id != 2 || matches!(message, Message::Request { .. })
    });
    assert_eq!(4, cluster.replicas[0].commit_number());
    assert_eq!(100, cluster.value(0));
    cluster.idle();
    cluster.tick();
    assert_eq!(100, cluster.value(1));
}

/// A view change must not start the next one. With a primary timeout of two
/// idle periods and messages that take a tick, a view change takes exactly
/// as long as a replica is willing to wait for it: a replica that joins
/// the change from normal status, with no backoff, times out one tick
/// before `StartView` reaches it and starts another view. The previous
/// view's primary is always such a replica, since completing a view reset
/// its backoff, so every view change starts the next one, round the ring,
/// forever. The backoff must survive a completed view long enough to break
/// the ring.
#[test]
fn test_view_change_does_not_start_the_next() {
    let mut cluster = Cluster::with_primary_timeout(3, 2);
    cluster.request(Op::Add(10));
    cluster.tick();
    cluster.idle();
    cluster.tick();
    for id in 0..3 {
        assert_eq!(10, cluster.value(id));
    }
    // Replica 2 hears nothing from the primary for two idle periods and
    // starts a view change. From here on the network is perfect.
    for _ in 0..3 {
        cluster.replicas[2].on_idle();
    }
    assert_eq!(cluster.replicas[2].status(), vsr_rs::Status::ViewChange);
    let mut quiet = 0;
    for _ in 0..500 {
        let busy = cluster.step();
        if !busy && cluster.settled() {
            quiet += 1;
            if quiet == 10 {
                break;
            }
        } else {
            quiet = 0;
        }
    }
    let views: Vec<_> = cluster.replicas.iter().map(|r| r.view_number()).collect();
    assert_eq!(
        quiet, 10,
        "the cluster never settled: replicas are in views {views:?}"
    );
}
