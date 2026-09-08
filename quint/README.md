# The Quint model of vsr-rs

A model of the replica and the cluster in [Quint](https://quint-lang.org),
the same model as `lean/` but checked instead of proved: `quint run`
explores random runs and `quint verify` (Apalache) explores every run up to
a bounded length, both against the safety properties of the Lean theorem
`Vsr.safety` and of `simulator/properties.rs`.

Where Lean gives a proof for every configuration and every run, Quint gives
a cheap, executable model that anyone can read, run, and change in a
minute. It found nothing the proof did not already cover; its value is as a
second, independent statement of the protocol, and as the place to try a
change before proving it.

## Files

| File | What it is |
|---|---|
| `vsr.qnt` | The protocol: types, one definition per handler in `lib.rs` (and per definition in `lean/Vsr/Replica.lean`), the cluster steps, the safety properties, and the witnesses. Parameterised by the replica count and the client workload. |
| `vsr3.qnt` | Three replicas, two clients, two requests each, views up to 3. |
| `vsr3min.qnt` | Three replicas, one client with one request, views up to 2: the smallest instance, for Apalache. |
| `vsr5.qnt` | Five replicas, otherwise the same. |
| `Makefile` | `typecheck`, `run`, `verify`. |

## Running

```console
npm install -g @informalsystems/quint
make typecheck
make run             # random simulation, 3 and 5 replicas
make verify          # Apalache, 3 replicas, every state one step from the start
```

`run` prints, for each witness, how many of the runs reached it. With the
defaults, on three replicas, roughly a third of the runs commit something,
a quarter commit something after a view change, and a tenth complete a
recovery; on five replicas the rates are lower, since progress needs more
messages. If a property fails, Quint prints the run that breaks it, state
by state.

## The model

The cluster is `replicas`, one record per replica id, and `sent`, the set
of every message ever sent. A step is one of:

- `deliver`: any message in `sent` arrives at its destination. Nothing is
  ever removed from `sent`, so a message can arrive again, out of order,
  or never. That one rule covers loss, delay, duplication, and reordering,
  and a replica that is never stepped is a crashed one.
- `idle`: an idle period passes at a replica. The environment also chooses
  whether it is the period on which the replica's wait runs out.
- `request`: a client request arrives at a replica. Any request may arrive
  anywhere; clients are not modelled.
- `recover`: a replica restarts with nothing but its view number, which
  the owner persisted, and a fresh nonce.

`step` is any of the four; `stepFair` is the same with deliveries weighted
up and crashes down, and at most one replica recovering at a time, so that
random runs get somewhere. Every run of `stepFair` is a run of `step`.

The replica is `lean/Vsr/Replica.lean` written again, handler for handler,
with three abstractions, each of which only adds behaviour:

- **No timers.** The Rust counts idle periods and starts a view change when
  the count reaches a bound; here the environment decides, on every idle
  period, whether the wait is over. Every schedule the Rust timers produce
  is one the environment can choose.
- **No state machine, no replies.** An entry is a client id, a request
  number, and an abstract op value. The client table records whether a
  request has been executed rather than its reply.
- **Bounded views.** A replica at `MAX_VIEW` no longer times out, so the
  state space is finite. Views can still be adopted from messages.

Every Rust `assert!` sets `panicked` instead of stopping, so every handler
is total and `noPanic` is a property.

## The properties

All are checked in every state of every run, and `safety` is their
conjunction:

| Property | Statement |
|---|---|
| `noPanic` | No replica's `panicked` flag is set. |
| `commitBounded` | Every replica's commit number is at most its log length. |
| `commitMonotonic` | No step lowers a replica's commit number, except a crash. |
| `prefixAgreement` | Two replicas that both committed index `i` hold the same entry there. |
| `historyAgreement` | Every committed entry is the one first committed at its index, ever (ghost `history`). |
| `durability` | Every committed entry is held at its index by enough non-recovering replicas to meet every quorum they could form. |
| `noDuplicateOps` | No request appears twice in a committed prefix. |

`prefixAgreement` and `durability` are the Lean `PrefixAgreement` and
`Durability` verbatim; `historyAgreement`, `commitMonotonic`, and
`noDuplicateOps` are the simulator's `CommittedPrefixAgreement`,
`CommitNumberMonotonic`, and `NoDuplicateOps`, which the Lean proof does
not state.

## Evidence that the checks have teeth

Four one-line faults, each found by `quint run` on three replicas within
a few seconds:

| Fault | Caught by |
|---|---|
| A backup acknowledges a `Prepare` with a gap before it, without state transfer. | `durability` |
| The primary commits an op when it prepares it, without a quorum. | `durability` |
| The new primary chooses the DoViewChange with the *smallest* `(last normal view, log length)`. | `historyAgreement`, `noPanic` |
| A `Commit` message sets the commit number instead of raising it. | `commitMonotonic` |

## Apalache does not get far

`quint verify` hands the model to Apalache, which encodes a bounded run
as an SMT problem. On `vsr3.qnt` it checks all seven properties on every
state one step from the start in a few minutes (`make verify`). Asked for
two steps, it checks the properties on the first two-step states within
five minutes and then does not return within an hour; on `vsr3min.qnt`,
the smallest instance, three steps did not finish in 40 minutes with a
12 GB heap, and four ran out of a 4 GB heap. The cost is the state: a set
of every message ever sent, each carrying a log of unbounded length, and
a delivery step that picks any of them. That is the shape that makes the
model faithful to the code and the Lean proof, and it is the shape a
symbolic checker pays most for. A protocol-level model with messages in a
fixed-size table would go deeper; it would also be a different model. So
the workhorse here is `quint run`, and the depth is the proof's.

## What this does not do

It is checking, not proof. Random simulation misses runs; Apalache gets
only one step deep before the encoding outgrows it. The Lean
proof in `lean/` covers every configuration and every run. Nothing here
checks that the model is the code: that is `verify/`, which replays traces
on the Rust replicas and on the Lean model, and the Lean model and this one
are kept in step by hand, handler for handler.
