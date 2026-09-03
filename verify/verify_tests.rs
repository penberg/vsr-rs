//! Runs seeded traces through the Rust replicas and the Lean model and
//! diffs what each prints. Needs `lake` from a Lean toolchain; without one
//! the test prints a note and passes, so a plain `cargo test` still works.

use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::Once;
use vsr_verify::{generate, Cluster};

const SEEDS: u64 = 40;
const STEPS: usize = 200;

fn lean_dir() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../lean")
}

fn lake() -> Option<PathBuf> {
    let home = std::env::var_os("HOME").map(PathBuf::from);
    let elan = home.map(|h| h.join(".elan/bin/lake"));
    std::env::var_os("PATH")
        .into_iter()
        .flat_map(|p| std::env::split_paths(&p).collect::<Vec<_>>())
        .map(|d| d.join("lake"))
        .chain(elan)
        .find(|p| p.is_file())
}

fn build_model(lake: &Path) {
    static BUILD: Once = Once::new();
    BUILD.call_once(|| {
        let status = Command::new(lake)
            .arg("build")
            .current_dir(lean_dir())
            .status()
            .expect("run lake build");
        assert!(status.success(), "lake build failed");
    });
}

fn replay_on_model(lake: &Path, trace_path: &Path) -> String {
    let output = Command::new(lake)
        .args(["exe", "vsr-replay"])
        .arg(trace_path)
        .current_dir(lean_dir())
        .output()
        .expect("run vsr-replay");
    assert!(
        output.status.success(),
        "vsr-replay failed on {}: {}",
        trace_path.display(),
        String::from_utf8_lossy(&output.stderr)
    );
    String::from_utf8(output.stdout).unwrap()
}

/// The first line where the two differ, with a little context.
fn first_difference(rust: &str, lean: &str) -> Option<String> {
    let rust: Vec<&str> = rust.lines().collect();
    let lean: Vec<&str> = lean.lines().collect();
    for i in 0..rust.len().max(lean.len()) {
        let (r, l) = (rust.get(i).copied(), lean.get(i).copied());
        if r != l {
            let step = rust[..i.min(rust.len())]
                .iter()
                .rev()
                .find(|line| line.starts_with("step "))
                .unwrap_or(&"(before the first step)");
            return Some(format!(
                "line {}, after `{step}`:\n  rust: {}\n  lean: {}",
                i + 1,
                r.unwrap_or("<end>"),
                l.unwrap_or("<end>")
            ));
        }
    }
    None
}

#[test]
fn replica_matches_lean_model() {
    let Some(lake) = lake() else {
        eprintln!("lake not found: skipping the Lean conformance test");
        return;
    };
    build_model(&lake);
    let dir = Path::new(env!("CARGO_TARGET_TMPDIR")).join("conformance");
    std::fs::create_dir_all(&dir).unwrap();
    for seed in 0..SEEDS {
        let trace = generate(seed, STEPS);
        let trace_path = dir.join(format!("trace-{seed}.txt"));
        std::fs::write(&trace_path, trace.to_string()).unwrap();
        let rust = Cluster::observe(&trace);
        let lean = replay_on_model(&lake, &trace_path);
        if let Some(diff) = first_difference(&rust, &lean) {
            panic!(
                "seed {seed}: the Rust replica and the Lean model diverge at {diff}\n\
                 trace: {}\nreplay: cargo run -p vsr-verify -- {seed} --observe",
                trace_path.display()
            );
        }
    }
}
