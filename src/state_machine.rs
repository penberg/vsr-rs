use std::fmt::Debug;

/// State machine.
pub trait StateMachine {
    type Input: Clone + Debug + Send;
    type Output;

    fn apply(&self, input: Self::Input) -> Self::Output;
}
