use crate::types::{ClientID, CommitID, OpNumber, ReplicaID, RequestNumber, ViewNumber};
use std::fmt::Debug;

#[derive(Clone, Debug)]
pub enum Message<Op>
where
    Op: Clone + Debug + Send,
{
    Request {
        client_id: ClientID,
        request_number: RequestNumber,
        op: Op,
    },
    Prepare {
        view_number: ViewNumber,
        op_number: OpNumber,
        op: Op,
        commit_number: CommitID,
    },
    PrepareOk {
        view_number: ViewNumber,
        op_number: OpNumber,
    },
    Commit {
        view_number: ViewNumber,
        commit_number: CommitID,
    },
    GetState {
        replica_id: ReplicaID,
        view_number: ViewNumber,
        op_number: OpNumber,
    },
    /// The NewState message is sent to a replica to repair it.
    ///
    /// We differ from the paper by not just sending the op number of the last
    /// entry in the log, but also the op number of the first entry. This allows
    /// us to verify that we're repairing the right part of the log in the
    /// replica.
    NewState {
        /// The view number of the replica that is sending the NewState message.
        view_number: ViewNumber,
        /// The log of operations that this replica needs to apply to catch up.
        log: Vec<Op>,
        /// The op number of the first entry in the log. This is the op number
        /// that we requested in the GetState message.
        op_number_start: OpNumber,
        /// The op number of the last entry in the log.
        op_number_end: OpNumber,
        /// The commit ID of the replica that is sending the NewState message.
        commit_number: CommitID,
    },
    StartViewChange {
        view_number: ViewNumber,
        replica_id: ReplicaID,
    },
    DoViewChange {
        view_number: ViewNumber,
        replica_id: ReplicaID,
        log: Vec<Op>,
        commit_number: CommitID,
    },
    StartView {
        view_number: ViewNumber,
        replica_id: ReplicaID,
        log: Vec<Op>,
        commit_number: CommitID,
    },
}
