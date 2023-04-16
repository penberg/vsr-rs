use std::cell::RefCell;

use crate::types::{ReplicaID, ViewNumber};

/// Configuration.
#[derive(Debug, Default)]
pub struct Config {
    /// IDs of all replicas (in sorted order).
    pub replicas: RefCell<Vec<ReplicaID>>,
}

impl Config {
    pub fn new() -> Config {
        let replicas = RefCell::new(Vec::default());
        Config { replicas }
    }

    pub fn primary_id(&self, view_number: ViewNumber) -> ReplicaID {
        let replicas = self.replicas.borrow();
        let idx = view_number % replicas.len();
        replicas[idx]
    }

    pub fn add_replica(&self) -> usize {
        let mut replicas = self.replicas.borrow_mut();
        let id = replicas.len();
        replicas.push(id);
        id
    }

    pub fn quorum(&self) -> usize {
        let replicas = self.replicas.borrow();
        replicas.len() / 2 + 1
    }
}
