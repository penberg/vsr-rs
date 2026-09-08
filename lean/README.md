# The Lean model of vsr-rs

A model of the replica in Lean 4, a model of the cluster around it, the
safety properties stated over every reachable cluster state, and their
proofs. The model is kept honest by `verify/`, which replays seeded traces
on the real replicas and on this model and diffs what they do.

## What is proved

```lean
theorem safety [DecidableEq Op] (m : Machine Op Output St) (sm : St) (config : Config)
    (htwo : 2 ≤ config.replicaCount) (s : System Op Output St) (h : Reachable m sm config s) :
    NoPanic s ∧ PrefixAgreement s ∧ Durability s
```

For every state machine, every initial state, and every configuration of
at least two replicas, every reachable cluster state satisfies:

| Property | Statement | Theorem |
|---|---|---|
| No panic | No Rust `assert!` fires: no replica's `panicked` flag is set. | `Vsr.safety` |
| Prefix agreement | Two replicas that both committed index `i` hold the same entry there. | `Vsr.safety`, from `Vsr.Inv.prefixAgreement` |
| Durability | Every committed entry is held at its index by enough non-recovering replicas to meet every quorum they could form. | `Vsr.safety`, from `Vsr.Inv.durability` |
| Commit bounded | Every replica's commit number is at most its log length. | `Vsr.commitBounded_of_reachable` |
| Well-formed messages | Every message ever sent has fields that agree with one another. | `Vsr.sentWF_of_reachable` |

All rest on the axioms `propext`, `Quot.sound`, and `Classical.choice`
only; no `sorry` anywhere. Check:

```console
lake env lean /dev/stdin <<'EOF2'
import Vsr
#print axioms Vsr.safety
#print axioms Vsr.commitBounded_of_reachable
#print axioms Vsr.sentWF_of_reachable
EOF2
```

`Reachable` (`Vsr/Safety.lean`) is the cluster reached from the initial
state by any sequence of `deliver`, `idle`, `request`, and `recover`
steps. Delivery picks any message ever sent, so loss, delay, duplication,
and reordering are all covered. The assumptions, all on the environment:

- At least two replicas. A cluster of one never sends a message, so
  nothing about it can be stated through `sent`; it is trivially safe.
- A `recover` step restarts the replica with the view number it held: the
  persisted view number of the paper.
- A `recover` step uses a fresh nonce (`NonceFresh`): no `Recovery` in
  `sent` carries it.
- Timers are the Rust ones, counting idle periods; the environment chooses
  which replica idles when, and every schedule is covered.

Not proved: linearizability of client histories (the model has no
clients) and liveness. Both are stated in the paper (`docs/paper`); the
paper's Appendix on the mechanised proof maps its lemmas and clauses to
the Lean names.

## Files

| File | What it is |
|---|---|
| `Vsr/Types.lean` | Ids, `Config`, `LogEntry`, `Reply`, `Message`, `Status`, the abstract `Machine`, and the sorted association lists that stand in for the Rust `BTreeMap`s. |
| `Vsr/Replica.lean` | The replica: one definition per Rust function in `lib.rs`, same control flow. Sends go to `outbox`, replies to `replies`. A Rust `assert!` sets `panicked` instead of stopping, so every handler is total. |
| `Vsr/System.lean` | The cluster: replicas by id, `sent`, the list of every message ever sent, which delivery never shrinks, `replies`, and the ghost `started`. Steps: `deliver`, `idle`, `request`, `recover`. |
| `Vsr/Frame.lean` | Frame lemmas: what each helper leaves alone, as `@[simp]` lemmas. |
| `Vsr/Local.lean` | The per-replica invariant `LocalInv` and the proof that every handler preserves it. |
| `Vsr/WellFormed.lean` | The well-formedness predicate `WF` on messages and the proof that every handler only sends well-formed messages. |
| `Vsr/Quorum.lean` | Quorum arithmetic. |
| `Vsr/Invariant.lean` | The inductive invariant `Inv`: the history definitions (`Frag`, `Holds`, `Acked`, `QuorumAcked`, `Committed`, `Backed`, `DvcOf`), every clause, monotonicity of everything stated through `sent` and `started`, `Inv.init`, and `Inv.prefixAgreement`. |
| `Vsr/Check.lean` | Executable (`Bool`) twins of every clause of `Inv`, which `vsr-replay` evaluates after every step. |
| `Vsr/Safety.lean` | `Reachable`, `NonceFresh`, the safety properties, `commitBounded_of_reachable`, `sentWF_of_reachable`. |
| `Vsr/Preserve/After.lean` | The shape of a step: `System.after` (replace one replica, append to `sent` and `started`), `StepOK` (one obligation per clause, about the new items only), and `Inv.after`. |
| `Vsr/Preserve/Shapes.lean` | The drained view `System.drainOf` of a replica mid-handler, and the step shapes on it: `Inv.drainStep`, `StepOK.replace`, `MsgOK` and `StepOK.send`. |
| `Vsr/Preserve/Best.lean`, `Assoc.lean` | `bestDoViewChange` and association-list lemmas. |
| `Vsr/Preserve/Chosen.lean` | The quorum argument: `Inv.bestHolds` (the chosen log holds every earlier commit) and `Inv.viewHolds_of_newAck` (a new `Committed` fact is held by every later view), by strong induction on the view. |
| `Vsr/Preserve/Kinds.lean` | `MsgOK` for each kind of message a handler can send. |
| `Vsr/Preserve/Replace.lean` | Replacing one replica without sending: `StepOK.keepLog`, `.install`, `.recover`; sending from the drained view. |
| `Vsr/Preserve/Normal.lean` | `Inv.onGetState`, `onCommit`, `onPrepare`, `onPrepareOk`, `onNewState`, and the commit, catch-up, and append steps they share. |
| `Vsr/Preserve/Request.lean` | `Inv.onRequest`. |
| `Vsr/Preserve/ViewChange.lean` | `Inv.recordDoViewChange` (starting a view), `startViewChange`, `sendDoViewChange`, `onStartViewChange`, `onDoViewChange`, `onStartView`. |
| `Vsr/Preserve/Recovery.lean` | `Inv.onRecovery`, `onRecoveryResponse`, `recover`. |
| `Vsr/Preserve/Idle.lean` | `Inv.onIdle`. |
| `Vsr/Preserve/Durable.lean` | `Inv.durability`, by counting. |
| `Vsr/Preserve/Step.lean` | `Inv.onMessage`, `Inv.step`, `inv_of_reachable`, and `safety`. |
| `Main.lean` | `vsr-replay`: runs a trace on the model and prints the observable state after each step, in the format `verify/` compares against. |

## The invariant

`Inv` is stated over the history: `sent`, every message ever sent, and
`started`, a ghost record of every started view and the DoViewChange
messages its log was chosen from. Its parts are the paper's: the local
invariant of every replica, well-formedness of every message, one log per
view (`OneLogPerView`), commits backed by quorums (`CommitsBacked`), and
survival of committed entries into every later view (`Survives`), plus
the clauses the induction needs. `proof/preservation.md` says which
clauses had to be added and why; the paper's appendix on the mechanised
proof has the full table.

Every clause has a `Bool` twin in `Vsr/Check.lean`, and `vsr-replay`
evaluates all of them after every step of a trace, printing
`violation step N name` on stderr for each that fails; the conformance
test fails on any such line. Every clause was tried this way before it
was proved.

```console
cargo run -p vsr-verify -- 7 > /tmp/t.txt
cd lean && lake exe vsr-replay /tmp/t.txt > /dev/null   # violations, if any, on stderr
```

## How preservation is proved

A step at replica `id` with old state `r` produces a new replica, a list
of messages, and possibly one started view; `System.after` is the cluster
with those applied. `StepOK` collects one obligation per clause of `Inv`,
each about the new replica, the new messages, and the new started view
only; old messages and untouched replicas transfer by monotonicity, and
`Inv.after` turns `StepOK` into `Inv` of the new cluster.

A handler is a chain of helpers, each of which may change the replica and
push to its outbox. Proofs follow the chain through the drained view
`System.drainOf s id r`: the cluster as it will be once `r`'s outbox and
started view have been handed over. `Inv.drainStep` moves from one link
to the next given a `StepOK` for the difference, and the shapes in
`Replace.lean`, `Normal.lean`, and `Kinds.lean` are the reusable links:
replacing a replica while keeping its log, installing a log, recovering,
appending an entry, committing up to a backed bound, and sending each
kind of message.

A `Committed` fact is created when the quorum-completing `PrepareOk` is
sent, not when the primary receives it, so the `Survives` obligation for
a new commit is discharged in `onPrepare`, `onNewState`, and
`onStartView`, by `Inv.viewHolds_of_newAck`. The same core lemma,
`Inv.bestHolds`, discharges the `install_log` and `commit_up_to` asserts
when a view is started, a `StartView` is adopted, or a catching-up replica
takes a `NewState`.

## How we know the model is the code

A proof about the model is worth nothing if the model drifts from
`lib.rs`. The `verify/` crate checks that, by differential testing:

1. **A trace** is a list of cluster steps in a small text format: which
   message in `sent` to deliver, which replica gets an idle period, a
   client request arriving at a replica, or a replica recovering from a
   crash. `vsr-verify` generates one per seed with a fixed generator:
   deliveries favour recent messages so the cluster makes progress, any
   message can be replayed at any time, clients only send a new request
   once the previous one was answered, and recoveries are rare.
2. **Both sides replay it.** The Rust side runs real `Replica`s through the
   steps. The Lean side is `lake exe vsr-replay TRACE`, which runs the
   model. Neither side parses messages: both keep their own `sent` list in
   the same order, and a step names a message by its index.
3. **Both sides print the same things after every step**, in the same
   format: each replica's status, view number, commit number, log, and
   applied ops, plus every message and reply sent in that step. The model
   also prints `panicked` if a Rust `assert!` would have fired.
4. **The test diffs the two outputs** and fails on the first differing
   line, naming the seed, the step, and both lines.

```console
cargo test -p vsr-verify                    # 40 seeds, 200 steps each, 3 and 5 replicas
cargo run -p vsr-verify -- 7                # the trace for seed 7
cargo run -p vsr-verify -- 7 --observe      # what the Rust replicas print on it
```

What the traces reach: view changes up to view 5, state transfer, recovery
with a primary's state, and commits. What the check sees: everything
observable, which is the state above and every message. What it does not
see directly: private state such as the acknowledgement table, the client
table, and timers. A divergence there shows up only when it changes what
is sent, which it eventually does.

Evidence that the check has teeth: making the model skip commits on
`Commit` messages is caught at step 29 of seed 0; making the Rust backup
append a `Prepare` with a gap before it is caught at step 36 of seed 0.
Removing a check that the next line makes redundant is not caught, and
should not be: the behaviour did not change.

The limit of the method: it is testing, not proof. A divergence on a
sequence no generated trace reaches stays invisible. The two ways to close
that gap are a verified translation of the Rust or a proof of the Rust
itself.

## Building

```console
lake exe cache get   # Mathlib's prebuilt files, once
lake build
```

Mathlib is used for the finite-set counting in `Vsr/Preserve/Durable.lean`.

## Conventions that made the proofs go through

- The theorem about a handler is `Inv.<handler>` (and `LocalInv.<handler>`,
  `OutboxWF.<handler>` for the lower layers). Unfold with
  `unfold Replica.<handler>`.
- Handlers use `let` and `have` bindings, which `split` cannot see through.
  `simp only` reduces them first; `try simp only` where there may be none.
- A `let (a, b) := f x` in a handler becomes a `match`. Prove the facts you
  need about `f x`, then `generalize f x = p at *` and `obtain ⟨a, b⟩ := p`.
- Frame lemmas are `@[simp]`. Structure updates such as `{ r with acks := a }`
  need no lemmas: `simp` reduces their projections.
- `omega` does not see arithmetic on the `Nat` abbreviations
  (`CommitNumber`, `ViewNumber`, `OpNumber`); use the `Nat.*` lemmas, or
  `generalize` the term to a plain `Nat` first.
- Mathlib reserves `to`; name a destination `dst`.
- A structure literal's fields must not continue on a line indented less
  than the opening brace.
- Any change to a handler must keep `cargo test -p vsr-verify` green; that
  test is what says the model still is the code.
