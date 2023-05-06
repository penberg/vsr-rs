use crate::config::Config;
use crate::message::Message;
use crate::state_machine::StateMachine;
use crate::types::{CommitID, OpNumber, ReplicaID, ViewNumber};
use crossbeam_channel::Sender;
use log::trace;
use std::cell::RefCell;
use std::collections::HashMap;
use std::fmt::Debug;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;

/// Replica status.
#[derive(Debug, PartialEq)]
enum Status {
    Normal,
    Recovery,
    ViewChange,
}

#[derive(Debug)]
pub struct Replica<SM: StateMachine> {
    config: Arc<Config>,
    self_id: ReplicaID,
    state_machine: Arc<SM>,
    status: RefCell<Status>,
    backup_idle_ticks: RefCell<usize>,
    view_number: RefCell<ViewNumber>,
    commit_number: AtomicUsize,
    op_number: AtomicUsize,
    log: RefCell<Vec<SM::Input>>,
    acks: RefCell<HashMap<ReplicaID, usize>>,
    start_view_change_counter: RefCell<HashMap<ViewNumber, usize>>,
    do_view_change_counter: RefCell<HashMap<ViewNumber, usize>>,
    client_tx: Sender<SM::Output>,
    replica_tx: Sender<(ReplicaID, Message<SM::Input>)>,
}

impl<SM: StateMachine> Replica<SM> {
    pub fn new(
        self_id: ReplicaID,
        config: Arc<Config>,
        state_machine: Arc<SM>,
        client_tx: Sender<SM::Output>,
        replica_tx: Sender<(ReplicaID, Message<SM::Input>)>,
    ) -> Replica<SM> {
        let status = RefCell::new(Status::Normal);
        let backup_idle_ticks = RefCell::new(0);
        let view_number = RefCell::new(0);
        let commit_number = AtomicUsize::new(0);
        let op_number = AtomicUsize::new(0);
        let log = RefCell::new(Vec::default());
        let acks = RefCell::new(HashMap::default());
        let start_view_change_counter = RefCell::new(HashMap::default());
        let do_view_change_counter = RefCell::new(HashMap::default());
        Replica {
            self_id,
            config,
            state_machine,
            status,
            backup_idle_ticks,
            view_number,
            commit_number,
            op_number,
            log,
            acks,
            start_view_change_counter,
            do_view_change_counter,
            client_tx,
            replica_tx,
        }
    }

    /// The main entry point to replica logic.
    pub fn on_message(&self, message: Message<SM::Input>) {
        trace!("Replica {} <- {:?}", self.self_id, message);
        match message {
            Message::Request { op, .. } => {
                self.on_request(op);
            }
            Message::Prepare {
                view_number,
                op_number,
                op,
                commit_number,
            } => {
                self.on_prepare(view_number, op_number, op, commit_number);
            }
            Message::PrepareOk {
                view_number,
                op_number,
            } => {
                self.on_prepare_ok(view_number, op_number);
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
                log,
                commit_number,
            } => {
                self.on_do_view_change(view_number, replica_id, log, commit_number);
            }
            Message::StartView {
                view_number,
                replica_id,
                log,
                commit_number,
            } => {
                self.on_start_view(view_number, replica_id, log, commit_number);
            }
        }
    }

    /// The client sends a `Request` message to the primary, which replicates
    /// the operation to the other replicas.
    fn on_request(&self, op: SM::Input) {
        // TODO: If not primary, drop request, advise client to connect to primary.
        assert!(self.is_primary());
        // TODO: If not in normal status, drop request, advise client to try later.
        assert_eq!(*self.status.borrow(), Status::Normal);
        // Append operation to our log.
        self.append_to_log(op.clone());
        // And then register our own acknowledgement.
        let op_number = self.op_number();
        let mut acks = self.acks.borrow_mut();
        acks.insert(op_number, 1);
        // TODO: Update client_table
        // Send a prepare message to all the replicas.
        let view_number = self.view_number();
        let commit_number = self.commit_number();
        self.send_msg_to_others(Message::Prepare {
            view_number,
            op,
            op_number,
            commit_number,
        });
    }

    /// The primary sends a `Prepare` message to replicate an operation to backup
    /// nodes. The nodes that receive a `Prepare` message will reply with `PrepareOk`
    /// when they have appended `op` to their logs. The message also contains the
    /// commit number of the primary, so that the backups can commit their logs up
    /// to that point.
    fn on_prepare(
        &self,
        view_number: ViewNumber,
        op_number: OpNumber,
        op: SM::Input,
        commit_number: CommitID,
    ) {
        self.backup_idle_ticks.replace(0);
        assert!(!self.is_primary());
        // TODO: If view number is not the same, initiate recovery.
        assert_eq!(self.view_number(), view_number);
        if op_number <= self.op_number() {
            return; // duplicate
        }
        // If we fell behind in the log, initiate state transfer.
        if op_number > self.op_number() + 1 {
            self.state_transfer();
            return;
        }
        assert_eq!(self.op_number() + 1, op_number);
        // Append op to our log.
        self.append_to_log(op);
        // Commit the log up to the commit number received in `Prepare`
        // message, which represents the committed state of the primary.
        for op_idx in self.commit_number()..commit_number {
            self.commit_op(op_idx);
        }
        // Acknowledge the `Prepare` message to the primary.
        self.send_msg_to_primary(Message::PrepareOk {
            view_number,
            op_number,
        });
    }

    /// Backup nodes send `PrepareOk` message to the primary to acknowledge that
    /// they have appended an op to their logs. When the primary has
    /// received `PrepareOk` messages from a quorum of replicas, it commits
    /// the operation and replies to the client.
    fn on_prepare_ok(&self, view_number: ViewNumber, op_number: OpNumber) {
        assert!(self.is_primary());
        assert_eq!(self.view_number(), view_number);
        // Register the acknowledgement
        let mut acks = self.acks.borrow_mut();
        let acks = acks.get_mut(&op_number).unwrap();
        *acks += 1;
        // If we have received a quorum of `PrepareOk` messages, commit the
        // operation and reply to the client.
        if *acks == self.config.quorum() {
            let response = self.commit_op(op_number - 1);
            self.respond_to_client(response);
        }
    }

    /// A backup node typically commits its log as part of `Prepare`
    /// message handling because the primary uses that also to signal the
    /// current commit number. However, `Prepare` is sent only in
    /// reaction to a client `Request` message. If there are no client
    /// requests, then the primary sends a `Commit` message to backup
    /// nodes instead to give backup nodes the chance to commit.
    fn on_commit(&self, view_number: ViewNumber, commit_number: CommitID) {
        self.backup_idle_ticks.replace(0);
        if *self.status.borrow() != Status::Normal {
            return;
        }
        if view_number < self.view_number() {
            return;
        }
        assert_eq!(*self.status.borrow(), Status::Normal);
        assert_eq!(self.view_number(), view_number);
        if commit_number > self.op_number() {
            self.state_transfer();
            return;
        }
        for op_idx in self.commit_number()..commit_number {
            self.commit_op(op_idx);
        }
    }

    /// A replica sends a `GetState` message to another replica to catch
    /// up on its log.
    fn on_get_state(&self, replica_id: ReplicaID, view_number: ViewNumber, op_number: OpNumber) {
        assert_eq!(*self.status.borrow(), Status::Normal);
        assert_eq!(self.view_number(), view_number);
        let log = self.log.borrow();
        self.send_msg(
            replica_id,
            Message::NewState {
                view_number: self.view_number(),
                log: log[op_number..].to_vec(),
                op_number_start: op_number,
                op_number_end: self.op_number(),
                commit_number: self.commit_number(),
            },
        );
    }

    /// A replica receives a `NewState` message in response to a
    /// `GetState` message it sent itself to catch up on its log.
    fn on_new_state(
        &self,
        view_number: ViewNumber,
        log: Vec<SM::Input>,
        op_number_start: OpNumber,
        op_number_end: OpNumber,
        commit_number: CommitID,
    ) {
        if *self.status.borrow() != Status::Recovery {
            return;
        }
        assert_eq!(*self.status.borrow(), Status::Recovery);
        assert_eq!(self.view_number(), view_number);
        assert_eq!(op_number_start, self.op_number());
        for op in log {
            self.append_to_log(op);
        }
        for op_idx in self.commit_number()..commit_number {
            self.commit_op(op_idx);
        }
        assert_eq!(self.op_number(), op_number_end);
        assert_eq!(self.commit_number(), commit_number);
        self.status.replace(Status::Normal);
        let view_number = self.view_number();
        self.send_msg_to_primary(Message::PrepareOk {
            view_number,
            op_number: op_number_end,
        });
    }

    ///  A replica sends a `StartViewChange` message to all other replicas if
    /// it detects that the primary is unavailable.
    fn on_start_view_change(&self, view_number: ViewNumber, replica_id: ReplicaID) {
        assert!(self.self_id != replica_id);
        self.status.replace(Status::ViewChange);
        self.view_number.replace(view_number);
        let mut start_view_changes = self.start_view_change_counter.borrow_mut();
        let start_view_changes = start_view_changes.entry(view_number).or_insert(0);
        *start_view_changes += 1;
        if *start_view_changes >= self.config.quorum() {
            self.send_msg_to_primary(Message::DoViewChange {
                view_number,
                replica_id: self.self_id,
                log: self.log.borrow().clone(),
                commit_number: self.commit_number(),
            });
        } else {
            self.send_msg_to_others(Message::StartViewChange {
                view_number,
                replica_id: self.self_id,
            });
        }
    }

    /// A replica sends a `DoViewChange` message to a possible new primary if
    /// a quorum of replicas have agreed to start a view change.
    fn on_do_view_change(
        &self,
        view_number: ViewNumber,
        _replica_id: ReplicaID,
        _log: Vec<SM::Input>,
        _commit_number: CommitID,
    ) {
        let mut do_view_change_counter = self.do_view_change_counter.borrow_mut();
        let do_view_change_counter = do_view_change_counter.entry(view_number).or_insert(0);
        *do_view_change_counter += 1;
        if *do_view_change_counter >= self.config.quorum() {
            // TODO Take log from "best" replica...
            self.status.replace(Status::Normal);
            self.send_msg_to_others(Message::StartView {
                view_number,
                replica_id: self.self_id,
                log: self.log.borrow().clone(),
                commit_number: self.commit_number(),
            });
        }
    }

    /// The new primary sends a `StartView` message to all other replicas if
    /// it has successfully started a new view.
    fn on_start_view(
        &self,
        _view_number: ViewNumber,
        _replica_id: ReplicaID,
        _log: Vec<SM::Input>,
        _commit_number: CommitID,
    ) {
        // TODO update log
        self.status.replace(Status::Normal);
    }

    /// When there are no client requests, the primary node sends a
    /// `Commit` message to backup nodes periodically to let them commit
    /// if needed.
    pub fn on_idle(&self) {
        if self.is_primary() {
            self.on_primary_idle();
        } else {
            self.on_backup_idle();
        }
    }

    fn on_primary_idle(&self) {
        assert_eq!(*self.status.borrow(), Status::Normal);
        let view_number = self.view_number();
        let commit_number = self.commit_number();
        self.send_msg_to_others(Message::Commit {
            view_number,
            commit_number,
        });
    }

    fn on_backup_idle(&self) {
        let mut backup_idle_ticks = self.backup_idle_ticks.borrow_mut();
        *backup_idle_ticks += 1;
        if *backup_idle_ticks > 2 {
            self.view_change();
        }
    }

    fn append_to_log(&self, op: SM::Input) {
        let mut log = self.log.borrow_mut();
        log.push(op);
        self.op_number.fetch_add(1, Ordering::SeqCst);
    }

    fn state_transfer(&self) {
        self.status.replace(Status::Recovery);
        // FIXME: pick *one* replica, doesn't need to be primary.
        let primary_id = self.primary_id();
        self.send_msg(
            primary_id,
            Message::GetState {
                replica_id: self.self_id,
                view_number: self.view_number(),
                op_number: self.op_number(),
            },
        );
    }

    fn view_change(&self) {
        self.status.replace(Status::ViewChange);
        let mut view_number = self.view_number.borrow_mut();
        *view_number += 1;
        let mut start_view_changes = self.start_view_change_counter.borrow_mut();
        start_view_changes.insert(*view_number, 1);
        self.send_msg_to_others(Message::StartViewChange {
            view_number: *view_number,
            replica_id: self.self_id,
        });
    }

    /// Commits an operation at log index `op_idx`.
    fn commit_op(&self, op_idx: usize) -> SM::Output {
        let log = self.log.borrow();
        let op = &log[op_idx];
        let ret = self.state_machine.apply(op.clone());
        self.commit_number.fetch_add(1, Ordering::SeqCst);
        ret
    }

    /// Sends a message to the primary.
    fn send_msg_to_primary(&self, message: Message<SM::Input>) {
        let primary_id = self.primary_id();
        self.send_msg(primary_id, message);
    }

    /// Sends a message to all other replicas.
    fn send_msg_to_others(&self, message: Message<SM::Input>) {
        let replicas = self.config.replicas.borrow();
        for replica_id in replicas.iter() {
            if *replica_id == self.self_id {
                continue;
            }
            self.send_msg(*replica_id, message.clone());
        }
    }

    fn send_msg(&self, replica_id: ReplicaID, message: Message<SM::Input>) {
        self.replica_tx.send((replica_id, message)).unwrap();
    }

    fn respond_to_client(&self, response: SM::Output) {
        self.client_tx.send(response).unwrap();
    }

    fn is_primary(&self) -> bool {
        self.self_id == self.primary_id()
    }

    fn primary_id(&self) -> ReplicaID {
        self.config.primary_id(self.view_number())
    }

    fn commit_number(&self) -> CommitID {
        self.commit_number.load(Ordering::SeqCst)
    }

    fn view_number(&self) -> ViewNumber {
        *self.view_number.borrow()
    }

    fn op_number(&self) -> OpNumber {
        self.op_number.load(Ordering::SeqCst)
    }
}
