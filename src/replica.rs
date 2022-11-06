use crate::config::Config;
use crate::message::Message;
use crate::types::{CommitID, OpNumber, ReplicaID, ViewNumber};
use crossbeam_channel::Sender;
use log::trace;
use parking_lot::Mutex;
use std::collections::HashMap;
use std::fmt::Debug;
use std::sync::Arc;

/// Replica status.
#[derive(Debug, PartialEq)]
enum Status {
    Normal,
    Recovery,
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
    config: Arc<Mutex<Config>>,
    self_id: ReplicaID,
    inner: Mutex<ReplicaInner<S, Op>>,
    client_tx: Sender<()>,
    replica_tx: Sender<(ReplicaID, Message<Op>)>,
}

#[derive(Debug)]
struct ReplicaInner<S, Op>
where
    Op: Clone + Debug + Send,
{
    state_machine: Arc<S>,
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
        config: Arc<Mutex<Config>>,
        state_machine: Arc<S>,
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
            config,
            client_tx,
            replica_tx,
            inner,
        }
    }

    pub fn on_idle(&self) {
        let inner = self.inner.lock();
        if !self.is_primary(&inner) {
            return;
        }
        assert_eq!(inner.status, Status::Normal);
        let view_number = inner.view_number;
        let commit_number = inner.commit_number;
        self.broadcast_allbutself(Message::Commit {
            view_number,
            commit_number,
        });
    }

    pub fn on_message(&self, message: Message<Op>) {
        trace!("Replica {} <- {:?}", self.self_id, message);
        match message {
            Message::Request { op, .. } => {
                let mut inner = self.inner.lock();
                // TODO: If not primary, drop request, advise client to connect to primary.
                assert!(self.is_primary(&inner));
                // TODO: If not in normal status, drop request, advise client to try later.
                assert_eq!(inner.status, Status::Normal);
                self.append_to_log(&mut inner, op.clone());
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
                commit_number,
            } => {
                let mut inner = self.inner.lock();
                assert!(!self.is_primary(&inner));
                // TODO: If view number is not the same, initiate recovery.
                assert_eq!(inner.view_number, view_number);
                if op_number > inner.op_number + 1 {
                    self.state_transfer(&mut inner);
                    return;
                }
                assert_eq!(inner.op_number + 1, op_number);
                self.append_to_log(&mut inner, op);
                for op_idx in inner.commit_number..commit_number {
                    self.commit_op(&mut inner, op_idx);
                }
                let view_number = inner.view_number;
                let primary_id = self.primary_id(&inner);
                self.send_msg(
                    primary_id,
                    Message::PrepareOk {
                        view_number,
                        op_number,
                    },
                );
            }
            Message::PrepareOk {
                view_number,
                op_number,
            } => {
                let mut inner = self.inner.lock();
                assert!(self.is_primary(&inner));
                assert_eq!(inner.view_number, view_number);
                let acks = inner.acks.get_mut(&op_number).unwrap();
                *acks += 1;
                if *acks == self.config.lock().quorum() {
                    self.commit_op(&mut inner, op_number - 1);
                    self.respond_to_client();
                }
            }
            Message::Commit {
                view_number,
                commit_number,
            } => {
                let mut inner = self.inner.lock();
                assert_eq!(inner.status, Status::Normal);
                assert_eq!(inner.view_number, view_number);
                if commit_number > inner.op_number {
                    self.state_transfer(&mut inner);
                    return;
                }
                for op_idx in inner.commit_number..commit_number {
                    self.commit_op(&mut inner, op_idx);
                }
            }
            Message::GetState {
                replica_id,
                view_number,
                op_number,
            } => {
                let inner = self.inner.lock();
                assert_eq!(inner.status, Status::Normal);
                assert_eq!(inner.view_number, view_number);
                self.send_msg(
                    replica_id,
                    Message::NewState {
                        view_number: inner.view_number,
                        log: inner.log[op_number..].to_vec(),
                        op_number: inner.op_number,
                        commit_number: inner.commit_number,
                    },
                );
            }
            Message::NewState {
                view_number,
                log,
                op_number,
                commit_number,
            } => {
                let mut inner = self.inner.lock();
                assert_eq!(inner.status, Status::Recovery);
                assert_eq!(inner.view_number, view_number);
                for op in log {
                    self.append_to_log(&mut inner, op);
                }
                for op_idx in inner.commit_number..commit_number {
                    self.commit_op(&mut inner, op_idx);
                }
                assert_eq!(inner.op_number, op_number);
                assert_eq!(inner.commit_number, commit_number);
                inner.status = Status::Normal;
                let view_number = inner.view_number;
                let primary_id = self.primary_id(&inner);
                self.send_msg(
                    primary_id,
                    Message::PrepareOk {
                        view_number,
                        op_number,
                    },
                );
            }
        }
    }

    fn append_to_log(&self, inner: &mut ReplicaInner<S, Op>, op: Op) {
        inner.log.push(op);
        inner.op_number += 1;
    }

    fn state_transfer(&self, inner: &mut ReplicaInner<S, Op>) {
        inner.status = Status::Recovery;
        // FIXME: pick *one* replica, doesn't need to be primary.
        let primary_id = self.primary_id(&inner);
        self.send_msg(
            primary_id,
            Message::GetState {
                replica_id: self.self_id,
                view_number: inner.view_number,
                op_number: inner.op_number,
            },
        );
    }

    /// Commits an operation at log index `op_idx`.
    fn commit_op(&self, inner: &mut ReplicaInner<S, Op>, op_idx: usize) {
        let op = &inner.log[op_idx];
        inner.state_machine.apply(op.clone());
        inner.commit_number += 1;
    }

    fn broadcast_allbutself(&self, message: Message<Op>) {
        let replicas = self.config.lock().replicas.clone();
        for replica_id in replicas {
            if replica_id == self.self_id {
                continue;
            }
            self.send_msg(replica_id, message.clone());
        }
    }

    fn send_msg(&self, replica_id: ReplicaID, message: Message<Op>) {
        self.replica_tx.send((replica_id, message)).unwrap();
    }

    fn respond_to_client(&self) {
        self.client_tx.send(()).unwrap();
    }

    fn is_primary(&self, inner: &ReplicaInner<S, Op>) -> bool {
        self.self_id == self.primary_id(inner)
    }

    fn primary_id(&self, inner: &ReplicaInner<S, Op>) -> ReplicaID {
        self.config.lock().primary_id(inner.view_number)
    }
}
