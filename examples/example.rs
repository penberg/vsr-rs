use std::sync::mpsc;
use std::sync::{Arc, Mutex};
use vsr_rs::{Client, Replica, StateMachine};

fn main() {
    env_logger::init();
    let (client_tx, client_rx) = mpsc::channel();
    let (replica_tx, replica_rx) = mpsc::channel();
    let nr_replicas = 3;
    let replica_a = Mutex::new(Replica::new(
        0,
        nr_replicas,
        client_tx.clone(),
        replica_tx.clone(),
    ));
    let replica_b = Mutex::new(Replica::new(
        1,
        nr_replicas,
        client_tx.clone(),
        replica_tx.clone(),
    ));
    let replica_c = Mutex::new(Replica::new(
        2,
        nr_replicas,
        client_tx.clone(),
        replica_tx.clone(),
    ));
    let replicas = vec![replica_a, replica_b, replica_c];
    let client = Arc::new(Mutex::new(Client::new(replicas.len(), replica_tx.clone())));
    let replica_event_loop = std::thread::spawn(move || loop {
        let (replica_id, message) = replica_rx.recv().unwrap();
        let mut replica = replicas[replica_id].lock().unwrap();
        replica.on_message(message);
    });
    let client_ = client.clone();
    let client_event_loop = std::thread::spawn(move || loop {
        let _ = client_rx.recv().unwrap();
        client_.lock().unwrap().on_message();
    });
    let callback = |request_number| {
        println!("Request {} completed", request_number);
    };
    client
        .lock()
        .unwrap()
        .request(CalculatorOperation::Add(10), callback);
    // client.request(CalculatorOperation::Rem(5));
    // client.request(CalculatorOperation::Add(7));
    // client.request(CalculatorOperation::Add(8));
    replica_event_loop.join().unwrap();
    client_event_loop.join().unwrap();
}

#[derive(Clone, Debug)]
enum CalculatorOperation {
    Add(i32),
    // Rem(i32),
}

struct CalculatorStateMachine {}

impl StateMachine<CalculatorOperation> for CalculatorStateMachine {}
