pub mod client;
pub mod config;
pub mod message;
pub mod replica;

mod types;

pub use client::Client;
pub use config::Config;
pub use message::Message;
pub use replica::{Replica, StateMachine};

#[cfg(test)]
mod tests {
    use crate::{Client, Config, Replica, StateMachine};
    use parking_lot::Mutex;
    use std::sync::Arc;

    #[test]
    fn test_normal_operation() {
        let _ = env_logger::try_init();
        let (client_tx, _client_rx) = crossbeam_channel::unbounded();
        let (replica_tx, replica_rx) = crossbeam_channel::unbounded();
        let config = Arc::new(Mutex::new(Config::new()));
        let sm = Arc::new(Accumulator::new());
        let a_id = config.lock().add_replica();
        let replica_a = Replica::new(
            a_id,
            config.clone(),
            sm.clone(),
            client_tx.clone(),
            replica_tx.clone(),
        );
        let b_id = config.lock().add_replica();
        let replica_b = Replica::new(
            b_id,
            config.clone(),
            Arc::new(Accumulator::new()),
            client_tx.clone(),
            replica_tx.clone(),
        );
        let c_id = config.lock().add_replica();
        let replica_c = Replica::new(
            c_id,
            config.clone(),
            Arc::new(Accumulator::new()),
            client_tx,
            replica_tx.clone(),
        );
        let replicas = vec![replica_a, replica_b, replica_c];
        let tick = || {
            while !replica_rx.is_empty() {
                let (replica_id, message) = replica_rx.recv().unwrap();
                replicas[replica_id].on_message(message);
            }
        };
        let client = Client::new(config, replica_tx);
        client.request_async(Op::Add(10), Box::new(|_| {}));
        tick();
        let accumulator = (sm.accumulator.lock()).to_owned();
        assert_eq!(10, accumulator);
        client.request_async(Op::Sub(5), Box::new(|_| {}));
        tick();
        let accumulator = (sm.accumulator.lock()).to_owned();
        assert_eq!(5, accumulator);
    }
    #[test]
    fn test_idle() {
        let _ = env_logger::try_init();
        let (client_tx, _client_rx) = crossbeam_channel::unbounded();
        let (replica_tx, replica_rx) = crossbeam_channel::unbounded();
        let config = Arc::new(Mutex::new(Config::new()));
        let sm = Arc::new(Accumulator::new());
        let a_id = config.lock().add_replica();
        let replica_a = Replica::new(
            a_id,
            config.clone(),
            sm.clone(),
            client_tx.clone(),
            replica_tx.clone(),
        );
        let sm_b = Arc::new(Accumulator::new());
        let b_id = config.lock().add_replica();
        let replica_b = Replica::new(
            b_id,
            config.clone(),
            sm_b,
            client_tx.clone(),
            replica_tx.clone(),
        );
        let sm_c = Arc::new(Accumulator::new());
        let c_id = config.lock().add_replica();
        let replica_c = Replica::new(c_id, config.clone(), sm_c, client_tx, replica_tx.clone());
        let replicas = vec![replica_a, replica_b, replica_c];
        let tick = || {
            while !replica_rx.is_empty() {
                let (replica_id, message) = replica_rx.recv().unwrap();
                replicas[replica_id].on_message(message);
            }
            for replica in &replicas {
                replica.on_idle();
            }
        };
        let client = Client::new(config, replica_tx);
        client.request_async(Op::Add(10), Box::new(|_| {}));
        tick();
        let accumulator = (sm.accumulator.lock()).to_owned();
        assert_eq!(10, accumulator);
        client.request_async(Op::Sub(5), Box::new(|_| {}));
        tick();
        let accumulator = (sm.accumulator.lock()).to_owned();
        assert_eq!(5, accumulator);
        tick();
        let accumulator_b = (sm.accumulator.lock()).to_owned();
        let accumulator_c = (sm.accumulator.lock()).to_owned();
        assert_eq!(accumulator, accumulator_b);
        assert_eq!(accumulator, accumulator_c);
    }

    #[test]
    fn test_recovery() {
        let _ = env_logger::try_init();
        let (client_tx, _client_rx) = crossbeam_channel::unbounded();
        let (replica_tx, replica_rx) = crossbeam_channel::unbounded();
        let config = Arc::new(Mutex::new(Config::new()));
        let sm = Arc::new(Accumulator::new());
        let a_id = config.lock().add_replica();
        let replica_a = Replica::new(
            a_id,
            config.clone(),
            sm.clone(),
            client_tx.clone(),
            replica_tx.clone(),
        );
        let b_id = config.lock().add_replica();
        let replica_b = Replica::new(
            b_id,
            config.clone(),
            Arc::new(Accumulator::new()),
            client_tx.clone(),
            replica_tx.clone(),
        );
        let c_id = config.lock().add_replica();
        let replica_c = Replica::new(
            c_id,
            config.clone(),
            Arc::new(Accumulator::new()),
            client_tx,
            replica_tx.clone(),
        );
        let replicas = vec![replica_a, replica_b, replica_c];
        let tick = || {
            while !replica_rx.is_empty() {
                let (replica_id, message) = replica_rx.recv().unwrap();
                replicas[replica_id].on_message(message);
            }
        };
        let tick_lossy = || {
            while !replica_rx.is_empty() {
                let (replica_id, message) = replica_rx.recv().unwrap();
                if replica_id == 1 {
                    continue;
                }
                replicas[replica_id].on_message(message);
            }
        };
        let client = Client::new(config, replica_tx);
        client.request_async(Op::Add(10), Box::new(|_| {}));
        tick_lossy();
        let accumulator = (sm.accumulator.lock()).to_owned();
        assert_eq!(10, accumulator);
        client.request_async(Op::Sub(5), Box::new(|_| {}));
        tick();
        let accumulator = (sm.accumulator.lock()).to_owned();
        assert_eq!(5, accumulator);
        client.request_async(Op::Add(7), Box::new(|_| {}));
        tick();
        let accumulator = (sm.accumulator.lock()).to_owned();
        assert_eq!(12, accumulator);
    }

    #[derive(Clone, Debug)]
    enum Op {
        Add(i32),
        Sub(i32),
    }

    struct Accumulator {
        accumulator: Mutex<i32>,
    }

    impl Accumulator {
        fn new() -> Accumulator {
            let accumulator = Mutex::new(0);
            Accumulator { accumulator }
        }
    }

    impl StateMachine<Op> for Accumulator {
        fn apply(&self, op: Op) {
            let mut accumulator = self.accumulator.lock();
            match op {
                Op::Add(value) => {
                    *accumulator += value;
                }
                Op::Sub(value) => {
                    *accumulator -= value;
                }
            }
        }
    }
}
