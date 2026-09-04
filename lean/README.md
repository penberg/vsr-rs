# The Lean model of vsr-rs

A model of the replica in Lean 4, a model of the cluster around it, the
safety properties stated over every reachable cluster state, and the
proofs so far. The model is kept honest by `verify/`, which replays seeded
traces on the real replicas and on this model and diffs what they do.

## Files

| File | What it is |
|---|---|
| `Vsr/Types.lean` | Ids, `Config`, `LogEntry`, `Reply`, `Message`, `Status`, the abstract `Machine`, and the sorted association lists that stand in for the Rust `BTreeMap`s. |
| `Vsr/Replica.lean` | The replica: one definition per Rust function in `lib.rs`, same control flow. Sends go to `outbox`, replies to `replies`. A Rust `assert!` sets `panicked` instead of stopping, so every handler is total. |
| `Vsr/System.lean` | The cluster: replicas by id, and `sent`, the list of every message ever sent, which delivery never shrinks. One rule covers loss, delay, replay, and reordering. Steps: `deliver`, `idle`, `request`, `recover`. |
| `Vsr/Frame.lean` | Frame lemmas: what each helper leaves alone, as `@[simp]` lemmas, so a goal about a handler stays a goal about a few fields. |
| `Vsr/Local.lean` | The per-replica invariant `LocalInv` and the proof that every handler preserves it. |
| `Vsr/WellFormed.lean` | The well-formedness predicate `WF` on messages and the proof that every handler only sends well-formed messages. |
| `Vsr/Invariant.lean` | Layers three to five stated as one invariant, `Inv`, with the ghost history of started views, monotonicity of everything stated through `sent`, the initial state, and the proof that `Inv` implies prefix agreement. Preservation is the open work. |
| `Vsr/Preserve.lean` | Preservation of `Inv`, one handler at a time: the step skeleton, and `onGetState`. |
| `Vsr/Liveness.lean` | A synchronous scheduler, the liveness property `settles`, and the storm counterexample: theorems, proved by running the model in the kernel, that a reachable state never settles. |
| `Vsr/Check.lean` | Executable (`Bool`) versions of every invariant, proved or candidate, and of bounded liveness, which `vsr-replay` evaluates after every step. |
| `Vsr/Safety.lean` | `Reachable`, the four safety properties, the lifts of the replica-level invariants to the system, and the main theorem. |
| `Main.lean` | `vsr-replay`: runs a trace on the model and prints the observable state after each step, in the format `verify/` compares against. |

## Status

| Property | Statement | Theorem | Status |
|---|---|---|---|
| Commit bounded | Every replica's commit number is at most its log length, in every reachable state. | `Vsr.commitBounded_of_reachable` | **Proved.** Axioms: `propext`, `Quot.sound`. |
| Local invariant | The per-replica facts below hold initially and after every handler, idle period, and recovery. | `Vsr.Replica.LocalInv.onMessage`, `.onIdle`, `.recover`, `.new`; lifted by `Vsr.AllLocal.step` | **Proved.** |
| Well-formed messages | Every message ever sent is well formed: `NewState`, `DoViewChange`, and `StartView` log lengths match the op numbers they carry, commit numbers do not exceed them, a `DoViewChange` vote's last normal view is not ahead of its view, and a recovery state's commit number is within its log. | `Vsr.sentWF_of_reachable`, from `Vsr.Replica.OutboxWF.onMessage`, `.onIdle`, `.recover` | **Proved.** Axioms: `propext`, `Quot.sound`. |
| No panic | No Rust `assert!` fires in any reachable state. | `Vsr.safety` | `sorry`. Needs layer 5. |
| Prefix agreement | Two replicas that both committed index `i` hold the same entry there. | `Vsr.safety` | `sorry`. **Follows from `Inv`**: `Vsr.Inv.prefixAgreement` is proved. What is missing is that every step preserves `Inv`. |
| Durability | Every committed entry is held at its index by enough non-recovering replicas to meet every quorum they could form. | `Vsr.safety` | `sorry`. Needs layers 4 and 5. |
| Liveness | On a synchronous network, from any reachable state with a quorum not recovering, the cluster settles: all normal, same view, nothing in flight. | `Vsr.settles` | `sorry`. Proved for the regression scenario by `Vsr.Storm.storm_settles`; tested by `Check.liveness` on every trace state. Refuted the view-change storm before its fix; see below. |

The local invariant, `Vsr.Replica.LocalInv`, is:

| Fact | In the Rust |
|---|---|
| `commitNumber ≤ log.length` | `commit_up_to` indexes `log[commit_number]`. |
| `lastNormalView ≤ viewNumber` | Views only move forward. |
| Normal status or state transfer implies `lastNormalView = viewNumber` | `enter_normal` sets it; state transfer stays in the view. |
| Catching up implies view-change status | `catch_up_with_view` sets both. |
| Recovering implies empty log and commit number zero | `Replica::recover` starts fresh. |

Supporting lemmas, all proved: `Vsr.Replica.commitUpTo_commit_le`
(committing never runs past the log), `installLog_commit_le` (a log
shorter than the commit number is refused), `commitUpTo_mono'` (commit
numbers only go up), and the frame lemmas in `Vsr/Frame.lean`.

Check any of these yourself:

```console
lake env lean /dev/stdin <<'EOF2'
import Vsr
#print axioms Vsr.commitBounded_of_reachable
#print axioms Vsr.sentWF_of_reachable
#print axioms Vsr.safety
EOF2
```

The first two print `[propext, Quot.sound]`. The third includes `sorryAx`,
which is how Lean marks a theorem that rests on an unwritten proof.

### The combined invariant

`Vsr/Invariant.lean` states layers three to five as one structure, `Inv`,
because they are one induction. Working the hardest case through on
paper, a `PrepareOk` that completes a quorum, showed that the three
layers alone are not inductive: the argument needs to know that a
replica's acknowledgement was sent before its vote for a later view, that
the primary's log covers everything it has sent in its view, and which
votes a view's log was chosen from. None of that is in the state, so
`Inv` carries fifteen helper clauses, each with a `Bool` twin in `Vsr/Check.lean`
that holds on every trace: `Ids`, `AcksCurrent`, `CatchingUpNotPrimary`,
`AcksHold`, `PrimaryToOthers`, `PrimaryLongest`, `StartViewChosen`,
`StartedVotesCover`, `MessagesBelowView`, `RecoveryCoversAcks`, `Covered`,
`ReplicasAgree`, `StartedViews`, `Clean`, and `TwoReplicas`. The last five
came from proving the first handler: every entry a replica holds must be
covered by some message of its view, two replicas last normal in the same
view must agree, every view above zero that anything refers to must have
been started, and a cluster of one replica never sends anything, so the
invariant is for clusters of at least two.

One of them needed a history variable. The primary's own vote never
appears in `sent`, so when its own log is the one a view starts from,
nothing persistent records what was chosen. The model now has a ghost
field, `System.started`, the votes every started view was chosen from,
filled by the system step from a ghost field on the replica. It is not in
the Rust and not observable, so the conformance test is unaffected; it
exists so that a proof can point at it.

### Preservation

`Vsr/Preserve.lean` proves `Inv` preserved by the steps, one handler at a
time. Two lemmas give the shape: `System.drain_clean`, a replica that
changed nothing and sent nothing leaves the cluster as it was, and
`System.drain_send`, a replica that changed nothing and sent one message
leaves the cluster with one more message. On those, `Inv.addNewState`
proves that a `NewState` cut from a normal replica's log keeps every
clause, and `Inv.onGetState` is the handler. Its axioms are `propext`
only.

Every handler proof has the same skeleton: old facts survive by
monotonicity of everything stated through `sent` and `started`; the new
message, and the new replica state, must satisfy their clauses; and a new
`Committed` fact, which only a `PrepareOk` can create, must already be
held by every later view. The last is the quorum-intersection argument
and arrives with `onPrepareOk`.

## Liveness

The safety properties say nothing about progress; a cluster that changes
view forever satisfies all of them. `Vsr/Liveness.lean` adds what a
liveness statement needs, time: a synchronous scheduler, `Sync.round`,
in which every replica gets an idle period and then everything in flight
is delivered, with what those deliveries send in flight for the next
round. It is the simulator's order within a tick and the order of `step`
in `tests/cluster.rs`. The property, `settles`, is that from any reachable
state with a quorum of replicas not recovering, and whatever was in flight
lost, the cluster reaches a round in which every replica is normal in the
same view and nothing is in flight.

`Storm.storm` is the state the regression test
`test_view_change_does_not_start_the_next` builds: three replicas, a
primary timeout of two idle periods, one op committed, and replica 2's
timer starting a view change. Three theorems about it are proved by
having the kernel run the model, about 70 seconds per build:

| Theorem | Says |
|---|---|
| `Storm.storm_settles` | A round among the first eight is settled. |
| `Storm.storm_settled_in_view_3` | After eight rounds every replica is normal in view 3 with its backoff decayed to zero. |
| `Storm.storm_stays_settled` | Round 30 is settled too. |

They depend on no axiom but `propext`.

This is the statement that caught the view-change storm. Before the fix,
the same three theorems said the opposite, and Lean proved that instead:
no settled round among 500, view 251 after 500 rounds, which is what the
Rust test printed, and a run periodic in everything but the view number.
The defect was that `enter_normal` reset the view-change backoff, so the
replica that had just completed a view joined the next view change with
the shortest wait and timed out one round before that view's `StartView`
reached it, round the ring, forever. The fix keeps the backoff across
`enter_normal` and forgets it only after a primary timeout of stable idle
periods.

`Check.liveness` is the bounded version, run after every step of a
conformance trace with `livenessBound` rounds. Before the fix it fired on
27 of the 40 traces; it fires on none now, and the Rust conformance test
fails on any it reports. A liveness bug in a handler now shows up there
before the simulator has to find it.

## The plan for the rest

The three `sorry` properties need an inductive invariant over the whole
system, proved in layers:

| Layer | Invariant | Status |
|---|---|---|
| 1 | Local facts per replica, above. | Done. |
| 2 | Every message in `sent` is well formed: log lengths match the op numbers carried, commit numbers do not exceed them, `NewState` lengths match its range. | Done: `Vsr/WellFormed.lean`. |
| 3 | One log per view: every `Prepare`, `StartView`, and `NewState` of view `v`, and the log of every replica whose last normal view is `v`, are prefixes of one another. | Stated as `OneLogPerView` in `Vsr/Invariant.lean`; check `one_log_per_view` holds on every trace. |
| 4 | Committed means acknowledged: a committed index has a quorum of `PrepareOk` messages in `sent` behind it, in some view whose log holds that entry. `sent` is never pruned, so it is the history. | Stated as `CommitsBacked`, for replicas and for every commit number a message carries; checks hold. |
| 5 | Committed entries cross view changes and recovery: any log whose last normal view is above `v` holds everything a quorum acknowledged in `v`. Quorum intersection; this is where Mathlib comes in. | Stated as `Survives`; check holds. `Inv.init` and `Inv.prefixAgreement` are proved. **Preservation of `Inv` is under way in `Vsr/Preserve.lean`**: the step skeleton and `Inv.onGetState` are proved; `onPrepare` and `onCommit` are next, then `onRequest`, then `onPrepareOk`, the view-change handlers, and recovery. |
| 6 | Liveness on the synchronous scheduler, `settles`. Needs layer 5 and a ranking argument on the backoff. | Stated, tested on every trace state, proved for one scenario. Proof waits for layer 5. |

The `assert!` in `install_log`, that an incoming log is at least as long
as the commit number, holds only because of layer 5, so no-panic finishes
there, not at layer 2.

### Testing an invariant before proving it

Every invariant, proved or candidate, also exists as a `Bool` check in
`Vsr/Check.lean`. `vsr-replay` evaluates all of them after every step of a
trace and prints `violation step N name` on stderr for each that fails; the
conformance test fails on any such line. A wrong candidate fails in seconds
this way instead of days into a proof. The three candidate layers have held
on 240 seeds of 200 to 300 steps, on 3 and 5 replicas, which says they are
worth proving, not that they are true.

```console
cargo run -p vsr-verify -- 7 > /tmp/t.txt
cd lean && lake exe vsr-replay /tmp/t.txt > /dev/null   # violations, if any, on stderr
```

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

Mathlib is required for the proofs still to come and is not yet imported
by any module.

## Conventions that made the proofs go through

- The theorem about a handler is `LocalInv.<handler>`, which shadows the
  handler's name inside the proof. Unfold with `unfold Replica.<handler>`.
- Handlers use `let` and `have` bindings, which `split` cannot see through.
  `simp only` reduces them first; `try simp only` where there may be none.
- A `let (a, b) := f x` in a handler becomes a `match`. Prove the facts you
  need about `f x`, then `generalize f x = p at *` and `obtain ⟨a, b⟩ := p`.
- Frame lemmas are `@[simp]`. Structure updates such as `{ r with acks := a }`
  need no lemmas: `simp` reduces their projections.
- `omega` sometimes fails to use hypotheses about the `Nat` abbreviations
  (`CommitNumber`, `ViewNumber`); the `Nat.le_*` lemmas work.
- Any change to a handler must keep `cargo test -p vsr-verify` green; that
  test is what says the model still is the code.
