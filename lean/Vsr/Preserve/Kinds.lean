import Vsr.Preserve.Chosen

/-!
Sending one message of each kind from an unchanged replica: what each kind
needs of its sender, as a `MsgOK`.
-/

namespace Vsr

variable {Op Output St : Type}

/-! ### One message -/

theorem FragNew.single {x : ReplicaId × Message Op} {v off log} (h : FragNew [x] [] v off log) :
    MsgFrag x v off log := by
  rcases h with ⟨y, hy, hf⟩ | ⟨_, _, _, _, hst, _⟩
  · rw [mem_singleton_eq hy] at hf; exact hf
  · simp at hst

theorem HoldsNew.single {x : ReplicaId × Message Op} {v i e} (h : HoldsNew [x] [] v i e) :
    ∃ off log, MsgFrag x v off log ∧ off ≤ i ∧ log[i - off]? = some e :=
  let ⟨off, log, hf, hle, hget⟩ := h; ⟨off, log, FragNew.single hf, hle, hget⟩

theorem DvcOfNew.single {x : ReplicaId × Message Op} {u q d} (h : DvcOfNew [x] [] u q d) :
    x.2 = Message.doViewChange u q d.lastNormalView d.log d.log.length d.commitNumber := by
  rcases h with ⟨dst, h⟩ | ⟨_, h, _⟩
  · exact (congrArg Prod.snd (mem_singleton_eq h)).symm
  · simp at h

theorem MsgFrag.prepare_inv {dst v o c n} {op : Op} {k v' off log}
    (h : MsgFrag (dst, Message.prepare v o c n op k) v' off log) :
    v' = v ∧ off = o - 1 ∧ log = [⟨c, n, op⟩] := by cases h; exact ⟨rfl, rfl, rfl⟩
theorem MsgFrag.newState_inv {dst v} {L : List (LogEntry Op)} {a b k v' off log}
    (h : MsgFrag (dst, Message.newState v L a b k) v' off log) : v' = v ∧ off = a ∧ log = L := by
  cases h; exact ⟨rfl, rfl, rfl⟩
theorem MsgFrag.startView_inv {dst v} {L : List (LogEntry Op)} {o k v' off log}
    (h : MsgFrag (dst, Message.startView v L o k) v' off log) : v' = v ∧ off = 0 ∧ log = L := by
  cases h; exact ⟨rfl, rfl, rfl⟩
theorem MsgFrag.dvc_inv {dst v q l} {L : List (LogEntry Op)} {o k v' off log}
    (h : MsgFrag (dst, Message.doViewChange v q l L o k) v' off log) : v' = l ∧ off = 0 ∧ log = L := by
  cases h; exact ⟨rfl, rfl, rfl⟩
theorem MsgFrag.recovery_inv {dst v n q} {st : Option (RecoveryState Op)} {v' off log}
    (h : MsgFrag (dst, Message.recoveryResponse v n q st) v' off log) :
    ∃ stt, st = some stt ∧ v' = v ∧ off = 0 ∧ log = stt.log := by
  cases h; exact ⟨_, rfl, rfl, rfl, rfl⟩

/-- A message with no fragment and no acknowledgement creates no
`Committed` fact. -/
theorem Committed.after_single_inert {s : System Op Output St} {id : ReplicaId} {r : Replica Op Output St}
    {x : ReplicaId × Message Op} (hfrag : ∀ v off log, ¬ MsgFrag x v off log)
    (hnook : ∀ v o q, x.2 ≠ Message.prepareOk v o q) {v i e}
    (hc : Committed (s.after id r [x] []) v i e) : Committed s v i e := by
  obtain ⟨hh, hq⟩ := hc
  refine ⟨?_, QuorumAcked.after_noOk (fun y hy => by rw [mem_singleton_eq hy]; exact hnook) hq⟩
  rcases Holds.after.mp hh with h | ⟨off, log, hf, _, _⟩
  · exact h
  · exact absurd (FragNew.single hf) (hfrag v off log)

/-- A message that is a fragment of a normal replica's own log, in its
view, is held by the fragments there already. -/
theorem Committed.after_single_covered {s : System Op Output St} (hinv : Inv s) {id : ReplicaId}
    {r : Replica Op Output St} (hr : r ∈ s.replicas) {x : ReplicaId × Message Op}
    (hfrag : ∀ v off log, MsgFrag x v off log → v = r.lastNormalView ∧
      ∀ i e, off ≤ i → log[i - off]? = some e → r.log[i]? = some e)
    (hnook : ∀ v o q, x.2 ≠ Message.prepareOk v o q) {v i e}
    (hc : Committed (s.after id r [x] []) v i e) : Committed s v i e := by
  obtain ⟨hh, hq⟩ := hc
  refine ⟨?_, QuorumAcked.after_noOk (fun y hy => by rw [mem_singleton_eq hy]; exact hnook) hq⟩
  rcases Holds.after.mp hh with h | ⟨off, log, hf, hle, hget⟩
  · exact h
  · obtain ⟨rfl, hlog⟩ := hfrag v off log (FragNew.single hf)
    have he := hlog i e hle hget
    obtain ⟨e0, he0⟩ := hinv.covered r hr i (List.getElem?_eq_some_iff.mp he).1
    rw [hinv.oneLog.2 r hr i e e0 he he0]
    exact he0

/-! ### Messages that carry no log and acknowledge nothing -/

/-- `GetState`, `StartViewChange`, `Recovery`, `Commit`: nothing but the
sender's view and id to check. -/
theorem MsgOK.inert {s : System Op Output St} (hinv : Inv s) {id : ReplicaId} {r : Replica Op Output St}
    (hr : s.replicas[id]? = some r) {x : ReplicaId × Message Op}
    (hfrag : ∀ v off log, ¬ MsgFrag x v off log)
    (hnodvc : ∀ u q l log o k, x.2 ≠ Message.doViewChange u q l log o k)
    (hnook : ∀ v o q, x.2 ≠ Message.prepareOk v o q)
    (hnorr : ∀ v n q st, x.2 ≠ Message.recoveryResponse v n q st)
    (hnosv : ∀ v log o k, x.2 ≠ Message.startView v log o k)
    (hnons : ∀ v log a b k, x.2 ≠ Message.newState v log a b k)
    (hnoprep : ∀ v o c n op k, x.2 ≠ Message.prepare v o c n op k)
    (wf : WF x.2) (backed : MsgBacked (s.after id r [x] []) x.2)
    (toOthers : match x.2 with
      | .prepare v _ _ _ _ _ => x.1 ≠ s.config.primaryId v
      | .commit v _ => x.1 ≠ s.config.primaryId v
      | _ => True)
    (below : ∀ z ∈ s.replicas, match x.2 with
      | .prepareOk v _ q => z.selfId = q → v ≤ z.viewNumber
      | .getState q v _ => z.selfId = q → v ≤ z.viewNumber
      | .startViewChange v q => z.selfId = q → v ≤ z.viewNumber
      | .doViewChange v q _ _ _ _ => z.selfId = q → v ≤ z.viewNumber
      | .recovery q _ v => z.selfId = q → v ≤ z.viewNumber
      | .recoveryResponse v _ q _ => z.selfId = q → v ≤ z.viewNumber
      | _ => True)
    (senders : match x.2 with
      | .prepareOk _ _ q => q < s.config.replicaCount
      | .getState q _ _ => q < s.config.replicaCount
      | .startViewChange _ q => q < s.config.replicaCount
      | .doViewChange _ q _ _ _ _ => q < s.config.replicaCount
      | .recovery q _ _ => q < s.config.replicaCount
      | .recoveryResponse _ _ q _ => q < s.config.replicaCount
      | _ => True)
    (svcPos : ∀ v q, x.2 = Message.startViewChange v q → 0 < v) : MsgOK s id r x where
  wf := wf
  okSelf := fun v o q h => absurd h (hnook v o q)
  oneLogNew := fun v i e e' h _ => (HoldsNew.single h).elim fun off => fun ⟨log, hf, _⟩ => absurd hf (hfrag v off log)
  oneLogOld := fun _ _ _ i e e' _ h => (HoldsNew.single h).elim fun off => fun ⟨log, hf, _⟩ => absurd hf (hfrag _ off log)
  backed := backed
  survivesOld := fun _ _ _ _ _ _ =>
    ⟨fun dst log o k h => absurd (congrArg Prod.snd h) (hnosv _ log o k),
     fun u q d hd => absurd (DvcOfNew.single hd) (hnodvc _ _ _ _ _ _),
     fun dst n q stt h => absurd (congrArg Prod.snd h) (hnorr _ n q _),
     fun dst log a b k h => absurd (congrArg Prod.snd h) (hnons _ log a b k),
     fun dst c n op k h => absurd (congrArg Prod.snd h) (hnoprep _ _ c n op k)⟩
  survivesNew := fun v i e hc hold => absurd (Committed.after_single_inert hfrag hnook hc) hold
  acksHoldSelf := fun v o h => absurd h (hnook v o _)
  toOthers := toOthers
  longest := fun p _ _ _ =>
    ⟨fun off log hf => absurd (FragNew.single hf) (hfrag _ off log),
     fun o q h => absurd h (hnook _ o q)⟩
  chosenNew := fun dst v log o k h => absurd (congrArg Prod.snd h) (hnosv v log o k)
  dvcCoversNew := fun u q d hd => absurd (DvcOfNew.single hd) (hnodvc _ _ _ _ _ _)
  dvcCoversOk := fun u q d _ o h => absurd h (hnook _ o q)
  dvcBehindNew := fun u q d hd => absurd (DvcOfNew.single hd) (hnodvc _ _ _ _ _ _)
  dvcBelowNew := fun u q d hd => absurd (DvcOfNew.single hd) (hnodvc _ _ _ _ _ _)
  dvcAfterAcksNew := fun u q d hd => absurd (DvcOfNew.single hd) (hnodvc _ _ _ _ _ _)
  dvcAfterAcksOk := fun u q d _ v o h => absurd h (hnook v o q)
  dvcAfterOwnNew := fun u q d hd => absurd (DvcOfNew.single hd) (hnodvc _ _ _ _ _ _)
  dvcPrimaryNew := fun u q d hd => absurd (DvcOfNew.single hd) (hnodvc _ _ _ _ _ _)
  dvcPrimaryFrag := fun u q d _ _ off log hf => absurd (FragNew.single hf) (hfrag _ off log)
  extendsOld := fun v dvcs b _ _ =>
    ⟨fun u q d hd => absurd (DvcOfNew.single hd) (hnodvc _ _ _ _ _ _),
     fun dst n q stt h => absurd (congrArg Prod.snd h) (hnorr v n q _),
     fun dst log a e k h => absurd (congrArg Prod.snd h) (hnons v log a e k)⟩
  rrNonceNew := fun dst v n q stt h => absurd (congrArg Prod.snd h) (hnorr v n q stt)
  belowNew := below
  recoveryRR := fun q _ _ dst v n p stt h => absurd (congrArg Prod.snd h) (hnorr v n p _)
  recoveryOk := fun q _ _ v o => hnook v o q.selfId
  fragStartedNew := fun v off log hf => absurd (FragNew.single hf) (hfrag v off log)
  acksStartedNew := fun u o q h => absurd h (hnook u o q)
  svcPosNew := svcPos
  rrPrimaryNew := fun v n q stt h => absurd h (hnorr v n q _)
  rrNotSelfNew := fun v n p stt h => absurd h (hnorr v n p stt)
  senderIdsNew := senders

section Sender
variable {s : System Op Output St} (hinv : Inv s) {id : ReplicaId} {r : Replica Op Output St}
  (hr : s.replicas[id]? = some r)
include hinv hr

/-- A message naming the sender is below its view: the only replica with
its id is itself. -/
theorem MsgOK.below_self (v : ViewNumber) (hv : v ≤ r.viewNumber) :
    ∀ z ∈ s.replicas, z.selfId = r.selfId → v ≤ z.viewNumber := by
  intro z hz hq
  rw [hinv.eq_of_selfId hz (List.mem_of_getElem? hr) hq]; exact hv

theorem MsgOK.getState (dst : ReplicaId) (o : OpNumber) :
    MsgOK s id r (dst, .getState r.selfId r.viewNumber o) :=
  MsgOK.inert hinv hr (fun _ _ _ h => nomatch h) (fun _ _ _ _ _ _ h => nomatch h)
    (fun _ _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h)
    (fun _ _ _ _ _ h => nomatch h) (fun _ _ _ _ _ _ h => nomatch h) trivial trivial trivial
    (MsgOK.below_self hinv hr r.viewNumber (Nat.le_refl _)) (hinv.selfId_lt (List.mem_of_getElem? hr))
    (fun _ _ h => nomatch h)

theorem MsgOK.startViewChange (dst : ReplicaId) (hpos : 0 < r.viewNumber) :
    MsgOK s id r (dst, .startViewChange r.viewNumber r.selfId) :=
  MsgOK.inert hinv hr (fun _ _ _ h => nomatch h) (fun _ _ _ _ _ _ h => nomatch h)
    (fun _ _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h)
    (fun _ _ _ _ _ h => nomatch h) (fun _ _ _ _ _ _ h => nomatch h) trivial trivial trivial
    (MsgOK.below_self hinv hr r.viewNumber (Nat.le_refl _)) (hinv.selfId_lt (List.mem_of_getElem? hr))
    (fun v q h => by simp only [Message.startViewChange.injEq] at h; rw [← h.1]; exact hpos)

theorem MsgOK.recovery (dst : ReplicaId) (n : Nat) :
    MsgOK s id r (dst, .recovery r.selfId n r.viewNumber) :=
  MsgOK.inert hinv hr (fun _ _ _ h => nomatch h) (fun _ _ _ _ _ _ h => nomatch h)
    (fun _ _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h)
    (fun _ _ _ _ _ h => nomatch h) (fun _ _ _ _ _ _ h => nomatch h) trivial trivial trivial
    (MsgOK.below_self hinv hr r.viewNumber (Nat.le_refl _)) (hinv.selfId_lt (List.mem_of_getElem? hr))
    (fun _ _ h => nomatch h)

/-- A `Commit` from a normal replica in its view, to a replica other than
the primary. -/
theorem MsgOK.commit (dst : ReplicaId) (hn : r.status = .normal) (hdst : dst ≠ s.config.primaryId r.viewNumber) :
    MsgOK s id r (dst, .commit r.viewNumber r.commitNumber) := by
  have hmem := List.mem_of_getElem? hr
  have hlnv : r.lastNormalView = r.viewNumber := (hinv.local_ r hmem).2.2.1 (Or.inl hn)
  refine MsgOK.inert hinv hr (fun _ _ _ h => nomatch h) (fun _ _ _ _ _ _ h => nomatch h)
    (fun _ _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h)
    (fun _ _ _ _ _ h => nomatch h) (fun _ _ _ _ _ _ h => nomatch h) trivial ?_ hdst
    (fun z _ => trivial) trivial (fun _ _ h => nomatch h)
  show Backed _ r.viewNumber r.commitNumber
  exact Backed.after_of (hlnv ▸ hinv.backed.1 r hmem)

/-! ### `PrepareOk`: the acknowledgement -/

/-- A `PrepareOk` for its whole log, from a replica normal in its view.
This is where a quorum completes and a `Committed` fact is born. -/
theorem MsgOK.prepareOk (dst : ReplicaId) (hn : r.status = .normal) :
    MsgOK s id r (dst, .prepareOk r.viewNumber r.log.length r.selfId) := by
  have hmem := List.mem_of_getElem? hr
  have hlnv : r.lastNormalView = r.viewNumber := (hinv.local_ r hmem).2.2.1 (Or.inl hn)
  have hnr : r.status ≠ .recovering := by rw [hn]; decide
  have hself : ∀ z ∈ s.replicas, z.selfId = r.selfId → z = r :=
    fun z hz h => hinv.eq_of_selfId hz hmem h
  -- no DoViewChange from `r` is for a view above its own
  have hnodvc : ∀ u d, DvcOf s u r.selfId d → u ≤ r.viewNumber :=
    fun u d hd => hinv.dvcBelow u r.selfId d hd r hmem rfl
  refine {
    wf := trivial
    okSelf := fun v o q h => by simp only [Message.prepareOk.injEq] at h; exact h.2.2.symm
    oneLogNew := fun v i e e' h _ => (HoldsNew.single h).elim fun off => fun ⟨log, hf, _⟩ => nomatch hf
    oneLogOld := fun _ _ _ i e e' _ h => (HoldsNew.single h).elim fun off => fun ⟨log, hf, _⟩ => nomatch hf
    backed := trivial
    survivesOld := fun _ _ _ _ _ _ =>
      ⟨fun dst log o k h => (nomatch congrArg Prod.snd h),
       fun u q d hd => (nomatch DvcOfNew.single hd),
       fun dst n q stt h => (nomatch congrArg Prod.snd h),
       fun dst log a b k h => (nomatch congrArg Prod.snd h),
       fun dst c n op k h => (nomatch congrArg Prod.snd h)⟩
    survivesNew := ?_
    acksHoldSelf := fun v o h => by
      simp only [Message.prepareOk.injEq] at h
      obtain ⟨rfl, rfl, _⟩ := h
      exact ⟨hlnv ▸ Nat.le_refl _, fun _ _ => Nat.le_refl _⟩
    toOthers := trivial
    longest := fun p hp hpn hpp =>
      ⟨fun off log hf => (nomatch FragNew.single hf), fun o q h => by
        simp only [Message.prepareOk.injEq] at h
        obtain ⟨hv, rfl, _⟩ := h
        exact (hinv.longest p hp hpn hpp).2.1 r hmem (hlnv.trans hv) hnr⟩
    chosenNew := fun dst v log o k h => nomatch congrArg Prod.snd h
    dvcCoversNew := fun u q d hd => nomatch DvcOfNew.single hd
    dvcCoversOk := fun u q d hd o h => by
      simp only [Message.prepareOk.injEq] at h
      obtain ⟨hl, rfl, rfl⟩ := h
      have h1 := hnodvc u d hd
      have h2 := hinv.dvcBehind u _ d hd
      exact absurd (Nat.lt_of_lt_of_le h2 h1) (by rw [hl]; exact Nat.lt_irrefl _)
    dvcBehindNew := fun u q d hd => nomatch DvcOfNew.single hd
    dvcBelowNew := fun u q d hd => nomatch DvcOfNew.single hd
    dvcAfterAcksNew := fun u q d hd => nomatch DvcOfNew.single hd
    dvcAfterAcksOk := fun u q d hd v o h hlt => by
      simp only [Message.prepareOk.injEq] at h
      obtain ⟨rfl, rfl, rfl⟩ := h
      exact absurd (Nat.lt_of_lt_of_le hlt (hnodvc u d hd)) (Nat.lt_irrefl _)
    dvcAfterOwnNew := fun u q d hd => nomatch DvcOfNew.single hd
    dvcPrimaryNew := fun u q d hd => nomatch DvcOfNew.single hd
    dvcPrimaryFrag := fun u q d _ _ off log hf => nomatch FragNew.single hf
    extendsOld := fun v dvcs b _ _ =>
      ⟨fun u q d hd => (nomatch DvcOfNew.single hd),
       fun dst n q stt h => (nomatch congrArg Prod.snd h),
       fun dst log a e k h => (nomatch congrArg Prod.snd h)⟩
    rrNonceNew := fun dst v n q stt h => nomatch congrArg Prod.snd h
    belowNew := fun z hz => MsgOK.below_self hinv hr r.viewNumber (Nat.le_refl _) z hz
    recoveryRR := fun q _ _ dst v n p stt h => nomatch congrArg Prod.snd h
    recoveryOk := fun q hq hqr v o h => by
      simp only [Message.prepareOk.injEq] at h
      have := hself q hq h.2.2.symm
      subst this; exact hnr hqr
    fragStartedNew := fun v off log hf => nomatch FragNew.single hf
    acksStartedNew := fun u o q h hu => by
      simp only [Message.prepareOk.injEq] at h
      obtain ⟨rfl, _, _⟩ := h
      exact hinv.startedViews.2.2 r hmem hnr (hlnv ▸ hu) |>.imp fun d hd => hlnv ▸ hd
    svcPosNew := fun _ _ h => nomatch h
    rrPrimaryNew := fun _ _ _ _ h => nomatch h
    rrNotSelfNew := fun _ _ _ _ h => nomatch h
    senderIdsNew := hinv.selfId_lt hmem }
  -- the new commit survives into every later view
  intro v' i e hc hold u hu
  obtain ⟨rfl, hh⟩ := Committed.after_ok hc hold
  have vh := hinv.viewHolds_of_newAck hr hh hc.2 u hu
  obtain ⟨h1, h2, h3, h4, h5, h6⟩ := vh
  refine ⟨fun dst log o k hs => ?_, fun u' q d hd hl => ?_, fun dst n q stt hs => ?_,
    fun dst log a b k hs ha => ?_, fun dst c n op k hs => ?_, fun z hz hzl hzn => ?_⟩
  · rcases Sent.after.mp hs with hs | hs
    · exact h1 dst log o k hs
    · exact nomatch congrArg Prod.snd (mem_singleton_eq hs)
  · rcases DvcOf.after.mp hd with hd | hd
    · exact h2 u' q d hd hl
    · exact nomatch DvcOfNew.single hd
  · rcases Sent.after.mp hs with hs | hs
    · exact h3 dst n q stt hs
    · exact nomatch congrArg Prod.snd (mem_singleton_eq hs)
  · rcases Sent.after.mp hs with hs | hs
    · exact h4 dst log a b k hs ha
    · exact nomatch congrArg Prod.snd (mem_singleton_eq hs)
  · rcases Sent.after.mp hs with hs | hs
    · exact h5 dst c n op k hs
    · exact nomatch congrArg Prod.snd (mem_singleton_eq hs)
  · rcases mem_after_replicas hinv.ids hr hz with hzr | ⟨hz, _⟩
    · subst hzr; exact h6 _ hmem hzl hzn
    · exact h6 z hz hzl hzn

/-! ### Messages that carry a piece of the sender's own log -/

/-- A message whose fragment is a suffix of the sender's log, tagged with
its last normal view: `NewState`, `StartView`, a recovery state, a
`DoViewChange`. What is left to show is specific to the kind. -/
theorem MsgOK.ownFrag (hnr : r.status ≠ .recovering) {x : ReplicaId × Message Op}
    (hfrag : ∀ v off log, MsgFrag x v off log → v = r.lastNormalView ∧ off ≤ r.log.length ∧ log = r.log.drop off)
    (hnook : ∀ v o q, x.2 ≠ Message.prepareOk v o q)
    (hnoprep : ∀ v o c n op k, x.2 ≠ Message.prepare v o c n op k)
    (wf : WF x.2) (backed : MsgBacked (s.after id r [x] []) x.2)
    (toOthers : match x.2 with
      | .prepare v _ _ _ _ _ => x.1 ≠ s.config.primaryId v
      | .commit v _ => x.1 ≠ s.config.primaryId v
      | _ => True)
    (below : ∀ z ∈ s.replicas, match x.2 with
      | .prepareOk v _ q => z.selfId = q → v ≤ z.viewNumber
      | .getState q v _ => z.selfId = q → v ≤ z.viewNumber
      | .startViewChange v q => z.selfId = q → v ≤ z.viewNumber
      | .doViewChange v q _ _ _ _ => z.selfId = q → v ≤ z.viewNumber
      | .recovery q _ v => z.selfId = q → v ≤ z.viewNumber
      | .recoveryResponse v _ q _ => z.selfId = q → v ≤ z.viewNumber
      | _ => True)
    (senders : match x.2 with
      | .prepareOk _ _ q => q < s.config.replicaCount
      | .getState q _ _ => q < s.config.replicaCount
      | .startViewChange _ q => q < s.config.replicaCount
      | .doViewChange _ q _ _ _ _ => q < s.config.replicaCount
      | .recovery q _ _ => q < s.config.replicaCount
      | .recoveryResponse _ _ q _ => q < s.config.replicaCount
      | _ => True)
    (svcPos : ∀ v q, x.2 = Message.startViewChange v q → 0 < v)
    (hsv : ∀ v log o k, x.2 = Message.startView v log o k → v = r.lastNormalView ∧ log = r.log)
    (hrr : ∀ v n q stt, x.2 = Message.recoveryResponse v n q (some stt) → v = r.lastNormalView ∧ stt.log = r.log)
    (hns : ∀ v log a e k, x.2 = Message.newState v log a e k → v = r.lastNormalView ∧ e = r.log.length ∧
      log = r.log.drop a)
    (hdvc : ∀ u q (d : DoViewChange Op), x.2 = Message.doViewChange u q d.lastNormalView d.log d.log.length d.commitNumber →
      d.lastNormalView = r.lastNormalView ∧ d.log = r.log ∧ q = r.selfId ∧ u = r.viewNumber ∧
      r.status = .viewChange)
    (chosenNew : ∀ dst v log o k, x = (dst, Message.startView v log o k) →
      ∃ dvcs best, (v, dvcs) ∈ s.started ∧ s.config.quorum ≤ dvcs.length ∧
        (dvcs.map Prod.fst).Nodup ∧ Replica.bestDoViewChange dvcs = some best ∧ best.log <+: log)
    (rrNonceNew : ∀ dst v n q stt, x = (dst, Message.recoveryResponse v n q stt) →
      ∃ dst' i v', Sent s dst' (.recovery i n v'))
    (rrPrimaryNew : ∀ v n q stt, x.2 = Message.recoveryResponse v n q (some stt) → q = s.config.primaryId v)
    (rrNotSelfNew : ∀ v n p stt, x.2 = Message.recoveryResponse v n p stt →
      ∀ q ∈ s.replicas, q.status = .recovering → q.recoveryNonce = n → p ≠ q.selfId)
    (recoveryRR : ∀ q ∈ s.replicas, q.status = .recovering →
      ∀ dst v n p stt, x = (dst, Message.recoveryResponse v n p (some stt)) → n = q.recoveryNonce →
        ∀ dst' o, Sent s dst' (.prepareOk v o q.selfId) → o ≤ stt.log.length) :
    MsgOK s id r x := by
  have hmem := List.mem_of_getElem? hr
  -- what the new fragment holds is what `r.log` holds
  have hnew : ∀ v i e, HoldsNew [x] [] v i e → v = r.lastNormalView ∧ r.log[i]? = some e := by
    intro v i e h
    obtain ⟨off, log, hf, hle, hget⟩ := HoldsNew.single h
    obtain ⟨rfl, hoff, rfl⟩ := hfrag v off log hf
    refine ⟨rfl, ?_⟩
    rw [List.getElem?_drop, Nat.add_sub_cancel' hle] at hget
    exact hget
  have hcov : ∀ v i e, HoldsNew [x] [] v i e → Holds s v i e := by
    intro v i e h
    obtain ⟨rfl, he⟩ := hnew v i e h
    obtain ⟨e0, he0⟩ := hinv.covered r hmem i (List.getElem?_eq_some_iff.mp he).1
    rw [hinv.oneLog.2 r hmem i e e0 he he0]; exact he0
  have hfraglen : ∀ v off log, FragNew [x] [] v off log → v = r.lastNormalView ∧ off + log.length = r.log.length := by
    intro v off log hf
    obtain ⟨rfl, hoff, rfl⟩ := hfrag v off log (FragNew.single hf)
    exact ⟨rfl, by rw [List.length_drop]; omega⟩
  have hsurv7 : ∀ v' i e, Committed s v' i e → v' < r.lastNormalView → r.log[i]? = some e :=
    fun v' i e hc hlt => (hinv.survives v' i e hc _ hlt).2.2.2.2.2 r hmem rfl hnr
  refine {
    wf := wf
    okSelf := fun v o q h => absurd h (hnook v o q)
    oneLogNew := fun v i e e' h h' => ?_
    oneLogOld := fun z hz hne i e e' he h => ?_
    backed := backed
    survivesOld := fun v' i e hc v hlt => ?_
    survivesNew := fun v i e hc hold => absurd (Committed.after_single_covered hinv hmem
      (fun v off log hf => ?_) hnook hc) hold
    acksHoldSelf := fun v o h => absurd h (hnook v o _)
    toOthers := toOthers
    longest := fun p hp hpn hpp => ⟨fun off log hf => ?_, fun o q h => absurd h (hnook _ o q)⟩
    chosenNew := chosenNew
    dvcCoversNew := fun u q d hd dst o hs => ?_
    dvcCoversOk := fun u q d _ o h => absurd h (hnook _ o q)
    dvcBehindNew := fun u q d hd => ?_
    dvcBelowNew := fun u q d hd z hz hq => ?_
    dvcAfterAcksNew := fun u q d hd dst v o hs hlt => ?_
    dvcAfterAcksOk := fun u q d _ v o h => absurd h (hnook v o q)
    dvcAfterOwnNew := fun u q d hd v dvcs hv hq hlt => ?_
    dvcPrimaryNew := fun u q d hd hq off log hf => ?_
    dvcPrimaryFrag := fun u q d hd hq off log hf => ?_
    extendsOld := fun v dvcs b hv hb => ?_
    rrNonceNew := rrNonceNew
    belowNew := below
    recoveryRR := recoveryRR
    recoveryOk := fun q _ _ v o => hnook v o q.selfId
    fragStartedNew := fun v off log hf hpos => ?_
    acksStartedNew := fun u o q h => absurd h (hnook u o q)
    svcPosNew := svcPos
    rrPrimaryNew := rrPrimaryNew
    rrNotSelfNew := rrNotSelfNew
    senderIdsNew := senders }
  · -- oneLogNew
    obtain ⟨rfl, he⟩ := hnew _ i e h
    rcases Holds.after.mp h' with h' | h'
    · exact hinv.oneLog.2 r hmem i e e' he h'
    · obtain ⟨_, he'⟩ := hnew _ i e' h'
      rw [he] at he'; exact Option.some.inj he'
  · -- oneLogOld
    obtain ⟨hl, he'⟩ := hnew _ i e' h
    exact hinv.agree z hz r hmem hl i e e' he he'
  · -- survivesOld
    refine ⟨fun dst log o k hx => ?_, fun u q d hd hl => ?_, fun dst n q stt hx => ?_,
      fun dst log a b k hx ha => ?_, fun dst c n op k hx => ?_⟩
    · obtain ⟨rfl, rfl⟩ := hsv v log o k (congrArg Prod.snd hx)
      exact hsurv7 v' i e hc hlt
    · obtain ⟨hl', hlog, _⟩ := hdvc u q d (DvcOfNew.single hd)
      rw [hlog]; exact hsurv7 v' i e hc (by rw [← hl', hl]; exact hlt)
    · obtain ⟨rfl, hlog⟩ := hrr v n q stt (congrArg Prod.snd hx)
      rw [hlog]; exact hsurv7 v' i e hc hlt
    · obtain ⟨rfl, rfl, rfl⟩ := hns v log a b k (congrArg Prod.snd hx)
      rw [List.getElem?_drop, Nat.add_sub_cancel' ha]
      exact hsurv7 v' i e hc hlt
    · exact absurd (congrArg Prod.snd hx) (hnoprep _ _ c n op k)
  · -- survivesNew: the fragment is covered
    obtain ⟨rfl, hoff, rfl⟩ := hfrag v off log hf
    refine ⟨rfl, fun i e hle hget => ?_⟩
    rw [List.getElem?_drop, Nat.add_sub_cancel' hle] at hget; exact hget
  · -- longest: the new fragment is within the primary's log
    obtain ⟨hl, hlen⟩ := hfraglen _ off log hf
    rw [hlen]
    exact (hinv.longest p hp hpn hpp).2.1 r hmem hl.symm hnr
  · -- dvcCoversNew
    obtain ⟨hl, hlog, rfl, rfl, _⟩ := hdvc u q d (DvcOfNew.single hd)
    rcases Sent.after.mp hs with hs | hs
    · rw [hlog]; exact (hinv.acksHold dst _ o r.selfId hs r hmem rfl).2 hl.symm hnr
    · exact absurd (congrArg Prod.snd (mem_singleton_eq hs)).symm (hnook _ o _)
  · -- dvcBehindNew
    obtain ⟨hl, _, _, rfl, hvc⟩ := hdvc u q d (DvcOfNew.single hd)
    rw [hl]; exact hinv.vcBehind r hmem hvc
  · -- dvcBelowNew
    obtain ⟨_, _, rfl, rfl, _⟩ := hdvc u q d (DvcOfNew.single hd)
    rw [hinv.eq_of_selfId hz hmem hq]
  · -- dvcAfterAcksNew
    obtain ⟨hl, _, rfl, rfl, _⟩ := hdvc u q d (DvcOfNew.single hd)
    rw [hl]
    rcases Sent.after.mp hs with hs | hs
    · exact (hinv.acksHold dst v o r.selfId hs r hmem rfl).1
    · exact absurd (congrArg Prod.snd (mem_singleton_eq hs)).symm (hnook _ o _)
  · -- dvcAfterOwnNew
    obtain ⟨hl, _, rfl, rfl, _⟩ := hdvc u q d (DvcOfNew.single hd)
    rw [hl]; exact hinv.primaryStarted v dvcs hv r hmem hq
  · -- dvcPrimaryNew
    obtain ⟨hl, hlog, rfl, rfl, _⟩ := hdvc u q d (DvcOfNew.single hd)
    rw [hlog]
    rcases Frag.after.mp hf with hf | hf
    · exact (hinv.longest r hmem hnr (hl ▸ hq)).1 off log (hl ▸ hf)
    · obtain ⟨_, hlen⟩ := hfraglen _ off log hf
      exact Nat.le_of_eq hlen
  · -- dvcPrimaryFrag: the new fragment is within a primary's DoViewChange
    obtain ⟨hl, hlen⟩ := hfraglen _ off log hf
    rw [hlen]
    exact hinv.log_le_of_frags hmem (fun off' log' hf' => hinv.dvcPrimary u q d hd hq off' log' (hl ▸ hf'))
  · -- extendsOld
    refine ⟨fun u q d hd hl => ?_, fun dst n q stt hx => ?_, fun dst log a e k hx => ?_⟩
    · obtain ⟨hl', hlog, _, _, _⟩ := hdvc u q d (DvcOfNew.single hd)
      rw [hlog]; exact (hinv.extendsBase v dvcs b hv hb).2.2.2 r hmem (hl'.symm.trans hl) hnr
    · obtain ⟨hl, hlog⟩ := hrr v n q stt (congrArg Prod.snd hx)
      rw [hlog]; exact (hinv.extendsBase v dvcs b hv hb).2.2.2 r hmem hl.symm hnr
    · obtain ⟨hl, rfl, _⟩ := hns v log a e k (congrArg Prod.snd hx)
      exact (hinv.extendsBase v dvcs b hv hb).2.2.2 r hmem hl.symm hnr
  · -- fragStartedNew
    obtain ⟨rfl, _⟩ := hfraglen _ off log hf
    exact hinv.startedViews.2.2 r hmem hnr hpos

/-- `NewState`: a suffix of a normal replica's log. -/
theorem MsgOK.newState (dst : ReplicaId) (hn : r.status = .normal) {o : OpNumber} (ho : o ≤ r.log.length) :
    MsgOK s id r (dst, .newState r.viewNumber (r.log.drop o) o r.log.length r.commitNumber) := by
  have hmem := List.mem_of_getElem? hr
  have hlnv : r.lastNormalView = r.viewNumber := (hinv.local_ r hmem).2.2.1 (Or.inl hn)
  have hnr : r.status ≠ .recovering := by rw [hn]; decide
  refine MsgOK.ownFrag hinv hr hnr (fun v off log hf => ?_) (fun _ _ _ h => nomatch h)
    (fun _ _ _ _ _ _ h => nomatch h) ⟨List.length_drop, ho, (hinv.local_ r hmem).1⟩ ?_ trivial
    (fun z _ => trivial) trivial (fun _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h)
    (fun _ _ _ _ h => nomatch h) (fun v log a e k h => ?_) (fun _ _ _ h => nomatch h)
    (fun _ _ _ _ _ h => nomatch (congrArg Prod.snd h)) (fun _ _ _ _ _ h => nomatch (congrArg Prod.snd h))
    (fun _ _ _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h)
    (fun _ _ _ _ _ _ _ _ h => nomatch (congrArg Prod.snd h))
  · obtain ⟨rfl, rfl, rfl⟩ := MsgFrag.newState_inv hf
    exact ⟨hlnv.symm, ho, rfl⟩
  · show Backed _ r.viewNumber r.commitNumber
    exact Backed.after_of (hlnv ▸ hinv.backed.1 r hmem)
  · simp only [Message.newState.injEq] at h
    obtain ⟨rfl, rfl, rfl, rfl, _⟩ := h
    exact ⟨hlnv.symm, rfl, rfl⟩

/-- `StartView` re-sent by the normal primary of a started view. -/
theorem MsgOK.startView (dst : ReplicaId) (hn : r.status = .normal) (hp : r.isPrimary = true)
    (hpos : 0 < r.viewNumber) :
    MsgOK s id r (dst, .startView r.viewNumber r.log r.log.length r.commitNumber) := by
  have hmem := List.mem_of_getElem? hr
  have hlnv : r.lastNormalView = r.viewNumber := (hinv.local_ r hmem).2.2.1 (Or.inl hn)
  have hnr : r.status ≠ .recovering := by rw [hn]; decide
  refine MsgOK.ownFrag hinv hr hnr (fun v off log hf => ?_) (fun _ _ _ h => nomatch h)
    (fun _ _ _ _ _ _ h => nomatch h) ⟨rfl, (hinv.local_ r hmem).1⟩ ?_ trivial
    (fun z _ => trivial) trivial (fun _ _ h => nomatch h) (fun v log o k h => ?_)
    (fun _ _ _ _ h => nomatch h) (fun _ _ _ _ _ h => nomatch h) (fun _ _ _ h => nomatch h)
    (fun dst' v log o k h => ?_) (fun _ _ _ _ _ h => nomatch (congrArg Prod.snd h))
    (fun _ _ _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h)
    (fun _ _ _ _ _ _ _ _ h => nomatch (congrArg Prod.snd h))
  · obtain ⟨rfl, rfl, rfl⟩ := MsgFrag.startView_inv hf
    exact ⟨hlnv.symm, Nat.zero_le _, by simp⟩
  · show Backed _ r.viewNumber r.commitNumber
    exact Backed.after_of (hlnv ▸ hinv.backed.1 r hmem)
  · simp only [Message.startView.injEq] at h
    obtain ⟨rfl, rfl, _⟩ := h
    exact ⟨hlnv.symm, rfl⟩
  · -- the started view's base is a prefix of the primary's log
    simp only [Prod.mk.injEq, Message.startView.injEq] at h
    obtain ⟨_, rfl, rfl, _, _⟩ := h
    have hconf := hinv.config_eq hmem
    have hprim : r.selfId = s.config.primaryId r.viewNumber := by
      unfold Replica.isPrimary Replica.primaryId at hp; rw [← hconf]; exact of_decide_eq_true hp
    obtain ⟨dvcs, hv⟩ := hinv.startedViews.2.2 r hmem hnr (hlnv ▸ hpos)
    obtain ⟨dst0, L0, o0, k0, hsv0⟩ := hinv.startedViews.1 _ dvcs hv
    obtain ⟨dvcs', b, hv', hq, hnd, hb, hpre⟩ := hinv.chosen dst0 _ L0 o0 k0 hsv0
    obtain rfl := hinv.startedOnce _ dvcs dvcs' hv hv'
    refine ⟨dvcs, b, hlnv ▸ hv, hq, hnd, hb, hpre.trans (List.prefix_of_agree ?_ ?_)⟩
    · have := (hinv.longest r hmem hnr (hlnv ▸ hprim)).1 0 L0 (.startView hsv0)
      simpa using this
    · intro i a c ha hc
      exact (hinv.oneLog.2 r hmem i c a hc ⟨0, L0, .startView hsv0, Nat.zero_le _, by simpa using ha⟩).symm

/-- A `RecoveryResponse` from a normal replica, with its state if it is
the primary, answering a `Recovery` in `sent`. -/
theorem MsgOK.recoveryResponse (dst : ReplicaId) (hn : r.status = .normal) {n : Nat}
    (hrec : ∃ dst' i v', Sent s dst' (.recovery i n v'))
    (hnotself : ∀ q ∈ s.replicas, q.status = .recovering → q.recoveryNonce = n → r.selfId ≠ q.selfId) :
    MsgOK s id r (dst, .recoveryResponse r.viewNumber n r.selfId
      (if r.isPrimary then some ⟨r.log, r.commitNumber⟩ else none)) := by
  have hmem := List.mem_of_getElem? hr
  have hlnv : r.lastNormalView = r.viewNumber := (hinv.local_ r hmem).2.2.1 (Or.inl hn)
  have hnr : r.status ≠ .recovering := by rw [hn]; decide
  have hconf := hinv.config_eq hmem
  have hprim : r.isPrimary = true → r.selfId = s.config.primaryId r.viewNumber := by
    intro hp; unfold Replica.isPrimary Replica.primaryId at hp; rw [← hconf]; exact of_decide_eq_true hp
  refine MsgOK.ownFrag hinv hr hnr (fun v off log hf => ?_) (fun _ _ _ h => nomatch h)
    (fun _ _ _ _ _ _ h => nomatch h) ?_ ?_ trivial
    (fun z hz => MsgOK.below_self hinv hr r.viewNumber (Nat.le_refl _) z hz) (hinv.selfId_lt hmem)
    (fun _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h) (fun v n' q stt h => ?_)
    (fun _ _ _ _ _ h => nomatch h) (fun _ _ _ h => nomatch h)
    (fun _ _ _ _ _ h => nomatch (congrArg Prod.snd h)) (fun dst' v n' q stt h => ?_)
    (fun v n' q stt h => ?_) (fun v n' p stt h => ?_) (fun q hq hqr dst' v n' p stt hx hn' dst'' o hs => ?_)
  · obtain ⟨stt, hst, rfl, rfl, rfl⟩ := MsgFrag.recovery_inv hf
    split at hst
    · obtain rfl := Option.some.inj hst
      exact ⟨hlnv.symm, Nat.zero_le _, by simp⟩
    · exact absurd hst (by simp)
  · show WF (Message.recoveryResponse _ _ _ _)
    split
    · exact (hinv.local_ r hmem).1
    · trivial
  · show MsgBacked _ (Message.recoveryResponse _ _ _ _)
    split
    · exact Backed.after_of (hlnv ▸ hinv.backed.1 r hmem)
    · trivial
  · simp only [Message.recoveryResponse.injEq] at h
    obtain ⟨rfl, _, _, hst⟩ := h
    split at hst
    · obtain rfl := Option.some.inj hst.symm
      exact ⟨hlnv.symm, rfl⟩
    · exact absurd hst.symm (by simp)
  · simp only [Prod.mk.injEq, Message.recoveryResponse.injEq] at h
    obtain ⟨_, _, rfl, _, _⟩ := h
    exact hrec
  · simp only [Message.recoveryResponse.injEq] at h
    obtain ⟨rfl, _, rfl, hst⟩ := h
    split at hst
    · exact hprim (by assumption)
    · exact absurd hst.symm (by simp)
  · simp only [Message.recoveryResponse.injEq] at h
    obtain ⟨_, rfl, rfl, _⟩ := h
    exact hnotself
  · simp only [Prod.mk.injEq, Message.recoveryResponse.injEq] at hx
    obtain ⟨_, rfl, rfl, rfl, hst⟩ := hx
    split at hst
    · obtain rfl := Option.some.inj hst.symm
      exact (hinv.longest r hmem hnr (hlnv ▸ hprim (by assumption))).2.2 dst'' o q.selfId (hlnv ▸ hs)
    · exact absurd hst.symm (by simp)

/-- A `DoViewChange` from a replica in view-change status. -/
theorem MsgOK.doViewChange (dst : ReplicaId) (hvc : r.status = .viewChange) :
    MsgOK s id r (dst, .doViewChange r.viewNumber r.selfId r.lastNormalView r.log r.log.length r.commitNumber) := by
  have hmem := List.mem_of_getElem? hr
  have hnr : r.status ≠ .recovering := by rw [hvc]; decide
  refine MsgOK.ownFrag hinv hr hnr (fun v off log hf => ?_) (fun _ _ _ h => nomatch h)
    (fun _ _ _ _ _ _ h => nomatch h) ⟨rfl, (hinv.local_ r hmem).1, (hinv.local_ r hmem).2.1⟩
    (Backed.after_of (hinv.backed.1 r hmem)) trivial
    (fun z hz => MsgOK.below_self hinv hr r.viewNumber (Nat.le_refl _) z hz) (hinv.selfId_lt hmem)
    (fun _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h)
    (fun _ _ _ _ _ h => nomatch h) (fun u q d h => ?_)
    (fun _ _ _ _ _ h => nomatch (congrArg Prod.snd h)) (fun _ _ _ _ _ h => nomatch (congrArg Prod.snd h))
    (fun _ _ _ _ h => nomatch h) (fun _ _ _ _ h => nomatch h)
    (fun _ _ _ _ _ _ _ _ h => nomatch (congrArg Prod.snd h))
  · obtain ⟨rfl, rfl, rfl⟩ := MsgFrag.dvc_inv hf
    exact ⟨rfl, Nat.zero_le _, by simp⟩
  · simp only [Message.doViewChange.injEq] at h
    obtain ⟨rfl, rfl, hl, hlog, _, _⟩ := h
    exact ⟨hl.symm, hlog.symm, rfl, rfl, hvc⟩

/-- A `Prepare` re-sent by the normal primary: its entry is already in
the history. -/
theorem MsgOK.prepareResend (dst : ReplicaId) (hn : r.status = .normal) (hp : r.isPrimary = true)
    {o : OpNumber} {e : LogEntry Op} (ho : 0 < o) (he : r.log[o - 1]? = some e)
    (hdst : dst ≠ s.config.primaryId r.viewNumber) :
    MsgOK s id r (dst, .prepare r.viewNumber o e.clientId e.requestNumber e.op r.commitNumber) := by
  have hmem := List.mem_of_getElem? hr
  have hlnv : r.lastNormalView = r.viewNumber := (hinv.local_ r hmem).2.2.1 (Or.inl hn)
  have hnr : r.status ≠ .recovering := by rw [hn]; decide
  have hconf := hinv.config_eq hmem
  have hprim : r.selfId = s.config.primaryId r.viewNumber := by
    unfold Replica.isPrimary Replica.primaryId at hp; rw [← hconf]; exact of_decide_eq_true hp
  have hlt : o - 1 < r.log.length := (List.getElem?_eq_some_iff.mp he).1
  -- the fragment holds `e` at `o - 1`, which `r.log` holds
  have hnew : ∀ v i e', HoldsNew [(dst, Message.prepare r.viewNumber o e.clientId e.requestNumber e.op r.commitNumber)] [] v i e' →
      v = r.lastNormalView ∧ i = o - 1 ∧ e' = e := by
    intro v i e' h
    obtain ⟨off, log, hf, hle, hget⟩ := HoldsNew.single h
    obtain ⟨rfl, rfl, rfl⟩ := MsgFrag.prepare_inv hf
    have hi : i - (o - 1) < 1 := by simpa using (List.getElem?_eq_some_iff.mp hget).1
    have hi' : i = o - 1 := by omega
    subst hi'
    simp only [Nat.sub_self, List.getElem?_cons_zero, Option.some.injEq] at hget
    exact ⟨hlnv.symm, rfl, by rw [← hget]⟩
  have hcov : ∀ v i e', HoldsNew [(dst, Message.prepare r.viewNumber o e.clientId e.requestNumber e.op r.commitNumber)] [] v i e' →
      Holds s v i e' := by
    intro v i e' h
    obtain ⟨rfl, rfl, rfl⟩ := hnew v i e' h
    obtain ⟨e0, he0⟩ := hinv.covered r hmem (o - 1) hlt
    rw [hinv.oneLog.2 r hmem (o - 1) e' e0 he he0]; exact he0
  have hfraglen : ∀ v off log, FragNew [(dst, Message.prepare r.viewNumber o e.clientId e.requestNumber e.op r.commitNumber)] [] v off log →
      v = r.lastNormalView ∧ off + log.length ≤ r.log.length := by
    intro v off log hf
    obtain ⟨rfl, rfl, rfl⟩ := MsgFrag.prepare_inv (FragNew.single hf)
    exact ⟨hlnv.symm, by simp; omega⟩
  refine {
    wf := ho
    okSelf := fun _ _ _ h => nomatch h
    oneLogNew := fun v i e1 e2 h h' => ?_
    oneLogOld := fun z hz hne i e1 e2 he1 h => ?_
    backed := Backed.after_of (hlnv ▸ hinv.backed.1 r hmem)
    survivesOld := fun v' i e0 hc v hlt' => ⟨fun _ _ _ _ h => (nomatch congrArg Prod.snd h),
      fun _ _ _ hd => (nomatch DvcOfNew.single hd), fun _ _ _ _ h => (nomatch congrArg Prod.snd h),
      fun _ _ _ _ _ h => (nomatch congrArg Prod.snd h), fun dst' c n op k hx => ?_⟩
    survivesNew := fun v i e0 hc hold => absurd ⟨?_, QuorumAcked.after_noOk
      (fun y hy => by rw [mem_singleton_eq hy]; exact fun _ _ _ h => nomatch h) hc.2⟩ hold
    acksHoldSelf := fun _ _ h => nomatch h
    toOthers := hdst
    longest := fun p hp hpn hpp => ⟨fun off log hf => ?_, fun _ _ h => nomatch h⟩
    chosenNew := fun _ _ _ _ _ h => nomatch (congrArg Prod.snd h)
    dvcCoversNew := fun _ _ _ hd => nomatch DvcOfNew.single hd
    dvcCoversOk := fun _ _ _ _ _ h => nomatch h
    dvcBehindNew := fun _ _ _ hd => nomatch DvcOfNew.single hd
    dvcBelowNew := fun _ _ _ hd => nomatch DvcOfNew.single hd
    dvcAfterAcksNew := fun _ _ _ hd => nomatch DvcOfNew.single hd
    dvcAfterAcksOk := fun _ _ _ _ _ _ h => nomatch h
    dvcAfterOwnNew := fun _ _ _ hd => nomatch DvcOfNew.single hd
    dvcPrimaryNew := fun _ _ _ hd => nomatch DvcOfNew.single hd
    dvcPrimaryFrag := fun u q d hd hq off log hf => ?_
    extendsOld := fun v dvcs b hv hb => ⟨fun _ _ _ hd => (nomatch DvcOfNew.single hd),
      fun _ _ _ _ h => (nomatch congrArg Prod.snd h), fun _ _ _ _ _ h => nomatch (congrArg Prod.snd h)⟩
    rrNonceNew := fun _ _ _ _ _ h => nomatch (congrArg Prod.snd h)
    belowNew := fun z _ => trivial
    recoveryRR := fun _ _ _ _ _ _ _ _ h => nomatch (congrArg Prod.snd h)
    recoveryOk := fun _ _ _ _ _ h => nomatch h
    fragStartedNew := fun v off log hf hpos => ?_
    acksStartedNew := fun _ _ _ h => nomatch h
    svcPosNew := fun _ _ h => nomatch h
    rrPrimaryNew := fun _ _ _ _ h => nomatch h
    rrNotSelfNew := fun _ _ _ _ h => nomatch h
    senderIdsNew := trivial }
  · obtain ⟨rfl, rfl, rfl⟩ := hnew _ i e1 h
    rcases Holds.after.mp h' with h' | h'
    · exact hinv.oneLog.2 r hmem (o - 1) e1 e2 he h'
    · obtain ⟨_, _, rfl⟩ := hnew _ _ e2 h'; rfl
  · obtain ⟨hl, rfl, rfl⟩ := hnew _ i e2 h
    exact hinv.agree z hz r hmem hl (o - 1) e1 e2 he1 he
  · -- a re-sent Prepare for a committed index carries the committed entry
    simp only [Prod.mk.injEq, Message.prepare.injEq] at hx
    obtain ⟨_, rfl, hio, rfl, rfl, rfl, _⟩ := hx
    have h7 := (hinv.survives v' i e0 hc _ hlt').2.2.2.2.2 r hmem hlnv hnr
    have : o - 1 = i := by rw [hio, Nat.add_sub_cancel]
    rw [this] at he; rw [he] at h7
    show e = e0
    exact Option.some.inj h7
  · -- survivesNew: covered
    rcases Holds.after.mp hc.1 with h | h
    · exact h
    · exact hcov _ _ _ h
  · obtain ⟨hl, hlen⟩ := hfraglen _ off log hf
    exact Nat.le_trans hlen ((hinv.longest p hp hpn hpp).2.1 r hmem hl.symm hnr)
  · obtain ⟨hl, hlen⟩ := hfraglen _ off log hf
    exact Nat.le_trans hlen (hinv.log_le_of_frags hmem
      (fun off' log' hf' => hinv.dvcPrimary u q d hd hq off' log' (hl ▸ hf')))
  · obtain ⟨rfl, _⟩ := hfraglen _ off log hf
    exact hinv.startedViews.2.2 r hmem hnr hpos

end Sender

end Vsr
