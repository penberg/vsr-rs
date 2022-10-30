use crate::message::Message;
use crate::types::{CommitID, OpNumber, ReplicaID, ViewNumber};
use crossbeam_channel::Sender;
use log::trace;
use std::collections::HashMap;
use std::fmt::Debug;
use std::sync::Mutex;

/// Replica status.
#[derive(Debug, PartialEq)]
enum Status {
    Normal,
}

/// State machine.
pub trait StateMachine<Op>
where
    Op: Clone + Debug + Send,
{
    fn apply(&self, op: Op);
}

#[derive(Debug)]
pub struct Replica<S, Op>
where
    S: StateMachine<Op>,
    Op: Clone + Debug + Send,
{
    self_id: ReplicaID,
    nr_replicas: usize,
    inner: Mutex<ReplicaInner<S, Op>>,
    client_tx: Sender<()>,
    replica_tx: Sender<(ReplicaID, Message<Op>)>,
}

#[derive(Debug)]
struct ReplicaInner<S, Op>
where
    Op: Clone + Debug + Send,
{
    state_machine: S,
    status: Status,
    view_number: ViewNumber,
    commit_number: CommitID,
    op_number: OpNumber,
    log: Vec<Op>,
    acks: HashMap<ReplicaID, usize>,
}

impl<S, Op> ReplicaInner<S, Op> where Op: Clone + Debug + Send {}

impl<S, Op> Replica<S, Op>
where
    S: StateMachine<Op>,
    Op: Clone + Debug + Send,
{
    pub fn new(
        self_id: ReplicaID,
        nr_replicas: usize,
        state_machine: S,
        client_tx: Sender<()>,
        replica_tx: Sender<(ReplicaID, Message<Op>)>,
    ) -> Replica<S, Op> {
        let status = Status::Normal;
        let view_number = 0;
        let commit_number = 0;
        let op_number = 0;
        let log = Vec::default();
        let acks = HashMap::default();
        let inner = ReplicaInner {
            state_machine,
            status,
            view_number,
            commit_number,
            op_number,
            log,
            acks,
        };
        let inner = Mutex::new(inner);
        Replica {
            self_id,
            nr_replicas,
            client_tx,
            replica_tx,
            inner,
        }
    }

    pub fn on_message(&self, message: Message<Op>) {
        trace!("Replica {} <- {:?}", self.self_id, message);
        match message {
            Message::Request { op, .. } => {
                let mut inner = self.inner.lock().unwrap();
                // TODO: If not primary, drop request, advise client to connect to primary.
                assert!(self.is_primary(&inner));
                // TODO: If not in normal status, drop request, advise client to try later.
                assert_eq!(inner.status, Status::Normal);
                inner.op_number += 1;
                inner.log.push(op.clone());
                let op_number = inner.op_number;
                inner.acks.insert(op_number, 1);
                // TODO: Update client_table
                let view_number = inner.view_number;
                let commit_number = inner.commit_number;
                self.broadcast_allbutself(Message::Prepare {
                    view_number,
                    op,
                    op_number,
                    commit_number,
                });
            }
            Message::Prepare {
                view_number,
                op,
                op_number,
                ..
            } => {
                let mut inner = self.inner.lock().unwrap();
                // TODO: If view number is not the same, initiate recovery.
                assert_eq!(inner.view_number, view_number);
                // TODO: If op number is not strictly consecutive, initiate recovery.
                assert_eq!(inner.op_number + 1, op_number);
                inner.op_number += 1;
                inner.log.push(op);
                let view_number = inner.view_number;
                self.replica_tx
                    .send((
                        self.primary_id(&inner),
                        Message::PrepareOk {
                            view_number,
                            op_number,
                        },
                    ))
                    .unwrap();
            }
            Message::PrepareOk {
                view_number,
                op_number,
            } => {
                let mut inner = self.inner.lock().unwrap();
                assert!(self.is_primary(&inner));
                assert_eq!(inner.view_number, view_number);
                let acks = inner.acks.get_mut(&op_number).unwrap();
                *acks += 1;
                if *acks == quorum(self.nr_replicas) {
                    let op = &inner.log[op_number - 1];
                    inner.state_machine.apply(op.clone());
                    inner.commit_number += 1;
                    self.client_tx.send(()).unwrap();
                }
            }
        }
    }

    fn broadcast_allbutself(&self, message: Message<Op>) {
        for replica_id in 0..self.nr_replicas {
            if replica_id == self.self_id {
                continue;
            }
            self.send_msg(replica_id, message.clone());
        }
    }

    fn send_msg(&self, replica_id: ReplicaID, message: Message<Op>) {
        self.replica_tx.send((replica_id, message)).unwrap();
    }

    fn is_primary(&self, inner: &ReplicaInner<S, Op>) -> bool {
        self.self_id == self.primary_id(inner)
    }

    fn primary_id(&self, inner: &ReplicaInner<S, Op>) -> ReplicaID {
        inner.view_number & self.nr_replicas
    }
}

fn quorum(nr_replicas: usize) -> usize {
    nr_replicas / 2 + 1
}
