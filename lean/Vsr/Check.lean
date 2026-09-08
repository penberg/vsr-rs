import Vsr.WellFormed
import Vsr.System

/-!
Executable versions of the invariants: the ones proved, and the candidates
for the layers still to prove. `vsr-replay` evaluates them after every step
of a conformance trace and reports a violation on stderr. A candidate that
is false shows up in seconds here, instead of days into a proof.

Each check mirrors a `Prop` in `Vsr.Safety`, `Vsr.Local`, or
`Vsr.WellFormed`, or a layer of the plan in `README.md`.
-/

namespace Vsr.Check

variable {Op Output St : Type} [DecidableEq Op]

/-! ### Proved layers -/

/-- `Replica.LocalInv`. -/
def localInv (r : Replica Op Output St) : Bool :=
  decide (r.commitNumber ≤ r.log.length) &&
  decide (r.lastNormalView ≤ r.viewNumber) &&
  (!(r.status == .normal || r.status == .stateTransfer) || r.lastNormalView == r.viewNumber) &&
  (!r.catchingUp || r.status == .viewChange) &&
  (r.status != .recovering || (r.log.isEmpty && r.commitNumber == 0))

/-- `WF`. -/
def wf : Message Op → Bool
  | .prepare _ o _ _ _ _ => decide (0 < o)
  | .newState _ log a b k => log.length == b - a && decide (a ≤ b) && decide (k ≤ b)
  | .doViewChange v _ l log o k => log.length == o && decide (k ≤ o) && decide (l ≤ v)
  | .startView _ log o k => log.length == o && decide (k ≤ o)
  | .recoveryResponse _ _ _ (some st) => decide (st.commitNumber ≤ st.log.length)
  | _ => true

def drained (s : System Op Output St) : Bool := s.replicas.all (·.outbox.isEmpty)

/-! ### The safety properties -/

def noPanic (s : System Op Output St) : Bool := s.replicas.all (!·.panicked)

def commitBounded (s : System Op Output St) : Bool :=
  s.replicas.all fun r => decide (r.commitNumber ≤ r.log.length)

def prefixAgreement (s : System Op Output St) : Bool :=
  s.replicas.all fun a => s.replicas.all fun b =>
    (List.range (min a.commitNumber b.commitNumber)).all fun i => a.log[i]? == b.log[i]?

def durability (s : System Op Output St) : Bool :=
  let participants := s.replicas.filter fun o => o.status != .recovering
  participants.all fun r => (List.range r.commitNumber).all fun i =>
    decide (participants.length + 1 - s.config.quorum ≤
      (participants.filter fun o => o.log[i]? == r.log[i]?).length)

/-! ### Candidates: layer 3, one log per view -/

/-- Every piece of a view's log the system holds: `(view, offset, entries)`.
A `Prepare` is one entry at its op number; `NewState` a segment; `StartView`,
a `DoViewChange` dvc, and a primary's recovery state whole logs; and each
replica's log belongs to its last normal view. -/
def fragments (s : System Op Output St) : List (ViewNumber × Nat × List (LogEntry Op)) :=
  (s.sent.filterMap fun (_, msg) =>
    match msg with
    | .prepare v o c n op _ => some (v, o - 1, [⟨c, n, op⟩])
    | .newState v log a _ _ => some (v, a, log)
    | .startView v log _ _ => some (v, 0, log)
    | .doViewChange _ _ l log _ _ => some (l, 0, log)
    | .recoveryResponse v _ _ (some st) => some (v, 0, st.log)
    | _ => none) ++
  (s.started.flatMap fun (_, dvcs) => dvcs.map fun (_, dvc) => (dvc.lastNormalView, 0, dvc.log)) ++
  s.replicas.map fun r => (r.lastNormalView, 0, r.log)

/-- Two fragments agree wherever they overlap. -/
def compatible (a b : Nat × List (LogEntry Op)) : Bool :=
  (List.range a.2.length).all fun i =>
    let p := a.1 + i
    if p < b.1 then true
    else match b.2[p - b.1]?, a.2[i]? with
      | some eb, some ea => ea == eb
      | _, _ => true

def oneLogPerView (s : System Op Output St) : Bool :=
  let fs := fragments s
  fs.all fun (v, a) => fs.all fun (v', b) => v != v' || compatible a b

/-! ### Candidates: layer 4, committed means acknowledged -/

/-- The replicas that acknowledged op `i + 1` or later in view `v`,
counting the primary, which acknowledges its own ops without a message. -/
def ackers (s : System Op Output St) (v : ViewNumber) (i : Nat) : List ReplicaId :=
  (s.config.primaryId v :: s.sent.filterMap fun (_, msg) =>
    match msg with
    | .prepareOk v' o q => if v' == v && decide (i + 1 ≤ o) then some q else none
    | _ => none).eraseDups

/-- Some fragment of view `v` holds `e` at index `i`. -/
def viewLogHolds (s : System Op Output St) (v : ViewNumber) (i : Nat) (e : LogEntry Op) : Bool :=
  (fragments s).any fun (v', off, entries) =>
    v' == v && decide (off ≤ i) && entries[i - off]? == some e

def committedAcked (s : System Op Output St) : Bool :=
  s.replicas.all fun r => (List.range r.commitNumber).all fun i =>
    match r.log[i]? with
    | none => false
    | some e => (List.range (r.viewNumber + 1)).any fun v =>
        decide (s.config.quorum ≤ (ackers s v i).length) && viewLogHolds s v i e

/-- The commit numbers messages carry are backed the same way a replica's
own is: every index below one was committed, in a view no later than the
message's, and the message's view holds that entry. A `DoViewChange`
is judged by its last normal view. -/
def messageCommitsBacked (s : System Op Output St) : Bool :=
  let backed (v : ViewNumber) (k : Nat) : Bool :=
    (List.range k).all fun i => (List.range (v + 1)).any fun v' =>
      (fragments s).any fun (v'', off, entries) =>
        v'' == v' && decide (off ≤ i) &&
        match entries[i - off]? with
        | none => false
        | some e => decide (s.config.quorum ≤ (ackers s v' i).length) && viewLogHolds s v i e
  s.sent.all fun (_, msg) =>
    match msg with
    | .prepare v _ _ _ _ k => backed v k
    | .commit v k => backed v k
    | .newState v _ _ _ k => backed v k
    | .startView v _ _ k => backed v k
    | .doViewChange _ _ l _ _ k => backed l k
    | .recoveryResponse v _ _ (some st) => backed v st.commitNumber
    | _ => true

/-- A primary in normal status only holds acknowledgements for its own
ops in its own view: each recorded acknowledger, other than itself, sent a
`PrepareOk` for that op in that view, and the op is in its log. -/
def acksCurrent (s : System Op Output St) : Bool :=
  s.replicas.all fun r =>
    !(r.status == .normal && r.isPrimary) ||
    r.acks.all fun (o, acked) =>
      decide (o ≤ r.log.length) && decide (acked.Pairwise (· < ·)) && acked.all fun q =>
        decide (q < s.config.replicaCount) &&
        (q == r.selfId || s.sent.any fun (_, msg) =>
          match msg with
          | .prepareOk v o' q' => v == r.viewNumber && o' == o && q' == q
          | _ => false)

/-- A replica catching up with a view is not that view's primary: only the
primary's own messages make a replica catch up, and it sends none to
itself. -/
def catchingUpNotPrimary (s : System Op Output St) : Bool :=
  s.replicas.all fun r => !r.catchingUp || r.selfId != r.config.primaryId r.viewNumber

/-- What an acknowledgement says stays true: a replica that acknowledged
op `o` in view `v` has a last normal view of at least `v`, and while that
is still `v` and it is not recovering, its log still has `o` entries. -/
def acksHold (s : System Op Output St) : Bool :=
  s.sent.all fun (_, msg) =>
    match msg with
    | .prepareOk v o q =>
      match s.replicas[q]? with
      | none => true
      | some r => decide (v ≤ r.lastNormalView) &&
          (r.lastNormalView != v || r.status == .recovering || decide (o ≤ r.log.length))
    | _ => true

/-- `Prepare` and `Commit` never go to the primary of their view. -/
def primaryMessagesToOthers (s : System Op Output St) : Bool :=
  s.sent.all fun (to, msg) =>
    match msg with
    | .prepare v _ _ _ _ _ => to != s.config.primaryId v
    | .commit v _ => to != s.config.primaryId v
    | _ => true

/-- The primary of a view holds the longest log of the view for as long as
that view is its last normal one and it is not recovering: every fragment
of the view, every log of a replica last normal in it, and every op
acknowledged in it is within its log. -/
def primaryLongest (s : System Op Output St) : Bool :=
  s.replicas.all fun p =>
    p.status == .recovering || p.selfId != s.config.primaryId p.lastNormalView ||
    ((fragments s).all fun (v, off, entries) =>
      v != p.lastNormalView || decide (off + entries.length ≤ p.log.length)) &&
    (s.replicas.all fun q =>
      q.lastNormalView != p.lastNormalView || q.status == .recovering || decide (q.log.length ≤ p.log.length)) &&
    (s.sent.all fun (_, msg) =>
      match msg with
      | .prepareOk v o _ => v != p.lastNormalView || decide (o ≤ p.log.length)
      | _ => true)

/-- The log a `StartView` carries extends the log its view was started
from: the best of a quorum of dvcs, by (last normal view, length), which
the ghost history `started` records. -/
def startViewChosen (s : System Op Output St) : Bool :=
  s.sent.all fun (_, msg) =>
    match msg with
    | .startView v log _ _ =>
      s.started.any fun (v', dvcs) =>
        v' == v && decide (s.config.quorum ≤ dvcs.length) &&
        match Replica.bestDoViewChange dvcs with
        | none => false
        | some best => best.log.isPrefixOf log
    | _ => true

/-- Every DoViewChange a view was started from covers every op its sender
acknowledged in the view the dvc is from. -/
def startedDoViewChangesCover (s : System Op Output St) : Bool :=
  s.started.all fun (_, dvcs) => dvcs.all fun (q, dvc) =>
    s.sent.all fun (_, m) =>
      match m with
      | .prepareOk v o q' => v != dvc.lastNormalView || q' != q || decide (o ≤ dvc.log.length)
      | _ => true

/-- A DoViewChange's log covers every op its sender acknowledged in the view the
dvc is from. -/
def doViewChangesCover (s : System Op Output St) : Bool :=
  s.sent.all fun (_, msg) =>
    match msg with
    | .doViewChange _ q l vlog _ _ =>
      s.sent.all fun (_, m) =>
        match m with
        | .prepareOk v o q' => v != l || q' != q || decide (o ≤ vlog.length)
        | _ => true
    | _ => true

/-- No message a replica sent carries a view beyond the replica's current
one. -/
def messagesBelowView (s : System Op Output St) : Bool :=
  s.sent.all fun (_, msg) =>
    let check (q : ReplicaId) (v : ViewNumber) : Bool :=
      match s.replicas[q]? with
      | none => true
      | some r => decide (v ≤ r.viewNumber)
    match msg with
    | .prepareOk v _ q => check q v
    | .getState q v _ => check q v
    | .startViewChange v q => check q v
    | .doViewChange v q _ _ _ _ => check q v
    | .recovery q _ v => check q v
    | .recoveryResponse v _ q _ => check q v
    | _ => true

/-- A recovery state covers every op the recovering replica acknowledged
in that view before it crashed. -/
def recoveryCoversAcks (s : System Op Output St) : Bool :=
  s.replicas.all fun q =>
    q.status != .recovering ||
    s.sent.all fun (_, msg) =>
      match msg with
      | .recoveryResponse v nonce _ (some st) =>
        nonce != q.recoveryNonce ||
        s.sent.all fun (_, m) =>
          match m with
          | .prepareOk v' o q' => v' != v || q' != q.selfId || decide (o ≤ st.log.length)
          | _ => true
      | _ => true

/-- Every entry a replica holds is covered by a message fragment of its
last normal view: nothing is in a log that was not sent. -/
def covered (s : System Op Output St) : Bool :=
  let msgFragments := (fragments s).take ((fragments s).length - s.replicas.length)
  s.replicas.all fun r => (List.range r.log.length).all fun i =>
    msgFragments.any fun (v, off, entries) =>
      v == r.lastNormalView && decide (off ≤ i) && decide (i < off + entries.length)

/-- Two replicas with the same last normal view agree wherever their logs
overlap. -/
def replicasAgree (s : System Op Output St) : Bool :=
  s.replicas.all fun r => s.replicas.all fun q =>
    r.lastNormalView != q.lastNormalView ||
    (List.range (min r.log.length q.log.length)).all fun i => r.log[i]? == q.log[i]?

/-- Every started view has a `StartView` message, and every view above 0
that anything refers to was started. -/
def startedViews (s : System Op Output St) : Bool :=
  (s.started.all fun (v, _) => s.sent.any fun (_, msg) =>
    match msg with
    | .startView v' _ _ _ => v' == v
    | _ => false) &&
  (((fragments s).take ((fragments s).length - s.replicas.length)).all fun (v, _, _) =>
    v == 0 || s.started.any fun (v', _) => v' == v) &&
  (s.replicas.all fun r => r.status == .recovering || r.lastNormalView == 0 ||
    s.started.any fun (v', _) => v' == r.lastNormalView)

/-! ### Candidates: layer 5, committed entries cross view changes -/

/-- Whatever `r` has committed is held, at its index, by every log of a
later normal view: `StartView` logs, `DoViewChange` dvcs, and replicas. -/
def committedSurvives (s : System Op Output St) : Bool :=
  s.replicas.all fun r => (List.range r.commitNumber).all fun i =>
    (s.sent.all fun (_, msg) =>
      match msg with
      | .startView v' log _ _ => decide (v' ≤ r.lastNormalView) || log[i]? == r.log[i]?
      | .doViewChange _ _ l log _ _ => decide (l ≤ r.lastNormalView) || log[i]? == r.log[i]?
      | .recoveryResponse v' _ _ (some st) => decide (v' ≤ r.lastNormalView) || st.log[i]? == r.log[i]?
      | .newState v' log a _ _ =>
        decide (v' ≤ r.lastNormalView) || decide (i < a) || log[i - a]? == r.log[i]?
      | .prepare v' o c n op _ =>
        decide (v' ≤ r.lastNormalView) || o != i + 1 || some (⟨c, n, op⟩ : LogEntry Op) == r.log[i]?
      | _ => true) &&
    (s.started.all fun (_, dvcs) => dvcs.all fun (_, dvc) =>
      decide (dvc.lastNormalView ≤ r.lastNormalView) || dvc.log[i]? == r.log[i]?) &&
    (s.replicas.all fun q =>
      decide (q.lastNormalView ≤ r.lastNormalView) || q.status == .recovering ||
        q.log[i]? == r.log[i]?)

/-! ### Candidates: what the induction needed -/

/-- Every `DoViewChange`, sent or started from: `(view, sender, body)`. -/
def dvcs (s : System Op Output St) : List (ViewNumber × ReplicaId × DoViewChange Op) :=
  (s.sent.filterMap fun (_, msg) =>
    match msg with
    | .doViewChange u x l log _ k => some (u, x, ⟨l, log, k⟩)
    | _ => none) ++
  (s.started.flatMap fun (u, ds) => ds.map fun (x, d) => (u, x, d))

/-- `DvcBehind`. -/
def dvcBehind (s : System Op Output St) : Bool :=
  (dvcs s).all fun (u, _, d) => decide (d.lastNormalView < u)

/-- `DvcBelowView`. -/
def dvcBelowView (s : System Op Output St) : Bool :=
  (dvcs s).all fun (u, x, _) =>
    match s.replicas[x]? with
    | none => true
    | some r => decide (u ≤ r.viewNumber)

/-- `DvcAfterAcks`. -/
def dvcAfterAcks (s : System Op Output St) : Bool :=
  (dvcs s).all fun (u, x, d) =>
    s.sent.all fun (_, m) =>
      match m with
      | .prepareOk v _ q => q != x || decide (u ≤ v) || decide (v ≤ d.lastNormalView)
      | _ => true

/-- `DvcAfterOwnView`. -/
def dvcAfterOwnView (s : System Op Output St) : Bool :=
  (dvcs s).all fun (u, x, d) =>
    s.started.all fun (v, _) =>
      x != s.config.primaryId v || decide (u ≤ v) || decide (v ≤ d.lastNormalView)

/-- `DvcPrimaryCovers`. -/
def dvcPrimaryCovers (s : System Op Output St) : Bool :=
  (dvcs s).all fun (_, x, d) =>
    x != s.config.primaryId d.lastNormalView ||
    (fragments s).all fun (v, off, entries) =>
      v != d.lastNormalView || decide (off + entries.length ≤ d.log.length)

/-- `ViewChangeBehind`. -/
def viewChangeBehind (s : System Op Output St) : Bool :=
  s.replicas.all fun r => r.status != .viewChange || decide (r.lastNormalView < r.viewNumber)

/-- `PrimaryStartedNormal`. -/
def primaryStartedNormal (s : System Op Output St) : Bool :=
  s.started.all fun (v, _) =>
    match s.replicas[s.config.primaryId v]? with
    | none => true
    | some p => decide (v ≤ p.lastNormalView)

/-- `StartedOnce`. -/
def startedOnce (s : System Op Output St) : Bool :=
  s.started.all fun (v, d1) => s.started.all fun (v', d2) => v != v' || d1 == d2

/-- `ViewExtendsBase`. -/
def viewExtendsBase (s : System Op Output St) : Bool :=
  s.started.all fun (v, ds) =>
    match Replica.bestDoViewChange ds with
    | none => false
    | some b =>
      ((dvcs s).all fun (_, _, d) => d.lastNormalView != v || decide (b.log.length ≤ d.log.length)) &&
      (s.sent.all fun (_, msg) =>
        match msg with
        | .recoveryResponse v' _ _ (some st) => v' != v || decide (b.log.length ≤ st.log.length)
        | .newState v' _ _ e _ => v' != v || decide (b.log.length ≤ e)
        | _ => true) &&
      (s.replicas.all fun r =>
        r.lastNormalView != v || r.status == .recovering || decide (b.log.length ≤ r.log.length))

/-- `AcksStarted`. -/
def acksStarted (s : System Op Output St) : Bool :=
  s.sent.all fun (_, msg) =>
    match msg with
    | .prepareOk u _ _ => u == 0 || s.started.any fun (v, _) => v == u
    | _ => true

/-- `StartViewChangePos`. -/
def startViewChangePos (s : System Op Output St) : Bool :=
  s.sent.all fun (_, msg) =>
    match msg with
    | .startViewChange v _ => decide (0 < v)
    | _ => true

/-- `TransferNotPrimary`. -/
def transferNotPrimary (s : System Op Output St) : Bool :=
  s.replicas.all fun r => r.status != .stateTransfer || r.selfId != s.config.primaryId r.viewNumber

/-- `RecoveryStateFromPrimary`. -/
def recoveryStateFromPrimary (s : System Op Output St) : Bool :=
  s.sent.all fun (_, msg) =>
    match msg with
    | .recoveryResponse v _ q (some _) => q == s.config.primaryId v
    | _ => true

/-- `RecoveryResponseNotSelf`. -/
def recoveryResponseNotSelf (s : System Op Output St) : Bool :=
  s.sent.all fun (_, msg) =>
    match msg with
    | .recoveryResponse _ n p _ =>
      s.replicas.all fun q => q.status != .recovering || q.recoveryNonce != n || p != q.selfId
    | _ => true

/-- `ReplicaCount`. -/
def replicaCount (s : System Op Output St) : Bool := s.replicas.length == s.config.replicaCount

/-- `SenderIds`. -/
def senderIds (s : System Op Output St) : Bool :=
  s.sent.all fun (_, msg) =>
    match msg with
    | .prepareOk _ _ q => decide (q < s.config.replicaCount)
    | .getState q _ _ => decide (q < s.config.replicaCount)
    | .startViewChange _ q => decide (q < s.config.replicaCount)
    | .doViewChange _ q _ _ _ _ => decide (q < s.config.replicaCount)
    | .recovery q _ _ => decide (q < s.config.replicaCount)
    | .recoveryResponse _ _ q _ => decide (q < s.config.replicaCount)
    | _ => true

/-- `StartedIds`. -/
def startedIds (s : System Op Output St) : Bool :=
  s.started.all fun (_, dvcs) => dvcs.all fun (x, _) => decide (x < s.config.replicaCount)

/-- `RecordedDvcs`. -/
def recordedDvcs (s : System Op Output St) : Bool :=
  s.replicas.all fun r =>
    r.status != .viewChange ||
    (decide ((r.doViewChangeFrom.map Prod.fst).Pairwise (· < ·)) &&
     r.doViewChangeFrom.all fun (x, d) =>
      decide (x < s.config.replicaCount) &&
      ((x == r.selfId && d == ⟨r.lastNormalView, r.log, r.commitNumber⟩) ||
       s.sent.any fun (_, msg) =>
        match msg with
        | .doViewChange v x' l log o k =>
          v == r.viewNumber && x' == x && l == d.lastNormalView && log == d.log && o == d.log.length &&
            k == d.commitNumber
        | _ => false))

/-- `RecordedRRs`. -/
def recordedRRs (s : System Op Output St) : Bool :=
  s.replicas.all fun r =>
    r.status != .recovering ||
    r.recoveryResponses.all fun (x, resp) =>
      s.sent.any fun (_, msg) =>
        match msg with
        | .recoveryResponse v n x' st =>
          v == resp.viewNumber && n == r.recoveryNonce && x' == x && st == resp.state
        | _ => false

/-- `RecoveryResponseNonce`. -/
def recoveryResponseNonce (s : System Op Output St) : Bool :=
  s.sent.all fun (_, msg) =>
    match msg with
    | .recoveryResponse _ n _ _ =>
      s.sent.any fun (_, m) =>
        match m with
        | .recovery _ n' _ => n' == n
        | _ => false
    | _ => true

/-! ### All together -/

/-- Every check, by name. -/
def all (s : System Op Output St) : List (String × Bool) :=
  [ ("local", s.replicas.all localInv),
    ("wf", s.sent.all fun (_, msg) => wf msg),
    ("drained", drained s),
    ("no_panic", noPanic s),
    ("commit_bounded", commitBounded s),
    ("prefix_agreement", prefixAgreement s),
    ("durability", durability s),
    ("one_log_per_view", oneLogPerView s),
    ("committed_acked", committedAcked s),
    ("committed_survives", committedSurvives s),
    ("message_commits_backed", messageCommitsBacked s),
    ("acks_current", acksCurrent s),
    ("catching_up_not_primary", catchingUpNotPrimary s),
    ("acks_hold", acksHold s),
    ("primary_messages_to_others", primaryMessagesToOthers s),
    ("primary_longest", primaryLongest s),
    ("covered", covered s),
    ("replicas_agree", replicasAgree s),
    ("started_views", startedViews s),
    ("start_view_chosen", startViewChosen s),
    ("started_do_view_change_cover", startedDoViewChangesCover s),
    ("do_view_change_cover", doViewChangesCover s),
    ("messages_below_view", messagesBelowView s),
    ("recovery_covers_acks", recoveryCoversAcks s),
    ("dvc_behind", dvcBehind s),
    ("dvc_below_view", dvcBelowView s),
    ("dvc_after_acks", dvcAfterAcks s),
    ("dvc_after_own_view", dvcAfterOwnView s),
    ("dvc_primary_covers", dvcPrimaryCovers s),
    ("view_change_behind", viewChangeBehind s),
    ("primary_started_normal", primaryStartedNormal s),
    ("started_once", startedOnce s),
    ("view_extends_base", viewExtendsBase s),
    ("recovery_response_nonce", recoveryResponseNonce s),
    ("acks_started", acksStarted s),
    ("start_view_change_pos", startViewChangePos s),
    ("transfer_not_primary", transferNotPrimary s),
    ("recovery_state_from_primary", recoveryStateFromPrimary s),
    ("recovery_response_not_self", recoveryResponseNotSelf s),
    ("replica_count", replicaCount s),
    ("sender_ids", senderIds s),
    ("started_ids", startedIds s),
    ("recorded_dvcs", recordedDvcs s),
    ("recorded_rrs", recordedRRs s) ]

/-- The names of the checks that fail. -/
def violations (s : System Op Output St) : List String :=
  (all s).filterMap fun (name, ok) => if ok then none else some name

end Vsr.Check
