//! vsr-simulator CLI.

use clap::Parser;
use rand::{RngCore, SeedableRng};
use rand_chacha::ChaCha8Rng;
use std::panic::AssertUnwindSafe;
use vsr_simulator::{Limits, Options, Simulator};

#[derive(Parser)]
#[command(name = "vsr-simulator")]
#[command(about = "Deterministic simulator for vsr-rs")]
struct Args {
    /// Seed as a decimal integer, or a 40-character git commit hash. Read
    /// from the SEED environment variable if not given; random otherwise.
    seed: Option<String>,
    /// Run a small 3-replica cluster with fewer requests.
    #[arg(long)]
    lite: bool,
    /// Override the number of requests to send.
    #[arg(long)]
    requests_max: Option<usize>,
    /// Ticks without a reply before the safety phase gives up.
    #[arg(long, default_value_t = Limits::default().ticks_max_requests)]
    ticks_max_requests: u64,
    /// Ticks the liveness phase may take to converge.
    #[arg(long, default_value_t = Limits::default().ticks_max_convergence)]
    ticks_max_convergence: u64,
    /// Override the packet loss probability.
    #[arg(long)]
    packet_loss_probability: Option<f64>,
    /// Override the packet replay probability.
    #[arg(long)]
    packet_replay_probability: Option<f64>,
    /// Inject faults into messages sent by clients too, whatever the seed
    /// chose.
    #[arg(long)]
    fault_client_messages: bool,
    /// Override the per-tick replica crash probability.
    #[arg(long)]
    replica_crash_probability: Option<f64>,
    /// Override the probability that a restart loses the replica's memory.
    #[arg(long)]
    replica_reboot_probability: Option<f64>,
}

fn main() -> anyhow::Result<()> {
    let _ = env_logger::try_init();
    let args = Args::parse();

    let seed_argument = args
        .seed
        .clone()
        .or_else(|| std::env::var("SEED").ok().filter(|s| !s.is_empty()));
    let seed = match seed_argument {
        Some(s) => parse_seed(&s)?,
        None => {
            if cfg!(debug_assertions) {
                eprintln!("warning: no seed provided; build with --release for long runs");
            }
            rand::thread_rng().next_u64()
        }
    };

    // Options are drawn from a PRNG seeded with the seed, so the seed
    // determines the whole configuration. The simulator itself gets the same
    // seed and its own PRNG.
    let mut option_prng = ChaCha8Rng::seed_from_u64(seed);
    let mut options = if args.lite {
        Options::lite(&mut option_prng)
    } else {
        Options::swarm(&mut option_prng)
    };
    if let Some(requests_max) = args.requests_max {
        options.requests_max = requests_max;
    }
    if let Some(p) = args.packet_loss_probability {
        options.network.packet_loss_probability = p;
    }
    if let Some(p) = args.packet_replay_probability {
        options.network.packet_replay_probability = p;
    }
    if args.fault_client_messages {
        options.network.fault_client_messages = true;
    }
    if let Some(p) = args.replica_crash_probability {
        options.replica_crash_probability = p;
    }
    if let Some(p) = args.replica_reboot_probability {
        options.replica_reboot_probability = p;
    }
    let limits = Limits {
        ticks_max_requests: args.ticks_max_requests,
        ticks_max_convergence: args.ticks_max_convergence,
    };

    println!();
    println!("          SEED={seed}");
    println!();
    println!("{options}");
    println!();

    let mut simulator = Simulator::init(seed, options)?;

    // Replica code asserts on unexpected states, so catch panics too and
    // still print how to reproduce the run.
    let result = std::panic::catch_unwind(AssertUnwindSafe(|| simulator.run(limits)));
    let failure = match result {
        Ok(Ok(())) => None,
        Ok(Err(err)) => Some(format!("{err:#}")),
        Err(panic) => Some(format!("panic: {}", panic_message(&panic))),
    };

    let summary = simulator.message_summary();
    println!(
        "          messages: sent={} delivered={} lost={} replayed={} delayed={}",
        summary.sent, summary.delivered, summary.lost, summary.replayed, summary.delayed
    );
    println!(
        "          requests: sent={} replied={}",
        simulator.requests_sent, simulator.requests_replied
    );
    println!(
        "          replicas: crashes={} restarts={} reboots={} core={:?} up={:?}",
        simulator.crashes,
        simulator.restarts,
        simulator.reboots,
        simulator.core(),
        (0..simulator.options.replica_count)
            .filter(|&id| simulator.is_up(id))
            .collect::<Vec<_>>()
    );
    match failure {
        None => {
            println!();
            println!("          PASSED ({} ticks)", simulator.ticks);
            Ok(())
        }
        Some(message) => {
            println!();
            println!("          FAILED at tick {}: {message}", simulator.ticks);
            println!("          you can reproduce this failure with seed={seed}");
            std::process::exit(1);
        }
    }
}

/// Parses a seed. A 40-character hex string is taken as a git commit hash and
/// truncated to 64 bits, so CI can use the commit under test as the seed and
/// failures stay reproducible from the commit alone.
fn parse_seed(s: &str) -> anyhow::Result<u64> {
    if s.len() == 40 && s.chars().all(|c| c.is_ascii_hexdigit()) {
        return Ok(u64::from_str_radix(&s[24..], 16)?);
    }
    s.parse::<u64>()
        .map_err(|err| anyhow::anyhow!("invalid seed {s:?}: {err}"))
}

fn panic_message(panic: &Box<dyn std::any::Any + Send>) -> String {
    if let Some(s) = panic.downcast_ref::<&str>() {
        (*s).to_string()
    } else if let Some(s) = panic.downcast_ref::<String>() {
        s.clone()
    } else {
        "unknown panic".to_string()
    }
}
