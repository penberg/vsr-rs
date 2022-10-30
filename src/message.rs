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
        op: Op,
        op_number: OpNumber,
        commit_number: CommitID,
    },
    PrepareOk {
        view_number: ViewNumber,
        op_number: OpNumber,
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
