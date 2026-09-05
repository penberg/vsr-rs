//! Viewstamped Replication for Rust.
//!
//! A work-in-progress implementation of the protocol described in
//! "Viewstamped Replication Revisited" by Liskov and Cowling.
//!
//! The library does no I/O, keeps no clocks, and starts no threads. A
//! [`Replica`] and a [`Client`] are state machines that their owner steps:
//! hand them incoming messages with `on_message` and `on_reply`, tell them
//! time has passed with `on_idle`, and afterwards drain what they want sent
//! with `drain_messages`, `drain_replies`, and `drain`. The owner decides
//! how those get delivered, whether over sockets, through a simulated
//! network, or straight into another replica in a test.
//!
//! The protocol keeps its state in memory, and a replica that crashes comes
//! back through [`Replica::recover`], which fetches the state from the
//! others. One thing must survive the crash: the view number. The owner
//! persists [`Replica::view_number`] after every step, before it delivers
//! what the step produced, and passes it back to `recover`. Without it a
//! replica can forget that it asked for a view change and let two views run
//! at once, as shown by Michael et al. in "Recovering Shared Objects Without
//! Stable Storage".

use log::trace;
use std::{
    collections::{BTreeMap, BTreeSet},
    fmt::Debug,
};

/// Identifies a client. Every client must have its own, and a client that
/// restarts must not reuse one, or the primary's client table takes its
/// first request for a re-send of an old one.
pub type ClientID = usize;

/// The number of log entries a replica has executed. The entries at
/// indexes below it are committed and never change.
pub type CommitID = usize;

/// The position of an entry in the log, counted from 1. A replica's op
/// number is that of its last entry, so also the length of its log.
pub type OpNumber = usize;

/// Identifies a replica: its index in the configuration's list of replicas.
pub type ReplicaID = usize;

/// Numbers the requests of one client, increasing with every request. The
/// client table keeps the latest per client to spot re-sends.
pub type RequestNumber = usize;

/// Numbers the views. The primary of view `v` is replica `v` modulo the
/// number of replicas, so the view number says who leads.
pub type ViewNumber = usize;

/// State machine.
pub trait StateMachine {
    type Input: Clone + Debug;
    /// The result of applying an input. Replicas keep the latest result per
    /// client to answer a re-sent request without running it again.
    type Output: Clone + Debug;

    fn apply(&mut self, input: Self::Input) -> Self::Output;
}

/// Configuration.
#[derive(Clone, Debug)]
pub struct Config {
    /// IDs of all replicas (in sorted order).
    replicas: Vec<ReplicaID>,
    /// Idle periods a backup waits without hearing from the primary before
    /// it starts a view change, and a view change may take before the next
    /// one starts.
    primary_timeout: usize,
}

impl Config {
    pub fn new() -> Config {
        Config {
            replicas: Vec::new(),
            primary_timeout: 3,
        }
    }

    pub fn replicas(&self) -> &[ReplicaID] {
        &self.replicas
    }

    pub fn primary_id(&self, view_number: ViewNumber) -> ReplicaID {
        self.replicas[view_number % self.replicas.len()]
    }

    pub fn add_replica(&mut self) -> ReplicaID {
        let id = self.replicas.len();
        self.replicas.push(id);
        id
    }

    pub fn quorum(&self) -> usize {
        self.replicas.len() / 2 + 1
    }

    pub fn primary_timeout(&self) -> usize {
        self.primary_timeout
    }

    pub fn set_primary_timeout(&mut self, idle_periods: usize) {
        assert!(idle_periods >= 1);
        self.primary_timeout = idle_periods;
    }
}

impl Default for Config {
    fn default() -> Config {
        Config::new()
    }
}

/// A log entry: the client request that was assigned this op number.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LogEntry<Op> {
    pub client_id: ClientID,
    pub request_number: RequestNumber,
    pub op: Op,
}

/// The primary's reply to a client request.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Reply<Output> {
    pub view_number: ViewNumber,
    pub client_id: ClientID,
    pub request_number: RequestNumber,
    pub result: Output,
}

/// A protocol message between replicas, or from a client to a replica.
///
/// Replies from the primary to a client are a [`Reply`], not a message.
/// Every message from one replica to another carries the sender's view
/// number, and a replica only acts on normal-case messages whose view
/// matches its own: a sender that is behind is ignored, one that is ahead
/// makes the replica catch up first. The variants follow the sections of
/// the paper: normal operation, state transfer, view changes, recovery.
#[derive(Clone, Debug)]
pub enum Message<Op> {
    /// A client asks the primary to execute `op`. Backups ignore it. A
    /// request number no larger than the client's latest in the primary's
    /// client table is a re-send: it is answered from the table if it has
    /// executed, dropped otherwise.
    Request {
        client_id: ClientID,
        request_number: RequestNumber,
        op: Op,
    },
    /// The primary replicates the request it appended as `op_number` to
    /// the backups, and tells them how far it has committed so they can
    /// commit too. Backups accept it only in order: a gap means state
    /// transfer first. A `Prepare` for an op a backup already has is a
    /// re-send, and is acknowledged again.
    Prepare {
        view_number: ViewNumber,
        op_number: OpNumber,
        /// The client request being replicated.
        client_id: ClientID,
        request_number: RequestNumber,
        op: Op,
        /// The primary's commit number.
        commit_number: CommitID,
    },
    /// A backup tells the primary that it holds every op up to `op_number`.
    /// With a quorum of these for an op, counting itself and each backup
    /// once, the primary commits that op and everything before it.
    PrepareOk {
        view_number: ViewNumber,
        op_number: OpNumber,
        /// The backup sending the acknowledgement.
        replica_id: ReplicaID,
    },
    /// The primary's heartbeat while there are no requests: it carries the
    /// commit number so backups can commit, and its absence is how backups
    /// notice the primary is gone.
    Commit {
        view_number: ViewNumber,
        commit_number: CommitID,
    },
    /// A replica that is missing log entries asks the primary for the
    /// entries after `op_number`. Within a view that is everything after
    /// its own log; a replica catching up with a newer view asks from its
    /// commit number, since its uncommitted suffix may not have survived
    /// the view change.
    GetState {
        replica_id: ReplicaID,
        view_number: ViewNumber,
        op_number: OpNumber,
    },
    /// The primary's answer to `GetState`: the log after the requested op
    /// number. The paper sends only the op number of the last entry; the
    /// first is included too, so the receiver can tell a late reply to an
    /// earlier request from the one it is waiting for.
    NewState {
        view_number: ViewNumber,
        /// The log entries after `op_number_start`.
        log: Vec<LogEntry<Op>>,
        /// The op number the entries start after, as asked in `GetState`.
        op_number_start: OpNumber,
        /// The op number of the last entry.
        op_number_end: OpNumber,
        /// The sender's commit number.
        commit_number: CommitID,
    },
    /// A replica that suspects the primary has failed asks the others to
    /// move to `view_number`. A replica that receives one for a view ahead
    /// of its own adopts that view and sends its own.
    StartViewChange {
        view_number: ViewNumber,
        replica_id: ReplicaID,
    },
    /// A replica that has `StartViewChange` for `view_number` from f other
    /// replicas sends its state to the new view's primary. With a quorum of
    /// these the primary starts the view from the log with the latest
    /// `last_normal_view`, the longest if several.
    DoViewChange {
        view_number: ViewNumber,
        replica_id: ReplicaID,
        /// The latest view in which the sender's status was normal.
        last_normal_view: ViewNumber,
        log: Vec<LogEntry<Op>>,
        /// The length of `log`.
        op_number: OpNumber,
        commit_number: CommitID,
    },
    /// The new primary starts `view_number` with the log it chose. Backups
    /// replace their log with it, commit up to `commit_number`, and
    /// acknowledge the rest.
    StartView {
        view_number: ViewNumber,
        log: Vec<LogEntry<Op>>,
        /// The length of `log`.
        op_number: OpNumber,
        commit_number: CommitID,
    },
    /// A replica back from a crash with no memory asks the others for the
    /// current state. The nonce tells this recovery's responses apart from
    /// an earlier one's.
    Recovery {
        replica_id: ReplicaID,
        nonce: u64,
        /// The view the replica persisted before the crash. A replica
        /// behind it takes this as the request for that view change, which
        /// the crashed replica may have started and forgotten.
        view_number: ViewNumber,
    },
    /// A replica in normal status answers `Recovery` with its view; the
    /// primary of that view also sends its log and commit number. The
    /// recovering replica needs a quorum of these, including one from the
    /// primary of the latest view among them, and that view must be at
    /// least the one it persisted.
    RecoveryResponse {
        view_number: ViewNumber,
        /// The nonce from the `Recovery` this answers.
        nonce: u64,
        replica_id: ReplicaID,
        /// The sender's log and commit number, if it is the primary.
        state: Option<RecoveryState<Op>>,
    },
}

/// The primary's state in a `RecoveryResponse`.
#[derive(Clone, Debug)]
pub struct RecoveryState<Op> {
    pub log: Vec<LogEntry<Op>>,
    pub commit_number: CommitID,
}

/// Client.
///
/// A client sends one request at a time to the primary and waits for the
/// reply. Its owner delivers what [`Client::drain`] yields, feeds replies
/// to [`Client::on_reply`], and calls [`Client::on_idle`] now and then so a
/// request that got no reply is re-sent.
#[derive(Debug)]
pub struct Client<Op> {
    config: Config,
    client_id: ClientID,
    /// The latest view this client has heard of, which tells it who the
    /// primary is.
    view_number: ViewNumber,
    next_request_number: RequestNumber,
    /// The request awaiting a reply, kept so it can be re-sent.
    pending: Option<(RequestNumber, Op)>,
    outbox: Vec<(ReplicaID, Message<Op>)>,
}

impl<Op: Clone + Debug> Client<Op> {
    pub fn new(client_id: ClientID, config: Config) -> Client<Op> {
        Client {
            config,
            client_id,
            view_number: 0,
            next_request_number: 0,
            pending: None,
            outbox: Vec::new(),
        }
    }

    pub fn client_id(&self) -> ClientID {
        self.client_id
    }

    pub fn view_number(&self) -> ViewNumber {
        self.view_number
    }

    /// Sends `op` to the primary and returns the request number it was given.
    pub fn on_request(&mut self, op: Op) -> RequestNumber {
        trace!("Client {} <- {:?}", self.client_id, op);
        let request_number = self.next_request_number;
        self.next_request_number += 1;
        self.pending = Some((request_number, op.clone()));
        let primary_id = self.config.primary_id(self.view_number);
        self.outbox.push((
            primary_id,
            Message::Request {
                client_id: self.client_id,
                request_number,
                op,
            },
        ));
        request_number
    }

    /// Handles a reply for `request_number`, sent in view `view_number`.
    /// Every reply tells the client the current view, and with it the
    /// primary to send the next request to. Returns whether the reply
    /// answers the pending request; a duplicate or a reply for an earlier
    /// request does not.
    pub fn on_reply(&mut self, request_number: RequestNumber, view_number: ViewNumber) -> bool {
        if view_number > self.view_number {
            self.view_number = view_number;
        }
        if self
            .pending
            .as_ref()
            .is_some_and(|(pending, _)| *pending == request_number)
        {
            self.pending = None;
            true
        } else {
            false
        }
    }

    /// Called when no reply has arrived in a while. Re-sends the pending
    /// request, if any, to every replica: the primary may have changed
    /// without this client knowing, and backups ignore client requests.
    pub fn on_idle(&mut self) {
        let Some((request_number, op)) = &self.pending else {
            return;
        };
        trace!(
            "Client {} re-sends request {request_number}",
            self.client_id
        );
        for replica_id in self.config.replicas() {
            self.outbox.push((
                *replica_id,
                Message::Request {
                    client_id: self.client_id,
                    request_number: *request_number,
                    op: op.clone(),
                },
            ));
        }
    }

    /// Messages to send, with the replica each one goes to.
    pub fn drain(&mut self) -> std::vec::Drain<'_, (ReplicaID, Message<Op>)> {
        self.outbox.drain(..)
    }
}

/// What a replica is doing. See [`Replica::status`].
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Status {
    /// Taking part in normal operation.
    Normal,
    /// Waiting for `NewState` to fill a gap in the log, within the current
    /// view.
    StateTransfer,
    /// Back from a crash with no memory, and waiting for `RecoveryResponse`
    /// from a quorum before taking part in anything.
    Recovering,
    /// Taking part in a view change, or, once the new view is known to have
    /// started, waiting for `NewState` to catch up with it.
    ViewChange,
}

/// What a replica remembers about a client: its latest request, and the
/// reply to it once the request has been executed.
#[derive(Debug)]
struct ClientEntry<Output> {
    request_number: RequestNumber,
    reply: Option<Output>,
}

/// What a replica reported in a `DoViewChange` message: the view it was
/// last normal in, its log, and its commit number.
#[derive(Debug)]
struct DoViewChange<Op> {
    last_normal_view: ViewNumber,
    log: Vec<LogEntry<Op>>,
    commit_number: CommitID,
}

/// What a recovering replica keeps of a `RecoveryResponse`: the sender's
/// view, and its state if it was the primary of that view.
#[derive(Debug)]
struct RecoveryResponse<Op> {
    view_number: ViewNumber,
    state: Option<RecoveryState<Op>>,
}

/// Replica.
///
/// The owner feeds it messages with [`Replica::on_message`], calls
/// [`Replica::on_idle`] at a regular interval, and after each of those
/// delivers what [`Replica::drain_messages`] and [`Replica::drain_replies`]
/// yield.
#[derive(Debug)]
pub struct Replica<SM: StateMachine> {
    config: Config,
    self_id: ReplicaID,
    state_machine: SM,
    status: Status,
    view_number: ViewNumber,
    /// The latest view in which this replica's status was normal.
    last_normal_view: ViewNumber,
    commit_number: CommitID,
    log: Vec<LogEntry<SM::Input>>,
    /// For each uncommitted op number, the replicas that have acknowledged it.
    acks: BTreeMap<OpNumber, BTreeSet<ReplicaID>>,
    /// The client table: the latest request seen from each client, and its
    /// result once executed, so that a re-sent request is not run twice.
    client_table: BTreeMap<ClientID, ClientEntry<SM::Output>>,
    /// Whether the primary has been heard from since the last idle period.
    heard_from_primary: bool,
    /// Consecutive idle periods spent without hearing from the primary, or
    /// waiting for a view change to complete.
    idle_periods_waiting: usize,
    /// View changes entered without a stable stretch of normal status in
    /// between. Each one doubles the wait before the next, so that
    /// replicas whose timers fire faster than a view change can complete
    /// stop cutting each other off. Completing a view does not reset it:
    /// the replica that just did is the one whose timer would otherwise
    /// fire first in the next view change, and start yet another. It
    /// resets once the replica has been normal, hearing from the primary,
    /// for `Config::primary_timeout` idle periods.
    view_change_attempts: u32,
    /// Consecutive idle periods in normal status with the primary heard
    /// from, or as the primary.
    idle_periods_stable: usize,
    /// Replicas that sent `StartViewChange` for the current view.
    start_view_change_from: BTreeSet<ReplicaID>,
    /// Whether this replica has sent `DoViewChange` for the current view.
    do_view_change_sent: bool,
    /// Replicas that sent `DoViewChange` for the current view, with what they
    /// reported, if this replica is to be its primary.
    do_view_change_from: BTreeMap<ReplicaID, DoViewChange<SM::Input>>,
    /// Whether this replica has learned that the current view has started
    /// without it, and is fetching the view's state from its primary.
    catching_up: bool,
    /// The nonce of the recovery under way, if any.
    recovery_nonce: u64,
    /// `RecoveryResponse`s received for it, by sender.
    recovery_responses: BTreeMap<ReplicaID, RecoveryResponse<SM::Input>>,
    outbox: Vec<(ReplicaID, Message<SM::Input>)>,
    replies: Vec<Reply<SM::Output>>,
}

impl<SM: StateMachine> Replica<SM> {
    pub fn new(self_id: ReplicaID, config: Config, state_machine: SM) -> Replica<SM> {
        Replica {
            self_id,
            config,
            state_machine,
            status: Status::Normal,
            view_number: 0,
            last_normal_view: 0,
            commit_number: 0,
            log: Vec::new(),
            acks: BTreeMap::new(),
            client_table: BTreeMap::new(),
            heard_from_primary: true,
            idle_periods_waiting: 0,
            view_change_attempts: 0,
            idle_periods_stable: 0,
            start_view_change_from: BTreeSet::new(),
            do_view_change_sent: false,
            do_view_change_from: BTreeMap::new(),
            catching_up: false,
            recovery_nonce: 0,
            recovery_responses: BTreeMap::new(),
            outbox: Vec::new(),
            replies: Vec::new(),
        }
    }

    /// Creates a replica that is back from a crash with no memory. It
    /// starts in recovering status, in the view the owner had persisted
    /// for it, and asks the other replicas for the current state; until a
    /// quorum has answered, it takes no part in anything else. The nonce
    /// must differ from that of any earlier recovery of this replica, so a
    /// late response to an earlier one is not taken for a current one.
    pub fn recover(
        self_id: ReplicaID,
        config: Config,
        state_machine: SM,
        view_number: ViewNumber,
        nonce: u64,
    ) -> Replica<SM> {
        let mut replica = Replica::new(self_id, config, state_machine);
        replica.status = Status::Recovering;
        replica.view_number = view_number;
        replica.last_normal_view = view_number;
        replica.recovery_nonce = nonce;
        replica.send_recovery();
        replica
    }

    /// The main entry point to replica logic.
    pub fn on_message(&mut self, message: Message<SM::Input>) {
        trace!("Replica {} <- {:?}", self.self_id, message);
        // A recovering replica knows nothing it could safely act on: not
        // which view is current, not what it acknowledged before the crash.
        // Until it has recovered, only recovery responses matter.
        if self.status == Status::Recovering && !matches!(message, Message::RecoveryResponse { .. })
        {
            return;
        }
        match message {
            Message::Request {
                client_id,
                request_number,
                op,
            } => {
                self.on_request(client_id, request_number, op);
            }
            Message::Prepare {
                view_number,
                op_number,
                client_id,
                request_number,
                op,
                commit_number,
            } => {
                let entry = LogEntry {
                    client_id,
                    request_number,
                    op,
                };
                self.on_prepare(view_number, op_number, entry, commit_number);
            }
            Message::PrepareOk {
                view_number,
                op_number,
                replica_id,
            } => {
                self.on_prepare_ok(view_number, op_number, replica_id);
            }
            Message::Commit {
                view_number,
                commit_number,
            } => {
                self.on_commit(view_number, commit_number);
            }
            Message::GetState {
                replica_id,
                view_number,
                op_number,
            } => {
                self.on_get_state(replica_id, view_number, op_number);
            }
            Message::NewState {
                view_number,
                log,
                op_number_start,
                op_number_end,
                commit_number,
            } => {
                self.on_new_state(
                    view_number,
                    log,
                    op_number_start,
                    op_number_end,
                    commit_number,
                );
            }
            Message::StartViewChange {
                view_number,
                replica_id,
            } => {
                self.on_start_view_change(view_number, replica_id);
            }
            Message::DoViewChange {
                view_number,
                replica_id,
                last_normal_view,
                log,
                op_number,
                commit_number,
            } => {
                assert_eq!(log.len(), op_number);
                let dvc = DoViewChange {
                    last_normal_view,
                    log,
                    commit_number,
                };
                self.on_do_view_change(view_number, replica_id, dvc);
            }
            Message::StartView {
                view_number,
                log,
                op_number,
                commit_number,
            } => {
                assert_eq!(log.len(), op_number);
                self.on_start_view(view_number, log, commit_number);
            }
            Message::Recovery {
                replica_id,
                nonce,
                view_number,
            } => {
                self.on_recovery(replica_id, nonce, view_number);
            }
            Message::RecoveryResponse {
                view_number,
                nonce,
                replica_id,
                state,
            } => {
                self.on_recovery_response(view_number, nonce, replica_id, state);
            }
        }
    }

    /// The client sends a `Request` message to the primary, which replicates
    /// the operation to the other replicas.
    fn on_request(&mut self, client_id: ClientID, request_number: RequestNumber, op: SM::Input) {
        // Backups ignore client requests; clients send to every replica
        // when they re-send, in case the primary has changed. A primary that
        // is not in normal status drops the request too, and the client's
        // re-send will find it once it is.
        if !self.is_primary() || self.status != Status::Normal {
            return;
        }
        // Consult the client table. A request number no larger than the
        // latest one from this client is a re-send: if it is the latest
        // request and it has been executed, re-send the reply, otherwise
        // drop it. The reply will follow once the request commits.
        if let Some(entry) = self.client_table.get(&client_id) {
            if request_number < entry.request_number {
                return;
            }
            if request_number == entry.request_number {
                if let Some(result) = &entry.reply {
                    let reply = Reply {
                        view_number: self.view_number,
                        client_id,
                        request_number,
                        result: result.clone(),
                    };
                    self.replies.push(reply);
                }
                return;
            }
        }
        // Append the request to our log, which also records it in the
        // client table.
        self.append_to_log(LogEntry {
            client_id,
            request_number,
            op: op.clone(),
        });
        // And then register our own acknowledgement.
        let op_number = self.op_number();
        self.acks.insert(op_number, BTreeSet::from([self.self_id]));
        // Send a prepare message to all the replicas.
        self.send_to_others(Message::Prepare {
            view_number: self.view_number,
            op_number,
            client_id,
            request_number,
            op,
            commit_number: self.commit_number,
        });
    }

    /// The primary sends a `Prepare` message to replicate an operation to backup
    /// nodes. The nodes that receive a `Prepare` message will reply with `PrepareOk`
    /// when they have appended `op` to their logs. The message also contains the
    /// commit number of the primary, so that the backups can commit their logs up
    /// to that point.
    fn on_prepare(
        &mut self,
        view_number: ViewNumber,
        op_number: OpNumber,
        entry: LogEntry<SM::Input>,
        commit_number: CommitID,
    ) {
        if !self.accept_from_primary(view_number) {
            return;
        }
        // If we fell behind in the log, initiate state transfer.
        if op_number > self.op_number() + 1 {
            self.state_transfer();
            return;
        }
        if op_number == self.op_number() + 1 {
            // Append the request to our log.
            self.append_to_log(entry);
        }
        // Otherwise we already have the op: the primary re-sent it because
        // it has not seen our `PrepareOk`, so acknowledge it again below.
        //
        // Commit the log up to the commit number received in `Prepare`
        // message, which represents the committed state of the primary. A
        // re-sent `Prepare` can carry a commit number beyond our log; the
        // re-sent ops that follow close that gap.
        self.commit_up_to(commit_number.min(self.op_number()), false);
        // Acknowledge to the primary that we have every op up to our op
        // number.
        self.send_prepare_ok();
    }

    /// Backup nodes send `PrepareOk` message to the primary to acknowledge that
    /// they have appended an op to their logs. When the primary has
    /// received `PrepareOk` messages from a quorum of replicas, it commits
    /// the operation and replies to the client.
    fn on_prepare_ok(
        &mut self,
        view_number: ViewNumber,
        op_number: OpNumber,
        replica_id: ReplicaID,
    ) {
        if view_number != self.view_number || !self.is_primary() || self.status != Status::Normal {
            return;
        }
        if op_number <= self.commit_number {
            return; // already committed
        }
        // Register the acknowledgement. A quorum is a set of distinct
        // replicas: the same backup acknowledging twice, because the network
        // replayed its message or because it answered a re-sent `Prepare`,
        // still counts once.
        let Some(acked_by) = self.acks.get_mut(&op_number) else {
            return;
        };
        if !acked_by.insert(replica_id) || acked_by.len() != self.config.quorum() {
            return;
        }
        // A quorum for `op_number` means the operation and all earlier ones
        // are committed: backups only acknowledge an operation once they
        // have every earlier one in their log. Earlier operations may not
        // have reached a quorum on their own, for example because their
        // `PrepareOk` messages were lost or overtaken, so commit everything
        // up to `op_number`, in order, and reply to the client for each.
        self.commit_up_to(op_number, true);
        self.acks
            .retain(|acked_op_number, _| *acked_op_number > op_number);
    }

    /// A backup node typically commits its log as part of `Prepare`
    /// message handling because the primary uses that also to signal the
    /// current commit number. However, `Prepare` is sent only in
    /// reaction to a client `Request` message. If there are no client
    /// requests, then the primary sends a `Commit` message to backup
    /// nodes instead to give backup nodes the chance to commit.
    fn on_commit(&mut self, view_number: ViewNumber, commit_number: CommitID) {
        if !self.accept_from_primary(view_number) {
            return;
        }
        if commit_number > self.op_number() {
            self.state_transfer();
            return;
        }
        self.commit_up_to(commit_number, false);
    }

    /// Checks a `Prepare` or `Commit` from the primary of `view_number`
    /// against our own view and status, and returns whether to process it
    /// as a normal-case message.
    ///
    /// A message from a later view means a view change happened without
    /// us, and one for our own view while we are still changing to it means
    /// the view has started: either way we first catch up with the view's
    /// state from its primary.
    fn accept_from_primary(&mut self, view_number: ViewNumber) -> bool {
        if view_number < self.view_number {
            return false;
        }
        if view_number > self.view_number {
            self.catch_up_with_view(view_number);
            return false;
        }
        // The primary of our view is alive.
        self.heard_from_primary = true;
        match self.status {
            Status::Normal => !self.is_primary(),
            Status::StateTransfer | Status::Recovering => false,
            Status::ViewChange => {
                self.catch_up_with_view(view_number);
                false
            }
        }
    }

    /// A replica sends a `GetState` message to another replica to catch
    /// up on its log. Only a replica in normal status and in the requested
    /// view answers.
    fn on_get_state(
        &mut self,
        replica_id: ReplicaID,
        view_number: ViewNumber,
        op_number: OpNumber,
    ) {
        if self.status != Status::Normal
            || view_number != self.view_number
            || op_number > self.op_number()
        {
            return;
        }
        let message = Message::NewState {
            view_number,
            log: self.log[op_number..].to_vec(),
            op_number_start: op_number,
            op_number_end: self.op_number(),
            commit_number: self.commit_number,
        };
        self.send(replica_id, message);
    }

    /// A replica receives a `NewState` message in response to a
    /// `GetState` message it sent itself to catch up on its log.
    fn on_new_state(
        &mut self,
        view_number: ViewNumber,
        log: Vec<LogEntry<SM::Input>>,
        op_number_start: OpNumber,
        op_number_end: OpNumber,
        commit_number: CommitID,
    ) {
        if view_number != self.view_number {
            return;
        }
        assert_eq!(log.len(), op_number_end - op_number_start);
        self.heard_from_primary = true;
        match self.status {
            Status::StateTransfer => {
                // We are filling a gap within our view. The reply may
                // answer an earlier `GetState` that the network delayed or
                // replayed, in which case it starts before our current op
                // number. We can still use whatever it has beyond our log,
                // since within a view the overlapping entries are
                // identical. A reply that starts past our log or that ends
                // inside it is of no use, so keep waiting for another.
                let op_number = self.op_number();
                if op_number_start > op_number || op_number_end <= op_number {
                    return;
                }
                for entry in log.into_iter().skip(op_number - op_number_start) {
                    self.append_to_log(entry);
                }
                assert_eq!(self.op_number(), op_number_end);
                self.commit_up_to(commit_number, false);
                self.status = Status::Normal;
            }
            Status::ViewChange if self.catching_up => {
                // We are catching up with a view that started without us,
                // and asked for everything after our commit number. What
                // we have beyond that is from an earlier view and never
                // committed, so it is replaced by the new view's log.
                if op_number_start != self.commit_number {
                    return;
                }
                let mut new_log = self.log.clone();
                new_log.truncate(op_number_start);
                new_log.extend(log);
                self.install_log(new_log);
                assert_eq!(self.op_number(), op_number_end);
                self.commit_up_to(commit_number, false);
                self.enter_normal();
            }
            _ => return,
        }
        self.send_prepare_ok();
    }

    /// Asks the primary for the log after our op number, to fill a gap
    /// within the current view.
    fn state_transfer(&mut self) {
        self.status = Status::StateTransfer;
        self.send_get_state(self.op_number());
    }

    /// A replica that suspects the primary has failed, or that hears of a
    /// view change already under way, asks the others to move to a new
    /// view.
    fn on_start_view_change(&mut self, view_number: ViewNumber, replica_id: ReplicaID) {
        if view_number < self.view_number {
            return;
        }
        if view_number > self.view_number {
            self.start_view_change(view_number);
        } else if self.status != Status::ViewChange {
            // The view has already started. If we are its primary, the
            // sender missed `StartView`, so send it again.
            if self.status == Status::Normal && self.is_primary() {
                self.send_start_view(replica_id);
            }
            return;
        }
        self.start_view_change_from.insert(replica_id);
        self.maybe_send_do_view_change();
    }

    /// Replicas that know a majority wants the new view send their state to
    /// its primary, which starts the view once it has a quorum of them.
    fn on_do_view_change(
        &mut self,
        view_number: ViewNumber,
        replica_id: ReplicaID,
        dvc: DoViewChange<SM::Input>,
    ) {
        if view_number < self.view_number || self.config.primary_id(view_number) != self.self_id {
            return;
        }
        if view_number > self.view_number {
            self.start_view_change(view_number);
        } else if self.status == Status::Normal {
            // The view has already started; the sender missed `StartView`.
            self.send_start_view(replica_id);
            return;
        }
        self.record_do_view_change(replica_id, dvc);
    }

    /// The new primary starts the view with the log it chose. Backups
    /// replace their log with it, commit what it says is committed, and
    /// acknowledge whatever is not.
    fn on_start_view(
        &mut self,
        view_number: ViewNumber,
        log: Vec<LogEntry<SM::Input>>,
        commit_number: CommitID,
    ) {
        // A `StartView` for our own view is only new to us while we are
        // still changing to it; a replayed one after that must not replace
        // a log that has since grown.
        if view_number < self.view_number
            || (view_number == self.view_number && self.status != Status::ViewChange)
        {
            return;
        }
        self.view_number = view_number;
        self.install_log(log);
        self.commit_up_to(commit_number, false);
        self.enter_normal();
        self.acks.clear();
        self.send_prepare_ok();
    }

    /// Moves to `view_number` and asks the other replicas to do the same.
    fn start_view_change(&mut self, view_number: ViewNumber) {
        trace!(
            "Replica {} starts view change to {view_number}",
            self.self_id
        );
        // A view change entered from another one, whether on our own
        // timer or because someone else's fired, means the previous one
        // did not complete: wait longer for this one.
        if self.status == Status::ViewChange {
            self.view_change_attempts += 1;
        }
        self.view_number = view_number;
        self.status = Status::ViewChange;
        self.catching_up = false;
        self.idle_periods_waiting = 0;
        self.clear_view_change_state();
        self.send_to_others(Message::StartViewChange {
            view_number,
            replica_id: self.self_id,
        });
        self.maybe_send_do_view_change();
    }

    fn clear_view_change_state(&mut self) {
        self.start_view_change_from.clear();
        self.do_view_change_sent = false;
        self.do_view_change_from.clear();
    }

    /// Sends `DoViewChange` once `f` other replicas want the same view.
    fn maybe_send_do_view_change(&mut self) {
        if self.status != Status::ViewChange || self.catching_up || self.do_view_change_sent {
            return;
        }
        let f = self.config.replicas().len() / 2;
        if self.start_view_change_from.len() < f {
            return;
        }
        self.do_view_change_sent = true;
        self.send_do_view_change();
    }

    /// Sends our state to the new view's primary, or records it directly if
    /// that is us.
    fn send_do_view_change(&mut self) {
        let view_number = self.view_number;
        let dvc = DoViewChange {
            last_normal_view: self.last_normal_view,
            log: self.log.clone(),
            commit_number: self.commit_number,
        };
        let primary_id = self.config.primary_id(view_number);
        if primary_id == self.self_id {
            self.record_do_view_change(self.self_id, dvc);
        } else {
            self.send(
                primary_id,
                Message::DoViewChange {
                    view_number,
                    replica_id: self.self_id,
                    last_normal_view: dvc.last_normal_view,
                    op_number: dvc.log.len(),
                    log: dvc.log,
                    commit_number: dvc.commit_number,
                },
            );
        }
    }

    /// Records a `DoViewChange` and, with a quorum of them, starts the
    /// view: the log is the one from the latest normal view, the longest if
    /// several, which by quorum intersection holds every committed op.
    fn record_do_view_change(&mut self, replica_id: ReplicaID, dvc: DoViewChange<SM::Input>) {
        self.do_view_change_from.insert(replica_id, dvc);
        if self.do_view_change_from.len() < self.config.quorum() {
            return;
        }
        let best = self
            .do_view_change_from
            .values()
            .max_by_key(|dvc| (dvc.last_normal_view, dvc.log.len()))
            .unwrap();
        let log = best.log.clone();
        let commit_number = self
            .do_view_change_from
            .values()
            .map(|dvc| dvc.commit_number)
            .max()
            .unwrap();
        trace!(
            "Replica {} starts view {} with {} ops, {commit_number} committed",
            self.self_id,
            self.view_number,
            log.len()
        );
        self.install_log(log);
        // Execute what committed in earlier views but was not yet executed
        // here, and reply to the clients: the old primary may have failed
        // before it could.
        self.commit_up_to(commit_number, true);
        self.enter_normal();
        self.acks.clear();
        for op_number in self.commit_number + 1..=self.op_number() {
            self.acks.insert(op_number, BTreeSet::from([self.self_id]));
        }
        for replica_id in self.config.replicas().to_vec() {
            if replica_id != self.self_id {
                self.send_start_view(replica_id);
            }
        }
    }

    fn send_start_view(&mut self, replica_id: ReplicaID) {
        let message = Message::StartView {
            view_number: self.view_number,
            log: self.log.clone(),
            op_number: self.op_number(),
            commit_number: self.commit_number,
        };
        self.send(replica_id, message);
    }

    /// Learns that `view_number` has started, and asks its primary for the
    /// log from our commit number on.
    fn catch_up_with_view(&mut self, view_number: ViewNumber) {
        if self.view_number == view_number && self.catching_up {
            return;
        }
        trace!(
            "Replica {} catches up with view {view_number}",
            self.self_id
        );
        self.view_number = view_number;
        self.status = Status::ViewChange;
        self.catching_up = true;
        self.idle_periods_waiting = 0;
        self.clear_view_change_state();
        self.send_get_state(self.commit_number);
    }

    /// Returns to normal status in the current view. The view change
    /// backoff stays until the view has proved stable; see
    /// `view_change_attempts`.
    fn enter_normal(&mut self) {
        self.status = Status::Normal;
        self.last_normal_view = self.view_number;
        self.catching_up = false;
        self.heard_from_primary = true;
        self.idle_periods_waiting = 0;
        self.idle_periods_stable = 0;
        self.clear_view_change_state();
    }

    /// A replica in normal status answers a recovering replica with its
    /// view; if it is the primary, with its log and commit number too.
    ///
    /// The recovering replica persisted `view_number` before it crashed.
    /// If that is ahead of us, it had started a view change we never heard
    /// of, and it will not rejoin a view older than that, so start the
    /// change now as if its `StartViewChange` had just arrived.
    fn on_recovery(&mut self, replica_id: ReplicaID, nonce: u64, view_number: ViewNumber) {
        if view_number > self.view_number && self.status != Status::Recovering {
            self.start_view_change(view_number);
            return;
        }
        if self.status != Status::Normal {
            return;
        }
        let state = self.is_primary().then(|| RecoveryState {
            log: self.log.clone(),
            commit_number: self.commit_number,
        });
        let message = Message::RecoveryResponse {
            view_number: self.view_number,
            nonce,
            replica_id: self.self_id,
            state,
        };
        self.send(replica_id, message);
    }

    /// Collects recovery responses. With a quorum of them, including one
    /// from the primary of the latest view among them, the replica takes
    /// that primary's state and is back. The latest view must be at least
    /// the one persisted before the crash: a lower one means the cluster
    /// has not yet caught up with a view change this replica took part in
    /// and then forgot, and joining it could let that view change complete
    /// against a view already running.
    fn on_recovery_response(
        &mut self,
        view_number: ViewNumber,
        nonce: u64,
        replica_id: ReplicaID,
        state: Option<RecoveryState<SM::Input>>,
    ) {
        if self.status != Status::Recovering || nonce != self.recovery_nonce {
            return;
        }
        self.recovery_responses
            .insert(replica_id, RecoveryResponse { view_number, state });
        if self.recovery_responses.len() < self.config.quorum() {
            return;
        }
        let latest_view = self
            .recovery_responses
            .values()
            .map(|response| response.view_number)
            .max()
            .unwrap();
        if latest_view < self.view_number {
            return;
        }
        let primary_id = self.config.primary_id(latest_view);
        let Some(RecoveryResponse {
            view_number: primary_view,
            state: Some(state),
        }) = self.recovery_responses.get(&primary_id)
        else {
            return;
        };
        if *primary_view != latest_view {
            return;
        }
        let state = state.clone();
        trace!(
            "Replica {} recovers into view {latest_view} with {} ops, {} committed",
            self.self_id,
            state.log.len(),
            state.commit_number
        );
        self.recovery_responses.clear();
        self.view_number = latest_view;
        self.install_log(state.log);
        self.commit_up_to(state.commit_number, false);
        self.enter_normal();
    }

    fn send_recovery(&mut self) {
        let message = Message::Recovery {
            replica_id: self.self_id,
            nonce: self.recovery_nonce,
            view_number: self.view_number,
        };
        self.send_to_others(message);
    }

    /// When there are no client requests, the primary node sends a
    /// `Commit` message to backup nodes periodically to let them commit
    /// if needed.
    ///
    /// Idle periods also drive retransmission, which the paper leaves out of
    /// its description: a backup waiting for `NewState` asks again in case
    /// its `GetState` or the reply was lost, the primary re-sends the
    /// `Prepare` for every op that has not committed yet in case a `Prepare`
    /// or its `PrepareOk` was lost, replicas in a view change re-send
    /// their view change messages, and a recovering replica re-sends
    /// `Recovery`.
    ///
    /// And they drive the timers: a backup that has not heard from the
    /// primary for `Config::primary_timeout` idle periods starts a view
    /// change, and a view change that takes as long to complete is
    /// followed by another, waiting twice as long each time.
    pub fn on_idle(&mut self) {
        match self.status {
            Status::Normal if self.is_primary() => {
                self.note_stable();
                let view_number = self.view_number;
                let commit_number = self.commit_number;
                self.send_to_others(Message::Commit {
                    view_number,
                    commit_number,
                });
                for op_number in commit_number + 1..=self.op_number() {
                    let entry = self.log[op_number - 1].clone();
                    self.send_to_others(Message::Prepare {
                        view_number,
                        op_number,
                        client_id: entry.client_id,
                        request_number: entry.request_number,
                        op: entry.op,
                        commit_number,
                    });
                }
            }
            Status::Recovering => self.send_recovery(),
            Status::Normal | Status::StateTransfer => {
                if self.status == Status::StateTransfer {
                    self.state_transfer();
                }
                if std::mem::replace(&mut self.heard_from_primary, false) {
                    self.idle_periods_waiting = 0;
                    self.note_stable();
                } else {
                    self.idle_periods_stable = 0;
                    if self.wait_timed_out() {
                        self.start_view_change(self.view_number + 1);
                    }
                }
            }
            Status::ViewChange => {
                if self.wait_timed_out() {
                    self.start_view_change(self.view_number + 1);
                } else if self.catching_up {
                    self.send_get_state(self.commit_number);
                } else {
                    self.send_to_others(Message::StartViewChange {
                        view_number: self.view_number,
                        replica_id: self.self_id,
                    });
                    if self.do_view_change_sent {
                        self.send_do_view_change();
                    }
                }
            }
        }
    }

    /// Counts an idle period of stable normal operation. After
    /// `Config::primary_timeout` of them in a row the view changes are
    /// over, and the backoff is forgotten.
    fn note_stable(&mut self) {
        self.idle_periods_stable += 1;
        if self.idle_periods_stable >= self.config.primary_timeout() {
            self.view_change_attempts = 0;
        }
    }

    /// Counts an idle period spent waiting, and returns whether the wait
    /// has gone on for `Config::primary_timeout` periods, doubled for every
    /// view change entered without a stable stretch of normal status in
    /// between.
    fn wait_timed_out(&mut self) -> bool {
        self.idle_periods_waiting += 1;
        let backoff = self.view_change_attempts.min(10);
        self.idle_periods_waiting >= self.config.primary_timeout() << backoff
    }

    /// Appends `entry` to the log and records it as the client's latest
    /// request, not yet executed.
    fn append_to_log(&mut self, entry: LogEntry<SM::Input>) {
        self.client_table.insert(
            entry.client_id,
            ClientEntry {
                request_number: entry.request_number,
                reply: None,
            },
        );
        self.log.push(entry);
    }

    /// Replaces the log with `log`, which must contain our committed prefix,
    /// and rebuilds the client table from it. Replies kept for committed
    /// requests survive; the rest of the table follows the new log.
    fn install_log(&mut self, log: Vec<LogEntry<SM::Input>>) {
        assert!(log.len() >= self.commit_number);
        let old_table = std::mem::take(&mut self.client_table);
        for (i, entry) in log.iter().enumerate() {
            let reply = if i < self.commit_number {
                old_table
                    .get(&entry.client_id)
                    .filter(|old| old.request_number == entry.request_number)
                    .and_then(|old| old.reply.clone())
            } else {
                None
            };
            self.client_table.insert(
                entry.client_id,
                ClientEntry {
                    request_number: entry.request_number,
                    reply,
                },
            );
        }
        self.log = log;
    }

    /// Commits every op up to `commit_number`, in order, replying to the
    /// clients if `reply` is set. The commit number never moves backwards.
    fn commit_up_to(&mut self, commit_number: CommitID, reply: bool) {
        while self.commit_number < commit_number {
            let response = self.commit_op(self.commit_number);
            if reply {
                self.replies.push(response);
            }
        }
    }

    /// Commits the operation at log index `op_idx` and returns the reply for
    /// it. The result is also kept in the client table, if the request is
    /// still the client's latest, so a re-sent request can be answered
    /// without running it again.
    fn commit_op(&mut self, op_idx: usize) -> Reply<SM::Output> {
        let entry = self.log[op_idx].clone();
        let result = self.state_machine.apply(entry.op);
        self.commit_number += 1;
        if let Some(client) = self.client_table.get_mut(&entry.client_id) {
            if client.request_number == entry.request_number {
                client.reply = Some(result.clone());
            }
        }
        Reply {
            view_number: self.view_number,
            client_id: entry.client_id,
            request_number: entry.request_number,
            result,
        }
    }

    /// Acknowledges to the primary that we have every op up to our op
    /// number.
    fn send_prepare_ok(&mut self) {
        let message = Message::PrepareOk {
            view_number: self.view_number,
            op_number: self.op_number(),
            replica_id: self.self_id,
        };
        self.send_to_primary(message);
    }

    fn send_get_state(&mut self, op_number: OpNumber) {
        let message = Message::GetState {
            replica_id: self.self_id,
            view_number: self.view_number,
            op_number,
        };
        self.send_to_primary(message);
    }

    fn send_to_primary(&mut self, message: Message<SM::Input>) {
        let primary_id = self.primary_id();
        self.send(primary_id, message);
    }

    fn send_to_others(&mut self, message: Message<SM::Input>) {
        for replica_id in self.config.replicas().to_vec() {
            if replica_id != self.self_id {
                self.send(replica_id, message.clone());
            }
        }
    }

    fn send(&mut self, replica_id: ReplicaID, message: Message<SM::Input>) {
        self.outbox.push((replica_id, message));
    }

    /// Returns the ID of this replica.
    pub fn id(&self) -> ReplicaID {
        self.self_id
    }

    /// Returns `true` if this replica is the primary of its current view.
    pub fn is_primary(&self) -> bool {
        self.self_id == self.primary_id()
    }

    /// Returns the ID of the primary of the current view.
    pub fn primary_id(&self) -> ReplicaID {
        self.config.primary_id(self.view_number)
    }

    /// Returns the current view number.
    pub fn view_number(&self) -> ViewNumber {
        self.view_number
    }

    /// What this replica is doing right now.
    pub fn status(&self) -> Status {
        self.status
    }

    /// Whether this replica is still recovering from a crash.
    pub fn is_recovering(&self) -> bool {
        self.status == Status::Recovering
    }

    /// Returns the commit number, i.e. the number of log entries that have
    /// been applied to the state machine.
    pub fn commit_number(&self) -> CommitID {
        self.commit_number
    }

    /// Returns the op number, i.e. the number of entries in the log.
    pub fn op_number(&self) -> OpNumber {
        self.log.len()
    }

    /// Returns the log.
    pub fn log(&self) -> &[LogEntry<SM::Input>] {
        &self.log
    }

    /// Returns the state machine.
    pub fn state_machine(&self) -> &SM {
        &self.state_machine
    }

    /// Messages to send to other replicas.
    pub fn drain_messages(&mut self) -> std::vec::Drain<'_, (ReplicaID, Message<SM::Input>)> {
        self.outbox.drain(..)
    }

    /// Replies to send to clients.
    pub fn drain_replies(&mut self) -> std::vec::Drain<'_, Reply<SM::Output>> {
        self.replies.drain(..)
    }
}
