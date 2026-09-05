# The safety properties and the invariant

The properties are those of `simulator/properties.rs`, stated over
reachable cluster states in `lean/Vsr/Safety.lean`. The invariant is `Inv`
in `lean/Vsr/Invariant.lean`, on top of the two layers already proved in
`lean/Vsr/Local.lean` and `lean/Vsr/WellFormed.lean`. Notation is that of
[`model.md`](model.md).

## The properties

For a cluster state $\Sigma$ with replicas $r$:

**NoPanic** (`NoPanic`). No replica has $\mathrm{panicked}_r$.

**CommitBounded** (`CommitBounded`). $k_r \le n_r$ for every $r$.

**PrefixAgreement** (`PrefixAgreement`). For all replicas $a, b$ and every
index $i$: if $i < k_a$ and $i < k_b$ then $L_a[i] = L_b[i]$.

**Durability** (`Durability`). Let $\mathit{voters}$ be the replicas with
$\mathrm{status} \ne \mathsf{recovering}$. For every $r \in \mathit{voters}$
and $i < k_r$:

$$
|\mathit{voters}| + 1 - Q \;\le\; |\{\, o \in \mathit{voters} : L_o[i] = L_r[i] \,\}| .
$$

That is, every quorum the non-recovering replicas could form contains a
replica holding the committed entry at its index. With nobody recovering
this is a majority. A recovering replica holds nothing and votes for
nothing, so it counts on neither side.

The main theorem (`Vsr.safety`) is that all four hold in every reachable
state. `CommitBounded` is proved. The rest follow from `Inv` below, and
`PrefixAgreement` from `Inv` is proved (`Inv.prefixAgreement`); what is
open is that every step preserves `Inv`.

## Layer one: the local invariant

**LocalInv** (`Replica.LocalInv`), for every replica $r$:

1. $k_r \le n_r$.
2. $\ell_r \le v_r$.
3. $\mathrm{status}_r \in \{\mathsf{normal}, \mathsf{transfer}\} \implies \ell_r = v_r$.
4. $\mathrm{catching}_r \implies \mathrm{status}_r = \mathsf{viewchange}$.
5. $\mathrm{status}_r = \mathsf{recovering} \implies L_r = \varepsilon \wedge k_r = 0$.

Proved: every handler, idle step, and recovery preserves it with no
assumption about the message received (`LocalInv.onMessage`,
`LocalInv.onIdle`, `LocalInv.recover`). Lifted to the cluster as
**AllLocal** (`AllLocal`).

## Layer two: well-formed messages

**WF** (`WF`), on a message:

- $\mathsf{Prepare}(v, n, e, k)$: $n > 0$.
- $\mathsf{NewState}(v, L, a, b, k)$: $|L| = b - a$, $a \le b$, $k \le b$.
- $\mathsf{DoViewChange}(v, i, \ell, L, n, k)$: $|L| = n$, $k \le n$, $\ell \le v$.
- $\mathsf{StartView}(v, L, n, k)$: $|L| = n$, $k \le n$.
- $\mathsf{RecoveryResponse}(v, x, i, (L, k))$: $k \le |L|$.
- everything else: true.

**SentWF** (`SentWF`): every $(\mathit{to}, m) \in \mathit{sent}$ has
$\mathrm{WF}(m)$. Proved (`sentWF_of_reachable`).

## The vocabulary of layers three to five

Everything below is stated through $\mathit{sent}$ and $\mathit{started}$,
which only grow, so a fact of this form, once true, stays true. Replica
logs are not like that, a view change replaces them, so they appear in
antecedents, and in `OneLogPerView`, which ties them to the history.

**Sent** (`Sent`). $\mathrm{Sent}(\mathit{to}, m) \iff (\mathit{to}, m) \in \mathit{sent}$.

**Frag** (`Frag`). $\mathrm{Frag}(v, \mathit{off}, L)$: the history holds
$L$ as a piece of view $v$'s log starting at index $\mathit{off}$. The
rules, one per kind of message that carries log:

$$
\begin{array}{ll}
\mathrm{Sent}(\_, \mathsf{Prepare}(v, n, e, \_)) & \implies \mathrm{Frag}(v, n - 1, [e]) \\
\mathrm{Sent}(\_, \mathsf{NewState}(v, L, a, \_, \_)) & \implies \mathrm{Frag}(v, a, L) \\
\mathrm{Sent}(\_, \mathsf{StartView}(v, L, \_, \_)) & \implies \mathrm{Frag}(v, 0, L) \\
\mathrm{Sent}(\_, \mathsf{DoViewChange}(\_, \_, \ell, L, \_, \_)) & \implies \mathrm{Frag}(\ell, 0, L) \\
\mathrm{Sent}(\_, \mathsf{RecoveryResponse}(v, \_, \_, (L, \_))) & \implies \mathrm{Frag}(v, 0, L) \\
(\_, V) \in \mathit{started},\ (\_, (\ell, L, \_)) \in V & \implies \mathrm{Frag}(\ell, 0, L)
\end{array}
$$

A vote is a fragment of the view the voter was *last normal in*, not of
the view it votes for. That is the decision that makes a replica catching
up, whose view number is ahead of its log, consistent with everything
else.

**Holds** (`Holds`). $\mathrm{Holds}(v, i, e)$: some fragment of $v$ has
$e$ at index $i$:

$$
\exists\, \mathit{off}, L.\ \mathrm{Frag}(v, \mathit{off}, L) \wedge \mathit{off} \le i \wedge L[i - \mathit{off}] = e .
$$

**Acked** (`Acked`). $\mathrm{Acked}(v, i, q)$: replica $q$ acknowledged
index $i$ in view $v$. The primary acknowledges its own ops without a
message:

$$
q = \mathrm{primary}(v) \;\vee\; \exists\, o > i.\ \mathrm{Sent}(\_, \mathsf{PrepareOk}(v, o, q)) .
$$

**QuorumAcked** (`QuorumAcked`). $\mathrm{QuorumAcked}(v, i)$: there is a
set $\mathcal{Q}$ of at least $Q$ distinct replica ids below $N$, each with
$\mathrm{Acked}(v, i, q)$.

**Committed** (`Committed`).
$\mathrm{Committed}(v, i, e) \iff \mathrm{Holds}(v, i, e) \wedge \mathrm{QuorumAcked}(v, i)$.

**Backed** (`Backed`). A commit number $k$ in view $v$ is backed when every
index below it was committed in a view no later than $v$ with the entry $v$
holds there:

$$
\mathrm{Backed}(v, k) \iff \forall i < k.\ \exists\, e, v' \le v.\ \mathrm{Committed}(v', i, e) \wedge \mathrm{Holds}(v, i, e) .
$$

**MsgBacked** (`MsgBacked`). The commit number a message carries is backed
in its view; a vote is judged by its last normal view:

$$
\begin{array}{ll}
\mathsf{Prepare}(v, \_, \_, k),\ \mathsf{Commit}(v, k),\ \mathsf{NewState}(v, \_, \_, \_, k),\ \mathsf{StartView}(v, \_, \_, k) & : \mathrm{Backed}(v, k) \\
\mathsf{DoViewChange}(\_, \_, \ell, \_, \_, k) & : \mathrm{Backed}(\ell, k) \\
\mathsf{RecoveryResponse}(v, \_, \_, (\_, k)) & : \mathrm{Backed}(v, k) \\
\text{else} & : \text{true}
\end{array}
$$

## The invariant, `Inv`

`Inv` is the conjunction of everything below. The three named layers are
the ones that carry the argument; the rest are what the induction needs to
go through.

### Layer three: one log per view

**OneLogPerView** (`OneLogPerView`).

1. $\mathrm{Holds}(v, i, e) \wedge \mathrm{Holds}(v, i, e') \implies e = e'$.
2. For every replica $r$: $L_r[i] = e \wedge \mathrm{Holds}(\ell_r, i, e') \implies e = e'$.

The fragments of a view agree with one another, and every replica's log
agrees with the fragments of its last normal view. This is what makes "the
entry at index $i$ in view $v$" mean one thing. See
[`one-log-per-view.md`](one-log-per-view.md).

### Layer four: commits are backed

**CommitsBacked** (`CommitsBacked`).

1. For every replica $r$: $\mathrm{Backed}(\ell_r, k_r)$.
2. For every $(\mathit{to}, m) \in \mathit{sent}$: $\mathrm{MsgBacked}(m)$.

### Layer five: committed entries survive

**Survives** (`Survives`). If $\mathrm{Committed}(v', i, e)$ then for every
$v > v'$:

1. $\mathrm{Sent}(\_, \mathsf{StartView}(v, L, \_, \_)) \implies L[i] = e$.
2. $\mathrm{Sent}(\_, \mathsf{DoViewChange}(\_, \_, v, L, \_, \_)) \implies L[i] = e$.
3. $\mathrm{Sent}(\_, \mathsf{RecoveryResponse}(v, \_, \_, (L, \_))) \implies L[i] = e$.
4. $\mathrm{Sent}(\_, \mathsf{NewState}(v, L, a, \_, \_)) \wedge a \le i \implies L[i - a] = e$.
5. $\mathrm{Sent}(\_, \mathsf{Prepare}(v, i + 1, e', \_)) \implies e' = e$.
6. $(\_, V) \in \mathit{started},\ (\_, (v, L, \_)) \in V \implies L[i] = e$.
7. For every replica $r$ with $\ell_r = v$ and
   $\mathrm{status}_r \ne \mathsf{recovering}$: $L_r[i] = e$.

Whatever was committed in a view is held, at its index, by every whole log
of every later view, every segment of a later view that reaches it, and
every replica last normal in a later view that has not lost its memory.

### The helpers

**Ids** (`Ids`). Replica $i$ of the cluster has $\mathrm{id} = i$ and the
cluster's configuration.

**Drained** (`Drained`), **Clean** (`Clean`). Between steps every replica's
outbox and replies are empty and it has no unrecorded started view. These
say the model's bookkeeping is done; they carry no protocol content.

**TwoReplicas** (`TwoReplicas`). $N \ge 2$. A cluster of one never sends,
so nothing about it can be said through $\mathit{sent}$.

**AcksCurrent** (`AcksCurrent`). A normal primary's $A_r$ records only
acknowledgements of its own ops in its own view: every $n \in \mathrm{dom}\, A_r$
has $n \le n_r$, and every $q \in A_r[n]$ is $\mathrm{id}_r$ or has
$\mathrm{Sent}(\_, \mathsf{PrepareOk}(v_r, n, q))$.

**CatchingUpNotPrimary** (`CatchingUpNotPrimary`). If $\mathrm{catching}_r$
then $\mathrm{id}_r \ne \mathrm{primary}(v_r)$.

**AcksHold** (`AcksHold`). What an acknowledgement says stays true. If
$\mathrm{Sent}(\_, \mathsf{PrepareOk}(v, o, q))$ and $r$ is replica $q$:
$v \le \ell_r$, and if $\ell_r = v$ and $\mathrm{status}_r \ne \mathsf{recovering}$
then $o \le n_r$.

**PrimaryToOthers** (`PrimaryToOthers`). No $\mathsf{Prepare}(v, \dots)$ or
$\mathsf{Commit}(v, \dots)$ was sent to $\mathrm{primary}(v)$.

**PrimaryLongest** (`PrimaryLongest`). For a replica $p$ with
$\mathrm{status}_p = \mathsf{normal}$ and $\mathrm{isPrimary}(p)$:

1. $\mathrm{Frag}(v_p, \mathit{off}, L) \implies \mathit{off} + |L| \le n_p$.
2. Every replica $q$ with $\ell_q = v_p$ and $\mathrm{status}_q \ne \mathsf{recovering}$ has $n_q \le n_p$.
3. $\mathrm{Sent}(\_, \mathsf{PrepareOk}(v_p, o, \_)) \implies o \le n_p$.

The primary of a view, while normal in it, holds the longest log of the
view.

**Covered** (`Covered`). For every replica $r$ and $i < n_r$ there is $e$
with $\mathrm{Holds}(\ell_r, i, e)$. Nothing is in a log that was not sent.

**ReplicasAgree** (`ReplicasAgree`). Two replicas with the same $\ell$
agree wherever their logs overlap.

**StartedViews** (`StartedViews`).

1. $(v, \_) \in \mathit{started} \implies \mathrm{Sent}(\_, \mathsf{StartView}(v, \_, \_, \_))$.
2. $\mathrm{Frag}(v, \_, \_) \wedge v > 0 \implies (v, \_) \in \mathit{started}$.
3. For every replica $r$ with $\mathrm{status}_r \ne \mathsf{recovering}$ and
   $\ell_r > 0$: $(\ell_r, \_) \in \mathit{started}$.

**StartViewChosen** (`StartViewChosen`). If
$\mathrm{Sent}(\_, \mathsf{StartView}(v, L, \_, \_))$ then there are
$(v, V) \in \mathit{started}$ with $|V| \ge Q$, distinct voters, and
$\mathit{best}$ = the best vote of $V$, such that $\mathit{best}.L \sqsubseteq L$.

**StartedVotesCover** (`StartedVotesCover`). If $(v, V) \in \mathit{started}$
and $(q, (\ell, L, \_)) \in V$ then
$\mathrm{Sent}(\_, \mathsf{PrepareOk}(\ell, o, q)) \implies o \le |L|$.
Every vote a view was started from covers every op its voter acknowledged
in the view the vote is from. This is the clause the truncation defect
would break.

**MessagesBelowView** (`MessagesBelowView`). A message that names its
sender carries a view no higher than the sender's current view: for
$\mathsf{PrepareOk}(v, \_, q)$, $\mathsf{GetState}(q, v, \_)$,
$\mathsf{StartViewChange}(v, q)$, $\mathsf{DoViewChange}(v, q, \dots)$,
$\mathsf{Recovery}(q, \_, v)$, $\mathsf{RecoveryResponse}(v, \_, q, \_)$ in
$\mathit{sent}$, replica $q$ has $v \le v_q$. This is the clause the
persisted view number exists for: it is false under diskless recovery.

**RecoveryCoversAcks** (`RecoveryCoversAcks`). For a replica $q$ with
$\mathrm{status}_q = \mathsf{recovering}$, every
$\mathsf{RecoveryResponse}(v, x_q, \_, (L, \_))$ in $\mathit{sent}$
answering its nonce covers every op it acknowledged in $v$:
$\mathrm{Sent}(\_, \mathsf{PrepareOk}(v, o, \mathrm{id}_q)) \implies o \le |L|$.

## What `Inv` gives

Proved in Lean, restated here because the hand proof will use the same
two lemmas:

**Committed entries are what the view holds** (`Inv.committed_entry`).
For a replica $r$ and $i < k_r$ there are $e$ and $v' \le \ell_r$ with
$L_r[i] = e$, $\mathrm{Committed}(v', i, e)$, and $\mathrm{Holds}(\ell_r, i, e)$.
From `CommitsBacked` (1) and `OneLogPerView` (2).

**Later views hold what earlier views committed** (`Inv.survives_holds`).
If $\mathrm{Committed}(v', i, e)$, $v' < v$, and $\mathrm{Holds}(v, i, e')$
then $e' = e$. By cases on the fragment, from `Survives`.

**Prefix agreement** (`Inv.prefixAgreement`). Take $a, b$ with
$i < k_a, k_b$. By the first lemma, $L_a[i] = e_a$ committed in some
$v_a$ and held by $\ell_a$; likewise $e_b$, $v_b$, $\ell_b$. If $v_a < v_b$,
the second lemma with $\mathrm{Holds}(v_b, i, e_b)$ gives $e_b = e_a$;
symmetrically if $v_b < v_a$; if equal, `OneLogPerView` (1).
