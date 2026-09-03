//! Prints the trace for a seed, or with `--observe` what the Rust replicas
//! do on it, for looking at a conformance failure by hand.

use vsr_verify::{generate, Cluster};

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let seed: u64 = args
        .iter()
        .find(|a| !a.starts_with("--"))
        .and_then(|a| a.parse().ok())
        .unwrap_or(0);
    let steps: usize = std::env::var("STEPS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(200);
    let trace = generate(seed, steps);
    if args.iter().any(|a| a == "--observe") {
        print!("{}", Cluster::observe(&trace));
    } else {
        print!("{trace}");
    }
}
