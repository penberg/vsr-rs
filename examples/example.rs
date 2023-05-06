use std::sync::Arc;
use vsr_rs::{Client, Config, Replica, StateMachine};

fn main() {
    env_logger::init();
    let (client_tx, _client_rx) = crossbeam_channel::unbounded();
    let (replica_tx, replica_rx) = crossbeam_channel::unbounded();
    let config = Arc::new(Config::new());
    let a_id = config.add_replica();
    let replica_a = Replica::new(
        a_id,
        config.clone(),
        Arc::new(Accumulator {}),
        client_tx.clone(),
        replica_tx.clone(),
    );
    let b_id = config.add_replica();
    let replica_b = Replica::new(
        b_id,
        config.clone(),
        Arc::new(Accumulator {}),
        client_tx.clone(),
        replica_tx.clone(),
    );
    let c_id = config.add_replica();
    let replica_c = Replica::new(
        c_id,
        config.clone(),
        Arc::new(Accumulator {}),
        client_tx,
        replica_tx.clone(),
    );
    let replicas = vec![replica_a, replica_b, replica_c];
    let tick = || {
        while !replica_rx.is_empty() {
            let (replica_id, message) = replica_rx.recv().unwrap();
            println!("Sending {:?} to {}", message, replica_id);
            replicas[replica_id].on_message(message);
        }
    };
    let client = Arc::new(Client::new(config, replica_tx));
    client.on_request(Op::Add(10), Box::new(|_| {}));
    tick();
    client.on_request(Op::Sub(5), Box::new(|_| {}));
    tick();
    client.on_request(Op::Add(7), Box::new(|_| {}));
    tick();
    client.on_request(Op::Add(8), Box::new(|_| {}));
    tick();
}

#[derive(Clone, Debug)]
enum Op {
    Add(i32),
    Sub(i32),
}

struct Accumulator {}

impl StateMachine for Accumulator {
    type Input = Op;
    type Output = ();

    fn apply(&self, op: Op) {
        println!("Applying {:?}", op);
    }
}
