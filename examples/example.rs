use std::sync::Arc;
use vsr_rs::{Client, Replica, StateMachine};

fn main() {
    env_logger::init();
    let (client_tx, client_rx) = crossbeam_channel::unbounded();
    let (replica_tx, replica_rx) = crossbeam_channel::unbounded();
    let nr_replicas = 3;
    let replica_a = Replica::new(
        0,
        nr_replicas,
        CalculatorStateMachine {},
        client_tx.clone(),
        replica_tx.clone(),
    );
    let replica_b = Replica::new(
        1,
        nr_replicas,
        CalculatorStateMachine {},
        client_tx.clone(),
        replica_tx.clone(),
    );
    let replica_c = Replica::new(
        2,
        nr_replicas,
        CalculatorStateMachine {},
        client_tx.clone(),
        replica_tx.clone(),
    );
    let replicas = vec![replica_a, replica_b, replica_c];
    let nr_replicas = replicas.len();
    std::thread::spawn(move || loop {
        let (replica_id, message) = replica_rx.recv().unwrap();
        let replica = &replicas[replica_id];
        replica.on_message(message);
    });
    let client = Arc::new(Client::new(nr_replicas, replica_tx.clone()));
    let client_ = client.clone();
    std::thread::spawn(move || loop {
        let _ = client_rx.recv().unwrap();
        client_.on_message();
    });
    client.request(CalculatorOperation::Add(10));
    client.request(CalculatorOperation::Rem(5));
    client.request(CalculatorOperation::Add(7));
    client.request(CalculatorOperation::Add(8));
}

#[derive(Clone, Debug)]
enum CalculatorOperation {
    Add(i32),
    Rem(i32),
}

struct CalculatorStateMachine {}

impl StateMachine<CalculatorOperation> for CalculatorStateMachine {
    fn apply(&self, op: CalculatorOperation) {
        println!("Applying {:?}", op);
    }
}
