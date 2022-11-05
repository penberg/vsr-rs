use rand::prelude::*;
use rand_chacha::ChaCha8Rng;
use std::sync::{Arc, Mutex};
use vsr_rs::{Client, Config, Replica, StateMachine};

fn main() {
    let mut args = std::env::args().skip(1);
    let seed = match args.next() {
        Some(seed) => seed.parse::<u64>().unwrap(),
        None => rand::thread_rng().next_u64(),
    };
    println!("Seed: {}", seed);
    env_logger::init();
    let (client_tx, _client_rx) = crossbeam_channel::unbounded();
    let (replica_tx, replica_rx) = crossbeam_channel::unbounded();
    let config = Arc::new(Mutex::new(Config::new()));
    let a_id = config.lock().unwrap().add_replica();
    let sm_a = Arc::new(Accumulator::new());
    let replica_a = Replica::new(
        a_id,
        config.clone(),
        sm_a.clone(),
        client_tx.clone(),
        replica_tx.clone(),
    );
    let b_id = config.lock().unwrap().add_replica();
    let replica_b = Replica::new(
        b_id,
        config.clone(),
        Arc::new(Accumulator::new()),
        client_tx.clone(),
        replica_tx.clone(),
    );
    let c_id = config.lock().unwrap().add_replica();
    let replica_c = Replica::new(
        c_id,
        config.clone(),
        Arc::new(Accumulator::new()),
        client_tx.clone(),
        replica_tx.clone(),
    );
    let replicas = vec![replica_a, replica_b, replica_c];
    let client = Arc::new(Client::new(config, replica_tx.clone()));
    let idle = || {
        for replica in &replicas {
            replica.on_idle();
        }
    };
    let tick = || {
        while !replica_rx.is_empty() {
            let (replica_id, message) = replica_rx.recv().unwrap();
            println!("Sending {:?} to {}", message, replica_id);
            replicas[replica_id].on_message(message);
        }
    };
    let tick_lossy = |to_drop_id| {
        while !replica_rx.is_empty() {
            let (replica_id, message) = replica_rx.recv().unwrap();
            if replica_id == to_drop_id {
                println!("Dropping {:?} to {}", message, to_drop_id);
                continue;
            }
            println!("Sending {:?} to {}", message, replica_id);
            replicas[replica_id].on_message(message);
        }
    };
    let mut rng = ChaCha8Rng::seed_from_u64(seed);
    let oracle = Accumulator::new();
    for _ in 0..100000 {
        if gen_idle(&mut rng) {
            idle();
        } else {
            let op = gen_op(&mut rng);
            println!("Op {:?}", op);
            oracle.apply(op.clone());
            client.request_async(op, Box::new(|_| {}));
        }
        if drop_message(&mut rng) {
            let id = rng.gen_range(1..3);
            tick_lossy(id);
        } else {
            tick();
        }
        let oracle_acc = *oracle.accumulator.lock().unwrap();
        let primary_acc = *(sm_a.accumulator.lock().unwrap());
        assert_eq!(oracle_acc, primary_acc);
    }
}

#[derive(Clone, Debug)]
enum Op {
    Add(i32),
    Sub(i32),
}

fn gen_op(rng: &mut ChaCha8Rng) -> Op {
    let op = rng.gen_range(0..2);
    let value = rng.next_u32() as i32;
    match op {
        0 => Op::Add(value),
        1 => Op::Sub(value),
        _ => panic!("internal error"),
    }
}

fn gen_idle(rng: &mut ChaCha8Rng) -> bool {
    rng.gen_range(0..100) > 95
}

fn drop_message(rng: &mut ChaCha8Rng) -> bool {
    rng.gen_range(0..2) == 1
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
                *accumulator = accumulator.wrapping_add(value);
            }
            Op::Sub(value) => {
                *accumulator = accumulator.wrapping_sub(value);
            }
        }
    }
}
