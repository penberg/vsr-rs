//! The state machine replicated by the simulator.
//!
//! The simulator uses a simple accumulator that also records every operation
//! it has applied. Properties use the recorded history to check that the
//! state machine state matches the committed prefix of the replica log.

use vsr_rs::StateMachine;

/// The kind of an operation.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum OpKind {
    Add(i64),
    Sub(i64),
}

impl OpKind {
    /// Applies this operation to `value`.
    pub fn apply(self, value: i64) -> i64 {
        match self {
            OpKind::Add(v) => value.wrapping_add(v),
            OpKind::Sub(v) => value.wrapping_sub(v),
        }
    }
}

/// An operation submitted by a client.
///
/// Every operation carries a unique `id` so that properties can detect
/// duplicate or missing operations in replica logs.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Op {
    pub id: u64,
    pub kind: OpKind,
}

/// An accumulator state machine that records its history.
#[derive(Debug, Default)]
pub struct Accumulator {
    /// The current value of the accumulator.
    pub value: i64,
    /// Every operation applied so far, in application order.
    pub applied: Vec<Op>,
}

impl StateMachine for Accumulator {
    type Input = Op;
    type Output = i64;

    fn apply(&mut self, op: Op) -> i64 {
        self.value = op.kind.apply(self.value);
        self.applied.push(op);
        self.value
    }
}
