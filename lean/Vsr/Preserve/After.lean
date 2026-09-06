import Vsr.Invariant

/-!
The shape of a step, and what a step has to establish.

A step at replica `id` replaces it by `r'`, appends what it sent to `sent`,
and appends the view it started, if any, to `started`: `System.after`.
Everything old transfers to the new state by monotonicity of the history;
what a handler has to show is confined to the new replica, the new
messages, and the new started view, and `StepOK` lists exactly that, one
field per clause of `Inv`. `Inv.after` then gives `Inv` afterwards.
-/

namespace Vsr

variable {Op Output St : Type}

/-! ### The shape -/

/-- The system after a step: replica `id` replaced, `out` sent, `st`
started. -/
def System.after (s : System Op Output St) (id : ReplicaId) (r' : Replica Op Output St)
    (out : List (ReplicaId × Message Op))
    (st : List (ViewNumber × List (ReplicaId × DoViewChange Op))) : System Op Output St :=
  { s with replicas := s.replicas.set id r', sent := s.sent ++ out, started := s.started ++ st }

@[simp] theorem System.after_replicas (s : System Op Output St) (id r' out st) :
    (s.after id r' out st).replicas = s.replicas.set id r' := rfl
@[simp] theorem System.after_sent (s : System Op Output St) (id r' out st) :
    (s.after id r' out st).sent = s.sent ++ out := rfl
@[simp] theorem System.after_started (s : System Op Output St) (id r' out st) :
    (s.after id r' out st).started = s.started ++ st := rfl
@[simp] theorem System.after_config (s : System Op Output St) (id r' out st) :
    (s.after id r' out st).config = s.config := rfl

/-- A replica with its outbox, replies, and started view taken. -/
def Replica.clear (r : Replica Op Output St) : Replica Op Output St :=
  { r with outbox := [], replies := [], chosenDoViewChanges := none }

/-- The view a replica started, as the list `drain` appends. -/
def Replica.startedList (r : Replica Op Output St) :
    List (ViewNumber × List (ReplicaId × DoViewChange Op)) :=
  match r.chosenDoViewChanges with
  | some dvcs => [(r.viewNumber, dvcs)]
  | none => []

theorem System.drain_eq_after (s : System Op Output St) (id : ReplicaId) (r : Replica Op Output St) :
    s.drain id r = { s.after id r.clear r.outbox r.startedList with replies := s.replies ++ r.replies } := by
  unfold System.drain System.after Replica.clear Replica.startedList
  rfl

/-- `Inv` depends only on the configuration, the replicas, `sent`, and
`started`; in particular not on the replies. -/
theorem Inv.transport {s s' : System Op Output St} (h : Inv s) (hc : s'.config = s.config)
    (hr : s'.replicas = s.replicas) (hs : s'.sent = s.sent) (hst : s'.started = s.started) : Inv s' := by
  have fS : ∀ x ∈ s.sent, x ∈ s'.sent := fun x hx => by rw [hs]; exact hx
  have fS' : ∀ x ∈ s'.sent, x ∈ s.sent := fun x hx => by rw [← hs]; exact hx
  have fT : ∀ x ∈ s.started, x ∈ s'.started := fun x hx => by rw [hst]; exact hx
  have fT' : ∀ x ∈ s'.started, x ∈ s.started := fun x hx => by rw [← hst]; exact hx
  have hSent : ∀ to msg, Sent s' to msg ↔ Sent s to msg := fun to msg => by simp only [Sent, hs]
  have hStarted : ∀ x, x ∈ s'.started ↔ x ∈ s.started := fun x => by rw [hst]
  have hFrag : ∀ v off log, Frag s' v off log ↔ Frag s v off log := fun v off log =>
    ⟨Frag.mono fS' fT', Frag.mono fS fT⟩
  have hHolds : ∀ v i e, Holds s' v i e ↔ Holds s v i e := fun v i e =>
    ⟨Holds.mono fS' fT', Holds.mono fS fT⟩
  have hDvc : ∀ u x d, DvcOf s' u x d ↔ DvcOf s u x d := fun u x d =>
    ⟨DvcOf.mono fS' fT', DvcOf.mono fS fT⟩
  have hBacked : ∀ v k, Backed s' v k ↔ Backed s v k := fun v k =>
    ⟨Backed.mono fS' fT' hc.symm, Backed.mono fS fT hc⟩
  have hComm : ∀ v i e, Committed s' v i e ↔ Committed s v i e := fun v i e =>
    ⟨Committed.mono fS' fT' hc.symm, Committed.mono fS fT hc⟩
  have hMsg : ∀ msg, MsgBacked s' msg ↔ MsgBacked s msg := fun msg =>
    ⟨MsgBacked.mono fS' fT' hc.symm, MsgBacked.mono fS fT hc⟩
  obtain ⟨noPanic, ids, local_, drained, wf, oneLog, backed, survives, acks, catching, acksHold, toOthers,
    longest, chosen, dvcCovers, dvcBehind, dvcBelow, dvcAfterAcks, dvcAfterOwn, dvcPrimary, vcBehind,
    primaryStarted, startedOnce, extendsBase, rrNonce, acksStarted, svcPos, transferNotPrimary, rrPrimary,
    rrNotSelf, count, senderIds, startedIds, recordedDvcs, recordedRRs, belowView, recoveryCovers, covered,
    agree, startedViews, clean, two⟩ := h
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_,
    ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro x hx; exact noPanic x (hr ▸ hx)
  · intro i x hx; rw [hr] at hx; exact ⟨(ids i x hx).1, hc ▸ (ids i x hx).2⟩
  · intro x hx; exact local_ x (hr ▸ hx)
  · intro x hx; exact drained x (hr ▸ hx)
  · intro x hx; exact wf x (fS' x hx)
  · exact ⟨fun v i e e' h1 h2 => oneLog.1 v i e e' ((hHolds ..).mp h1) ((hHolds ..).mp h2),
      fun z hz i e e' he hh => oneLog.2 z (hr ▸ hz) i e e' he ((hHolds ..).mp hh)⟩
  · exact ⟨fun z hz => (hBacked ..).mpr (backed.1 z (hr ▸ hz)),
      fun to msg hm => (hMsg _).mpr (backed.2 to msg ((hSent ..).mp hm))⟩
  · intro v' i e hcm v hlt
    obtain ⟨h1, h2, h3, h4, h5, h6⟩ := survives v' i e ((hComm ..).mp hcm) v hlt
    exact ⟨fun to log o k hs => h1 to log o k ((hSent ..).mp hs),
      fun u x d hd hl => h2 u x d ((hDvc ..).mp hd) hl,
      fun to n q stt hs => h3 to n q stt ((hSent ..).mp hs),
      fun to log a b k hs ha => h4 to log a b k ((hSent ..).mp hs) ha,
      fun to c n op k hs => h5 to c n op k ((hSent ..).mp hs),
      fun z hz => h6 z (hr ▸ hz)⟩
  · intro z hz hn hp oa hoa
    obtain ⟨c1, c0, c2⟩ := acks z (hr ▸ hz) hn hp oa hoa
    exact ⟨c1, c0, fun q hq => ⟨hc ▸ (c2 q hq).1, (c2 q hq).2.imp (fun h => h)
      (fun ⟨to, ht⟩ => ⟨to, (hSent ..).mpr ht⟩)⟩⟩
  · intro z hz; exact catching z (hr ▸ hz)
  · intro to v o q hs z hz; exact acksHold to v o q ((hSent ..).mp hs) z (hr ▸ hz)
  · intro to msg hs; have := toOthers to msg ((hSent ..).mp hs); revert this; cases msg <;> simp_all
  · intro p hp hn hpp
    rw [hc] at hpp
    obtain ⟨f1, f2, f3⟩ := longest p (hr ▸ hp) hn hpp
    exact ⟨fun off log hf => f1 off log ((hFrag ..).mp hf),
      fun q hq hl hn' => f2 q (hr ▸ hq) hl hn', fun to o q hs => f3 to o q ((hSent ..).mp hs)⟩
  · intro to v log o k hs
    obtain ⟨dvcs, best, h1, h2, h3, h4, h5⟩ := chosen to v log o k ((hSent ..).mp hs)
    exact ⟨dvcs, best, (hStarted _).mpr h1, hc ▸ h2, h3, h4, h5⟩
  · intro u x d hd to o hs; exact dvcCovers u x d ((hDvc ..).mp hd) to o ((hSent ..).mp hs)
  · intro u x d hd; exact dvcBehind u x d ((hDvc ..).mp hd)
  · intro u x d hd z hz; exact dvcBelow u x d ((hDvc ..).mp hd) z (hr ▸ hz)
  · intro u x d hd to v o hs; exact dvcAfterAcks u x d ((hDvc ..).mp hd) to v o ((hSent ..).mp hs)
  · intro u x d hd v dvcs hv hx; rw [hc] at hx
    exact dvcAfterOwn u x d ((hDvc ..).mp hd) v dvcs ((hStarted _).mp hv) hx
  · intro u x d hd hx off log hf; rw [hc] at hx
    exact dvcPrimary u x d ((hDvc ..).mp hd) hx off log ((hFrag ..).mp hf)
  · intro z hz; exact vcBehind z (hr ▸ hz)
  · intro v dvcs hv p hp hpp; rw [hc] at hpp
    exact primaryStarted v dvcs ((hStarted _).mp hv) p (hr ▸ hp) hpp
  · intro v d1 d2 h1 h2; exact startedOnce v d1 d2 ((hStarted _).mp h1) ((hStarted _).mp h2)
  · intro v dvcs b hv hb
    obtain ⟨e1, e2, e3, e4⟩ := extendsBase v dvcs b ((hStarted _).mp hv) hb
    exact ⟨fun u x d hd hl => e1 u x d ((hDvc ..).mp hd) hl,
      fun to n q stt hs => e2 to n q stt ((hSent ..).mp hs),
      fun to log a e k hs => e3 to log a e k ((hSent ..).mp hs),
      fun z hz => e4 z (hr ▸ hz)⟩
  · intro to v n q stt hs
    obtain ⟨to', i, v', h'⟩ := rrNonce to v n q stt ((hSent ..).mp hs)
    exact ⟨to', i, v', (hSent ..).mpr h'⟩
  · intro to u o q hs hu
    obtain ⟨dvcs, hd⟩ := acksStarted to u o q ((hSent ..).mp hs) hu
    exact ⟨dvcs, (hStarted _).mpr hd⟩
  · intro to v q hs; exact svcPos to v q ((hSent ..).mp hs)
  · intro z hz hs; rw [hc]; exact transferNotPrimary z (hr ▸ hz) hs
  · intro to v n q stt hs; rw [hc]; exact rrPrimary to v n q stt ((hSent ..).mp hs)
  · intro to v n p stt hs q hq; exact rrNotSelf to v n p stt ((hSent ..).mp hs) q (hr ▸ hq)
  · show s'.replicas.length = s'.config.replicaCount; rw [hr, hc]; exact count
  · intro to msg hs; have := senderIds to msg ((hSent ..).mp hs); rw [hc]; exact this
  · intro v dvcs hv x d hd; rw [hc]; exact startedIds v dvcs ((hStarted _).mp hv) x d hd
  · intro z hz hs
    obtain ⟨h1, h2⟩ := recordedDvcs z (hr ▸ hz) hs
    refine ⟨h1, fun x d hd => ⟨hc ▸ (h2 x d hd).1, (h2 x d hd).2.imp (fun ⟨dst, h⟩ => ⟨dst, (hSent ..).mpr h⟩) (fun h => h)⟩⟩
  · intro z hz hs x resp hx
    obtain ⟨dst, h⟩ := recordedRRs z (hr ▸ hz) hs x resp hx
    exact ⟨dst, (hSent ..).mpr h⟩
  · intro to msg hs z hz; exact belowView to msg ((hSent ..).mp hs) z (hr ▸ hz)
  · intro q hq hqr to v n p stt hs hn to' o hs'
    exact recoveryCovers q (hr ▸ hq) hqr to v n p stt ((hSent ..).mp hs) hn to' o ((hSent ..).mp hs')
  · intro z hz i hi
    obtain ⟨e, he⟩ := covered z (hr ▸ hz) i hi
    exact ⟨e, (hHolds ..).mpr he⟩
  · intro z hz w hw; exact agree z (hr ▸ hz) w (hr ▸ hw)
  · obtain ⟨g1, g2, g3⟩ := startedViews
    refine ⟨fun v dvcs hv => ?_, fun v off log hf hpos => ?_, fun z hz hzr hzv => ?_⟩
    · obtain ⟨to, log, o, k, h'⟩ := g1 v dvcs ((hStarted _).mp hv)
      exact ⟨to, log, o, k, (hSent ..).mpr h'⟩
    · exact (g2 v off log ((hFrag ..).mp hf) hpos).imp fun dvcs hd => (hStarted _).mpr hd
    · exact (g3 z (hr ▸ hz) hzr hzv).imp fun dvcs hd => (hStarted _).mpr hd
  · intro z hz; exact clean z (hr ▸ hz)
  · show 2 ≤ s'.config.replicaCount; rw [hc]; exact two

/-- `Inv` says nothing about the replies. -/
theorem Inv.withReplies {s : System Op Output St} (h : Inv s) (x : List (Reply Output)) :
    Inv { s with replies := x } :=
  h.transport rfl rfl rfl rfl

section Clear
variable (r : Replica Op Output St)
@[simp] theorem Replica.clear_status : r.clear.status = r.status := rfl
@[simp] theorem Replica.clear_viewNumber : r.clear.viewNumber = r.viewNumber := rfl
@[simp] theorem Replica.clear_lastNormalView : r.clear.lastNormalView = r.lastNormalView := rfl
@[simp] theorem Replica.clear_commitNumber : r.clear.commitNumber = r.commitNumber := rfl
@[simp] theorem Replica.clear_log : r.clear.log = r.log := rfl
@[simp] theorem Replica.clear_catchingUp : r.clear.catchingUp = r.catchingUp := rfl
@[simp] theorem Replica.clear_selfId : r.clear.selfId = r.selfId := rfl
@[simp] theorem Replica.clear_config : r.clear.config = r.config := rfl
@[simp] theorem Replica.clear_acks : r.clear.acks = r.acks := rfl
@[simp] theorem Replica.clear_recoveryNonce : r.clear.recoveryNonce = r.recoveryNonce := rfl
@[simp] theorem Replica.clear_panicked : r.clear.panicked = r.panicked := rfl
@[simp] theorem Replica.clear_outbox : r.clear.outbox = [] := rfl
@[simp] theorem Replica.clear_replies : r.clear.replies = [] := rfl
@[simp] theorem Replica.clear_chosenDoViewChanges : r.clear.chosenDoViewChanges = none := rfl
@[simp] theorem Replica.clear_isPrimary : r.clear.isPrimary = r.isPrimary := rfl
@[simp] theorem Replica.clear_primaryId : r.clear.primaryId = r.primaryId := rfl
theorem Replica.LocalInv.clear {r : Replica Op Output St} (h : Replica.LocalInv r) : Replica.LocalInv r.clear := by
  simpa [Replica.LocalInv] using h
end Clear

/-! ### Decomposing the new state -/

/-- The fragment a message contributes, if any. -/
inductive MsgFrag : ReplicaId × Message Op → ViewNumber → Nat → List (LogEntry Op) → Prop
  | prepare {to v o c n op k} : MsgFrag (to, .prepare v o c n op k) v (o - 1) [⟨c, n, op⟩]
  | newState {to v log a b k} : MsgFrag (to, .newState v log a b k) v a log
  | startView {to v log o k} : MsgFrag (to, .startView v log o k) v 0 log
  | dvc {to v r l log o k} : MsgFrag (to, .doViewChange v r l log o k) l 0 log
  | recovery {to v n r st} : MsgFrag (to, .recoveryResponse v n r (some st)) v 0 st.log

/-- The fragments a step adds: from its messages, and from the DoViewChanges
of the view it started. -/
def FragNew (out : List (ReplicaId × Message Op))
    (st : List (ViewNumber × List (ReplicaId × DoViewChange Op)))
    (v : ViewNumber) (off : Nat) (log : List (LogEntry Op)) : Prop :=
  (∃ x ∈ out, MsgFrag x v off log) ∨
  (∃ (u : ViewNumber) (dvcs : List (ReplicaId × DoViewChange Op)) (q : ReplicaId) (d : DoViewChange Op),
    (u, dvcs) ∈ st ∧ (q, d) ∈ dvcs ∧ v = d.lastNormalView ∧ off = 0 ∧ log = d.log)

def HoldsNew (out : List (ReplicaId × Message Op))
    (st : List (ViewNumber × List (ReplicaId × DoViewChange Op)))
    (v : ViewNumber) (i : Nat) (e : LogEntry Op) : Prop :=
  ∃ off log, FragNew out st v off log ∧ off ≤ i ∧ log[i - off]? = some e

def DvcOfNew (out : List (ReplicaId × Message Op))
    (st : List (ViewNumber × List (ReplicaId × DoViewChange Op)))
    (u : ViewNumber) (x : ReplicaId) (d : DoViewChange Op) : Prop :=
  (∃ to, (to, Message.doViewChange u x d.lastNormalView d.log d.log.length d.commitNumber) ∈ out) ∨
  (∃ dvcs, (u, dvcs) ∈ st ∧ (x, d) ∈ dvcs)

section Decompose
variable {s : System Op Output St} {id : ReplicaId} {r' : Replica Op Output St}
  {out : List (ReplicaId × Message Op)} {st : List (ViewNumber × List (ReplicaId × DoViewChange Op))}

theorem FragNew.ofMsg {x : ReplicaId × Message Op} {v off log} (hx : x ∈ out) (h : MsgFrag x v off log) :
    FragNew out st v off log := Or.inl ⟨x, hx, h⟩
theorem FragNew.ofStarted {u dvcs q} {d : DoViewChange Op} (h1 : (u, dvcs) ∈ st) (h2 : (q, d) ∈ dvcs) :
    FragNew out st d.lastNormalView 0 d.log := Or.inr ⟨u, dvcs, q, d, h1, h2, rfl, rfl, rfl⟩
theorem DvcOfNew.ofMsg {to u x} {d : DoViewChange Op}
    (h : (to, Message.doViewChange u x d.lastNormalView d.log d.log.length d.commitNumber) ∈ out) :
    DvcOfNew out st u x d := Or.inl ⟨to, h⟩
theorem DvcOfNew.ofStarted {u dvcs x} {d : DoViewChange Op} (h1 : (u, dvcs) ∈ st) (h2 : (x, d) ∈ dvcs) :
    DvcOfNew out st u x d := Or.inr ⟨dvcs, h1, h2⟩

theorem sent_after_of {y : ReplicaId × Message Op} (hy : y ∈ s.sent) : y ∈ (s.after id r' out st).sent :=
  List.mem_append_left _ hy
theorem started_after_of {y : ViewNumber × List (ReplicaId × DoViewChange Op)} (hy : y ∈ s.started) :
    y ∈ (s.after id r' out st).started :=
  List.mem_append_left _ hy

theorem Sent.after {to : ReplicaId} {msg : Message Op} :
    Sent (s.after id r' out st) to msg ↔ Sent s to msg ∨ (to, msg) ∈ out := by
  simp [Sent, System.after, List.mem_append]

theorem Sent.after_of {to : ReplicaId} {msg : Message Op} (h : Sent s to msg) :
    Sent (s.after id r' out st) to msg := Sent.after.mpr (Or.inl h)

theorem Sent.after_new {to : ReplicaId} {msg : Message Op} (h : (to, msg) ∈ out) :
    Sent (s.after id r' out st) to msg := Sent.after.mpr (Or.inr h)

theorem mem_started_after {x : ViewNumber × List (ReplicaId × DoViewChange Op)} :
    x ∈ (s.after id r' out st).started ↔ x ∈ s.started ∨ x ∈ st := by
  simp [System.after, List.mem_append]

theorem Frag.after {v off log} :
    Frag (s.after id r' out st) v off log ↔ Frag s v off log ∨ FragNew out st v off log := by
  constructor
  · intro h
    cases h with
    | prepare h =>
      rcases Sent.after.mp h with h | h
      · exact Or.inl (.prepare h)
      · exact Or.inr (FragNew.ofMsg h .prepare)
    | newState h =>
      rcases Sent.after.mp h with h | h
      · exact Or.inl (.newState h)
      · exact Or.inr (FragNew.ofMsg h .newState)
    | startView h =>
      rcases Sent.after.mp h with h | h
      · exact Or.inl (.startView h)
      · exact Or.inr (FragNew.ofMsg h .startView)
    | dvc h =>
      rcases Sent.after.mp h with h | h
      · exact Or.inl (.dvc h)
      · exact Or.inr (FragNew.ofMsg h .dvc)
    | recovery h =>
      rcases Sent.after.mp h with h | h
      · exact Or.inl (.recovery h)
      · exact Or.inr (FragNew.ofMsg h .recovery)
    | started h hv =>
      rcases mem_started_after.mp h with h | h
      · exact Or.inl (.started h hv)
      · exact Or.inr (FragNew.ofStarted h hv)
  · intro h
    rcases h with h | ⟨x, hx, hf⟩ | ⟨u, dvcs, q, d, hst, hd, rfl, rfl, rfl⟩
    · exact Frag.mono (s := s) (s' := s.after id r' out st) (fun _ hy => sent_after_of hy)
        (fun _ hy => started_after_of hy) h
    · cases hf with
      | prepare => exact .prepare (Sent.after_new hx)
      | newState => exact .newState (Sent.after_new hx)
      | startView => exact .startView (Sent.after_new hx)
      | dvc => exact .dvc (Sent.after_new hx)
      | recovery => exact .recovery (Sent.after_new hx)
    · exact .started (mem_started_after.mpr (Or.inr hst)) hd

theorem Holds.after {v i e} :
    Holds (s.after id r' out st) v i e ↔ Holds s v i e ∨ HoldsNew out st v i e := by
  constructor
  · rintro ⟨off, log, hf, hle, hget⟩
    rcases Frag.after.mp hf with hf | hf
    · exact Or.inl ⟨off, log, hf, hle, hget⟩
    · exact Or.inr ⟨off, log, hf, hle, hget⟩
  · rintro (⟨off, log, hf, hle, hget⟩ | ⟨off, log, hf, hle, hget⟩)
    · exact ⟨off, log, Frag.after.mpr (Or.inl hf), hle, hget⟩
    · exact ⟨off, log, Frag.after.mpr (Or.inr hf), hle, hget⟩

theorem Holds.after_of {v i e} (h : Holds s v i e) : Holds (s.after id r' out st) v i e :=
  Holds.after.mpr (Or.inl h)

theorem Frag.after_of {v off log} (h : Frag s v off log) : Frag (s.after id r' out st) v off log :=
  Frag.after.mpr (Or.inl h)

theorem DvcOf.after {u x d} :
    DvcOf (s.after id r' out st) u x d ↔ DvcOf s u x d ∨ DvcOfNew out st u x d := by
  constructor
  · rintro (⟨to, h⟩ | ⟨dvcs, h1, h2⟩)
    · rcases Sent.after.mp h with h | h
      · exact Or.inl (Or.inl ⟨to, h⟩)
      · exact Or.inr (DvcOfNew.ofMsg h)
    · rcases mem_started_after.mp h1 with h1 | h1
      · exact Or.inl (Or.inr ⟨dvcs, h1, h2⟩)
      · exact Or.inr (DvcOfNew.ofStarted h1 h2)
  · rintro ((⟨to, h⟩ | ⟨dvcs, h1, h2⟩) | (⟨to, h⟩ | ⟨dvcs, h1, h2⟩))
    · exact Or.inl ⟨to, Sent.after_of h⟩
    · exact Or.inr ⟨dvcs, mem_started_after.mpr (Or.inl h1), h2⟩
    · exact Or.inl ⟨to, Sent.after_new h⟩
    · exact Or.inr ⟨dvcs, mem_started_after.mpr (Or.inr h1), h2⟩

theorem DvcOf.after_of {u x d} (h : DvcOf s u x d) : DvcOf (s.after id r' out st) u x d :=
  DvcOf.after.mpr (Or.inl h)

theorem Acked.after {v i q} :
    Acked (s.after id r' out st) v i q ↔
      Acked s v i q ∨ ∃ to o, (to, Message.prepareOk v o q) ∈ out ∧ i < o := by
  unfold Acked
  constructor
  · rintro (h | ⟨to, o, hs, hlt⟩)
    · exact Or.inl (Or.inl h)
    · rcases Sent.after.mp hs with hs | hs
      · exact Or.inl (Or.inr ⟨to, o, hs, hlt⟩)
      · exact Or.inr ⟨to, o, hs, hlt⟩
  · rintro ((h | ⟨to, o, hs, hlt⟩) | ⟨to, o, hs, hlt⟩)
    · exact Or.inl h
    · exact Or.inr ⟨to, o, Sent.after_of hs, hlt⟩
    · exact Or.inr ⟨to, o, Sent.after_new hs, hlt⟩

/-- No `PrepareOk` among the new messages. -/
def NoPrepareOk (out : List (ReplicaId × Message Op)) : Prop :=
  ∀ x ∈ out, ∀ v o q, x.2 ≠ Message.prepareOk v o q

theorem QuorumAcked.after_noOk (hno : NoPrepareOk out) {v i}
    (h : QuorumAcked (s.after id r' out st) v i) : QuorumAcked s v i := by
  obtain ⟨Q, hnd, hlen, hq⟩ := h
  refine ⟨Q, hnd, hlen, fun q hq' => ?_⟩
  obtain ⟨hlt, hack⟩ := hq q hq'
  refine ⟨hlt, ?_⟩
  rcases Acked.after.mp hack with hack | ⟨to, o, hs, _⟩
  · exact hack
  · exact absurd rfl (hno _ hs v o q)

theorem QuorumAcked.after_of {v i} (h : QuorumAcked s v i) : QuorumAcked (s.after id r' out st) v i :=
  QuorumAcked.mono (s := s) (s' := s.after id r' out st) (fun _ hy => sent_after_of hy) rfl h

theorem Backed.after_of {v k} (h : Backed s v k) : Backed (s.after id r' out st) v k :=
  Backed.mono (s := s) (s' := s.after id r' out st) (fun _ hy => sent_after_of hy)
    (fun _ hy => started_after_of hy) rfl h

theorem MsgBacked.after_of {msg : Message Op} (h : MsgBacked s msg) : MsgBacked (s.after id r' out st) msg :=
  MsgBacked.mono (s := s) (s' := s.after id r' out st) (fun _ hy => sent_after_of hy)
    (fun _ hy => started_after_of hy) rfl h

theorem Committed.after_of {v i e} (h : Committed s v i e) : Committed (s.after id r' out st) v i e :=
  ⟨Holds.after_of h.1, QuorumAcked.after_of h.2⟩

/-- Membership in the new replicas: the new one, or an old one with a
different id. -/
theorem mem_after_replicas (hids : Ids s) {r : Replica Op Output St} (hr : s.replicas[id]? = some r)
    {x : Replica Op Output St} (hx : x ∈ (s.after id r' out st).replicas) :
    x = r' ∨ (x ∈ s.replicas ∧ x.selfId ≠ r.selfId) := by
  simp only [System.after_replicas] at hx
  obtain ⟨j, hj⟩ := List.mem_iff_getElem?.mp hx
  have hlt : id < s.replicas.length := (List.getElem?_eq_some_iff.mp hr).1
  by_cases hji : j = id
  · subst hji
    rw [List.getElem?_set_self hlt] at hj
    exact Or.inl (Option.some.inj hj).symm
  · rw [List.getElem?_set_ne (Ne.symm hji)] at hj
    refine Or.inr ⟨List.mem_of_getElem? hj, ?_⟩
    rw [(hids j x hj).1, (hids id r hr).1]
    exact hji

theorem after_replicas_self {r : Replica Op Output St} (hr : s.replicas[id]? = some r) :
    (s.after id r' out st).replicas[id]? = some r' := by
  simp only [System.after_replicas]
  exact List.getElem?_set_self (List.getElem?_eq_some_iff.mp hr).1

theorem mem_after_replicas_self {r : Replica Op Output St} (hr : s.replicas[id]? = some r) :
    r' ∈ (s.after id r' out st).replicas :=
  List.mem_of_getElem? (after_replicas_self hr)

theorem mem_after_replicas_old (hids : Ids s) {r : Replica Op Output St} (hr : s.replicas[id]? = some r)
    {x : Replica Op Output St} (hx : x ∈ s.replicas) (hne : x.selfId ≠ r.selfId) :
    x ∈ (s.after id r' out st).replicas := by
  simp only [System.after_replicas]
  obtain ⟨j, hj⟩ := List.mem_iff_getElem?.mp hx
  have hji : j ≠ id := by
    intro h; subst h
    exact hne ((hids j x hj).1.trans (hids j r hr).1.symm)
  exact List.mem_of_getElem? (by rw [List.getElem?_set_ne (Ne.symm hji)]; exact hj)

end Decompose

/-! ### What a step has to establish -/

/-- The obligations of a step at `id` that replaces `r` by `r'`, sends
`out`, and starts `st`. One field per clause of `Inv`, restricted to what
is new. `s'` abbreviates the state afterwards. -/
structure StepOK (s : System Op Output St) (id : ReplicaId) (r r' : Replica Op Output St)
    (out : List (ReplicaId × Message Op))
    (st : List (ViewNumber × List (ReplicaId × DoViewChange Op))) : Prop where
  self : r'.selfId = r.selfId
  conf : r'.config = r.config
  panic : r'.panicked = false
  outbox : r'.outbox = []
  replies : r'.replies = []
  chosen : r'.chosenDoViewChanges = none
  local_ : Replica.LocalInv r'
  view : r.viewNumber ≤ r'.viewNumber
  lnv : r.lastNormalView ≤ r'.lastNormalView
  wf : ∀ x ∈ out, WF x.2
  /-- The senders of new `PrepareOk` messages are this replica. -/
  okSelf : ∀ x ∈ out, ∀ v o q, x.2 = Message.prepareOk v o q → q = r'.selfId
  oneLogNew : ∀ v i e e', HoldsNew out st v i e → Holds (s.after id r' out st) v i e' → e = e'
  oneLogSelf : ∀ i e e', r'.log[i]? = some e → Holds (s.after id r' out st) r'.lastNormalView i e' → e = e'
  oneLogOld : ∀ z ∈ s.replicas, z.selfId ≠ r.selfId → ∀ i e e', z.log[i]? = some e →
    HoldsNew out st z.lastNormalView i e' → e = e'
  backedSelf : Backed (s.after id r' out st) r'.lastNormalView r'.commitNumber
  backedOut : ∀ x ∈ out, MsgBacked (s.after id r' out st) x.2
  /-- An old committed entry is held by everything new of a later view. -/
  survivesOld : ∀ v' i e, Committed s v' i e → ∀ v, v' < v →
    (∀ to log o k, (to, Message.startView v log o k) ∈ out → log[i]? = some e) ∧
    (∀ u x d, DvcOfNew out st u x d → d.lastNormalView = v → d.log[i]? = some e) ∧
    (∀ to n q stt, (to, Message.recoveryResponse v n q (some stt)) ∈ out → stt.log[i]? = some e) ∧
    (∀ to log a b k, (to, Message.newState v log a b k) ∈ out → a ≤ i → log[i - a]? = some e) ∧
    (∀ to c n op k, (to, Message.prepare v (i + 1) c n op k) ∈ out → (⟨c, n, op⟩ : LogEntry Op) = e) ∧
    (r'.lastNormalView = v → r'.status ≠ .recovering → r'.log[i]? = some e)
  /-- A newly committed entry is held by everything of a later view. -/
  survivesNew : ∀ v' i e, Committed (s.after id r' out st) v' i e → ¬ Committed s v' i e →
    ∀ v, v' < v →
    (∀ to log o k, Sent (s.after id r' out st) to (.startView v log o k) → log[i]? = some e) ∧
    (∀ u x d, DvcOf (s.after id r' out st) u x d → d.lastNormalView = v → d.log[i]? = some e) ∧
    (∀ to n q stt, Sent (s.after id r' out st) to (.recoveryResponse v n q (some stt)) → stt.log[i]? = some e) ∧
    (∀ to log a b k, Sent (s.after id r' out st) to (.newState v log a b k) → a ≤ i → log[i - a]? = some e) ∧
    (∀ to c n op k, Sent (s.after id r' out st) to (.prepare v (i + 1) c n op k) → (⟨c, n, op⟩ : LogEntry Op) = e) ∧
    (∀ z ∈ (s.after id r' out st).replicas, z.lastNormalView = v → z.status ≠ .recovering → z.log[i]? = some e)
  acksSelf : r'.status = .normal → r'.isPrimary = true →
    ∀ oa ∈ r'.acks, oa.1 ≤ r'.log.length ∧ oa.2.Pairwise (· < ·) ∧
      ∀ q ∈ oa.2, q < s.config.replicaCount ∧
        (q = r'.selfId ∨ ∃ to, Sent (s.after id r' out st) to (.prepareOk r'.viewNumber oa.1 q))
  catchingSelf : r'.catchingUp = true → r'.selfId ≠ r'.config.primaryId r'.viewNumber
  acksHoldSelf : ∀ to v o, Sent (s.after id r' out st) to (.prepareOk v o r'.selfId) →
    v ≤ r'.lastNormalView ∧ (r'.lastNormalView = v → r'.status ≠ .recovering → o ≤ r'.log.length)
  toOthers : ∀ x ∈ out, match x.2 with
    | .prepare v _ _ _ _ _ => x.1 ≠ s.config.primaryId v
    | .commit v _ => x.1 ≠ s.config.primaryId v
    | _ => True
  longestSelf : r'.status ≠ .recovering → r'.selfId = s.config.primaryId r'.lastNormalView →
    (∀ off log, Frag (s.after id r' out st) r'.lastNormalView off log → off + log.length ≤ r'.log.length) ∧
    (∀ q ∈ (s.after id r' out st).replicas, q.lastNormalView = r'.lastNormalView → q.status ≠ .recovering →
      q.log.length ≤ r'.log.length) ∧
    (∀ to o q, Sent (s.after id r' out st) to (.prepareOk r'.lastNormalView o q) → o ≤ r'.log.length)
  longestOld : ∀ p ∈ s.replicas, p.selfId ≠ r.selfId → p.status ≠ .recovering →
    p.selfId = s.config.primaryId p.lastNormalView →
    (∀ off log, FragNew out st p.lastNormalView off log → off + log.length ≤ p.log.length) ∧
    (r'.lastNormalView = p.lastNormalView → r'.status ≠ .recovering → r'.log.length ≤ p.log.length) ∧
    (∀ x ∈ out, ∀ o q, x.2 = Message.prepareOk p.lastNormalView o q → o ≤ p.log.length)
  chosenNew : ∀ to v log o k, (to, Message.startView v log o k) ∈ out →
    ∃ dvcs best, (v, dvcs) ∈ (s.after id r' out st).started ∧ s.config.quorum ≤ dvcs.length ∧
      (dvcs.map Prod.fst).Nodup ∧ Replica.bestDoViewChange dvcs = some best ∧ best.log <+: log
  dvcCoversNew : ∀ u x d, DvcOfNew out st u x d →
    ∀ to o, Sent (s.after id r' out st) to (.prepareOk d.lastNormalView o x) → o ≤ d.log.length
  dvcCoversOk : ∀ u x d, DvcOf s u x d →
    ∀ y ∈ out, ∀ o, y.2 = Message.prepareOk d.lastNormalView o x → o ≤ d.log.length
  dvcBehindNew : ∀ u x d, DvcOfNew out st u x d → d.lastNormalView < u
  dvcBelowNew : ∀ u x d, DvcOfNew out st u x d →
    ∀ z ∈ (s.after id r' out st).replicas, z.selfId = x → u ≤ z.viewNumber
  dvcAfterAcksNew : ∀ u x d, DvcOfNew out st u x d →
    ∀ to v o, Sent (s.after id r' out st) to (.prepareOk v o x) → v < u → v ≤ d.lastNormalView
  dvcAfterAcksOk : ∀ u x d, DvcOf s u x d →
    ∀ y ∈ out, ∀ v o, y.2 = Message.prepareOk v o x → v < u → v ≤ d.lastNormalView
  dvcAfterOwnNew : ∀ u x d, DvcOfNew out st u x d →
    ∀ v dvcs, (v, dvcs) ∈ (s.after id r' out st).started → x = s.config.primaryId v →
      v < u → v ≤ d.lastNormalView
  dvcAfterOwnSt : ∀ u x d, DvcOf s u x d →
    ∀ v dvcs, (v, dvcs) ∈ st → x = s.config.primaryId v → v < u → v ≤ d.lastNormalView
  dvcPrimaryNew : ∀ u x d, DvcOfNew out st u x d → x = s.config.primaryId d.lastNormalView →
    ∀ off log, Frag (s.after id r' out st) d.lastNormalView off log → off + log.length ≤ d.log.length
  dvcPrimaryFrag : ∀ u x d, DvcOf s u x d → x = s.config.primaryId d.lastNormalView →
    ∀ off log, FragNew out st d.lastNormalView off log → off + log.length ≤ d.log.length
  vcBehindSelf : r'.status = .viewChange → r'.lastNormalView < r'.viewNumber
  primaryStartedNew : ∀ v dvcs, (v, dvcs) ∈ st →
    ∀ p ∈ (s.after id r' out st).replicas, p.selfId = s.config.primaryId v → v ≤ p.lastNormalView
  startedOnceNew : ∀ v d1, (v, d1) ∈ st → ∀ d2, (v, d2) ∈ (s.after id r' out st).started → d1 = d2
  extendsOld : ∀ v dvcs b, (v, dvcs) ∈ s.started → Replica.bestDoViewChange dvcs = some b →
    (∀ u x d, DvcOfNew out st u x d → d.lastNormalView = v → b.log.length ≤ d.log.length) ∧
    (∀ to n q stt, (to, Message.recoveryResponse v n q (some stt)) ∈ out → b.log.length ≤ stt.log.length) ∧
    (∀ to log a e k, (to, Message.newState v log a e k) ∈ out → b.log.length ≤ e) ∧
    (r'.lastNormalView = v → r'.status ≠ .recovering → b.log.length ≤ r'.log.length)
  extendsNew : ∀ v dvcs b, (v, dvcs) ∈ st → Replica.bestDoViewChange dvcs = some b →
    (∀ u x d, DvcOf (s.after id r' out st) u x d → d.lastNormalView = v → b.log.length ≤ d.log.length) ∧
    (∀ to n q stt, Sent (s.after id r' out st) to (.recoveryResponse v n q (some stt)) →
      b.log.length ≤ stt.log.length) ∧
    (∀ to log a e k, Sent (s.after id r' out st) to (.newState v log a e k) → b.log.length ≤ e) ∧
    (∀ z ∈ (s.after id r' out st).replicas, z.lastNormalView = v → z.status ≠ .recovering →
      b.log.length ≤ z.log.length)
  rrNonceNew : ∀ to v n q stt, (to, Message.recoveryResponse v n q stt) ∈ out →
    ∃ to' i v', Sent (s.after id r' out st) to' (.recovery i n v')
  belowNew : ∀ x ∈ out, ∀ z ∈ (s.after id r' out st).replicas, match x.2 with
    | .prepareOk v _ q => z.selfId = q → v ≤ z.viewNumber
    | .getState q v _ => z.selfId = q → v ≤ z.viewNumber
    | .startViewChange v q => z.selfId = q → v ≤ z.viewNumber
    | .doViewChange v q _ _ _ _ => z.selfId = q → v ≤ z.viewNumber
    | .recovery q _ v => z.selfId = q → v ≤ z.viewNumber
    | .recoveryResponse v _ q _ => z.selfId = q → v ≤ z.viewNumber
    | _ => True
  recoverySelf : r'.status = .recovering →
    ∀ to v n q stt, Sent (s.after id r' out st) to (.recoveryResponse v n q (some stt)) → n = r'.recoveryNonce →
      ∀ to' o, Sent (s.after id r' out st) to' (.prepareOk v o r'.selfId) → o ≤ stt.log.length
  recoveryOk : ∀ q ∈ s.replicas, q.selfId ≠ r.selfId → q.status = .recovering →
    ∀ to v n p stt, Sent s to (.recoveryResponse v n p (some stt)) → n = q.recoveryNonce →
      ∀ y ∈ out, ∀ o, y.2 = Message.prepareOk v o q.selfId → o ≤ stt.log.length
  recoveryRR : ∀ q ∈ s.replicas, q.selfId ≠ r.selfId → q.status = .recovering →
    ∀ to v n p stt, (to, Message.recoveryResponse v n p (some stt)) ∈ out → n = q.recoveryNonce →
      ∀ to' o, Sent (s.after id r' out st) to' (.prepareOk v o q.selfId) → o ≤ stt.log.length
  coveredSelf : ∀ i, i < r'.log.length → ∃ e, Holds (s.after id r' out st) r'.lastNormalView i e
  agreeSelf : ∀ z ∈ s.replicas, z.selfId ≠ r.selfId → z.lastNormalView = r'.lastNormalView →
    ∀ (i : Nat) (e e' : LogEntry Op), r'.log[i]? = some e → z.log[i]? = some e' → e = e'
  startedViewsNew : ∀ v dvcs, (v, dvcs) ∈ st → ∃ to log o k, Sent (s.after id r' out st) to (.startView v log o k)
  fragStartedNew : ∀ v off log, FragNew out st v off log → 0 < v → ∃ dvcs, (v, dvcs) ∈ (s.after id r' out st).started
  selfStarted : r'.status ≠ .recovering → 0 < r'.lastNormalView →
    ∃ dvcs, (r'.lastNormalView, dvcs) ∈ (s.after id r' out st).started
  acksStartedNew : ∀ x ∈ out, ∀ u o q, x.2 = Message.prepareOk u o q → 0 < u →
    ∃ dvcs, (u, dvcs) ∈ (s.after id r' out st).started
  svcPosNew : ∀ x ∈ out, ∀ v q, x.2 = Message.startViewChange v q → 0 < v
  transferSelf : r'.status = .stateTransfer → r'.selfId ≠ s.config.primaryId r'.viewNumber
  rrPrimaryNew : ∀ x ∈ out, ∀ v n q stt, x.2 = Message.recoveryResponse v n q (some stt) →
    q = s.config.primaryId v
  rrNotSelfNew : ∀ x ∈ out, ∀ v n p stt, x.2 = Message.recoveryResponse v n p stt →
    ∀ q ∈ (s.after id r' out st).replicas, q.status = .recovering → q.recoveryNonce = n → p ≠ q.selfId
  rrNotSelfSelf : r'.status = .recovering → ∀ to v n p stt, Sent s to (.recoveryResponse v n p stt) →
    r'.recoveryNonce = n → p ≠ r'.selfId
  senderIdsNew : ∀ x ∈ out, match x.2 with
    | .prepareOk _ _ q => q < s.config.replicaCount
    | .getState q _ _ => q < s.config.replicaCount
    | .startViewChange _ q => q < s.config.replicaCount
    | .doViewChange _ q _ _ _ _ => q < s.config.replicaCount
    | .recovery q _ _ => q < s.config.replicaCount
    | .recoveryResponse _ _ q _ => q < s.config.replicaCount
    | _ => True
  startedIdsNew : ∀ v dvcs, (v, dvcs) ∈ st → ∀ x d, (x, d) ∈ dvcs → x < s.config.replicaCount
  dvcsSelf : r'.status = .viewChange →
    (r'.doViewChangeFrom.map Prod.fst).Pairwise (· < ·) ∧
    ∀ x d, (x, d) ∈ r'.doViewChangeFrom → x < s.config.replicaCount ∧
      ((∃ dst, Sent (s.after id r' out st) dst
          (.doViewChange r'.viewNumber x d.lastNormalView d.log d.log.length d.commitNumber)) ∨
        (x = r'.selfId ∧ d = ⟨r'.lastNormalView, r'.log, r'.commitNumber⟩))
  rrsSelf : r'.status = .recovering →
    ∀ x (resp : RecoveryResponse Op), (x, resp) ∈ r'.recoveryResponses →
      ∃ dst, Sent (s.after id r' out st) dst (.recoveryResponse resp.viewNumber r'.recoveryNonce x resp.state)

end Vsr

namespace Vsr

variable {Op Output St : Type}

/-! ### The step lemma -/

/-- A step whose obligations hold keeps the invariant. -/
theorem Inv.after {s : System Op Output St} (hinv : Inv s) {id : ReplicaId} {r r' : Replica Op Output St}
    (hr : s.replicas[id]? = some r) {out : List (ReplicaId × Message Op)}
    {st : List (ViewNumber × List (ReplicaId × DoViewChange Op))} (h : StepOK s id r r' out st) :
    Inv (s.after id r' out st) := by
  have hmem : r ∈ s.replicas := List.mem_of_getElem? hr
  have hrepl : ∀ x ∈ (s.after id r' out st).replicas, x = r' ∨ (x ∈ s.replicas ∧ x.selfId ≠ r.selfId) :=
    fun x hx => mem_after_replicas hinv.ids hr hx
  have hself' : r'.selfId = id := h.self.trans (hinv.ids id r hr).1
  have hconf' : r'.config = s.config := h.conf.trans (hinv.ids id r hr).2
  have hrs : r.selfId = r'.selfId := h.self.symm
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_,
    ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · -- noPanic
    intro x hx; rcases hrepl x hx with rfl | ⟨hx, _⟩
    · exact h.panic
    · exact hinv.noPanic x hx
  · -- ids
    intro i x hx
    simp only [System.after_replicas] at hx
    have hlt : id < s.replicas.length := (List.getElem?_eq_some_iff.mp hr).1
    by_cases hi : i = id
    · subst hi
      rw [List.getElem?_set_self hlt] at hx
      obtain rfl := Option.some.inj hx
      exact ⟨hself', hconf'⟩
    · rw [List.getElem?_set_ne (Ne.symm hi)] at hx
      exact hinv.ids i x hx
  · -- local
    intro x hx; rcases hrepl x hx with rfl | ⟨hx, _⟩
    · exact h.local_
    · exact hinv.local_ x hx
  · -- drained
    intro x hx; rcases hrepl x hx with rfl | ⟨hx, _⟩
    · exact h.outbox
    · exact hinv.drained x hx
  · -- wf
    intro x hx
    rcases List.mem_append.mp hx with hx | hx
    · exact hinv.wf x hx
    · exact h.wf x hx
  · -- oneLog
    refine ⟨fun v i e e' h1 h2 => ?_, fun z hz i e e' he hh => ?_⟩
    · rcases Holds.after.mp h1 with h1' | h1'
      · rcases Holds.after.mp h2 with h2' | h2'
        · exact hinv.oneLog.1 v i e e' h1' h2'
        · exact (h.oneLogNew v i e' e h2' h1).symm
      · exact h.oneLogNew v i e e' h1' h2
    · rcases hrepl z hz with rfl | ⟨hz, hne⟩
      · exact h.oneLogSelf i e e' he hh
      · rcases Holds.after.mp hh with hh' | hh'
        · exact hinv.oneLog.2 z hz i e e' he hh'
        · exact h.oneLogOld z hz hne i e e' he hh'
  · -- backed
    refine ⟨fun z hz => ?_, fun to msg hm => ?_⟩
    · rcases hrepl z hz with rfl | ⟨hz, _⟩
      · exact h.backedSelf
      · exact Backed.after_of (hinv.backed.1 z hz)
    · rcases Sent.after.mp hm with hm | hm
      · exact MsgBacked.after_of (hinv.backed.2 to msg hm)
      · exact h.backedOut (to, msg) hm
  · -- survives
    intro v' i e hc v hlt
    by_cases hold : Committed s v' i e
    · obtain ⟨o1, o2, o3, o4, o5, o6⟩ := hinv.survives v' i e hold v hlt
      obtain ⟨n1, n2, n3, n4, n5, n6⟩ := h.survivesOld v' i e hold v hlt
      refine ⟨fun to log o k hs => ?_, fun u x d hd hl => ?_, fun to n q stt hs => ?_,
        fun to log a b k hs ha => ?_, fun to c n op k hs => ?_, fun z hz hzv hzr => ?_⟩
      · rcases Sent.after.mp hs with hs | hs
        · exact o1 to log o k hs
        · exact n1 to log o k hs
      · rcases DvcOf.after.mp hd with hd | hd
        · exact o2 u x d hd hl
        · exact n2 u x d hd hl
      · rcases Sent.after.mp hs with hs | hs
        · exact o3 to n q stt hs
        · exact n3 to n q stt hs
      · rcases Sent.after.mp hs with hs | hs
        · exact o4 to log a b k hs ha
        · exact n4 to log a b k hs ha
      · rcases Sent.after.mp hs with hs | hs
        · exact o5 to c n op k hs
        · exact n5 to c n op k hs
      · rcases hrepl z hz with rfl | ⟨hz, _⟩
        · exact n6 hzv hzr
        · exact o6 z hz hzv hzr
    · exact h.survivesNew v' i e hc hold v hlt
  · -- acks
    intro z hz hn hp oa hoa
    rcases hrepl z hz with rfl | ⟨hz, _⟩
    · exact h.acksSelf hn hp oa hoa
    · obtain ⟨c1, c0, c2⟩ := hinv.acks z hz hn hp oa hoa
      exact ⟨c1, c0, fun q hq => ⟨(c2 q hq).1, (c2 q hq).2.imp (fun h => h)
        (fun ⟨to, ht⟩ => ⟨to, Sent.after_of ht⟩)⟩⟩
  · -- catching
    intro z hz hc; rcases hrepl z hz with rfl | ⟨hz, _⟩
    · exact h.catchingSelf hc
    · exact hinv.catching z hz hc
  · -- acksHold
    intro to v o q hs z hz hq
    rcases hrepl z hz with rfl | ⟨hz, hne⟩
    · subst hq; exact h.acksHoldSelf to v o hs
    · rcases Sent.after.mp hs with hs | hs
      · exact hinv.acksHold to v o q hs z hz hq
      · exact absurd (hq.trans (h.okSelf _ hs v o q rfl)) (hrs ▸ hne)
  · -- toOthers
    intro to msg hs
    rcases Sent.after.mp hs with hs | hs
    · have := hinv.toOthers to msg hs; revert this; cases msg <;> simp_all
    · exact h.toOthers (to, msg) hs
  · -- longest
    intro p hp hpn hpp
    rcases hrepl p hp with rfl | ⟨hp, hne⟩
    · exact h.longestSelf hpn hpp
    · obtain ⟨f1, f2, f3⟩ := hinv.longest p hp hpn hpp
      obtain ⟨g1, g2, g3⟩ := h.longestOld p hp hne hpn hpp
      refine ⟨fun off log hf => ?_, fun q hq hql hqn => ?_, fun to o q hs => ?_⟩
      · rcases Frag.after.mp hf with hf | hf
        · exact f1 off log hf
        · exact g1 off log hf
      · rcases hrepl q hq with rfl | ⟨hq, _⟩
        · exact g2 hql hqn
        · exact f2 q hq hql hqn
      · rcases Sent.after.mp hs with hs | hs
        · exact f3 to o q hs
        · exact g3 _ hs o q rfl
  · -- chosen
    intro to v log o k hs
    rcases Sent.after.mp hs with hs | hs
    · obtain ⟨dvcs, best, h1, h2, h3, h4, h5⟩ := hinv.chosen to v log o k hs
      exact ⟨dvcs, best, started_after_of h1, h2, h3, h4, h5⟩
    · exact h.chosenNew to v log o k hs
  · -- dvcCovers
    intro u x d hd to o hs
    rcases DvcOf.after.mp hd with hd | hd
    · rcases Sent.after.mp hs with hs | hs
      · exact hinv.dvcCovers u x d hd to o hs
      · exact h.dvcCoversOk u x d hd _ hs o rfl
    · exact h.dvcCoversNew u x d hd to o hs
  · -- dvcBehind
    intro u x d hd
    rcases DvcOf.after.mp hd with hd | hd
    · exact hinv.dvcBehind u x d hd
    · exact h.dvcBehindNew u x d hd
  · -- dvcBelow
    intro u x d hd z hz hzx
    rcases DvcOf.after.mp hd with hd' | hd'
    · rcases hrepl z hz with hzr | ⟨hz', _⟩
      · subst hzr; exact Nat.le_trans (hinv.dvcBelow u x d hd' r hmem (hrs.trans hzx)) h.view
      · exact hinv.dvcBelow u x d hd' z hz' hzx
    · exact h.dvcBelowNew u x d hd' z hz hzx
  · -- dvcAfterAcks
    intro u x d hd to v o hs hlt
    rcases DvcOf.after.mp hd with hd | hd
    · rcases Sent.after.mp hs with hs | hs
      · exact hinv.dvcAfterAcks u x d hd to v o hs hlt
      · exact h.dvcAfterAcksOk u x d hd _ hs v o rfl hlt
    · exact h.dvcAfterAcksNew u x d hd to v o hs hlt
  · -- dvcAfterOwn
    intro u x d hd v dvcs hv hx hlt
    rcases DvcOf.after.mp hd with hd | hd
    · rcases mem_started_after.mp hv with hv | hv
      · exact hinv.dvcAfterOwn u x d hd v dvcs hv hx hlt
      · exact h.dvcAfterOwnSt u x d hd v dvcs hv hx hlt
    · exact h.dvcAfterOwnNew u x d hd v dvcs hv hx hlt
  · -- dvcPrimary
    intro u x d hd hx off log hf
    rcases DvcOf.after.mp hd with hd | hd
    · rcases Frag.after.mp hf with hf | hf
      · exact hinv.dvcPrimary u x d hd hx off log hf
      · exact h.dvcPrimaryFrag u x d hd hx off log hf
    · exact h.dvcPrimaryNew u x d hd hx off log hf
  · -- vcBehind
    intro z hz hs; rcases hrepl z hz with rfl | ⟨hz, _⟩
    · exact h.vcBehindSelf hs
    · exact hinv.vcBehind z hz hs
  · -- primaryStarted
    intro v dvcs hv p hp hpp
    rcases mem_started_after.mp hv with hv' | hv'
    · rcases hrepl p hp with hpr | ⟨hp', _⟩
      · subst hpr; exact Nat.le_trans (hinv.primaryStarted v dvcs hv' r hmem (hrs.trans hpp)) h.lnv
      · exact hinv.primaryStarted v dvcs hv' p hp' hpp
    · exact h.primaryStartedNew v dvcs hv' p hp hpp
  · -- startedOnce
    intro v d1 d2 h1 h2
    rcases mem_started_after.mp h1 with h1 | h1
    · rcases mem_started_after.mp h2 with h2 | h2
      · exact hinv.startedOnce v d1 d2 h1 h2
      · exact (h.startedOnceNew v d2 h2 d1 (started_after_of h1)).symm
    · exact h.startedOnceNew v d1 h1 d2 h2
  · -- extendsBase
    intro v dvcs b hv hb
    rcases mem_started_after.mp hv with hv | hv
    · obtain ⟨e1, e2, e3, e4⟩ := hinv.extendsBase v dvcs b hv hb
      obtain ⟨n1, n2, n3, n4⟩ := h.extendsOld v dvcs b hv hb
      refine ⟨fun u x d hd hl => ?_, fun to n q stt hs => ?_, fun to log a e k hs => ?_,
        fun z hz hzl hzn => ?_⟩
      · rcases DvcOf.after.mp hd with hd | hd
        · exact e1 u x d hd hl
        · exact n1 u x d hd hl
      · rcases Sent.after.mp hs with hs | hs
        · exact e2 to n q stt hs
        · exact n2 to n q stt hs
      · rcases Sent.after.mp hs with hs | hs
        · exact e3 to log a e k hs
        · exact n3 to log a e k hs
      · rcases hrepl z hz with rfl | ⟨hz, _⟩
        · exact n4 hzl hzn
        · exact e4 z hz hzl hzn
    · exact h.extendsNew v dvcs b hv hb
  · -- rrNonce
    intro to v n q stt hs
    rcases Sent.after.mp hs with hs | hs
    · obtain ⟨to', i, v', h'⟩ := hinv.rrNonce to v n q stt hs
      exact ⟨to', i, v', Sent.after_of h'⟩
    · exact h.rrNonceNew to v n q stt hs
  · -- acksStarted
    intro to u o q hs hu
    rcases Sent.after.mp hs with hs | hs
    · obtain ⟨dvcs, hd⟩ := hinv.acksStarted to u o q hs hu
      exact ⟨dvcs, started_after_of hd⟩
    · exact h.acksStartedNew _ hs u o q rfl hu
  · -- svcPos
    intro to v q hs
    rcases Sent.after.mp hs with hs | hs
    · exact hinv.svcPos to v q hs
    · exact h.svcPosNew _ hs v q rfl
  · -- transferNotPrimary
    intro z hz hs; rcases hrepl z hz with rfl | ⟨hz, _⟩
    · exact h.transferSelf hs
    · exact hinv.transferNotPrimary z hz hs
  · -- rrPrimary
    intro to v n q stt hs
    rcases Sent.after.mp hs with hs | hs
    · exact hinv.rrPrimary to v n q stt hs
    · exact h.rrPrimaryNew _ hs v n q stt rfl
  · -- rrNotSelf
    intro to v n p stt hs q hq hqr hqn
    rcases Sent.after.mp hs with hs' | hs'
    · rcases hrepl q hq with hqr' | ⟨hq', _⟩
      · subst hqr'; exact h.rrNotSelfSelf hqr to v n p stt hs' hqn
      · exact hinv.rrNotSelf to v n p stt hs' q hq' hqr hqn
    · exact h.rrNotSelfNew _ hs' v n p stt rfl q hq hqr hqn
  · -- count
    show (s.replicas.set id r').length = s.config.replicaCount
    rw [List.length_set]; exact hinv.count
  · -- senderIds
    intro to msg hs
    rcases Sent.after.mp hs with hs | hs
    · exact hinv.senderIds to msg hs
    · exact h.senderIdsNew _ hs
  · -- startedIds
    intro v dvcs hv x d hd
    rcases mem_started_after.mp hv with hv | hv
    · exact hinv.startedIds v dvcs hv x d hd
    · exact h.startedIdsNew v dvcs hv x d hd
  · -- recordedDvcs
    intro z hz hs
    rcases hrepl z hz with hzr | ⟨hz', _⟩
    · subst hzr; exact h.dvcsSelf hs
    · obtain ⟨h1, h2⟩ := hinv.recordedDvcs z hz' hs
      exact ⟨h1, fun x d hd => ⟨(h2 x d hd).1, (h2 x d hd).2.imp (fun ⟨dst, hd'⟩ => ⟨dst, Sent.after_of hd'⟩) (fun h => h)⟩⟩
  · -- recordedRRs
    intro z hz hs x resp hx
    rcases hrepl z hz with hzr | ⟨hz', _⟩
    · subst hzr; exact h.rrsSelf hs x resp hx
    · obtain ⟨dst, hd⟩ := hinv.recordedRRs z hz' hs x resp hx
      exact ⟨dst, Sent.after_of hd⟩
  · -- belowView
    intro to msg hs z hz
    rcases Sent.after.mp hs with hs' | hs'
    · rcases hrepl z hz with hzr | ⟨hz', _⟩
      · subst hzr
        have hb := hinv.belowView to msg hs' r hmem
        revert hb; cases msg <;> intro hb <;>
          first
          | exact hb
          | exact (fun hq => Nat.le_trans (hb (hrs.trans hq)) h.view)
      · exact hinv.belowView to msg hs' z hz'
    · exact h.belowNew (to, msg) hs' z hz
  · -- recoveryCovers
    intro q hq hqr to v n p stt hs hn to' o hs'
    rcases hrepl q hq with rfl | ⟨hq, hne⟩
    · exact h.recoverySelf hqr to v n p stt hs hn to' o hs'
    · rcases Sent.after.mp hs with hs | hs
      · rcases Sent.after.mp hs' with hs' | hs'
        · exact hinv.recoveryCovers q hq hqr to v n p stt hs hn to' o hs'
        · exact h.recoveryOk q hq hne hqr to v n p stt hs hn _ hs' o rfl
      · exact h.recoveryRR q hq hne hqr to v n p stt hs hn to' o hs'
  · -- covered
    intro z hz i hi
    rcases hrepl z hz with rfl | ⟨hz, _⟩
    · exact h.coveredSelf i hi
    · obtain ⟨e, he⟩ := hinv.covered z hz i hi
      exact ⟨e, Holds.after_of he⟩
  · -- agree
    intro z hz w hw hl i e e' he he'
    rcases hrepl z hz with hzr | ⟨hz', hzne⟩ <;> rcases hrepl w hw with hwr | ⟨hw', hwne⟩
    · subst hzr hwr; rw [he] at he'; exact Option.some.inj he'
    · subst hzr; exact h.agreeSelf w hw' hwne hl.symm i e e' he he'
    · subst hwr; exact (h.agreeSelf z hz' hzne hl i e' e he' he).symm
    · exact hinv.agree z hz' w hw' hl i e e' he he'
  · -- startedViews
    obtain ⟨g1, g2, g3⟩ := hinv.startedViews
    refine ⟨fun v dvcs hv => ?_, fun v off log hf hpos => ?_, fun z hz hzr hzv => ?_⟩
    · rcases mem_started_after.mp hv with hv | hv
      · obtain ⟨to, log, o, k, h'⟩ := g1 v dvcs hv
        exact ⟨to, log, o, k, Sent.after_of h'⟩
      · exact h.startedViewsNew v dvcs hv
    · rcases Frag.after.mp hf with hf | hf
      · exact (g2 v off log hf hpos).imp fun dvcs hd => started_after_of hd
      · exact h.fragStartedNew v off log hf hpos
    · rcases hrepl z hz with rfl | ⟨hz, _⟩
      · exact h.selfStarted hzr hzv
      · exact (g3 z hz hzr hzv).imp fun dvcs hd => started_after_of hd
  · -- clean
    intro z hz; rcases hrepl z hz with rfl | ⟨hz, _⟩
    · exact ⟨h.replies, h.chosen⟩
    · exact hinv.clean z hz
  · -- two
    exact hinv.two

end Vsr
