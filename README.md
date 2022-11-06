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

* [Reading Group: Viewstamped Replication Revisited](http://charap.co/reading-group-viewstamped-replication-revisited/)
* [Viewstamped Replication explained](https://blog.brunobonacci.com/2018/07/15/viewstamped-replication-explained/)

