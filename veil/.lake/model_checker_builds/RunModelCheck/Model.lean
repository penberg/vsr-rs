import Veil

set_option veil.__modelCheckCompileMode true

/-!
# VSR in Veil

A protocol-level model of the replica in `lib.rs`, written for Veil's
SMT-checked inductive invariants and its explicit-state model checker.
It is not the line-by-line twin that `lean/Vsr/Replica.lean` is; it is the
abstraction that `lean/Vsr/Invariant.lean` reasons about, written directly
as a transition system. Each action names the Rust handler it renders.

## What is kept and what is abstracted

- **Message history.** Every message ever sent is a tuple in a relation
  that only grows, exactly `System.sent` in the Lean: delivery never
  removes anything, so loss, delay, replay and reordering are one rule.
  A handler fires on any tuple in the relation, any number of times.
- **Log content by view, not by message.** The Lean's `Frag`/`Holds` say
  that all fragments of one view's log agree; here that is the state.
  `frag v n e` records that some message of view `v` carried entry `e` at
  op number `n`. `Prepare` keeps its entry; the whole-log messages
  (`StartView`, `DoViewChange`, `NewState`, `RecoveryResponse`) carry a
  length and a commit number and the receiver reads the entries from
  `frag`. That over-approximates the Rust: whatever the Rust receiver
  installs, this receiver may install. Under `one_log_per_view` the two
  coincide.
- **Op numbers are 1-based** and live in an ordered sort `idx` with a
  successor, so "append" is "the next op number". The Lean's log index
  `i` is op number `i + 1`.
- **Timers** are the environment's choice: `timeout` may fire on any
  backup, as in `proof/model.md`.
- **Dropped for safety:** the client table and request de-duplication
  (entries are abstract), reply generation, the state machine, backoff
  counters, and the message re-sends that would add a tuple that is
  already there.
- **The primary's own vote** is written into the `DoViewChange` history
  like everyone else's, so the ghost `System.started` of the Lean is not
  needed; `chosen v q` records which votes a view was started from.
-/

set_option maxHeartbeats 4000000

veil module RunModelCheck

type replica
type view
type idx      -- op numbers
type entry    -- a log entry: client id, request number, op
type quorum
type nonce

instantiate vw : TotalOrderWithMinimum view
instantiate ix : TotalOrderWithMinimum idx

/- `Config::primary_id`: `v mod N`. For safety only that it is a function
of the view matters. -/
immutable function primary : view → replica
immutable relation member (r : replica) (q : quorum)

enum status_t = { normal, view_change, state_transfer, recovering }

/-! ## Replica state (`Replica` in the Lean) -/

function status : replica → status_t
function cur_view : replica → view          -- `viewNumber`
function last_normal : replica → view       -- `lastNormalView`
relation log (r : replica) (n : idx) (e : entry)
function log_len : replica → idx            -- `opNumber`
function commit : replica → idx             -- `commitNumber`
relation acks (r : replica) (n : idx) (q : replica)
function catching_up : replica → Bool
relation svc_from (r : replica) (q : replica)   -- `startViewChangeFrom`
function dvc_sent : replica → Bool
relation votes (r : replica) (q : replica)      -- keys of `doViewChangeVotes`
function rec_nonce : replica → nonce
relation rec_from (r : replica) (q : replica)   -- keys of `recoveryResponses`

/-! ## Message history (`System.sent`) -/

/- Some message of view `v` carried entry `e` at op number `n`: the
union of the Lean's `Frag`s of `v`. -/
relation frag (v : view) (n : idx) (e : entry)

relation m_prepare (v : view) (n : idx) (e : entry) (k : idx)
relation m_prepare_ok (v : view) (n : idx) (q : replica)
relation m_commit (v : view) (k : idx)
relation m_get_state (q : replica) (v : view) (n : idx)
relation m_new_state (v : view) (a : idx) (b : idx) (k : idx)   -- entries `a < n ≤ b` of view `v`
relation m_svc (v : view) (q : replica)                          -- `StartViewChange`
relation m_dvc (v : view) (q : replica)                          -- `DoViewChange`: `q` voted in `v`
function vote_lnv : view → replica → view                        -- the vote's last normal view
function vote_len : view → replica → idx
function vote_commit : view → replica → idx
relation m_start_view (v : view) (n : idx) (k : idx)
relation m_recovery (q : replica) (x : nonce) (v : view)
relation m_rr (x : nonce) (q : replica) (v : view)               -- `RecoveryResponse`
relation m_rr_state (x : nonce) (q : replica) (v : view) (n : idx) (k : idx)  -- ... with a state
relation nonce_used (x : nonce)

/-! ## Ghost history (`System.started`) -/

relation chosen (v : view) (q : replica)        -- view `v` was started from these votes
relation chosen_best (v : view) (q : replica)   -- and its log is this one's

#gen_state

/- Quorums intersect, and every quorum has a member other than any given
replica: the cluster has at least two replicas (`TwoReplicas` in the
Lean's `Inv`; a cluster of one never sends). -/
assumption [quorum_intersection] ∀ (Q1 Q2 : quorum), ∃ p, member p Q1 ∧ member p Q2
assumption [two_replicas] ∀ (Q : quorum) (r : replica), ∃ p, member p Q ∧ p ≠ r

/-! ## The vocabulary of the invariant, as in `lean/Vsr/Invariant.lean` -/

/- `Acked`: `q` acknowledged op `n` in view `v`. The primary acknowledges
its own ops without a message. -/
ghost relation acked (v : view) (n : idx) (q : replica) :=
  q = primary v ∨ ∃ o, m_prepare_ok v o q ∧ ix.le n o

ghost relation quorum_acked (v : view) (n : idx) :=
  ∃ Q : quorum, ∀ q, member q Q → acked v n q

/- `Committed`: view `v` holds `e` at `n` and a quorum acknowledged it. -/
ghost relation committed (v : view) (n : idx) (e : entry) :=
  frag v n e ∧ quorum_acked v n

/- `Backed`: every op up to `k` was committed in a view no later than `v`
with the entry `v` holds there. -/
ghost relation backed (v : view) (k : idx) :=
  ∀ n, ix.lt ix.zero n → ix.le n k →
    ∃ e v', vw.le v' v ∧ committed v' n e ∧ frag v n e

ghost relation is_primary (r : replica) := primary (cur_view r) = r

procedure init_replicas {
  status R := normal
  cur_view R := vw.zero
  last_normal R := vw.zero
  log R N E := false
  log_len R := ix.zero
  commit R := ix.zero
  acks R N Q := false
  catching_up R := false
}

procedure init_view_change_state {
  svc_from R Q := false
  dvc_sent R := false
  votes R Q := false
  rec_nonce R := *
  rec_from R Q := false
  chosen V Q := false
  chosen_best V Q := false
}

procedure init_normal_messages {
  frag V N E := false
  m_prepare V N E K := false
  m_prepare_ok V N Q := false
  m_commit V K := false
  m_get_state Q V N := false
  m_new_state V A B K := false
}

procedure init_view_change_messages {
  m_svc V Q := false
  m_dvc V Q := false
  vote_lnv V Q := *
  vote_len V Q := *
  vote_commit V Q := *
  m_start_view V N K := false
}

procedure init_recovery_messages {
  m_recovery Q X V := false
  m_rr X Q V := false
  m_rr_state X Q V N K := false
  nonce_used X := false
}

after_init {
  init_replicas
  init_view_change_state
  init_normal_messages
  init_view_change_messages
  init_recovery_messages
}

/-! ## Helpers (`Replica::*` in the Lean) -/

/- `commit_up_to`. The Rust indexes `log[commit_number]`, so a commit
number past the log is the panic; `assert` is Veil's `doesNotThrow`. -/
procedure commit_up_to (r : replica) (k : idx) {
  if ix.lt (commit r) k then
    assert ix.le k (log_len r)
    commit r := k
}

/- `install_log`: the log of view `v` up to op `n`. The Rust asserts the
new log is at least as long as the commit number. -/
procedure install_log (r : replica) (v : view) (n : idx) {
  assert ix.le (commit r) n
  log r N E := decide (frag v N E ∧ ix.le N n)
  log_len r := n
}

procedure clear_view_change_state (r : replica) {
  svc_from r Q := false
  dvc_sent r := false
  votes r Q := false
}

procedure enter_normal (r : replica) {
  clear_view_change_state r
  status r := normal
  last_normal r := cur_view r
  catching_up r := false
}

procedure send_prepare_ok (r : replica) {
  m_prepare_ok (cur_view r) (log_len r) r := true
}

/- `send_start_view`: publishes the primary's log as the view's log. -/
procedure send_start_view (r : replica) {
  frag (cur_view r) N E := decide (frag (cur_view r) N E ∨ log r N E)
  m_start_view (cur_view r) (log_len r) (commit r) := true
}

/- `catch_up_with_view`. -/
procedure catch_up_with_view (r : replica) (v : view) {
  if ¬ (cur_view r = v ∧ catching_up r) then
    clear_view_change_state r
    cur_view r := v
    status r := view_change
    catching_up r := true
    m_get_state r v (commit r) := true
}

/- `record_do_view_change`: with a quorum of votes, the primary starts the
view from the best vote by (last normal view, log length) and the highest
commit number. -/
/- `start_view_change`. The Rust then calls
`maybe_send_do_view_change`, which with the sender set just cleared can
only fire if the replica is a quorum by itself; `two_replicas` rules that
out, and the action `send_do_view_change` below is the rest of it. -/
procedure start_view_change (r : replica) (v : view) {
  clear_view_change_state r
  cur_view r := v
  status r := view_change
  catching_up r := false
  m_svc v r := true
}

/-! ## Actions: one per handler, plus the environment's choices -/

/- `on_request` at the primary; `prepare_request`. -/
action client_request (r : replica) (e : entry) {
  require status r = normal ∧ is_primary r
  let n :| ix.next (log_len r) n
  log r n e := true
  log_len r := n
  acks r n P := decide (P = r)
  frag (cur_view r) n e := true
  m_prepare (cur_view r) n e (commit r) := true
}

/- `on_prepare`, with `accept_from_primary` inlined. -/
action recv_prepare (r : replica) (v : view) (n : idx) (e : entry) (k : idx) {
  require m_prepare v n e k
  require status r ≠ recovering
  if vw.lt v (cur_view r) then
    pure ()
  else if vw.lt (cur_view r) v then
    catch_up_with_view r v
  else if status r = normal ∧ ¬ is_primary r then
    let len := log_len r
    if ix.lt len n ∧ ¬ ix.next len n then
      status r := state_transfer
      m_get_state r v len := true
    else
      if ix.next len n then
        log r n e := true
        log_len r := n
      if ix.le k (log_len r) then
        commit_up_to r k
      else
        commit_up_to r (log_len r)
      send_prepare_ok r
  else if status r = view_change then
    catch_up_with_view r v
}

/- `on_prepare_ok`: records the acknowledgement. -/
action recv_prepare_ok (r : replica) (v : view) (n : idx) (q : replica) {
  require m_prepare_ok v n q
  require status r = normal ∧ cur_view r = v ∧ is_primary r
  require ix.lt (commit r) n
  require ∃ p, acks r n p
  acks r n q := true
}

/- `on_prepare_ok` on reaching a quorum: commits. The Rust commits on the
acknowledgement that completes the quorum; here on any later step, with
the guard re-checked. -/
action commit_quorum (r : replica) (n : idx) {
  require status r = normal ∧ is_primary r
  require ix.lt (commit r) n
  require ∃ Q : quorum, ∀ p, member p Q → acks r n p
  commit_up_to r n
  acks r N P := decide (acks r N P ∧ ix.lt n N)
}

/- `on_commit`. -/
action recv_commit (r : replica) (v : view) (k : idx) {
  require m_commit v k
  require status r ≠ recovering
  if vw.lt v (cur_view r) then
    pure ()
  else if vw.lt (cur_view r) v then
    catch_up_with_view r v
  else if status r = normal ∧ ¬ is_primary r then
    if ix.lt (log_len r) k then
      status r := state_transfer
      m_get_state r v (log_len r) := true
    else
      commit_up_to r k
  else if status r = view_change then
    catch_up_with_view r v
}

/- `on_get_state`: answers with `log[n:]`, which is already in `frag`
of this view (`covered`). -/
action recv_get_state (r : replica) (q : replica) (v : view) (n : idx) {
  require m_get_state q v n
  require status r = normal ∧ cur_view r = v ∧ ix.le n (log_len r)
  m_new_state v n (log_len r) (commit r) := true
}

/- `on_new_state`. -/
action recv_new_state (r : replica) (v : view) (a : idx) (b : idx) (k : idx) {
  require m_new_state v a b k
  require status r ≠ recovering ∧ cur_view r = v
  if status r = state_transfer then
    let len := log_len r
    if ix.le a len ∧ ix.lt len b then
      log r N E := decide (log r N E ∨ (ix.lt len N ∧ ix.le N b ∧ frag v N E))
      log_len r := b
      commit_up_to r k
      status r := normal
      send_prepare_ok r
  else if status r = view_change ∧ catching_up r ∧ a = commit r then
    assert ix.le (commit r) b
    log r N E := decide ((log r N E ∧ ix.le N a) ∨ (ix.lt a N ∧ ix.le N b ∧ frag v N E))
    log_len r := b
    commit_up_to r k
    enter_normal r
    send_prepare_ok r
}

/- `on_start_view_change`, minus the `DoViewChange` it may send, which
is `send_do_view_change`. -/
action recv_start_view_change (r : replica) (v : view) (q : replica) {
  require m_svc v q
  require status r ≠ recovering
  if vw.lt v (cur_view r) then
    pure ()
  else if vw.lt (cur_view r) v then
    start_view_change r v
    svc_from r q := true
  else if status r ≠ view_change then
    if status r = normal ∧ is_primary r then
      send_start_view r
  else
    svc_from r q := true
}

/- `maybe_send_do_view_change` and `send_do_view_change`, as a step of
their own: `f` others want the view, and with this replica that is a
quorum. The Rust does this inside the handler that records the `f`-th
sender; here it can happen any time later, with the guard re-checked,
which is the same set of votes. The primary's own vote goes into the
history too, and it collects it with `recv_do_view_change` like the
others; the Rust records it on the spot. -/
action send_do_view_change (r : replica) {
  require status r = view_change ∧ ¬ catching_up r ∧ ¬ dvc_sent r
  require ∃ Q : quorum, ∀ p, member p Q → (p = r ∨ svc_from r p)
  let v := cur_view r
  dvc_sent r := true
  m_dvc v r := true
  vote_lnv v r := last_normal r
  vote_len v r := log_len r
  vote_commit v r := commit r
}

/- `on_do_view_change`, minus starting the view, which is `start_view`. -/
action recv_do_view_change (r : replica) (v : view) (q : replica) {
  require m_dvc v q
  require status r ≠ recovering
  require primary v = r ∧ ¬ vw.lt v (cur_view r)
  if vw.lt (cur_view r) v then
    start_view_change r v
    votes r q := true
  else if status r = normal then
    send_start_view r
  else
    votes r q := true
}

/- `record_do_view_change` on reaching a quorum: the primary starts the
view from the best vote by (last normal view, log length) and the highest
commit number among the votes. The Rust does this on the vote that
completes the quorum, with exactly those votes; here any set of votes
that contains a quorum will do, which is more behaviours, all of which
the argument covers. -/
action start_view (r : replica) {
  require status r ≠ normal ∧ status r ≠ recovering ∧ is_primary r
  require ∃ Q : quorum, ∀ p, member p Q → votes r p
  let v := cur_view r
  let bq :| votes r bq ∧ ∀ p, votes r p →
      (vw.lt (vote_lnv v p) (vote_lnv v bq) ∨
       (vote_lnv v p = vote_lnv v bq ∧ ix.le (vote_len v p) (vote_len v bq)))
  let kmax :| (∃ p, votes r p ∧ vote_commit v p = kmax) ∧
      ∀ p, votes r p → ix.le (vote_commit v p) kmax
  chosen v P := votes r P
  chosen_best v P := decide (P = bq)
  install_log r (vote_lnv v bq) (vote_len v bq)
  commit_up_to r kmax
  enter_normal r
  acks r N P := decide (ix.lt (commit r) N ∧ ix.le N (log_len r) ∧ P = r)
  send_start_view r
}

/- `on_start_view`. -/
action recv_start_view (r : replica) (v : view) (n : idx) (k : idx) {
  require m_start_view v n k
  require status r ≠ recovering
  require ¬ (vw.lt v (cur_view r) ∨ (v = cur_view r ∧ status r ≠ view_change))
  cur_view r := v
  install_log r v n
  commit_up_to r k
  enter_normal r
  acks r N P := false
  send_prepare_ok r
}

/- `on_idle` at a backup, or in a view change, when the wait timed out. -/
action timeout (r : replica) {
  require status r ≠ recovering
  require ¬ (status r = normal ∧ is_primary r)
  let v' :| vw.next (cur_view r) v'
  start_view_change r v'
}

/- `on_idle` at the primary: a `Commit`, and every uncommitted `Prepare`
again with the current commit number. -/
action primary_idle (r : replica) {
  require status r = normal ∧ is_primary r
  let v := cur_view r
  let k := commit r
  m_commit v k := true
  m_prepare v N E k := decide (m_prepare v N E k ∨ (ix.lt k N ∧ ix.le N (log_len r) ∧ log r N E))
}

/- `Replica::recover`: back from a crash with nothing but the view
number. -/
procedure forget (r : replica) {
  log r N E := false
  log_len r := ix.zero
  commit r := ix.zero
  acks r N Q := false
  catching_up r := false
  clear_view_change_state r
}

action crash_recover (r : replica) (x : nonce) {
  require ¬ nonce_used x
  nonce_used x := true
  status r := recovering
  forget r
  last_normal r := cur_view r
  rec_nonce r := x
  rec_from r Q := false
  m_recovery r x (cur_view r) := true
}

/- `on_recovery`. -/
action recv_recovery (r : replica) (q : replica) (x : nonce) (v : view) {
  require m_recovery q x v
  require status r ≠ recovering
  if vw.lt (cur_view r) v then
    start_view_change r v
  else if status r = normal then
    let cv := cur_view r
    m_rr x r cv := true
    if is_primary r then
      frag cv N E := decide (frag cv N E ∨ log r N E)
      m_rr_state x r cv (log_len r) (commit r) := true
}

/- `on_recovery_response`. -/
/- `on_recovery_response`: records the response. -/
action recv_recovery_response (r : replica) (q : replica) (x : nonce) (v : view) {
  require m_rr x q v
  require status r = recovering ∧ rec_nonce r = x
  rec_from r q := true
}

/- `on_recovery_response` on reaching a quorum: the latest view among the
responses, and the primary of that view's state. -/
action finish_recovery (r : replica) (lv : view) (n : idx) (k : idx) {
  require status r = recovering
  require ∃ Q : quorum, ∀ p, member p Q → rec_from r p
  require ∃ p, rec_from r p ∧ m_rr (rec_nonce r) p lv
  require ∀ p v2, rec_from r p → m_rr (rec_nonce r) p v2 → vw.le v2 lv
  require vw.le (cur_view r) lv
  require rec_from r (primary lv) ∧ m_rr_state (rec_nonce r) (primary lv) lv n k
  rec_from r P := false
  cur_view r := lv
  install_log r lv n
  commit_up_to r k
  enter_normal r
}

/-! ## Safety -/

/- `PrefixAgreement`: two replicas that both committed op `n` hold the
same entry there. -/
safety [prefix_agreement]
  ix.le N (commit A) ∧ ix.le N (commit B) ∧ log A N E1 ∧ log B N E2 → E1 = E2

/-! ## Layer one: `LocalInv` -/

invariant [commit_bounded] ix.le (commit R) (log_len R)
invariant [last_normal_le_view] vw.le (last_normal R) (cur_view R)
invariant [normal_last_normal]
  (status R = normal ∨ status R = state_transfer) → last_normal R = cur_view R
invariant [catching_up_view_change] catching_up R → status R = view_change
invariant [recovering_empty]
  status R = recovering → log_len R = ix.zero ∧ commit R = ix.zero ∧ ¬ log R N E

/-! ## The shape of logs -/

invariant [log_within] log R N E → ix.lt ix.zero N ∧ ix.le N (log_len R)
invariant [log_dense] ix.lt ix.zero N ∧ ix.le N (log_len R) → ∃ E, log R N E
invariant [log_unique] log R N E1 ∧ log R N E2 → E1 = E2
invariant [frag_positive] frag V N E → ix.lt ix.zero N

/-! ## Layer two: `WF` -/

invariant [wf_prepare] m_prepare V N E K → ix.lt ix.zero N ∧ frag V N E
invariant [wf_new_state] m_new_state V A B K → ix.le A B ∧ ix.le K B
invariant [wf_start_view] m_start_view V N K → ix.le K N
invariant [wf_dvc] m_dvc V Q → ix.le (vote_commit V Q) (vote_len V Q) ∧ vw.le (vote_lnv V Q) V
invariant [wf_rr_state] m_rr_state X Q V N K → ix.le K N ∧ m_rr X Q V

/-! ## Layer three: `OneLogPerView` -/

invariant [one_log_per_view] frag V N E1 ∧ frag V N E2 → E1 = E2
invariant [covered] log R N E → frag (last_normal R) N E

/-! ## Layer four: `CommitsBacked` -/

invariant [replica_backed] backed (last_normal R) (commit R)
invariant [prepare_backed] m_prepare V N E K → backed V K
invariant [commit_backed] m_commit V K → backed V K
invariant [new_state_backed] m_new_state V A B K → backed V K
invariant [start_view_backed] m_start_view V N K → backed V K
invariant [dvc_backed] m_dvc V Q → backed (vote_lnv V Q) (vote_commit V Q)
invariant [rr_backed] m_rr_state X Q V N K → backed V K

/-! ## Layer five: `Survives` -/

invariant [survives_frag] committed W0 N E ∧ vw.lt W0 V ∧ frag V N E2 → E2 = E
invariant [survives_start_view]
  committed W0 N E ∧ vw.lt W0 V ∧ m_start_view V L K → frag V N E
invariant [survives_vote]
  committed W0 N E ∧ vw.lt W0 V ∧ m_dvc V2 Q ∧ vote_lnv V2 Q = V → frag V N E
invariant [survives_rr]
  committed W0 N E ∧ vw.lt W0 V ∧ m_rr_state X Q V L K → frag V N E
invariant [survives_replica]
  committed W0 N E ∧ vw.lt W0 V ∧ last_normal R = V ∧ status R ≠ recovering → log R N E

/-! ## The helpers the induction needs -/

invariant [acks_current]
  status P = normal ∧ is_primary P ∧ acks P N Q →
    ix.le N (log_len P) ∧ (Q = P ∨ m_prepare_ok (cur_view P) N Q)
invariant [catching_up_not_primary] catching_up R → ¬ is_primary R
invariant [acks_hold]
  m_prepare_ok V O Q →
    vw.le V (last_normal Q) ∧
    (last_normal Q = V ∧ status Q ≠ recovering → ix.le O (log_len Q))
invariant [primary_longest_frag]
  status P = normal ∧ is_primary P ∧ frag (cur_view P) N E → ix.le N (log_len P)
invariant [primary_longest_replica]
  status P = normal ∧ is_primary P ∧ last_normal Q = cur_view P ∧ status Q ≠ recovering →
    ix.le (log_len Q) (log_len P)
invariant [primary_longest_ack]
  status P = normal ∧ is_primary P ∧ m_prepare_ok (cur_view P) O Q → ix.le O (log_len P)
invariant [primary_holds_view]
  status P = normal ∧ is_primary P ∧ frag (cur_view P) N E → log P N E
invariant [votes_are_dvcs] votes R Q → m_dvc (cur_view R) Q
invariant [chosen_are_dvcs] chosen V Q → m_dvc V Q
invariant [chosen_best_chosen] chosen_best V B → chosen V B
invariant [chosen_best_is_best]
  chosen V Q ∧ chosen_best V B →
    vw.lt (vote_lnv V Q) (vote_lnv V B) ∨
    (vote_lnv V Q = vote_lnv V B ∧ ix.le (vote_len V Q) (vote_len V B))
invariant [start_view_chosen]
  m_start_view V L K → ∃ Q : quorum, ∀ p, member p Q → chosen V p
invariant [start_view_extends_best]
  m_start_view V L K ∧ chosen_best V B →
    ix.le (vote_len V B) L ∧
    (frag (vote_lnv V B) N E ∧ ix.le N (vote_len V B) → frag V N E)
invariant [chosen_votes_cover]
  chosen V Q ∧ m_prepare_ok (vote_lnv V Q) O Q → ix.le O (vote_len V Q)
invariant [prepare_ok_below_view] m_prepare_ok V O Q → vw.le V (cur_view Q)
invariant [svc_below_view] m_svc V Q → vw.le V (cur_view Q)
invariant [dvc_below_view] m_dvc V Q → vw.le V (cur_view Q)
invariant [get_state_below_view] m_get_state Q V N → vw.le V (cur_view Q)
invariant [recovery_below_view] m_recovery Q X V → vw.le V (cur_view Q)
invariant [rr_below_view] m_rr X Q V → vw.le V (cur_view Q)
invariant [recovery_covers_acks]
  status Q = recovering ∧ m_rr_state (rec_nonce Q) P V N K ∧ m_prepare_ok V O Q → ix.le O N
invariant [started_views]
  frag V N E ∧ V ≠ vw.zero → ∃ L K, m_start_view V L K

#gen_spec
#model_check
  { replica := Fin 3, view := Fin 2, idx := Fin 3, entry := Fin 2,
    quorum := Quorum 3, nonce := Fin 1 }
  { primary := fun v => Fin.castLE (by decide) v, member := fun r q => r ∈ q }
