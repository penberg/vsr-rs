# VSR in Veil

An experiment: the same protocol as `lean/`, written for
[Veil](https://veil.dev) instead of as a twin of `lib.rs`. Veil is a Lean 4
DSL for transition systems with three checkers behind it: an SMT-backed
inductive-invariant checker with counterexamples to induction, an
explicit-state model checker for finite instances, and bounded symbolic
model checking through trace queries. When SMT gives up, the failed
verification condition becomes an ordinary Lean theorem to prove by hand.

## Where it sits

The repository already has two things that this is neither of:

- `lean/` is a **twin** of `lib.rs`: one Lean definition per Rust function,
  same control flow, kept honest by `verify/`, which replays the same traces
  on the Rust and the Lean and diffs them. Proofs there are about the code,
  through the model.
- `proof/` is the **argument** on paper: the inductive invariant `Inv`,
  clause by clause.

`veil/` is the **abstraction** that `Inv` is stated over, written as a
transition system with relations for state and for the message history,
and with `Inv`'s clauses as `invariant` lines. It is what `Inv` looks like
in Ivy-style first-order logic. Nothing about `lib.rs` follows from it
directly; what it offers is a machine that finds counterexamples to
induction in seconds where `lean/Vsr/Preserve.lean` takes a proof per
handler, and a model checker that runs the whole protocol, recoveries and
view changes included, on a three-replica instance.

## The model

`Vsr/Protocol.lean`. Each action names the handler it renders. The
decisions, and why:

| Lean | Veil | Why |
|---|---|---|
| `System.sent`, a list that only grows | one relation per message kind, only ever set to `true` | Same semantics: any message can be delivered any number of times, in any order, or never. |
| `Frag`/`Holds`: pieces of a view's log carried by messages | `frag v n e`: some message of view `v` carried `e` at op `n` | Layer three says the fragments of a view agree, so the state keeps the union. Whole-log messages carry a length; the receiver reads entries from `frag`. This over-approximates the Rust, which makes a proof on the model a proof for the Rust's behaviour, and makes "one log per view" a one-line invariant. |
| `List (LogEntry Op)` | `log r n e` with `log_len r`, op numbers in an ordered sort `idx` with a successor | First-order logic has no lists. Index `i` of the Lean log is op number `i + 1`. |
| `Config.primaryId v = v % N` | `immutable function primary : view → replica` | Safety needs only that the primary is a function of the view. |
| `Config.quorum`, counting | `type quorum`, `member`, and quorums intersect as an axiom | The Ivy encoding of majorities; the Mathlib counting argument the Lean plan mentions is not needed. |
| Ghost `System.started` | the primary's own vote is written to the `DoViewChange` history; `chosen v q` records the votes a view was started from | The Lean needed the ghost because the primary's own vote is never in `sent`. |
| Timers, backoff | `timeout` may fire on any backup at any time | As `proof/model.md` says: safety holds under every schedule. |
| Client table, replies, state machine | dropped | Prefix agreement is about logs. |
| `panicked := true` | `assert` | Veil's `doesNotThrow` condition is `NoPanic`. |

The invariant clauses keep the Lean names: `one_log_per_view`, `covered`,
`replica_backed` and the `*_backed` message clauses (`CommitsBacked`), the
`survives_*` clauses (`Survives`), `acks_current`, `acks_hold`,
`primary_longest_*`, `start_view_chosen`, `chosen_votes_cover`,
`*_below_view` (`MessagesBelowView`), `recovery_covers_acks`,
`started_views`.

## Building

Veil pins its own Lean toolchain (`v4.32.0`, one behind `lean/`), and needs
Mathlib, node, and cvc5:

```console
cd veil
lake update
lake exe cache get   # Mathlib's prebuilt files, once
lake build
```

The commands at the end of `Vsr/Protocol.lean` run when the file is
built. They must run under `lake build`, not `lake env lean FILE`: Lake is
what loads the cvc5 native library the trace queries use. Or open the file
in VS Code and read the InfoView on each command. Elaborating the model
alone takes about six minutes and four gigabytes; the checks come on top.

## Status

Filled in below as the checks run.
