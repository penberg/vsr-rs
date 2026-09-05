# One log per view

The first clause. Notation is that of [`model.md`](model.md), the
definitions those of [`invariant.md`](invariant.md).

## Statement

**OneLogPerView** (`OneLogPerView`).

1. $\mathrm{Holds}(v, i, e) \wedge \mathrm{Holds}(v, i, e') \implies e = e'$.
2. For every replica $r$: $L_r[i] = e \wedge \mathrm{Holds}(\ell_r, i, e') \implies e = e'$.

## Why it is first

It is what every later clause quantifies over. `Committed`, `Backed`, and
`Survives` all speak of *the* entry at index $i$ in view $v$; this clause
is what makes that a single entry. It needs no quorum reasoning, only that
a view has one primary, that the primary only appends while normal, and
that every other log of the view was copied from it. And it is where the
two modelling decisions that the rest depends on get tested: fragments are
tagged with the log's origin view ($\ell$), not the holder's view number,
and state transfer never truncates.

## What it depends on

From the proved layers: `LocalInv`, in particular (3), that a normal or
transferring replica has $\ell_r = v_r$; and `WF`.

From `Inv`, the clauses it cannot be proved without, to be confirmed as the
cases are written:

- `PrimaryLongest`: while the primary of $v$ is normal in $v$, every
  fragment of $v$ is within its log. The new fragment a step adds is a
  piece of the primary's log, so it agrees with the old ones because they
  are all prefixes of one sequence.
- `Covered` and `ReplicasAgree`: a replica's log is made of fragments of
  its $\ell$, so two replicas with the same $\ell$ agree.
- `MessagesBelowView`: needed so that no replica can become primary of $v$
  a second time and build a second log for $v$. This is where the persisted
  view number carries weight, in the **recover** step.
- `StartedViews` (2): a fragment of a view $v > 0$ implies $v$ was started,
  so a `StartView` for $v$ exists and everything of $v$ descends from it.

## Initial state

$\mathit{sent}$ and $\mathit{started}$ are empty, so nothing holds any
fragment and (1) is vacuous. Every log is empty, so (2) is vacuous.
(`Inv.init`, `oneLog`.)

## Preservation

One row per rule of the model. A step changes $\mathit{sent}$,
$\mathit{started}$, and one replica. For (1) the question is whether the
new fragments agree with the old ones of the same view. For (2) it is
whether the changed replica's new log agrees with the fragments of its new
$\ell$, and whether any new fragment disagrees with some unchanged replica.

| Rule | New fragments | Log or $\ell$ changed | Argument |
|---|---|---|---|
| onRequest, prepareRequest | Prepare of $v_r$ at $n_r$ | appends | *to write* |
| onPrepare | PrepareOk (none) | appends, or stateTransfer | *to write* |
| onPrepareOk | none | commit only | frame |
| onCommit | none, or GetState (none) | commit only | frame |
| onGetState | NewState of $v_r$ | none | *to write* |
| onNewState, transfer | PrepareOk (none) | appends | *to write* |
| onNewState, catching up | PrepareOk (none) | installLog, $\ell := v$ | *to write* |
| onStartViewChange, $v > v_r$ | SVC, maybe DVC vote of $\ell_r$ | none | *to write* |
| onStartViewChange, $v = v_r$ | maybe DVC vote of $\ell_r$, or StartView of $v_r$ | none | *to write* |
| onDoViewChange, recordVote completes | started, StartView of $v$ | installLog, $\ell := v$ | *to write* |
| onDoViewChange, otherwise | StartView of $v_r$, or none | none | *to write* |
| onStartView | PrepareOk (none) | installLog, $\ell := v$ | *to write* |
| onRecovery | RecoveryResponse of $v_r$, or SVC | none | *to write* |
| onRecoveryResponse | none | installLog, $\ell := v^*$ | *to write* |
| recover | Recovery (none) | log emptied, $\ell := v$ | *to write* |
| onIdle, normal primary | Commit, Prepares of $v_r$ | none | *to write* |
| onIdle, other | SVC, GetState, Recovery, or DVC vote of $\ell_r$ | none | *to write* |

The cases marked *to write* are the proof. The order to write them in is
the order that builds the lemmas: the primary's own sends first
(prepareRequest, onIdle primary, onGetState), then the copies
(onStartView, onNewState), then the votes, then recovery.

## Lemmas needed

To be filled in as the cases are written. Each gets a name here and, when
proved in Lean, the same name there.
