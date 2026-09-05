# The model

The replica and the cluster of `lean/Vsr/Replica.lean` and
`lean/Vsr/System.lean`, written as a state, a set of messages, and a
transition rule per handler. Every rule names the Lean definition it
renders. The Lean is the definition; if the two disagree, the Lean wins and
this file has a bug.

Two things are abstracted, and both only for safety, which must hold under
every schedule:

- **Timers.** The Lean counts idle periods (`idlePeriodsWaiting`,
  `viewChangeAttempts`, `idlePeriodsStable`, `heardFromPrimary`,
  `waitTimedOut`, `noteStable`) to decide when a timeout fires. Here a
  timeout is a nondeterministic choice of the environment: on an idle step
  it may or may not fire.
- **Containers.** The Lean keeps the Rust `BTreeMap`s as sorted
  association lists so that iteration order matches. Here they are finite
  maps and sets, and the one place order matters, the choice of the best
  vote, states its tie-break.

## Configuration

`Config`. A cluster of $N \ge 2$ replicas with ids $0, \dots, N-1$.

$$
f = \lfloor N/2 \rfloor, \qquad
Q = f + 1, \qquad
\mathrm{primary}(v) = v \bmod N .
$$

$Q$ is `Config.quorum`, $\mathrm{primary}$ is `Config.primaryId`. The
threshold $f$ appears in the view change as the number of *other* replicas
that must want a view before a replica votes for it, so $f$ others plus the
replica itself is $Q$.

## Log entries, replies, and the state machine

`LogEntry`. An entry is $e = (c, s, \mathit{op})$: client id, request
number, operation. `Reply`. A reply is $(v, c, s, \mathit{result})$.

`Machine`. The replicated state machine is a function
$\mathrm{apply}(\sigma, \mathit{op}) = (\sigma', \mathit{result})$.

## Messages

`Message`, variant for variant. $i$ is always a replica id, $v$ a view
number, $n$ an op number, $k$ a commit number, $L$ a log, $x$ a nonce.

$$
\begin{aligned}
&\mathsf{Request}(c, s, \mathit{op}) \\
&\mathsf{Prepare}(v, n, e, k) && \text{entry } e \text{ has op number } n \\
&\mathsf{PrepareOk}(v, n, i) && i \text{ has every op up to } n \\
&\mathsf{Commit}(v, k) \\
&\mathsf{GetState}(i, v, n) && i \text{ asks for the log after index } n \\
&\mathsf{NewState}(v, L, a, b, k) && L = \text{the sender's } \mathrm{log}[a{:}b] \\
&\mathsf{StartViewChange}(v, i) \\
&\mathsf{DoViewChange}(v, i, \ell, L, n, k) && i\text{'s vote: last normal view } \ell \text{, log } L \text{, } n = |L| \\
&\mathsf{StartView}(v, L, n, k) && n = |L| \\
&\mathsf{Recovery}(i, x, v) \\
&\mathsf{RecoveryResponse}(v, x, i, \mathit{st}) && \mathit{st} \in \{\bot\} \cup \{(L, k)\}
\end{aligned}
$$

A vote (`Vote`) is the triple $(\ell, L, k)$ a `DoViewChange` carries.

## Replica state

`Replica`. Replica $r$ has:

| Field | Lean | Meaning |
|---|---|---|
| $\mathrm{id}_r$ | `selfId` | its id |
| $\mathrm{status}_r$ | `status` | one of $\mathsf{normal}$, $\mathsf{transfer}$, $\mathsf{recovering}$, $\mathsf{viewchange}$ |
| $v_r$ | `viewNumber` | view number |
| $\ell_r$ | `lastNormalView` | the last view it was normal in |
| $k_r$ | `commitNumber` | commit number |
| $L_r$ | `log` | the log; $n_r = \lvert L_r \rvert$ is `opNumber` |
| $A_r$ | `acks` | partial map, op number $\mapsto$ set of ids that acknowledged it |
| $C_r$ | `clientTable` | partial map, client id $\mapsto (s, \mathit{reply} \in \{\bot\} \cup \mathit{Output})$ |
| $\mathrm{catching}_r$ | `catchingUp` | in a view change, waiting for the new view's log |
| $S_r$ | `startViewChangeFrom` | ids that sent `StartViewChange` for $v_r$ |
| $\mathrm{dvcSent}_r$ | `doViewChangeSent` | voted in $v_r$ already |
| $V_r$ | `doViewChangeVotes` | partial map, id $\mapsto$ vote, the votes collected as primary of $v_r$ |
| $x_r$ | `recoveryNonce` | nonce of the recovery under way |
| $R_r$ | `recoveryResponses` | partial map, id $\mapsto (v, \mathit{st})$ |
| $\sigma_r$ | `sm` | the state machine's state |
| $\mathrm{panicked}_r$ | `panicked` | a Rust `assert!` would have fired |

Derived: $\mathrm{isPrimary}(r) \iff \mathrm{id}_r = \mathrm{primary}(v_r)$
(`isPrimary`).

Not in the state here, because they are what a step *does* rather than what
a replica *is*: the outbox and the replies (`outbox`, `replies`), which the
cluster step moves into its history, and the ghost `chosenVotes`, which it
moves into $\mathit{started}$.

`Replica.new`. A fresh replica: $\mathsf{normal}$, $v = \ell = k = 0$,
$L = \varepsilon$, every map empty, every flag false.

## The cluster

`System`. A cluster state is

$$
\Sigma = (\mathit{replicas}, \mathit{sent}, \mathit{replies}, \mathit{started})
$$

where $\mathit{replicas}$ maps each id to its replica, $\mathit{sent}$ is
the set of every $(\mathit{to}, m)$ ever sent, $\mathit{replies}$ every
reply ever produced, and $\mathit{started}$ (ghost) the set of $(v, V)$
for every view $v$ some primary started with the votes $V$ it chose the log
from. $\mathit{sent}$ and $\mathit{started}$ only grow.

`System.init`: every replica fresh, the three sets empty.

## Notation in the rules

"$r$ sends $m$ to $j$" adds $(j, m)$ to $\mathit{sent}$ (`send`). "to the
others" means to every $j \ne \mathrm{id}_r$ (`sendToOthers`); "to the
primary" means to $\mathrm{primary}(v_r)$ (`sendToPrimary`). "$r$ replies
$\rho$" adds $\rho$ to $\mathit{replies}$. "$r$ starts $v$ from $V$" adds
$(v, V)$ to $\mathit{started}$.

"**panic**" sets $\mathrm{panicked}_r$ and is where the Rust would
`assert!`. The rule continues as written after it, as the Lean does; the
safety property `NoPanic` says the flag is never set, so what happens after
does not matter.

Rules are written as: guard, then the updates in order. Anything not
mentioned is unchanged. When a guard fails the message is dropped and the
replica is unchanged, unless the rule says otherwise.

## Helpers

**append** (`appendToLog`). $\mathrm{append}(r, e)$:
$L_r := L_r \cdot e$; $C_r[e.c] := (e.s, \bot)$.

**installLog** (`installLog`). $\mathrm{installLog}(r, L)$:
if $|L| < k_r$ then **panic** and stop. Else $L_r := L$ and $C_r$ is rebuilt
from $L$ (`rebuildClientTable`): for each index $i$ in order,
$C_r[L[i].c] := (L[i].s, \rho)$ where $\rho$ is the old reply for that
client if $i < k_r$ and the old entry had the same request number, else
$\bot$.

**commitUpTo** (`commitUpTo`). $\mathrm{commitUpTo}(r, k, \mathit{reply})$:
while $k_r < k$:
if $k_r \ge n_r$ then **panic** and stop;
$(\sigma_r, \mathit{result}) := \mathrm{apply}(\sigma_r, L_r[k_r].\mathit{op})$;
if $C_r[L_r[k_r].c]$ has request number $L_r[k_r].s$, set its reply to
$\mathit{result}$;
if $\mathit{reply}$, $r$ replies $(v_r, L_r[k_r].c, L_r[k_r].s, \mathit{result})$;
$k_r := k_r + 1$.
Commit numbers only go up: $\mathrm{commitUpTo}$ with $k \le k_r$ does
nothing.

**enterNormal** (`enterNormal`).
$\mathrm{status}_r := \mathsf{normal}$; $\ell_r := v_r$;
$S_r := \emptyset$; $\mathrm{dvcSent}_r := \mathrm{false}$; $V_r := \emptyset$;
$\mathrm{catching}_r := \mathrm{false}$.

**stateTransfer** (`stateTransfer`).
$\mathrm{status}_r := \mathsf{transfer}$;
$r$ sends $\mathsf{GetState}(\mathrm{id}_r, v_r, n_r)$ to the primary.

**catchUpWithView** (`catchUpWithView`). $\mathrm{catchUp}(r, v)$:
if $v = v_r$ and $\mathrm{catching}_r$ then nothing. Else
$v_r := v$; $\mathrm{status}_r := \mathsf{viewchange}$;
$\mathrm{catching}_r := \mathrm{true}$;
$S_r := \emptyset$; $\mathrm{dvcSent}_r := \mathrm{false}$; $V_r := \emptyset$;
$r$ sends $\mathsf{GetState}(\mathrm{id}_r, v, k_r)$ to $\mathrm{primary}(v)$.
Note the request is from the *commit number*, not the op number: the
uncommitted suffix belongs to an older view and will be replaced. The log
is not truncated.

**acceptFromPrimary** (`acceptFromPrimary`). $\mathrm{accept}(r, v)$
decides whether a normal-case message in view $v$ is processed:

- $v < v_r$: no.
- $v > v_r$: $\mathrm{catchUp}(r, v)$; no.
- $v = v_r$ and $\mathrm{status}_r = \mathsf{normal}$: yes iff
  $\lnot\mathrm{isPrimary}(r)$.
- $v = v_r$ and $\mathrm{status}_r \in \{\mathsf{transfer}, \mathsf{recovering}\}$: no.
- $v = v_r$ and $\mathrm{status}_r = \mathsf{viewchange}$: $\mathrm{catchUp}(r, v)$; no.

**startViewChange** (`startViewChange`). $\mathrm{svc}(r, v)$:
$v_r := v$; $\mathrm{status}_r := \mathsf{viewchange}$;
$\mathrm{catching}_r := \mathrm{false}$;
$S_r := \emptyset$; $\mathrm{dvcSent}_r := \mathrm{false}$; $V_r := \emptyset$;
$r$ sends $\mathsf{StartViewChange}(v, \mathrm{id}_r)$ to the others;
$\mathrm{maybeVote}(r)$.

**maybeVote** (`maybeSendDoViewChange`).
If $\mathrm{status}_r = \mathsf{viewchange}$, $\lnot\mathrm{catching}_r$,
$\lnot\mathrm{dvcSent}_r$, and $|S_r| \ge f$:
$\mathrm{dvcSent}_r := \mathrm{true}$; $\mathrm{vote}(r)$.

**vote** (`sendDoViewChange`).
Let $\mathit{vote} = (\ell_r, L_r, k_r)$.
If $\mathrm{primary}(v_r) = \mathrm{id}_r$ then
$\mathrm{recordVote}(r, \mathrm{id}_r, \mathit{vote})$, else $r$ sends
$\mathsf{DoViewChange}(v_r, \mathrm{id}_r, \ell_r, L_r, n_r, k_r)$ to
$\mathrm{primary}(v_r)$.

**recordVote** (`recordDoViewChange`). $\mathrm{recordVote}(r, i, \mathit{vote})$:
$V_r[i] := \mathit{vote}$. If $|V_r| < Q$ stop. Else:

- $\mathit{best}$ = the vote in $V_r$ with the greatest
  $(\ell, |L|)$ in lexicographic order (`voteKey`, `bestVote`); among
  equal keys, the one from the highest replica id.
- $k^* = \max \{\, k : (\ell, L, k) \in V_r \,\}$.
- $r$ starts $v_r$ from $V_r$.
- $\mathrm{installLog}(r, \mathit{best}.L)$;
  $\mathrm{commitUpTo}(r, k^*, \mathrm{true})$;
  $\mathrm{enterNormal}(r)$;
- $A_r := \{\, n \mapsto \{\mathrm{id}_r\} : k_r < n \le n_r \,\}$
  (`addAcksForUncommitted`);
- $r$ sends $\mathsf{StartView}(v_r, L_r, n_r, k_r)$ to the others
  (`sendStartView`).

## Handlers

`onMessage` first: a replica with $\mathrm{status}_r = \mathsf{recovering}$
drops every message but $\mathsf{RecoveryResponse}$. A
$\mathsf{DoViewChange}$ or $\mathsf{StartView}$ whose $|L| \ne n$ is a
**panic**.

### Normal operation

**onRequest** (`onRequest`), on $\mathsf{Request}(c, s, \mathit{op})$.
Guard: $\mathrm{isPrimary}(r)$ and $\mathrm{status}_r = \mathsf{normal}$.

- $C_r[c]$ undefined, or $s > C_r[c].s$: $\mathrm{prepareRequest}(r, (c, s, \mathit{op}))$.
- $s = C_r[c].s$ and $C_r[c].\mathit{reply} = \mathit{result} \ne \bot$:
  $r$ replies $(v_r, c, s, \mathit{result})$.
- otherwise: drop.

**prepareRequest** (`prepareRequest`).
$\mathrm{append}(r, e)$; $A_r[n_r] := \{\mathrm{id}_r\}$;
$r$ sends $\mathsf{Prepare}(v_r, n_r, e, k_r)$ to the others.

**onPrepare** (`onPrepare`), on $\mathsf{Prepare}(v, n, e, k)$.
Guard: $\mathrm{accept}(r, v)$.

- $n > n_r + 1$: $\mathrm{stateTransfer}(r)$.
- else: if $n = n_r + 1$ then $\mathrm{append}(r, e)$;
  $\mathrm{commitUpTo}(r, \min(k, n_r), \mathrm{false})$;
  $r$ sends $\mathsf{PrepareOk}(v_r, n_r, \mathrm{id}_r)$ to the primary.

So a `Prepare` at or below the op number is acknowledged without being
appended, and the acknowledgement always names the replica's whole log.

**onPrepareOk** (`onPrepareOk`), on $\mathsf{PrepareOk}(v, n, i)$.
Guard: $v = v_r$, $\mathrm{isPrimary}(r)$,
$\mathrm{status}_r = \mathsf{normal}$, $n > k_r$, $n \in \mathrm{dom}\, A_r$.
$A_r[n] := A_r[n] \cup \{i\}$. If $i$ was new and now $|A_r[n]| = Q$:
$\mathrm{commitUpTo}(r, n, \mathrm{true})$;
remove every $n' \le n$ from $A_r$.

**onCommit** (`onCommit`), on $\mathsf{Commit}(v, k)$.
Guard: $\mathrm{accept}(r, v)$.
If $k > n_r$ then $\mathrm{stateTransfer}(r)$ else
$\mathrm{commitUpTo}(r, k, \mathrm{false})$.

### State transfer

**onGetState** (`onGetState`), on $\mathsf{GetState}(i, v, n)$.
Guard: $\mathrm{status}_r = \mathsf{normal}$, $v = v_r$, $n \le n_r$.
$r$ sends $\mathsf{NewState}(v, L_r[n{:}], n, n_r, k_r)$ to $i$.

**onNewState** (`onNewState`), on $\mathsf{NewState}(v, L, a, b, k)$.
Guard: $v = v_r$. If $|L| \ne b - a$: **panic**. Then by status:

- $\mathsf{transfer}$: if $a > n_r$ or $b \le n_r$ drop. Else
  $\mathrm{append}(r, e)$ for each $e$ in $L[n_r - a{:}]$ in order;
  if $n_r \ne b$ **panic**;
  $\mathrm{commitUpTo}(r, k, \mathrm{false})$;
  $\mathrm{status}_r := \mathsf{normal}$;
  $r$ sends $\mathsf{PrepareOk}(v_r, n_r, \mathrm{id}_r)$ to the primary.
- $\mathsf{viewchange}$ with $\mathrm{catching}_r$ and $a = k_r$:
  $\mathrm{installLog}(r, L_r[{:}a] \cdot L)$;
  if $n_r \ne b$ **panic**;
  $\mathrm{commitUpTo}(r, k, \mathrm{false})$;
  $\mathrm{enterNormal}(r)$;
  $r$ sends $\mathsf{PrepareOk}(v_r, n_r, \mathrm{id}_r)$ to the primary.
- otherwise: drop.

The catching-up case keeps the committed prefix and replaces everything
after it. That is the whole of the fix for the truncation defect.

### View change

**onStartViewChange** (`onStartViewChange`), on $\mathsf{StartViewChange}(v, i)$.

- $v < v_r$: drop.
- $v > v_r$: $\mathrm{svc}(r, v)$; $S_r := S_r \cup \{i\}$; $\mathrm{maybeVote}(r)$.
- $v = v_r$, $\mathrm{status}_r = \mathsf{viewchange}$:
  $S_r := S_r \cup \{i\}$; $\mathrm{maybeVote}(r)$.
- $v = v_r$, $\mathrm{status}_r = \mathsf{normal}$, $\mathrm{isPrimary}(r)$:
  $r$ sends $\mathsf{StartView}(v_r, L_r, n_r, k_r)$ to $i$.
- otherwise: drop.

**onDoViewChange** (`onDoViewChange`), on
$\mathsf{DoViewChange}(v, i, \ell, L, n, k)$, vote $\mathit{vote} = (\ell, L, k)$.
Guard: $v \ge v_r$ and $\mathrm{primary}(v) = \mathrm{id}_r$.

- $v > v_r$: $\mathrm{svc}(r, v)$; $\mathrm{recordVote}(r, i, \mathit{vote})$.
- $v = v_r$, $\mathrm{status}_r = \mathsf{normal}$:
  $r$ sends $\mathsf{StartView}(v_r, L_r, n_r, k_r)$ to $i$.
- $v = v_r$, otherwise: $\mathrm{recordVote}(r, i, \mathit{vote})$.

**onStartView** (`onStartView`), on $\mathsf{StartView}(v, L, n, k)$.
Guard: $v > v_r$, or $v = v_r$ and $\mathrm{status}_r = \mathsf{viewchange}$.
$v_r := v$; $\mathrm{installLog}(r, L)$;
$\mathrm{commitUpTo}(r, k, \mathrm{false})$;
$\mathrm{enterNormal}(r)$; $A_r := \emptyset$;
$r$ sends $\mathsf{PrepareOk}(v_r, n_r, \mathrm{id}_r)$ to the primary.

A `StartView` for the replica's own view is accepted only in view-change
status, so a late one cannot undo progress a normal replica made since.

### Recovery

**onRecovery** (`onRecovery`), on $\mathsf{Recovery}(i, x, v)$.

- $v > v_r$ and $\mathrm{status}_r \ne \mathsf{recovering}$: $\mathrm{svc}(r, v)$.
- else if $\mathrm{status}_r \ne \mathsf{normal}$: drop.
- else: $r$ sends $\mathsf{RecoveryResponse}(v_r, x, \mathrm{id}_r, \mathit{st})$
  to $i$, where $\mathit{st} = (L_r, k_r)$ if $\mathrm{isPrimary}(r)$ and
  $\bot$ otherwise.

The first case is why a recovering replica's persisted view matters to the
others: a `Recovery` from a higher view drags them forward.

**onRecoveryResponse** (`onRecoveryResponse`), on
$\mathsf{RecoveryResponse}(v, x, i, \mathit{st})$.
Guard: $\mathrm{status}_r = \mathsf{recovering}$ and $x = x_r$.
$R_r[i] := (v, \mathit{st})$. If $|R_r| < Q$ stop. Let
$v^* = \max \{\, v' : (v', \_) \in \mathrm{ran}\, R_r \,\}$.
Guard: $v^* \ge v_r$, and $R_r[\mathrm{primary}(v^*)] = (v^*, (L, k))$ with a
state present. Then:
$R_r := \emptyset$; $v_r := v^*$; $\mathrm{installLog}(r, L)$;
$\mathrm{commitUpTo}(r, k, \mathrm{false})$; $\mathrm{enterNormal}(r)$.

**recover** (`Replica.recover`). $\mathrm{recover}(i, v, x)$ is a fresh
replica with $\mathrm{status} = \mathsf{recovering}$, $v_r = \ell_r = v$,
$x_r = x$, which sends $\mathsf{Recovery}(i, x, v)$ to the others. $v$ is
the view number the owner persisted before the crash. Everything else is
gone: $L = \varepsilon$, $k = 0$, $\sigma$ the initial state.

### Idle

**onIdle** (`onIdle`), by status. "The timer fires" is the environment's
choice.

- $\mathsf{normal}$, primary:
  $r$ sends $\mathsf{Commit}(v_r, k_r)$ to the others, then for each
  $n = k_r + 1, \dots, n_r$ sends $\mathsf{Prepare}(v_r, n, L_r[n-1], k_r)$
  to the others (`resendPrepares`).
- $\mathsf{normal}$, backup: if the timer fires, $\mathrm{svc}(r, v_r + 1)$.
- $\mathsf{recovering}$: $r$ sends $\mathsf{Recovery}(\mathrm{id}_r, x_r, v_r)$
  to the others.
- $\mathsf{transfer}$: $\mathrm{stateTransfer}(r)$ again (a fresh
  `GetState`); then if the timer fires, $\mathrm{svc}(r, v_r + 1)$.
- $\mathsf{viewchange}$: if the timer fires, $\mathrm{svc}(r, v_r + 1)$.
  Else if $\mathrm{catching}_r$, $r$ sends
  $\mathsf{GetState}(\mathrm{id}_r, v_r, k_r)$ to the primary. Else $r$
  sends $\mathsf{StartViewChange}(v_r, \mathrm{id}_r)$ to the others and,
  if $\mathrm{dvcSent}_r$, $\mathrm{vote}(r)$ again.

## The cluster step

`System.step`. From $\Sigma$, the environment picks one of:

- **deliver** $(\mathit{to}, m) \in \mathit{sent}$: replica $\mathit{to}$
  runs $\mathrm{onMessage}(m)$. The message stays in $\mathit{sent}$.
- **idle** $i$: replica $i$ runs $\mathrm{onIdle}$.
- **request** $(i, c, s, \mathit{op})$: replica $i$ runs
  $\mathrm{onRequest}(c, s, \mathit{op})$. Clients are not modelled; any
  request may arrive anywhere at any time, which covers every client
  behaviour including retransmission to a backup.
- **recover** $(i, x)$: replica $i$ is replaced by
  $\mathrm{recover}(i, v_i, x)$, where $v_i$ is its view number in $\Sigma$.

After the replica runs, `drain` moves what it sent into $\mathit{sent}$,
its replies into $\mathit{replies}$, and the view it started, if any, into
$\mathit{started}$.

A replica is stepped only when the environment chooses it, so a crashed
replica is one that is not chosen until its **recover** step. Loss, delay,
duplication, and reordering are all the one rule that **deliver** picks any
element of $\mathit{sent}$.

`Reachable` (in `Vsr/Safety.lean`): the states obtained from
`System.init` by finitely many steps. Every property in
[`invariant.md`](invariant.md) is claimed over these.
