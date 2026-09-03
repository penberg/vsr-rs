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
  let voters := s.replicas.filter fun o => o.status != .recovering
  voters.all fun r => (List.range r.commitNumber).all fun i =>
    decide (voters.length + 1 - s.config.quorum ≤
      (voters.filter fun o => o.log[i]? == r.log[i]?).length)

/-! ### Candidates: layer 3, one log per view -/

/-- Every piece of a view's log the system holds: `(view, offset, entries)`.
A `Prepare` is one entry at its op number; `NewState` a segment; `StartView`,
a `DoViewChange` vote, and a primary's recovery state whole logs; and each
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

/-! ### Candidates: layer 5, committed entries cross view changes -/

/-- Whatever `r` has committed is held, at its index, by every log of a
later normal view: `StartView` logs, `DoViewChange` votes, and replicas. -/
def committedSurvives (s : System Op Output St) : Bool :=
  s.replicas.all fun r => (List.range r.commitNumber).all fun i =>
    (s.sent.all fun (_, msg) =>
      match msg with
      | .startView v' log _ _ => decide (v' ≤ r.lastNormalView) || log[i]? == r.log[i]?
      | .doViewChange _ _ l log _ _ => decide (l ≤ r.lastNormalView) || log[i]? == r.log[i]?
      | _ => true) &&
    (s.replicas.all fun q =>
      decide (q.lastNormalView ≤ r.lastNormalView) || q.status == .recovering ||
        q.log[i]? == r.log[i]?)

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
    ("committed_survives", committedSurvives s) ]

/-- The names of the checks that fail. -/
def violations (s : System Op Output St) : List String :=
  (all s).filterMap fun (name, ok) => if ok then none else some name

end Vsr.Check
