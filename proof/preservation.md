# Preservation of `Inv`: the plan and the working notes

This file is the plan for `lean/Vsr/Preserve*.lean` and the record of what
the induction turned out to need. Notation is that of `model.md` and
`invariant.md`.

## The shape of a step

A step at replica `id` with old state `r` produces a new replica `r'`, a
list `out` of messages, and possibly one started view. The new system is

    s' = { s with replicas := s.replicas.set id r', sent := s.sent ++ out,
           started := s.started ++ st }

(`System.after`). Every handler proof computes `out` and `st` for each
branch and then discharges the hypotheses of one lemma, `Inv.after`, which
takes `Inv s` and per-clause facts about `r'`, `out`, and `st` only. Old
messages and untouched replicas transfer by monotonicity.

## Clauses that had to be added

The clauses of `invariant.md` are not inductive on their own. Working the
handlers through in Lean added these (all with `Bool` twins in `Check.lean`):

- `ViewChangeBehind`: view-change status implies $\ell_r < v_r$.
- `DvcOf s u x d`: a `DoViewChange` from `x` for view `u` with body `d`,
  either in `sent` or in a started view's set. Lets one clause speak of
  both.
- `DvcBehind`: $d.\ell < u$.
- `DvcBelowView`: $u \le v_x$ for the current replica `x`.
- `DvcAfterAcks`: if `x` acknowledged in $v' < u$ then $v' \le d.\ell$.
  Without it the intersecting replica's DoViewChange could be from before
  its acknowledgement, which time forbids but the state did not.
- `DvcAfterOwnView`: if `x` is the primary of a started view $v' < u$
  then $v' \le d.\ell$. Same reason, for the primary's implicit
  acknowledgement.
- `DvcCoversAcks`: replaces `StartedDoViewChangesCover`, now for sent
  DoViewChanges too, so a recorded one inherits it.
- `DvcPrimaryCovers`: a DoViewChange from the primary of its own $\ell$
  covers every fragment of $\ell$. The primary acknowledges without a
  message, so `DvcCoversAcks` says nothing about it.
- `PrimaryLongest` generalised: from "normal primary of its view" to "not
  recovering and primary of its last normal view". The primary's log in
  its view never shrinks, even after it moves to a view change, and the
  durability proof needs the primary's implicit acknowledgement to be
  backed by its log then too.
- `PrimaryStartedNormal`: the primary of a started view has
  $\ell \ge$ that view.
- `StartedOnce`: a view is started at most once.
- `ViewExtendsBase`: every whole log of view $v$ (DoViewChange, recovery
  state, replica) is at least as long as the log $v$ was started from, and
  every `NewState` of $v$ ends at or past it. This is what makes a
  `NewState` reach every committed index, which the catching-up replica
  needs, and what bounds the `install_log` assert.
- `RecoveryResponseNonce`: every `RecoveryResponse` answers a `Recovery`
  with the same nonce. With nonce freshness (an assumption on the
  environment, in `Reachable`) it makes `RecoveryCoversAcks` hold for a
  freshly recovering replica.

## Where the quorum argument lives

A `Committed` fact is created when the quorum-completing `PrepareOk` is
*sent*, not when the primary receives it. So `Survives` for a new
`Committed(v, i, e)` is proved in `onPrepare`, `onNewState`, and
`onStartView`, by strong induction on the later view $u > v$: the started
set of $u$ intersects the acknowledging quorum in some `x`, whose
DoViewChange is from $d.\ell \ge v$ (`DvcAfterAcks`, `DvcAfterOwnView`);
if $d.\ell = v$ it covers the acknowledgement (`DvcCoversAcks`,
`DvcPrimaryCovers`), if $v < d.\ell < u$ the induction hypothesis applies
to it as a whole log of $d.\ell$. The best DoViewChange is at least as
good, so it holds $e$ at $i$; every `StartView` of $u$ extends it
(`StartViewChosen`, `StartedOnce`), and everything else of $u$ agrees with
that and is long enough (`OneLogPerView`, `ViewExtendsBase`).

The same core lemma, `Inv.bestHolds`, gives the `install_log` and
`commit_up_to` asserts in `recordDoViewChange` and the `install_log` assert
in `onStartView` and `onNewState`.

## Status

Done. Every handler is proved (`Inv.onRequest`, `onPrepare`, `onPrepareOk`,
`onCommit`, `onGetState`, `onNewState`, `onStartViewChange`,
`onDoViewChange`, `onStartView`, `onRecovery`, `onRecoveryResponse`,
`onIdle`, `recover`), assembled by `Inv.onMessage` and `Inv.step` into
`inv_of_reachable` and `safety` in `lean/Vsr/Preserve/Step.lean`. Beyond
the clauses listed above, closing the last handlers added `AcksStarted`
(an acknowledgement in a view above zero means the view was started),
`StartViewChangePos`, `TransferNotPrimary`, `RecoveryStateFromPrimary`,
`RecoveryResponseNotSelf`, `ReplicaCount`, `SenderIds`, `StartedIds`,
`RecordedDvcs`, and `RecordedRRs` (what a replica has recorded was sent to
it), all with `Bool` twins that hold on every trace. `AcksCurrent` now also
says the acknowledgers are distinct replicas, which the counting in
`Inv.durability` needs. The final theorem assumes at least two replicas
and, for each recover step, a fresh nonce.
