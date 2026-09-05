# The safety proof of vsr-rs, by hand

A proof on paper that the replica in `lib.rs` is safe, written against the
model of it in [`lean/`](../lean). The Lean files are the definition of the
model and, where they exist, the machine-checked proofs. What is here is the
argument: the invariant, why it is the right one, and why every step of the
cluster preserves it, in a form a reader can check without a proof
assistant. The two are kept in step by name: every definition and clause
below is called what the Lean calls it, so a gap between the two is a
finding.

The subject is the model, not `lib.rs` directly. [`verify/`](../verify)
replays seeded traces on both and diffs what they do, and that is the bridge
from the model to the code.

## Files

| File | What it is |
|---|---|
| [`model.md`](model.md) | The model in mathematical notation: state, messages, one rule per handler, the cluster step. Each rule names the Lean definition it renders. |
| [`invariant.md`](invariant.md) | The safety properties and the inductive invariant, clause by clause, with what each clause is for. |
| [`one-log-per-view.md`](one-log-per-view.md) | The first clause to prove: every fragment of a view's log is a prefix of one sequence. |

One file per clause follows, in the order they are proved.

## Conventions

- Logs are 0-indexed sequences. $L[i]$ is the entry at index $i$, for
  $0 \le i < |L|$. The op number of that entry is $i + 1$. A commit number
  $k$ means the entries at indices $0, \dots, k-1$ are committed. This is
  how the Lean lists work, and it keeps the two proofs from disagreeing by
  one.
- $L[a{:}b]$ is the subsequence at indices $a, \dots, b-1$; $L[a{:}]$ runs
  to the end. $L \cdot e$ appends $e$. $L \sqsubseteq L'$ says $L$ is a
  prefix of $L'$.
- Code is cited by function name, never by line.
- The Lean name of everything is given in `monospace` the first time it
  appears.

## What the proof is about

A cluster state is the replicas plus every message ever sent. Delivery
never removes a message, so a message can arrive late, twice, or never,
and a replica that is never stepped is a crashed one. The invariant is
mostly about that message history rather than about the replicas, because
replicas forget: a view change replaces a backup's log, but the
`PrepareOk` it sent stays in the history.

The proof is an induction over reachable states: the invariant holds
initially, every step preserves it, and it implies the safety properties.
The last part is short and is already checked in Lean
(`Vsr.Inv.prefixAgreement`). Preservation is the work, and it is done one
handler at a time against one clause at a time.

## Status

| Clause | Hand proof | Lean |
|---|---|---|
| `LocalInv` (layer one) | not written | proved, `Vsr/Local.lean` |
| `WF` on every sent message (layer two) | not written | proved, `Vsr/WellFormed.lean` |
| `OneLogPerView` | statement and case table, no proofs | stated |
| everything else in `Inv` | not started | stated; `Inv.init`, `Inv.prefixAgreement`, `Inv.onGetState` proved |
