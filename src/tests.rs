#[cfg(test)]
mod tests {
    use crate::{Client, Replica, StateMachine};
    use std::sync::{Arc, Mutex};

    #[test]
    fn test_normal_operation() {
        env_logger::init();
        let (client_tx, _client_rx) = crossbeam_channel::unbounded();
        let (replica_tx, replica_rx) = crossbeam_channel::unbounded();
        let nr_replicas = 3;
        let sm = Arc::new(Accumulator::new());
        let replica_a = Replica::new(
            0,
            nr_replicas,
            sm.clone(),
            client_tx.clone(),
            replica_tx.clone(),
        );
        let replica_b = Replica::new(
            1,
            nr_replicas,
            Arc::new(Accumulator::new()),
            client_tx.clone(),
            replica_tx.clone(),
        );
        let replica_c = Replica::new(
            2,
            nr_replicas,
            Arc::new(Accumulator::new()),
            client_tx.clone(),
            replica_tx.clone(),
        );
        let replicas = vec![replica_a, replica_b, replica_c];
        let tick = || {
            while !replica_rx.is_empty() {
                let (replica_id, message) = replica_rx.recv().unwrap();
                replicas[replica_id].on_message(message);
            }
        };
        let client = Client::new(nr_replicas, replica_tx.clone());
        client.request_async(Op::Add(10), Box::new(|_| {}));
        tick();
        let accumulator = (sm.accumulator.lock().unwrap()).to_owned();
        assert_eq!(10, accumulator);
        client.request_async(Op::Sub(5), Box::new(|_| {}));
        tick();
        let accumulator = (sm.accumulator.lock().unwrap()).to_owned();
        assert_eq!(5, accumulator);
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
            let mut accumulator = self.accumulator.lock().unwrap();
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
