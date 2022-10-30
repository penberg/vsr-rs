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
        view_number: usize,
        op: Op,
        op_number: usize,
        commit_number: usize,
    },
    PrepareOk {
        view_number: usize,
        op_number: usize,
    },
    GetState {
        replica_id: ReplicaID,
        view_number: ViewNumber,
        op_number: OpNumber,
    },
    NewState {
        view_number: ViewNumber,
        log: Vec<Op>,
        op_number: OpNumber,
        commit_number: CommitID,
    },
}
