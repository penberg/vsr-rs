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
* [ ] State transfer
* [ ] Deterministic simulator
* [ ] View changes 
* [ ] Failed replica recovery
* [ ] Reconfiguration

## References

* [Reading Group: Viewstamped Replication Revisited](http://charap.co/reading-group-viewstamped-replication-revisited/)
* [Viewstamped Replication explained](https://blog.brunobonacci.com/2018/07/15/viewstamped-replication-explained/)

