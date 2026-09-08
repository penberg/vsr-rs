import Vsr.Preserve.After

/-!
The shapes a handler proof is built from.

A handler is a chain of helpers, each of which changes the replica or
sends. `System.drainOf s id r` is the cluster as it would be if the replica
in progress, `r`, were drained now. A handler proof carries
`Inv (s.drainOf id r)` along the chain: it starts as `Inv s`, since the
replica starts clean, and ends as `Inv` of the drained cluster. Each link
is one of two shapes: the replica changes and sends nothing
(`StepOK.replace`), or it sends one message and does not change
(`StepOK.send`, from `MsgOK`).
-/

namespace Vsr

variable {Op Output St : Type}

/-! ### The drained view -/

/-- The cluster with replica `id` replaced by `r` drained. -/
def System.drainOf (s : System Op Output St) (id : ReplicaId) (r : Replica Op Output St) :
    System Op Output St :=
  s.after id r.clear r.outbox r.startedList

@[simp] theorem System.drainOf_config (s : System Op Output St) (id : ReplicaId) (r : Replica Op Output St) :
    (s.drainOf id r).config = s.config := rfl
@[simp] theorem System.drainOf_sent (s : System Op Output St) (id : ReplicaId) (r : Replica Op Output St) :
    (s.drainOf id r).sent = s.sent ++ r.outbox := rfl
@[simp] theorem System.drainOf_started (s : System Op Output St) (id : ReplicaId) (r : Replica Op Output St) :
    (s.drainOf id r).started = s.started ++ r.startedList := rfl

theorem System.drain_eq_drainOf (s : System Op Output St) (id : ReplicaId) (r : Replica Op Output St) :
    s.drain id r = { s.drainOf id r with replies := s.replies ++ r.replies } :=
  s.drain_eq_after id r

theorem Inv.ofDrainOf {s : System Op Output St} {id : ReplicaId} {r : Replica Op Output St}
    (h : Inv (s.drainOf id r)) : Inv (s.drain id r) := by
  rw [System.drain_eq_drainOf]; exact h.withReplies _

theorem System.after_after (s : System Op Output St) (id : ReplicaId) (r1 r2 : Replica Op Output St)
    (o1 o2 : List (ReplicaId × Message Op)) (s1 s2 : List (ViewNumber × List (ReplicaId × DoViewChange Op))) :
    (s.after id r1 o1 s1).after id r2 o2 s2 = s.after id r2 (o1 ++ o2) (s1 ++ s2) := by
  simp [System.after, List.set_set, List.append_assoc]

theorem List.set_getElem?_self' {α : Type} : ∀ (l : List α) (i : Nat) (x : α), l[i]? = some x → l.set i x = l
  | [], _, _, h => by simp at h
  | a :: l, 0, x, h => by simp at h; rw [h]; rfl
  | a :: l, i + 1, x, h => by
    simp only [List.getElem?_cons_succ] at h
    simp [List.set_getElem?_self' l i x h]

/-- A clean replica drained is no change. -/
theorem System.drainOf_clean (s : System Op Output St) {id : ReplicaId} {r : Replica Op Output St}
    (hr : s.replicas[id]? = some r) (ho : r.outbox = []) (hp : r.replies = [])
    (hc : r.chosenDoViewChanges = none) : s.drainOf id r = s := by
  have hclear : r.clear = r := by
    unfold Replica.clear; rw [← ho, ← hp, ← hc]
  have hst : r.startedList = [] := by unfold Replica.startedList; rw [hc]
  unfold System.drainOf System.after
  rw [hclear, ho, hst, List.append_nil, List.append_nil]
  cases s with
  | mk config replicas sent replies started =>
    simp only
    congr 1
    exact List.set_getElem?_self' _ _ _ hr

/-- The drained view of the replica after one more helper is the drained
view before it, after a step with what the helper added. -/
theorem System.drainOf_step (s : System Op Output St) (id : ReplicaId) {r1 r2 : Replica Op Output St}
    {out : List (ReplicaId × Message Op)} {st : List (ViewNumber × List (ReplicaId × DoViewChange Op))}
    (hout : r2.outbox = r1.outbox ++ out) (hst : r2.startedList = r1.startedList ++ st) :
    s.drainOf id r2 = (s.drainOf id r1).after id r2.clear out st := by
  unfold System.drainOf
  rw [System.after_after, hout, hst]

theorem System.drainOf_replicas_self (s : System Op Output St) {id : ReplicaId} (r : Replica Op Output St)
    (hlt : id < s.replicas.length) : (s.drainOf id r).replicas[id]? = some r.clear := by
  unfold System.drainOf System.after
  exact List.getElem?_set_self hlt

theorem System.drainOf_length (s : System Op Output St) (id : ReplicaId) (r : Replica Op Output St) :
    (s.drainOf id r).replicas.length = s.replicas.length := by
  unfold System.drainOf System.after; simp

/-- One link of a handler proof. -/
theorem Inv.drainStep {s : System Op Output St} {id : ReplicaId} {r1 r2 : Replica Op Output St}
    (hinv : Inv (s.drainOf id r1)) (hlt : id < s.replicas.length)
    {out : List (ReplicaId × Message Op)} {st : List (ViewNumber × List (ReplicaId × DoViewChange Op))}
    (hout : r2.outbox = r1.outbox ++ out) (hst : r2.startedList = r1.startedList ++ st)
    (h : StepOK (s.drainOf id r1) id r1.clear r2.clear out st) : Inv (s.drainOf id r2) := by
  rw [System.drainOf_step s id hout hst]
  exact hinv.after (s.drainOf_replicas_self r1 hlt) h

/-- `startedList` of a replica that has not started a view. -/
theorem Replica.startedList_none {r : Replica Op Output St} (h : r.chosenDoViewChanges = none) :
    r.startedList = [] := by unfold Replica.startedList; rw [h]

theorem Replica.startedList_some {r : Replica Op Output St} {dvcs} (h : r.chosenDoViewChanges = some dvcs) :
    r.startedList = [(r.viewNumber, dvcs)] := by unfold Replica.startedList; rw [h]

/-! ### Nothing new -/

section Nil
variable {s : System Op Output St} {id : ReplicaId} {r' : Replica Op Output St}

theorem FragNew.nil {v off log} (h : FragNew ([] : List (ReplicaId × Message Op)) [] v off log) : False := by
  rcases h with ⟨x, hx, _⟩ | ⟨_, _, _, _, h, _⟩
  · simp at hx
  · simp at h

theorem HoldsNew.nil {v i e} (h : HoldsNew ([] : List (ReplicaId × Message Op)) [] v i e) : False :=
  let ⟨_, _, hf, _, _⟩ := h; FragNew.nil hf

theorem DvcOfNew.nil {u x d} (h : DvcOfNew ([] : List (ReplicaId × Message Op)) [] u x d) : False := by
  rcases h with ⟨_, h⟩ | ⟨_, h, _⟩ <;> simp at h

theorem Sent.after_nil {to : ReplicaId} {msg : Message Op} :
    Sent (s.after id r' [] []) to msg ↔ Sent s to msg := by
  rw [Sent.after]; simp

theorem Holds.after_nil {v i e} : Holds (s.after id r' [] []) v i e ↔ Holds s v i e := by
  rw [Holds.after]; exact ⟨fun h => h.elim (fun h => h) (fun h => (HoldsNew.nil h).elim), Or.inl⟩

theorem Frag.after_nil {v off log} : Frag (s.after id r' [] []) v off log ↔ Frag s v off log := by
  rw [Frag.after]; exact ⟨fun h => h.elim (fun h => h) (fun h => (FragNew.nil h).elim), Or.inl⟩

theorem DvcOf.after_nil {u x d} : DvcOf (s.after id r' [] []) u x d ↔ DvcOf s u x d := by
  rw [DvcOf.after]; exact ⟨fun h => h.elim (fun h => h) (fun h => (DvcOfNew.nil h).elim), Or.inl⟩

theorem started_after_nil {x : ViewNumber × List (ReplicaId × DoViewChange Op)} :
    x ∈ (s.after id r' [] []).started ↔ x ∈ s.started := by
  rw [mem_started_after]; simp

theorem Committed.after_nil {v i e} : Committed (s.after id r' [] []) v i e ↔ Committed s v i e :=
  ⟨fun h => ⟨Holds.after_nil.mp h.1, QuorumAcked.after_noOk (fun _ hx => by simp at hx) h.2⟩,
   Committed.after_of⟩

end Nil

/-! ### Shape one: the replica changes, nothing is sent -/

/-- What a step that only changes the replica has to show. -/
theorem StepOK.replace {s : System Op Output St} (hinv : Inv s) {id : ReplicaId}
    {r r' : Replica Op Output St} (hr : s.replicas[id]? = some r)
    (self : r'.selfId = r.selfId) (conf : r'.config = r.config) (panic : r'.panicked = false)
    (outbox : r'.outbox = []) (replies : r'.replies = []) (chosen : r'.chosenDoViewChanges = none)
    (local_ : Replica.LocalInv r') (view : r.viewNumber ≤ r'.viewNumber)
    (lnv : r.lastNormalView ≤ r'.lastNormalView)
    (oneLog : ∀ i e e', r'.log[i]? = some e → Holds s r'.lastNormalView i e' → e = e')
    (backed : Backed s r'.lastNormalView r'.commitNumber)
    (survives : ∀ v' i e, Committed s v' i e → v' < r'.lastNormalView → r'.status ≠ .recovering →
      r'.log[i]? = some e)
    (acks : r'.status = .normal → r'.isPrimary = true → ∀ oa ∈ r'.acks, oa.1 ≤ r'.log.length ∧
      oa.2.Pairwise (· < ·) ∧ ∀ q ∈ oa.2, q < s.config.replicaCount ∧
        (q = r'.selfId ∨ ∃ to, Sent s to (.prepareOk r'.viewNumber oa.1 q)))
    (catching : r'.catchingUp = true → r'.selfId ≠ r'.config.primaryId r'.viewNumber)
    (acksHold : ∀ to v o, Sent s to (.prepareOk v o r'.selfId) →
      v ≤ r'.lastNormalView ∧ (r'.lastNormalView = v → r'.status ≠ .recovering → o ≤ r'.log.length))
    (longestSelf : r'.status ≠ .recovering → r'.selfId = s.config.primaryId r'.lastNormalView →
      (∀ off log, Frag s r'.lastNormalView off log → off + log.length ≤ r'.log.length) ∧
      (∀ q ∈ s.replicas, q.selfId ≠ r.selfId → q.lastNormalView = r'.lastNormalView →
        q.status ≠ .recovering → q.log.length ≤ r'.log.length) ∧
      (∀ to o q, Sent s to (.prepareOk r'.lastNormalView o q) → o ≤ r'.log.length))
    (longestOld : ∀ p ∈ s.replicas, p.selfId ≠ r.selfId → p.status ≠ .recovering →
      p.selfId = s.config.primaryId p.lastNormalView → r'.lastNormalView = p.lastNormalView →
      r'.status ≠ .recovering → r'.log.length ≤ p.log.length)
    (vcBehind : r'.status = .viewChange → r'.lastNormalView < r'.viewNumber)
    (extends_ : ∀ v dvcs b, (v, dvcs) ∈ s.started → Replica.bestDoViewChange dvcs = some b →
      r'.lastNormalView = v → r'.status ≠ .recovering → b.log.length ≤ r'.log.length)
    (recovery : r'.status = .recovering → ∀ to v n q stt, Sent s to (.recoveryResponse v n q (some stt)) →
      n = r'.recoveryNonce → ∀ to' o, Sent s to' (.prepareOk v o r'.selfId) → o ≤ stt.log.length)
    (covered : ∀ i, i < r'.log.length → ∃ e, Holds s r'.lastNormalView i e)
    (agree : ∀ z ∈ s.replicas, z.selfId ≠ r.selfId → z.lastNormalView = r'.lastNormalView →
      ∀ (i : Nat) (e e' : LogEntry Op), r'.log[i]? = some e → z.log[i]? = some e' → e = e')
    (started : r'.status ≠ .recovering → 0 < r'.lastNormalView →
      ∃ dvcs, (r'.lastNormalView, dvcs) ∈ s.started)
    (transfer : r'.status = .stateTransfer → r'.selfId ≠ s.config.primaryId r'.viewNumber)
    (rrNotSelf : r'.status = .recovering → ∀ to v n p stt, Sent s to (.recoveryResponse v n p stt) →
      r'.recoveryNonce = n → p ≠ r'.selfId)
    (dvcs : r'.status = .viewChange →
      (r'.doViewChangeFrom.map Prod.fst).Pairwise (· < ·) ∧
      ∀ x d, (x, d) ∈ r'.doViewChangeFrom → x < s.config.replicaCount ∧
        ((∃ dst, Sent s dst (.doViewChange r'.viewNumber x d.lastNormalView d.log d.log.length d.commitNumber)) ∨
          (x = r'.selfId ∧ d = ⟨r'.lastNormalView, r'.log, r'.commitNumber⟩)))
    (rrs : r'.status = .recovering →
      ∀ x (resp : RecoveryResponse Op), (x, resp) ∈ r'.recoveryResponses →
        ∃ dst, Sent s dst (.recoveryResponse resp.viewNumber r'.recoveryNonce x resp.state)) :
    StepOK s id r r' [] [] where
  self := self
  conf := conf
  panic := panic
  outbox := outbox
  replies := replies
  chosen := chosen
  local_ := local_
  view := view
  lnv := lnv
  wf := fun x hx => by simp at hx
  okSelf := fun x hx => by simp at hx
  oneLogNew := fun _ _ _ _ h => (HoldsNew.nil h).elim
  oneLogSelf := fun i e e' he hh => oneLog i e e' he (Holds.after_nil.mp hh)
  oneLogOld := fun _ _ _ _ _ _ _ h => (HoldsNew.nil h).elim
  backedSelf := Backed.after_of backed
  backedOut := fun x hx => by simp at hx
  survivesOld := fun v' i e hc v hlt =>
    ⟨fun _ _ _ _ h => by simp at h, fun _ _ _ h => (DvcOfNew.nil h).elim, fun _ _ _ _ h => by simp at h,
     fun _ _ _ _ _ h => by simp at h, fun _ _ _ _ _ h => by simp at h,
     fun hv hn => survives v' i e hc (hv ▸ hlt) hn⟩
  survivesNew := fun v' i e hc hold => absurd (Committed.after_nil.mp hc) hold
  acksSelf := fun hn hp oa hoa =>
    ⟨(acks hn hp oa hoa).1, (acks hn hp oa hoa).2.1, fun q hq => ⟨((acks hn hp oa hoa).2.2 q hq).1,
      ((acks hn hp oa hoa).2.2 q hq).2.imp (fun h => h) (fun ⟨to, ht⟩ => ⟨to, Sent.after_of ht⟩)⟩⟩
  catchingSelf := catching
  acksHoldSelf := fun to v o hs => acksHold to v o (Sent.after_nil.mp hs)
  toOthers := fun x hx => by simp at hx
  longestSelf := fun hn hp => by
    obtain ⟨l1, l2, l3⟩ := longestSelf hn hp
    refine ⟨fun off log hf => l1 off log (Frag.after_nil.mp hf), fun q hq hql hqn => ?_,
      fun to o q hs => l3 to o q (Sent.after_nil.mp hs)⟩
    rcases mem_after_replicas hinv.ids hr hq with hqr | ⟨hq, hne⟩
    · subst hqr; exact Nat.le_refl _
    · exact l2 q hq hne hql hqn
  longestOld := fun p hp hne hpn hpp =>
    ⟨fun _ _ h => (FragNew.nil h).elim, longestOld p hp hne hpn hpp, fun x hx => by simp at hx⟩
  chosenNew := fun _ _ _ _ _ h => by simp at h
  dvcCoversNew := fun _ _ _ h => (DvcOfNew.nil h).elim
  dvcCoversOk := fun _ _ _ _ x hx => by simp at hx
  dvcBehindNew := fun _ _ _ h => (DvcOfNew.nil h).elim
  dvcBelowNew := fun _ _ _ h => (DvcOfNew.nil h).elim
  dvcAfterAcksNew := fun _ _ _ h => (DvcOfNew.nil h).elim
  dvcAfterAcksOk := fun _ _ _ _ x hx => by simp at hx
  dvcAfterOwnNew := fun _ _ _ h => (DvcOfNew.nil h).elim
  dvcAfterOwnSt := fun _ _ _ _ _ _ h => by simp at h
  dvcPrimaryNew := fun _ _ _ h => (DvcOfNew.nil h).elim
  dvcPrimaryFrag := fun _ _ _ _ _ _ _ h => (FragNew.nil h).elim
  vcBehindSelf := vcBehind
  primaryStartedNew := fun _ _ h => by simp at h
  startedOnceNew := fun _ _ h => by simp at h
  extendsOld := fun v dvcs b hv hb =>
    ⟨fun _ _ _ h => (DvcOfNew.nil h).elim, fun _ _ _ _ h => by simp at h, fun _ _ _ _ _ h => by simp at h,
     extends_ v dvcs b hv hb⟩
  extendsNew := fun _ _ _ h => by simp at h
  rrNonceNew := fun _ _ _ _ _ h => by simp at h
  belowNew := fun x hx => by simp at hx
  recoverySelf := fun hrec to v n q stt hs hn to' o hs' =>
    recovery hrec to v n q stt (Sent.after_nil.mp hs) hn to' o (Sent.after_nil.mp hs')
  recoveryOk := fun _ _ _ _ _ _ _ _ _ _ _ y hy => by simp at hy
  recoveryRR := fun _ _ _ _ _ _ _ _ _ h => by simp at h
  coveredSelf := fun i hi => (covered i hi).imp fun e he => Holds.after_of he
  agreeSelf := agree
  startedViewsNew := fun _ _ h => by simp at h
  fragStartedNew := fun _ _ _ h => (FragNew.nil h).elim
  selfStarted := fun hn hpos => (started hn hpos).imp fun dvcs hd => started_after_of hd
  acksStartedNew := fun x hx => by simp at hx
  svcPosNew := fun x hx => by simp at hx
  transferSelf := transfer
  rrPrimaryNew := fun x hx => by simp at hx
  rrNotSelfNew := fun x hx => by simp at hx
  rrNotSelfSelf := rrNotSelf
  senderIdsNew := fun x hx => by simp at hx
  startedIdsNew := fun _ _ h => by simp at h
  dvcsSelf := fun hs => ⟨(dvcs hs).1, fun x d hd => ⟨((dvcs hs).2 x d hd).1,
    ((dvcs hs).2 x d hd).2.imp (fun ⟨dst, h⟩ => ⟨dst, Sent.after_of h⟩) (fun h => h)⟩⟩
  rrsSelf := fun hs x resp hx => (rrs hs x resp hx).imp fun dst h => Sent.after_of h

/-- A replica that changes only its commit number, to a backed bound, and
its bookkeeping: the receiving side of a commit. -/
theorem StepOK.replaceSame {s : System Op Output St} (hinv : Inv s) {id : ReplicaId}
    {r r' : Replica Op Output St} (hr : s.replicas[id]? = some r)
    (hlog : r'.log = r.log) (hstat : r'.status = r.status) (hview : r'.viewNumber = r.viewNumber)
    (hlnv : r'.lastNormalView = r.lastNormalView) (hcatch : r'.catchingUp = r.catchingUp)
    (hself : r'.selfId = r.selfId) (hconf : r'.config = r.config) (hacks : r'.acks = r.acks)
    (hnonce : r'.recoveryNonce = r.recoveryNonce) (hpanic : r'.panicked = false)
    (hout : r'.outbox = []) (hreplies : r'.replies = []) (hcv : r'.chosenDoViewChanges = none)
    (hbacked : Backed s r.lastNormalView r'.commitNumber) (hloc : Replica.LocalInv r')
    (hdvcs : r'.status ≠ .viewChange) (hrrs : r'.status ≠ .recovering) :
    StepOK s id r r' [] [] := by
  have hmem : r ∈ s.replicas := List.mem_of_getElem? hr
  have hprim : r'.isPrimary = r.isPrimary := by
    unfold Replica.isPrimary Replica.primaryId; rw [hself, hconf, hview]
  refine StepOK.replace hinv hr hself hconf hpanic hout hreplies hcv hloc (hview ▸ Nat.le_refl _)
    (hlnv ▸ Nat.le_refl _) ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_
  · intro i e e' he hh; exact hinv.oneLog.2 r hmem i e e' (hlog ▸ he) (hlnv ▸ hh)
  · rw [hlnv]; exact hbacked
  · intro v' i e hc hlt hn; rw [hlog]; exact (hinv.survives v' i e hc _ (hlnv ▸ hlt)).2.2.2.2.2 r hmem rfl (hstat ▸ hn)
  · intro hn hp oa hoa
    have := hinv.acks r hmem (hstat ▸ hn) (hprim ▸ hp) oa (hacks ▸ hoa)
    exact ⟨by rw [hlog]; exact this.1, this.2.1,
      fun q hq => ⟨(this.2.2 q hq).1, (this.2.2 q hq).2.imp (fun h => hself.symm ▸ h)
        (fun ⟨to, ht⟩ => ⟨to, hview ▸ ht⟩)⟩⟩
  · intro hc; rw [hself, hconf, hview]; exact hinv.catching r hmem (hcatch ▸ hc)
  · intro to v o hs
    obtain ⟨ha, hb⟩ := hinv.acksHold to v o r'.selfId hs r hmem hself.symm
    exact ⟨hlnv ▸ ha, fun he hn => by rw [hlog]; exact hb (hlnv ▸ he) (hstat ▸ hn)⟩
  · intro hn hp
    obtain ⟨f1, f2, f3⟩ := hinv.longest r hmem (hstat ▸ hn) (by rw [← hself, ← hlnv]; exact hp)
    refine ⟨fun off log hf => by rw [hlog]; exact f1 off log (hlnv ▸ hf),
      fun q hq _ hql hqn => by rw [hlog]; exact f2 q hq (hlnv ▸ hql) hqn,
      fun to o q hs => by rw [hlog]; exact f3 to o q (hlnv ▸ hs)⟩
  · intro p hp _ hpn hpp hl hn
    rw [hlog]; exact (hinv.longest p hp hpn hpp).2.1 r hmem (hlnv ▸ hl) (hstat ▸ hn)
  · intro hs; rw [hlnv, hview]; exact hinv.vcBehind r hmem (hstat ▸ hs)
  · intro v dvcs b hv hb hl hn; rw [hlog]
    exact (hinv.extendsBase v dvcs b hv hb).2.2.2 r hmem (hlnv ▸ hl) (hstat ▸ hn)
  · intro hrec to v n q stt hs hn to' o hs'
    exact hinv.recoveryCovers r hmem (hstat ▸ hrec) to v n q stt hs (hnonce ▸ hn) to' o (hself ▸ hs')
  · intro i hi; rw [hlnv]; exact hinv.covered r hmem i (hlog ▸ hi)
  · intro z hz _ hl i e e' he he'; exact hinv.agree r hmem z hz (hlnv ▸ hl).symm i e e' (hlog ▸ he) he'
  · intro hn hpos; rw [hlnv] at hpos ⊢; exact hinv.startedViews.2.2 r hmem (hstat ▸ hn) hpos
  · intro hs; rw [hself, hview]; exact hinv.transferNotPrimary r hmem (hstat ▸ hs)
  · intro hrec to v n p stt hs hn; rw [hself]
    exact hinv.rrNotSelf to v n p stt hs r hmem (hstat ▸ hrec) (hnonce ▸ hn)
  · intro hs; exact absurd hs hdvcs
  · intro hs; exact absurd hs hrrs

/-! ### Shape two: one message is sent, the replica does not change -/

/-- What sending one message `x` from the replica `r` at `id`, which does
not otherwise change, has to show. `s'` is the state with `x` sent. -/
structure MsgOK (s : System Op Output St) (id : ReplicaId) (r : Replica Op Output St)
    (x : ReplicaId × Message Op) : Prop where
  wf : WF x.2
  okSelf : ∀ v o q, x.2 = Message.prepareOk v o q → q = r.selfId
  oneLogNew : ∀ v i e e', HoldsNew [x] [] v i e → Holds (s.after id r [x] []) v i e' → e = e'
  oneLogOld : ∀ z ∈ s.replicas, z.selfId ≠ r.selfId → ∀ i e e', z.log[i]? = some e →
    HoldsNew [x] [] z.lastNormalView i e' → e = e'
  backed : MsgBacked (s.after id r [x] []) x.2
  survivesOld : ∀ v' i e, Committed s v' i e → ∀ v, v' < v →
    (∀ to log o k, x = (to, Message.startView v log o k) → log[i]? = some e) ∧
    (∀ u q d, DvcOfNew [x] [] u q d → d.lastNormalView = v → d.log[i]? = some e) ∧
    (∀ to n q stt, x = (to, Message.recoveryResponse v n q (some stt)) → stt.log[i]? = some e) ∧
    (∀ to log a b k, x = (to, Message.newState v log a b k) → a ≤ i → log[i - a]? = some e) ∧
    (∀ to c n op k, x = (to, Message.prepare v (i + 1) c n op k) → (⟨c, n, op⟩ : LogEntry Op) = e)
  survivesNew : ∀ v' i e, Committed (s.after id r [x] []) v' i e → ¬ Committed s v' i e →
    ∀ v, v' < v →
    (∀ to log o k, Sent (s.after id r [x] []) to (.startView v log o k) → log[i]? = some e) ∧
    (∀ u q d, DvcOf (s.after id r [x] []) u q d → d.lastNormalView = v → d.log[i]? = some e) ∧
    (∀ to n q stt, Sent (s.after id r [x] []) to (.recoveryResponse v n q (some stt)) → stt.log[i]? = some e) ∧
    (∀ to log a b k, Sent (s.after id r [x] []) to (.newState v log a b k) → a ≤ i → log[i - a]? = some e) ∧
    (∀ to c n op k, Sent (s.after id r [x] []) to (.prepare v (i + 1) c n op k) → (⟨c, n, op⟩ : LogEntry Op) = e) ∧
    (∀ z ∈ (s.after id r [x] []).replicas, z.lastNormalView = v → z.status ≠ .recovering → z.log[i]? = some e)
  acksHoldSelf : ∀ v o, x.2 = Message.prepareOk v o r.selfId →
    v ≤ r.lastNormalView ∧ (r.lastNormalView = v → r.status ≠ .recovering → o ≤ r.log.length)
  toOthers : match x.2 with
    | .prepare v _ _ _ _ _ => x.1 ≠ s.config.primaryId v
    | .commit v _ => x.1 ≠ s.config.primaryId v
    | _ => True
  /-- New fragments and acknowledgements of a view are within the log of
  its primary, if that primary is last normal in it and not recovering. -/
  longest : ∀ p ∈ s.replicas, p.status ≠ .recovering → p.selfId = s.config.primaryId p.lastNormalView →
    (∀ off log, FragNew [x] [] p.lastNormalView off log → off + log.length ≤ p.log.length) ∧
    (∀ o q, x.2 = Message.prepareOk p.lastNormalView o q → o ≤ p.log.length)
  chosenNew : ∀ to v log o k, x = (to, Message.startView v log o k) →
    ∃ dvcs best, (v, dvcs) ∈ s.started ∧ s.config.quorum ≤ dvcs.length ∧
      (dvcs.map Prod.fst).Nodup ∧ Replica.bestDoViewChange dvcs = some best ∧ best.log <+: log
  dvcCoversNew : ∀ u q d, DvcOfNew [x] [] u q d →
    ∀ to o, Sent (s.after id r [x] []) to (.prepareOk d.lastNormalView o q) → o ≤ d.log.length
  dvcCoversOk : ∀ u q d, DvcOf s u q d → ∀ o, x.2 = Message.prepareOk d.lastNormalView o q → o ≤ d.log.length
  dvcBehindNew : ∀ u q d, DvcOfNew [x] [] u q d → d.lastNormalView < u
  dvcBelowNew : ∀ u q d, DvcOfNew [x] [] u q d → ∀ z ∈ s.replicas, z.selfId = q → u ≤ z.viewNumber
  dvcAfterAcksNew : ∀ u q d, DvcOfNew [x] [] u q d →
    ∀ to v o, Sent (s.after id r [x] []) to (.prepareOk v o q) → v < u → v ≤ d.lastNormalView
  dvcAfterAcksOk : ∀ u q d, DvcOf s u q d → ∀ v o, x.2 = Message.prepareOk v o q → v < u → v ≤ d.lastNormalView
  dvcAfterOwnNew : ∀ u q d, DvcOfNew [x] [] u q d →
    ∀ v dvcs, (v, dvcs) ∈ s.started → q = s.config.primaryId v → v < u → v ≤ d.lastNormalView
  dvcPrimaryNew : ∀ u q d, DvcOfNew [x] [] u q d → q = s.config.primaryId d.lastNormalView →
    ∀ off log, Frag (s.after id r [x] []) d.lastNormalView off log → off + log.length ≤ d.log.length
  dvcPrimaryFrag : ∀ u q d, DvcOf s u q d → q = s.config.primaryId d.lastNormalView →
    ∀ off log, FragNew [x] [] d.lastNormalView off log → off + log.length ≤ d.log.length
  extendsOld : ∀ v dvcs b, (v, dvcs) ∈ s.started → Replica.bestDoViewChange dvcs = some b →
    (∀ u q d, DvcOfNew [x] [] u q d → d.lastNormalView = v → b.log.length ≤ d.log.length) ∧
    (∀ to n q stt, x = (to, Message.recoveryResponse v n q (some stt)) → b.log.length ≤ stt.log.length) ∧
    (∀ to log a e k, x = (to, Message.newState v log a e k) → b.log.length ≤ e)
  rrNonceNew : ∀ to v n q stt, x = (to, Message.recoveryResponse v n q stt) →
    ∃ to' i v', Sent s to' (.recovery i n v')
  belowNew : ∀ z ∈ s.replicas, match x.2 with
    | .prepareOk v _ q => z.selfId = q → v ≤ z.viewNumber
    | .getState q v _ => z.selfId = q → v ≤ z.viewNumber
    | .startViewChange v q => z.selfId = q → v ≤ z.viewNumber
    | .doViewChange v q _ _ _ _ => z.selfId = q → v ≤ z.viewNumber
    | .recovery q _ v => z.selfId = q → v ≤ z.viewNumber
    | .recoveryResponse v _ q _ => z.selfId = q → v ≤ z.viewNumber
    | _ => True
  /-- A new recovery state answering a recovering replica covers its
  acknowledgements; a new acknowledgement is not from a recovering replica. -/
  recoveryRR : ∀ q ∈ s.replicas, q.status = .recovering →
    ∀ to v n p stt, x = (to, Message.recoveryResponse v n p (some stt)) → n = q.recoveryNonce →
      ∀ to' o, Sent s to' (.prepareOk v o q.selfId) → o ≤ stt.log.length
  recoveryOk : ∀ q ∈ s.replicas, q.status = .recovering → ∀ v o, x.2 ≠ Message.prepareOk v o q.selfId
  fragStartedNew : ∀ v off log, FragNew [x] [] v off log → 0 < v → ∃ dvcs, (v, dvcs) ∈ s.started
  acksStartedNew : ∀ u o q, x.2 = Message.prepareOk u o q → 0 < u → ∃ dvcs, (u, dvcs) ∈ s.started
  svcPosNew : ∀ v q, x.2 = Message.startViewChange v q → 0 < v
  rrPrimaryNew : ∀ v n q stt, x.2 = Message.recoveryResponse v n q (some stt) → q = s.config.primaryId v
  rrNotSelfNew : ∀ v n p stt, x.2 = Message.recoveryResponse v n p stt →
    ∀ q ∈ s.replicas, q.status = .recovering → q.recoveryNonce = n → p ≠ q.selfId
  senderIdsNew : match x.2 with
    | .prepareOk _ _ q => q < s.config.replicaCount
    | .getState q _ _ => q < s.config.replicaCount
    | .startViewChange _ q => q < s.config.replicaCount
    | .doViewChange _ q _ _ _ _ => q < s.config.replicaCount
    | .recovery q _ _ => q < s.config.replicaCount
    | .recoveryResponse _ _ q _ => q < s.config.replicaCount
    | _ => True

theorem mem_singleton_eq {α : Type} {a b : α} (h : a ∈ [b]) : a = b := by simpa using h

/-- Sending one message from an unchanged replica. -/
theorem StepOK.send {s : System Op Output St} (hinv : Inv s) {id : ReplicaId}
    {r : Replica Op Output St} (hr : s.replicas[id]? = some r) {x : ReplicaId × Message Op}
    (h : MsgOK s id r x) : StepOK s id r r [x] [] := by
  have hmem : r ∈ s.replicas := List.mem_of_getElem? hr
  have hrepl : ∀ z ∈ (s.after id r [x] []).replicas, z ∈ s.replicas := fun z hz => by
    rcases mem_after_replicas hinv.ids hr hz with rfl | ⟨hz, _⟩
    · exact hmem
    · exact hz
  refine {
    self := rfl, conf := rfl, panic := hinv.noPanic r hmem, outbox := hinv.drained r hmem,
    replies := (hinv.clean r hmem).1, chosen := (hinv.clean r hmem).2, local_ := hinv.local_ r hmem,
    view := Nat.le_refl _, lnv := Nat.le_refl _,
    wf := fun y hy => by rw [mem_singleton_eq hy]; exact h.wf,
    okSelf := fun y hy v o q hq => h.okSelf v o q (by rw [← mem_singleton_eq hy]; exact hq),
    oneLogNew := h.oneLogNew,
    oneLogSelf := fun i e e' he hh => ?_,
    oneLogOld := h.oneLogOld,
    backedSelf := Backed.after_of (hinv.backed.1 r hmem),
    backedOut := fun y hy => by rw [mem_singleton_eq hy]; exact h.backed,
    survivesOld := fun v' i e hc v hlt => ?_,
    survivesNew := h.survivesNew,
    acksSelf := fun hn hp oa hoa => ?_,
    catchingSelf := hinv.catching r hmem,
    acksHoldSelf := fun to v o hs => ?_,
    toOthers := fun y hy => by rw [mem_singleton_eq hy]; exact h.toOthers,
    longestSelf := fun hn hp => ?_,
    longestOld := fun p hp hne hpn hpp => ?_,
    chosenNew := fun to v log o k hx => ?_,
    dvcCoversNew := h.dvcCoversNew,
    dvcCoversOk := fun u q d hd y hy o hy2 => h.dvcCoversOk u q d hd o (by rw [← mem_singleton_eq hy]; exact hy2),
    dvcBehindNew := h.dvcBehindNew,
    dvcBelowNew := fun u q d hd z hz hq => h.dvcBelowNew u q d hd z (hrepl z hz) hq,
    dvcAfterAcksNew := h.dvcAfterAcksNew,
    dvcAfterAcksOk := fun u q d hd y hy v o hy2 => h.dvcAfterAcksOk u q d hd v o (by rw [← mem_singleton_eq hy]; exact hy2),
    dvcAfterOwnNew := fun u q d hd v dvcs hv hq hlt => ?_,
    dvcAfterOwnSt := fun _ _ _ _ _ _ hv => by simp at hv,
    dvcPrimaryNew := h.dvcPrimaryNew,
    dvcPrimaryFrag := h.dvcPrimaryFrag,
    vcBehindSelf := hinv.vcBehind r hmem,
    primaryStartedNew := fun _ _ hv => by simp at hv,
    startedOnceNew := fun _ _ hv => by simp at hv,
    extendsOld := fun v dvcs b hv hb => ?_,
    extendsNew := fun _ _ _ hv => by simp at hv,
    rrNonceNew := fun to v n q stt hx => ?_,
    belowNew := fun y hy z hz => by rw [mem_singleton_eq hy]; exact h.belowNew z (hrepl z hz),
    recoverySelf := fun hrec to v n q stt hs hn to' o hs' => ?_,
    recoveryOk := fun q hq _ hqr to v n p stt hs hn y hy o hy2 =>
      absurd (by rw [← mem_singleton_eq hy]; exact hy2) (h.recoveryOk q hq hqr v o),
    recoveryRR := fun q hq _ hqr to v n p stt hx hn to' o hs' => ?_,
    coveredSelf := fun i hi => (hinv.covered r hmem i hi).imp fun e he => Holds.after_of he,
    agreeSelf := fun z hz _ hl i e e' he he' => hinv.agree r hmem z hz hl.symm i e e' he he',
    startedViewsNew := fun _ _ hv => by simp at hv,
    fragStartedNew := fun v off log hf hpos => (h.fragStartedNew v off log hf hpos).imp fun d hd => started_after_of hd,
    selfStarted := fun hn hpos => (hinv.startedViews.2.2 r hmem hn hpos).imp fun d hd => started_after_of hd,
    acksStartedNew := fun y hy u o q hy2 hu =>
      (h.acksStartedNew u o q (by rw [← mem_singleton_eq hy]; exact hy2) hu).imp fun d hd => started_after_of hd,
    svcPosNew := fun y hy v q hy2 => h.svcPosNew v q (by rw [← mem_singleton_eq hy]; exact hy2),
    transferSelf := hinv.transferNotPrimary r hmem,
    rrPrimaryNew := fun y hy v n q stt hy2 => h.rrPrimaryNew v n q stt (by rw [← mem_singleton_eq hy]; exact hy2),
    rrNotSelfNew := fun y hy v n p stt hy2 q hq hqr hqn =>
      h.rrNotSelfNew v n p stt (by rw [← mem_singleton_eq hy]; exact hy2) q (hrepl q hq) hqr hqn,
    rrNotSelfSelf := fun hrec to v n p stt hs hn => hinv.rrNotSelf to v n p stt hs r hmem hrec hn,
    senderIdsNew := fun y hy => by rw [mem_singleton_eq hy]; exact h.senderIdsNew,
    startedIdsNew := fun _ _ hv => by simp at hv,
    dvcsSelf := fun hs => ⟨(hinv.recordedDvcs r hmem hs).1, fun x d hd =>
      ⟨((hinv.recordedDvcs r hmem hs).2 x d hd).1,
       ((hinv.recordedDvcs r hmem hs).2 x d hd).2.imp (fun ⟨dst, hd'⟩ => ⟨dst, Sent.after_of hd'⟩) (fun h => h)⟩⟩,
    rrsSelf := fun hs x resp hx => (hinv.recordedRRs r hmem hs x resp hx).imp fun dst hd => Sent.after_of hd }
  · -- oneLogSelf
    rcases Holds.after.mp hh with hh | hh
    · exact hinv.oneLog.2 r hmem i e e' he hh
    · obtain ⟨e0, he0⟩ := hinv.covered r hmem i (List.getElem?_eq_some_iff.mp he).1
      exact (hinv.oneLog.2 r hmem i e e0 he he0).trans (h.oneLogNew _ i e' e0 hh (Holds.after_of he0)).symm
  · -- survivesOld
    obtain ⟨m1, m2, m3, m4, m5⟩ := h.survivesOld v' i e hc v hlt
    exact ⟨fun to log o k hy => m1 to log o k (mem_singleton_eq hy).symm,
      fun u q d hd hl => m2 u q d hd hl,
      fun to n q stt hy => m3 to n q stt (mem_singleton_eq hy).symm,
      fun to log a b k hy ha => m4 to log a b k (mem_singleton_eq hy).symm ha,
      fun to c n op k hy => m5 to c n op k (mem_singleton_eq hy).symm,
      fun hv hn => (hinv.survives v' i e hc v hlt).2.2.2.2.2 r hmem hv hn⟩
  · -- acksSelf
    obtain ⟨c1, c0, c2⟩ := hinv.acks r hmem hn hp oa hoa
    exact ⟨c1, c0, fun q hq => ⟨(c2 q hq).1, (c2 q hq).2.imp (fun h => h)
      (fun ⟨to, ht⟩ => ⟨to, Sent.after_of ht⟩)⟩⟩
  · -- acksHoldSelf
    rcases Sent.after.mp hs with hs | hs
    · exact hinv.acksHold to v o r.selfId hs r hmem rfl
    · exact h.acksHoldSelf v o (by rw [← mem_singleton_eq hs])
  · -- longestSelf
    obtain ⟨f1, f2, f3⟩ := hinv.longest r hmem hn hp
    obtain ⟨g1, g2⟩ := h.longest r hmem hn hp
    refine ⟨fun off log hf => ?_, fun q hq hql hqn => f2 q (hrepl q hq) hql hqn, fun to o q hs => ?_⟩
    · rcases Frag.after.mp hf with hf | hf
      · exact f1 off log hf
      · exact g1 off log hf
    · rcases Sent.after.mp hs with hs | hs
      · exact f3 to o q hs
      · exact g2 o q (by rw [← mem_singleton_eq hs])
  · -- longestOld
    obtain ⟨g1, g2⟩ := h.longest p hp hpn hpp
    exact ⟨g1, fun hl hn => (hinv.longest p hp hpn hpp).2.1 r hmem hl hn,
      fun y hy o q hy2 => g2 o q (by rw [← mem_singleton_eq hy]; exact hy2)⟩
  · -- chosenNew
    obtain ⟨dvcs, best, h1, h2, h3, h4, h5⟩ := h.chosenNew to v log o k (mem_singleton_eq hx).symm
    exact ⟨dvcs, best, started_after_of h1, h2, h3, h4, h5⟩
  · -- dvcAfterOwnNew
    rcases mem_started_after.mp hv with hv | hv
    · exact h.dvcAfterOwnNew u q d hd v dvcs hv hq hlt
    · simp at hv
  · -- extendsOld
    obtain ⟨e1, e2, e3⟩ := h.extendsOld v dvcs b hv hb
    exact ⟨e1, fun to n q stt hy => e2 to n q stt (mem_singleton_eq hy).symm,
      fun to log a e k hy => e3 to log a e k (mem_singleton_eq hy).symm,
      fun hl hn => (hinv.extendsBase v dvcs b hv hb).2.2.2 r hmem hl hn⟩
  · -- rrNonceNew
    obtain ⟨to', i, v', h'⟩ := h.rrNonceNew to v n q stt (mem_singleton_eq hx).symm
    exact ⟨to', i, v', Sent.after_of h'⟩
  · -- recoverySelf
    rcases Sent.after.mp hs with hs | hs <;> rcases Sent.after.mp hs' with hs' | hs'
    · exact hinv.recoveryCovers r hmem hrec to v n q stt hs hn to' o hs'
    · exact absurd (by rw [← mem_singleton_eq hs']) (h.recoveryOk r hmem hrec v o)
    · exact h.recoveryRR r hmem hrec to v n q stt (mem_singleton_eq hs).symm hn to' o hs'
    · have := (mem_singleton_eq hs).trans (mem_singleton_eq hs').symm; simp at this
  · -- recoveryRR
    rcases Sent.after.mp hs' with hs' | hs'
    · exact h.recoveryRR q hq hqr to v n p stt (mem_singleton_eq hx).symm hn to' o hs'
    · have := (mem_singleton_eq hx).trans (mem_singleton_eq hs').symm; simp at this

end Vsr
