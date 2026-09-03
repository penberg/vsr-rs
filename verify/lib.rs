//! Conformance of the Rust replica to the Lean model in `lean/`.
//!
//! A trace is a list of cluster steps: deliver a message, tick a replica,
//! hand a replica a client request, or recover a replica. [`Cluster`]
//! runs the real replicas through a trace and prints what it sees after
//! each step. `lean/Main.lean` does the same with the model, in the same
//! format, and the test in `verify_tests.rs` diffs the two.
//!
//! The network is the model's: every message ever sent stays in a list
//! and any of them can be delivered at any time, so one rule covers loss,
//! delay, replay, and reordering.

use std::fmt::{self, Write};
use vsr_rs::{ClientID, Config, LogEntry, Message, Replica, ReplicaID, Reply, StateMachine, Status};

/// The state machine on both sides: it records every op and answers with
/// how many it has applied.
#[derive(Debug, Default)]
pub struct Recorder {
    pub applied: Vec<u64>,
}

impl StateMachine for Recorder {
    type Input = u64;
    type Output = usize;

    fn apply(&mut self, op: u64) -> usize {
        self.applied.push(op);
        self.applied.len()
    }
}

/// One step of a trace.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Step {
    Deliver(usize),
    Idle(ReplicaID),
    Request {
        to: ReplicaID,
        client_id: ClientID,
        request_number: usize,
        op: u64,
    },
    Recover {
        replica_id: ReplicaID,
        nonce: u64,
    },
}

impl fmt::Display for Step {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Step::Deliver(i) => write!(f, "deliver {i}"),
            Step::Idle(id) => write!(f, "idle {id}"),
            Step::Request {
                to,
                client_id,
                request_number,
                op,
            } => write!(f, "request to={to} client={client_id} request={request_number} op={op}"),
            Step::Recover { replica_id, nonce } => write!(f, "recover {replica_id} nonce={nonce}"),
        }
    }
}

#[derive(Clone, Debug)]
pub struct Trace {
    pub replica_count: usize,
    pub primary_timeout: usize,
    pub steps: Vec<Step>,
}

impl fmt::Display for Trace {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        writeln!(
            f,
            "config replicas={} timeout={}",
            self.replica_count, self.primary_timeout
        )?;
        for step in &self.steps {
            writeln!(f, "{step}")?;
        }
        Ok(())
    }
}

pub struct Cluster {
    config: Config,
    pub replicas: Vec<Replica<Recorder>>,
    pub sent: Vec<(ReplicaID, Message<u64>)>,
    pub replies: Vec<Reply<usize>>,
}

impl Cluster {
    pub fn new(replica_count: usize, primary_timeout: usize) -> Cluster {
        let mut config = Config::new();
        for _ in 0..replica_count {
            config.add_replica();
        }
        config.set_primary_timeout(primary_timeout);
        let replicas = (0..replica_count)
            .map(|id| Replica::new(id, config.clone(), Recorder::default()))
            .collect();
        Cluster {
            config,
            replicas,
            sent: Vec::new(),
            replies: Vec::new(),
        }
    }

    pub fn step(&mut self, step: Step) {
        match step {
            Step::Deliver(i) => {
                let Some((to, message)) = self.sent.get(i).cloned() else {
                    return;
                };
                self.replicas[to].on_message(message);
                self.drain(to);
            }
            Step::Idle(id) => {
                if id >= self.replicas.len() {
                    return;
                }
                self.replicas[id].on_idle();
                self.drain(id);
            }
            Step::Request {
                to,
                client_id,
                request_number,
                op,
            } => {
                if to >= self.replicas.len() {
                    return;
                }
                self.replicas[to].on_message(Message::Request {
                    client_id,
                    request_number,
                    op,
                });
                self.drain(to);
            }
            Step::Recover { replica_id, nonce } => {
                if replica_id >= self.replicas.len() {
                    return;
                }
                let view_number = self.replicas[replica_id].view_number();
                self.replicas[replica_id] = Replica::recover(
                    replica_id,
                    self.config.clone(),
                    Recorder::default(),
                    view_number,
                    nonce,
                );
                self.drain(replica_id);
            }
        }
    }

    fn drain(&mut self, id: ReplicaID) {
        let replica = &mut self.replicas[id];
        self.sent.extend(replica.drain_messages());
        self.replies.extend(replica.drain_replies());
    }

    /// Runs the trace and returns what the model's replay prints for it.
    pub fn observe(trace: &Trace) -> String {
        let mut cluster = Cluster::new(trace.replica_count, trace.primary_timeout);
        let mut out = String::new();
        for (n, step) in trace.steps.iter().enumerate() {
            let sent_before = cluster.sent.len();
            let replies_before = cluster.replies.len();
            cluster.step(*step);
            writeln!(out, "step {n} {step}").unwrap();
            for (i, (to, message)) in cluster.sent.iter().enumerate().skip(sent_before) {
                writeln!(out, "send {i} to={to} {}", format_message(message)).unwrap();
            }
            for reply in &cluster.replies[replies_before..] {
                writeln!(
                    out,
                    "Reply view={} client={} request={} result={}",
                    reply.view_number, reply.client_id, reply.request_number, reply.result
                )
                .unwrap();
            }
            for (id, replica) in cluster.replicas.iter().enumerate() {
                writeln!(out, "{}", format_replica(id, replica)).unwrap();
            }
        }
        out
    }
}

fn format_entry(entry: &LogEntry<u64>) -> String {
    format!("{}:{}:{}", entry.client_id, entry.request_number, entry.op)
}

fn format_log(log: &[LogEntry<u64>]) -> String {
    let entries: Vec<String> = log.iter().map(format_entry).collect();
    format!("[{}]", entries.join(","))
}

pub fn format_message(message: &Message<u64>) -> String {
    match message {
        Message::Request {
            client_id,
            request_number,
            op,
        } => format!("Request client={client_id} request={request_number} op={op}"),
        Message::Prepare {
            view_number,
            op_number,
            client_id,
            request_number,
            op,
            commit_number,
        } => format!(
            "Prepare view={view_number} op={op_number} client={client_id} request={request_number} input={op} commit={commit_number}"
        ),
        Message::PrepareOk {
            view_number,
            op_number,
            replica_id,
        } => format!("PrepareOk view={view_number} op={op_number} replica={replica_id}"),
        Message::Commit {
            view_number,
            commit_number,
        } => format!("Commit view={view_number} commit={commit_number}"),
        Message::GetState {
            replica_id,
            view_number,
            op_number,
        } => format!("GetState replica={replica_id} view={view_number} op={op_number}"),
        Message::NewState {
            view_number,
            log,
            op_number_start,
            op_number_end,
            commit_number,
        } => format!(
            "NewState view={view_number} log={} start={op_number_start} end={op_number_end} commit={commit_number}",
            format_log(log)
        ),
        Message::StartViewChange {
            view_number,
            replica_id,
        } => format!("StartViewChange view={view_number} replica={replica_id}"),
        Message::DoViewChange {
            view_number,
            replica_id,
            last_normal_view,
            log,
            op_number,
            commit_number,
        } => format!(
            "DoViewChange view={view_number} replica={replica_id} last_normal={last_normal_view} log={} op={op_number} commit={commit_number}",
            format_log(log)
        ),
        Message::StartView {
            view_number,
            log,
            op_number,
            commit_number,
        } => format!(
            "StartView view={view_number} log={} op={op_number} commit={commit_number}",
            format_log(log)
        ),
        Message::Recovery {
            replica_id,
            nonce,
            view_number,
        } => format!("Recovery replica={replica_id} nonce={nonce} view={view_number}"),
        Message::RecoveryResponse {
            view_number,
            nonce,
            replica_id,
            state,
        } => {
            let state = match state {
                None => "none".to_string(),
                Some(state) => format!("{}/{}", format_log(&state.log), state.commit_number),
            };
            format!("RecoveryResponse view={view_number} nonce={nonce} replica={replica_id} state={state}")
        }
    }
}

pub fn format_replica(id: ReplicaID, replica: &Replica<Recorder>) -> String {
    let status = match replica.status() {
        Status::Normal => "Normal",
        Status::StateTransfer => "StateTransfer",
        Status::Recovering => "Recovering",
        Status::ViewChange => "ViewChange",
    };
    let applied: Vec<String> = replica
        .state_machine()
        .applied
        .iter()
        .map(u64::to_string)
        .collect();
    format!(
        "replica {id} status={status} view={} commit={} log={} applied=[{}]",
        replica.view_number(),
        replica.commit_number(),
        format_log(replica.log()),
        applied.join(",")
    )
}

/// SplitMix64: enough randomness for a trace, and no dependency.
pub struct Rng(u64);

impl Rng {
    pub fn new(seed: u64) -> Rng {
        Rng(seed)
    }

    pub fn next_u64(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }

    pub fn below(&mut self, n: usize) -> usize {
        (self.next_u64() % n as u64) as usize
    }

    pub fn chance(&mut self, percent: u64) -> bool {
        self.next_u64() % 100 < percent
    }
}

/// Generates a trace for `seed`. Deliveries favour recent messages so the
/// cluster makes progress, but any message can be replayed at any time.
/// Recoveries are rare and start after the cluster has had time to commit
/// something.
pub fn generate(seed: u64, steps: usize) -> Trace {
    let mut rng = Rng::new(seed);
    let replica_count = if seed.is_multiple_of(2) { 3 } else { 5 };
    let primary_timeout = 2;
    let client_count = 2;
    let mut cluster = Cluster::new(replica_count, primary_timeout);
    let mut next_request = vec![0usize; client_count];
    let mut last_op = vec![0u64; client_count];
    let mut next_op = 0u64;
    let mut nonce = 0u64;
    let mut trace = Trace {
        replica_count,
        primary_timeout,
        steps: Vec::new(),
    };
    while trace.steps.len() < steps {
        let roll = rng.below(100);
        let step = if roll < 60 && !cluster.sent.is_empty() {
            let n = cluster.sent.len();
            let i = if rng.chance(70) {
                n - 1 - rng.below(n.min(8))
            } else {
                rng.below(n)
            };
            Step::Deliver(i)
        } else if roll < 75 {
            Step::Idle(rng.below(replica_count))
        } else if roll < 98 || trace.steps.len() < 30 {
            let client_id = rng.below(client_count);
            // A new request only once the last one has been answered, as
            // the real client does; until then it is re-sent.
            let answered = next_request[client_id] == 0
                || cluster.replies.iter().any(|reply| {
                    reply.client_id == client_id
                        && reply.request_number == next_request[client_id] - 1
                });
            if answered {
                last_op[client_id] = next_op;
                next_op += 1;
                next_request[client_id] += 1;
            }
            Step::Request {
                to: rng.below(replica_count),
                client_id,
                request_number: next_request[client_id] - 1,
                op: last_op[client_id],
            }
        } else {
            nonce += 1;
            Step::Recover {
                replica_id: rng.below(replica_count),
                nonce,
            }
        };
        cluster.step(step);
        trace.steps.push(step);
    }
    trace
}
