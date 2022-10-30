# Viewstamped Replication for Rust

This is a _work-in-progress_ Rust implementation of the Viewstamped Replication consensus algorithm.

## Getting Started

```
RUST_LOG=trace cargo run --example example
```

## ToDo

* [x] Normal operation (mostly works)
* [ ] Deterministic simulator
* [ ] View changes 
* [ ] Failed replica recovery
* [ ] Reconfiguration

## References

* [Reading Group: Viewstamped Replication Revisited](http://charap.co/reading-group-viewstamped-replication-revisited/)
* [Viewstamped Replication explained](https://blog.brunobonacci.com/2018/07/15/viewstamped-replication-explained/)

