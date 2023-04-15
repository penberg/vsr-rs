use log::debug;
use parking_lot::Mutex;
use rand::prelude::*;
use rand_chacha::ChaCha8Rng;
use std::sync::Arc;
use vsr_rs::{Client, Config, Replica, StateMachine};

#[test]
fn test_simulation() {
    let seed = match std::env::var("SEED") {
        Ok(seed) => seed.parse::<u64>().unwrap(),
        Err(_) => rand::thread_rng().next_u64(),
    };    
    
    println!("Seed: {}", seed);
    env_logger::init();
    let (client_tx, _client_rx) = crossbeam_channel::unbounded();
    let (replica_tx, replica_rx) = crossbeam_channel::unbounded();
    let config = Arc::new(Mutex::new(Config::new()));
    let a_id = config.lock().add_replica();
    let sm_a = Arc::new(Accumulator::new());
    let replica_a = Replica::new(
        a_id,
        config.clone(),
        sm_a.clone(),
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
    let client = Arc::new(Client::new(config, replica_tx));
    let idle = || {
        for replica in &replicas {
            replica.on_idle();
        }
    };
    let tick = || {
        while !replica_rx.is_empty() {
            let (replica_id, message) = replica_rx.recv().unwrap();
            debug!("Sending {:?} to {}", message, replica_id);
            replicas[replica_id].on_message(message);
        }
    };
    let tick_drop = |to_drop_id| {
        while !replica_rx.is_empty() {
            let (replica_id, message) = replica_rx.recv().unwrap();
            if replica_id == to_drop_id {
                debug!("Dropping {:?} to {}", message, to_drop_id);
                continue;
            }
            debug!("Sending {:?} to {}", message, replica_id);
            replicas[replica_id].on_message(message);
        }
    };
    let tick_dup = |to_dup_id| {
        while !replica_rx.is_empty() {
            let (replica_id, message) = replica_rx.recv().unwrap();
            debug!("Sending {:?} to {}", message, replica_id);
            replicas[replica_id].on_message(message.clone());
            if replica_id == to_dup_id {
                debug!("Duplicating {:?} to {}", message, to_dup_id);
                replicas[replica_id].on_message(message);
            }
        }
    };
    let mut rng = ChaCha8Rng::seed_from_u64(seed);
    let oracle = Accumulator::new();
    for _ in 0..100000 {
        if gen_idle(&mut rng) {
            idle();
        } else {
            let op = gen_op(&mut rng);
            debug!("Op {:?}", op);
            oracle.apply(op.clone());
            client.request_async(op, Box::new(|_| {}));
        }
        match gen_hardship(&mut rng) {
            Hardship::None => {
                tick();
            }
            Hardship::DropMsg => {
                let id = rng.gen_range(1..3);
                tick_drop(id);
            }
            Hardship::DupMsg => {
                let id = rng.gen_range(1..3);
                tick_dup(id);
            }
        }
        let oracle_acc = *oracle.accumulator.lock();
        let primary_acc = *(sm_a.accumulator.lock());
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

enum Hardship {
    None,
    DropMsg,
    DupMsg,
}

fn gen_hardship(rng: &mut ChaCha8Rng) -> Hardship {
    let hardship = rng.gen_range(0..3);
    match hardship {
        0 => Hardship::None,
        1 => Hardship::DropMsg,
        2 => Hardship::DupMsg,
        _ => panic!("internal error"),
    }
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
                *accumulator = accumulator.wrapping_add(value);
            }
            Op::Sub(value) => {
                *accumulator = accumulator.wrapping_sub(value);
            }
        }
    }
}