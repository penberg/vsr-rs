use crate::message::Message;
use crate::types::ReplicaID;
use log::trace;
use std::collections::HashMap;
use std::fmt::Debug;
use std::sync::mpsc::Sender;

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
    state_machine: S,
    client_tx: Sender<()>,
    replica_tx: Sender<(ReplicaID, Message<Op>)>,
    status: Status,
    view_number: usize,
    commit_number: usize,
    op_number: usize,
    log: Vec<Op>,
    acks: HashMap<usize, usize>,
}

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
        Replica {
            self_id,
            nr_replicas,
            state_machine,
            client_tx,
            replica_tx,
            status,
            commit_number,
            view_number,
            op_number,
            log,
            acks,
        }
    }

    pub fn on_message(&mut self, message: Message<Op>) {
        trace!("Replica {} <- {:?}", self.self_id, message);
        match message {
            Message::Request { op, .. } => {
                // TODO: If not primary, drop request, advise client to connect to primary.
                assert!(self.is_primary());
                // TODO: If not in normal status, drop request, advise client to try later.
                assert_eq!(self.status, Status::Normal);
                self.op_number += 1;
                self.log.push(op.clone());
                let op_number = self.op_number;
                self.acks.insert(op_number, 1);
                // TODO: Update client_table
                self.broadcast_allbutself(Message::Prepare {
                    view_number: self.view_number,
                    op,
                    op_number,
                    commit_number: self.commit_number,
                });
            }
            Message::Prepare {
                view_number,
                op,
                op_number,
                ..
            } => {
                // TODO: If view number is not the same, initiate recovery.
                assert_eq!(self.view_number, view_number);
                // TODO: If op number is not strictly consecutive, initiate recovery.
                assert_eq!(self.op_number + 1, op_number);
                self.op_number += 1;
                self.log.push(op);
                self.replica_tx
                    .send((
                        self.primary_id(),
                        Message::PrepareOk {
                            view_number: self.view_number,
                            op_number: self.op_number,
                        },
                    ))
                    .unwrap();
            }
            Message::PrepareOk {
                view_number,
                op_number,
            } => {
                assert!(self.is_primary());
                assert_eq!(self.view_number, view_number);
                let acks = self.acks.get_mut(&op_number).unwrap();
                *acks += 1;
                if *acks == self.quorum() {
                    let op = &self.log[op_number - 1];
                    self.state_machine.apply(op.clone());
                    self.commit_number += 1;
                    self.client_tx.send(()).unwrap();
                }
            }
        }
    }

    fn broadcast_allbutself(&mut self, message: Message<Op>) {
        for replica_id in 0..self.nr_replicas {
            if replica_id == self.self_id {
                continue;
            }
            self.send_msg(replica_id, message.clone());
        }
    }

    fn send_msg(&mut self, replica_id: ReplicaID, message: Message<Op>) {
        self.replica_tx.send((replica_id, message)).unwrap();
    }

    fn quorum(&self) -> usize {
        self.nr_replicas / 2 + 1
    }

    fn primary_id(&self) -> ReplicaID {
        self.view_number % self.nr_replicas
    }

    fn is_primary(&self) -> bool {
        self.self_id == self.primary_id()
    }
}
