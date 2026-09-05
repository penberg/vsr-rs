import Vsr.WellFormed
import Vsr.System
import Vsr.Liveness

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
      decide (o ≤ r.log.length) && acked.all fun q =>
        q == r.selfId || s.sent.any fun (_, msg) =>
          match msg with
          | .prepareOk v o' q' => v == r.viewNumber && o' == o && q' == q
          | _ => false

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

/-- The primary of view `v`, while normal in `v`, holds the longest log of
the view: every fragment of `v`, every log of a replica whose last normal
view is `v`, and every op acknowledged in `v` is within its log. -/
def primaryLongest (s : System Op Output St) : Bool :=
  s.replicas.all fun p =>
    !(p.status == .normal && p.isPrimary) ||
    ((fragments s).all fun (v, off, entries) =>
      v != p.viewNumber || decide (off + entries.length ≤ p.log.length)) &&
    (s.replicas.all fun q =>
      q.lastNormalView != p.viewNumber || q.status == .recovering || decide (q.log.length ≤ p.log.length)) &&
    (s.sent.all fun (_, msg) =>
      match msg with
      | .prepareOk v o _ => v != p.viewNumber || decide (o ≤ p.log.length)
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

/-! ### Liveness on the synchronous network -/

/-- Rounds a cluster gets to settle. The backoff doubles per failed view
change, up to ten doublings of the primary timeout, so a cluster deep in
backoff legitimately needs a while. -/
def livenessBound : Nat := 1000

/-- `Vsr.settles`, bounded: from this state, with whatever was in flight
lost, a cluster with a quorum not recovering settles within
`livenessBound` rounds. -/
def liveness (m : Machine Op Output St) (s : System Op Output St) : Bool :=
  let participants := (s.replicas.filter fun r => r.status != .recovering).length
  decide (participants < s.config.quorum) || Sync.settledWithin m livenessBound (Sync.ofSystem s)

/-! ### All together -/

/-- Every check, by name. -/
def all (m : Machine Op Output St) (s : System Op Output St) : List (String × Bool) :=
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
    ("liveness", liveness m s) ]

/-- The names of the checks that fail. -/
def violations (m : Machine Op Output St) (s : System Op Output St) : List String :=
  (all m s).filterMap fun (name, ok) => if ok then none else some name

end Vsr.Check
