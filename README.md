# Viewstamped Replication for Rust

This is a _work-in-progress_ Rust implementation of the Viewstamped Replication consensus algorithm.

## Getting Started

Run the example:

```console
cargo run --example example
```

To see some debug traces, use `RUST_LOG` environment variable:

```console
RUST_LOG=trace cargo run --example example
```

## ToDo

* [x] Normal operation
* [x] State transfer
* [x] Deterministic simulator
* [ ] View changes 
* [ ] Failed replica recovery
* [ ] Reconfiguration

## Testing with Deterministic Simulation

You can run the deterministic simulator with:

```console
cargo run --example sim
```

The run will print out a *seed* value such as:

```console
Seed: 10693013600028533629
```

If the simulation triggers a problem, you can reproduce the exact same run by passing a seed to the simulator:

```console
cargo run --example sim 10693013600028533629
```

You can also increase logging level to see more output of the run with:

```console
RUST_LOG=debug cargo run --example sim 10693013600028533629
```

## References

The implementation of `vsr-rs` is based on the paper [Viewstamped Replication Revisited](https://pmg.csail.mit.edu/papers/vr-revisited.pdf) by Liskov and Cowling.
However, the algorithm in the paper has the following known bugs:

* The recovery algorithm described in Section 4.3 can result in the system being in an inconsistent state as reported by Michael et al in Appendix B1 of [Recovering Shared Objects Without Stable Storage](https://drkp.net/papers/recovery-tr17.pdf)
* The state transfer algorithm described in Section 5.2 can cause data loss as discovered by Jack Vanlightly in https://twitter.com/vanlightly/status/1596190819421413377 and https://twitter.com/vanlightly/status/1596425599026970624.

The `vsr-rs` library does not yet implement recovery or view changes so the bugs are not addressed.

For more information on VSR, please also check out the following presentations and blog posts:

* [Reading Group: Viewstamped Replication Revisited](http://charap.co/reading-group-viewstamped-replication-revisited/)
* [Viewstamped Replication explained](https://blog.brunobonacci.com/2018/07/15/viewstamped-replication-explained/)
