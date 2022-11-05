use crate::types::{ReplicaID, ViewNumber};

/// Configuration.
#[derive(Debug, Default)]
pub struct Config {
    /// IDs of all replicas (in sorted order).
    pub replicas: Vec<ReplicaID>,
}

impl Config {
    pub fn new() -> Config {
        let replicas = Vec::default();
        Config { replicas }
    }

    pub fn primary_id(&self, view_number: ViewNumber) -> ReplicaID {
        let idx = view_number % self.replicas.len();
        self.replicas[idx]
    }

    pub fn add_replica(&mut self) -> usize {
        let id = self.replicas.len();
        self.replicas.push(id);
        id
    }

    pub fn quorum(&self) -> usize {
        self.replicas.len() / 2 + 1
    }
}
