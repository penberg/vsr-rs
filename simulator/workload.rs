//! The workload generates the operations clients submit.

use crate::state_machine::OpKind;
use rand::Rng;
use rand_chacha::ChaCha8Rng;

/// Generates random add and subtract operations.
#[derive(Clone, Debug, Default)]
pub struct Workload;

impl Workload {
    pub fn build_request(&self, rng: &mut ChaCha8Rng) -> OpKind {
        let value = i64::from(rng.gen::<i32>());
        if rng.gen_bool(0.5) {
            OpKind::Add(value)
        } else {
            OpKind::Sub(value)
        }
    }
}
