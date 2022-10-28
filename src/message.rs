use crate::types::{ClientID, RequestNumber};
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
}
