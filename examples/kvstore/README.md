# kvstore

A key-value store replicated with vsr-rs. Every node accepts clients over a
Redis-like inline protocol, so `nc` works.

## Run

Build and start three nodes, each in its own terminal:

```console
cargo build --example kvstore
./target/debug/examples/kvstore --id 0 --replicas 127.0.0.1:7000,127.0.0.1:7001,127.0.0.1:7002 --listen 127.0.0.1:6379
./target/debug/examples/kvstore --id 1 --replicas 127.0.0.1:7000,127.0.0.1:7001,127.0.0.1:7002 --listen 127.0.0.1:6380
./target/debug/examples/kvstore --id 2 --replicas 127.0.0.1:7000,127.0.0.1:7001,127.0.0.1:7002 --listen 127.0.0.1:6381
```

Talk to any node:

```console
$ nc localhost 6379
PING
+PONG
SET foo bar
+OK
GET foo
$3
bar
GET nope
$-1
```

Stop node 0 with Ctrl-C. The others pick node 1 as the new primary within
a second and keep serving. Start node 0 again and it rejoins as a backup.

## Notes

- Keys and values are single words. One command at a time per connection.
- Only the view number is stored on disk, in `kvstore-node-N.view`. A
  restarted node recovers the rest from the others.
- `RUST_LOG=trace` shows every protocol message.
