//! Tests of the simulator itself: determinism and a few fixed
//! configurations that must pass.

use rand::SeedableRng;
use rand_chacha::ChaCha8Rng;
use vsr_simulator::{parse_script, Fault, Limits, NetworkOptions, Options, Simulator};

/// Runs the swarm configuration for `seed`, with `adjust` applied to it.
fn run(seed: u64, adjust: impl FnOnce(&mut Options)) -> Simulator {
    let _ = env_logger::try_init();
    let mut prng = ChaCha8Rng::seed_from_u64(seed);
    let mut options = Options::lite(&mut prng);
    adjust(&mut options);
    let mut simulator = Simulator::init(seed, options).expect("options are valid");
    if let Err(err) = simulator.run(Limits::default()) {
        panic!("seed {seed} failed at tick {}: {err:#}", simulator.ticks);
    }
    simulator
}

fn perfect_network(options: &mut Options) {
    options.network = NetworkOptions::perfect();
}

fn replay_only(options: &mut Options) {
    options.network = NetworkOptions {
        packet_replay_probability: 0.1,
        ..NetworkOptions::perfect()
    };
}

#[test]
fn same_seed_gives_same_run() {
    let a = run(1, replay_only);
    let b = run(1, replay_only);
    assert_eq!(a.ticks, b.ticks);
    assert_eq!(
        format!("{:?}", a.message_summary()),
        format!("{:?}", b.message_summary())
    );
    assert_eq!(
        a.replicas()[0].state_machine().value,
        b.replicas()[0].state_machine().value
    );
}

#[test]
fn perfect_network_replies_to_every_request() {
    let simulator = run(2, perfect_network);
    assert_eq!(simulator.requests_sent, simulator.options.requests_max);
    assert_eq!(simulator.requests_replied, simulator.options.requests_max);
}

#[test]
fn replayed_messages() {
    for seed in [3, 4, 5] {
        run(seed, replay_only);
    }
}

#[test]
fn seven_replicas() {
    run(6, |options| {
        options.replica_count = 7;
        replay_only(options);
    });
}

/// Injected faults on a cluster with no random ones: the primary crashes
/// and comes back, a backup reboots with no memory, a replica is cut off
/// and reconnected. The run must still pass.
#[test]
fn fault_script() {
    let _ = env_logger::try_init();
    let mut prng = ChaCha8Rng::seed_from_u64(7);
    let mut options = Options::lite(&mut prng);
    options.network = NetworkOptions::perfect();
    options.replica_crash_probability = 0.0;
    options.full_core = true;
    options.requests_max = 20_000;
    let script = parse_script(
        "100 crash 0\n\
         2000 restart 0\n\
         2500 crash 1\n\
         2600 reboot 1\n\
         4000 partition 2\n\
         # replica 2 is alone for a while\n\
         5000 heal-all\n",
    )
    .unwrap();
    assert_eq!(script[1], (2000, Fault::Restart(0)));
    let mut simulator = Simulator::init(7, options).expect("options are valid");
    if let Err(err) = simulator.run_script(&script, Limits::default()) {
        panic!("script failed at tick {}: {err:#}", simulator.ticks);
    }
    let snapshot = simulator.snapshot();
    assert!(
        snapshot.tick > 5000,
        "the run ended at tick {}",
        snapshot.tick
    );
    assert!(
        snapshot
            .replicas
            .iter()
            .all(|replica| replica.up && !replica.partitioned),
        "{:?}",
        snapshot.replicas
    );
    assert!(snapshot
        .replicas
        .iter()
        .any(|replica| replica.view_number > 0));
    assert_eq!(1, snapshot.reboots);
}
