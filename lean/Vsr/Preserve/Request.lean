import Vsr.Preserve.Normal

/-!
`onRequest`: the primary appends a new entry and replicates it. The append
and the `Prepare` messages go together, since the new entry must be in
the history the moment it is in the log, so this is one step of the
general shape.
-/

namespace Vsr

variable {Op Output St : Type}

/-- `sendToOthers` only fills the outbox. -/
theorem Replica.sendToOthers_eq_withOutbox (r : Replica Op Output St) (msg : Message Op) :
    r.sendToOthers msg = { r with outbox := r.outbox ++
      (r.config.replicas.filter (· ≠ r.selfId)).map (fun dst => (dst, msg)) } := by
  unfold Replica.sendToOthers
  generalize r.config.replicas.filter (· ≠ r.selfId) = l
  induction l generalizing r with
  | nil => cases r; simp
  | cons dst l ih =>
    rw [List.foldl_cons, ih]
    cases r; simp [Replica.send]

/-- Draining a broadcast from a clean replica. -/
theorem System.drainOf_sendToOthers (s : System Op Output St) (id : ReplicaId) (r : Replica Op Output St)
    (msg : Message Op) (ho : r.outbox = []) (hc : r.chosenDoViewChanges = none) :
    s.drainOf id (r.sendToOthers msg) =
      s.after id r.clear ((r.config.replicas.filter (· ≠ r.selfId)).map (fun dst => (dst, msg))) [] := by
  unfold System.drainOf
  rw [Replica.sendToOthers_eq_withOutbox]
  simp [System.after, Replica.clear, Replica.startedList, ho, hc]

theorem mem_others {r : Replica Op Output St} {msg : Message Op} {x : ReplicaId × Message Op}
    (hx : x ∈ (r.config.replicas.filter (· ≠ r.selfId)).map (fun dst => (dst, msg))) :
    x.2 = msg ∧ x.1 ≠ r.selfId ∧ x.1 < r.config.replicaCount := by
  obtain ⟨dst, hd, rfl⟩ := List.mem_map.mp hx
  rw [List.mem_filter] at hd
  exact ⟨rfl, by simpa using hd.2, by simpa [Config.replicas] using hd.1⟩

/-- Some other replica exists to send to. -/
theorem others_nonempty {r : Replica Op Output St} (msg : Message Op) (htwo : 2 ≤ r.config.replicaCount)
    (hself : r.selfId < r.config.replicaCount) :
    ∃ x, x ∈ (r.config.replicas.filter (· ≠ r.selfId)).map (fun dst => (dst, msg)) := by
  by_cases h0 : r.selfId = 0
  · refine ⟨(1, msg), List.mem_map.mpr ⟨1, List.mem_filter.mpr ⟨?_, ?_⟩, rfl⟩⟩
    · simp [Config.replicas]; omega
    · simp [h0]
  · refine ⟨(0, msg), List.mem_map.mpr ⟨0, List.mem_filter.mpr ⟨?_, ?_⟩, rfl⟩⟩
    · simp [Config.replicas]; omega
    · simpa using fun h => h0 h.symm

/-- A list of at least two distinct ids has one that is not `p`. -/
theorem exists_ne_of_nodup {Q : List ReplicaId} (hnd : Q.Nodup) (hlen : 2 ≤ Q.length) (p : ReplicaId) :
    ∃ q ∈ Q, q ≠ p := by
  match Q, hnd, hlen with
  | a :: b :: _, hnd, _ =>
    have hab : a ≠ b := by
      have := List.nodup_cons.mp hnd
      exact fun h => this.1 (h ▸ List.mem_cons_self ..)
    by_cases ha : a = p
    · exact ⟨b, List.mem_cons_of_mem _ (List.mem_cons_self ..), fun h => hab (ha.trans h.symm)⟩
    · exact ⟨a, List.mem_cons_self .., ha⟩

section Request
variable {s : System Op Output St} (hinv : Inv s) {id : ReplicaId} {r : Replica Op Output St}
  (hr : s.replicas[id]? = some r)
include hinv hr

/-- `prepareRequest`: the normal primary appends and replicates. -/
theorem Inv.prepareRequest (c : ClientId) (n : RequestNumber) (op : Op) (hn : r.status = .normal)
    (hp : r.isPrimary = true) : Inv (s.drainOf id (r.prepareRequest c n op)) := by
  have hmem := List.mem_of_getElem? hr
  have hloc := hinv.local_ r hmem
  have hconf := hinv.config_eq hmem
  have hlnv : r.lastNormalView = r.viewNumber := hloc.2.2.1 (Or.inl hn)
  have hnr : r.status ≠ .recovering := by rw [hn]; decide
  have hprim : r.selfId = s.config.primaryId r.viewNumber := by
    unfold Replica.isPrimary Replica.primaryId at hp; rw [← hconf]; exact of_decide_eq_true hp
  have hprim' : r.selfId = s.config.primaryId r.lastNormalView := hlnv ▸ hprim
  have hselfN : r.selfId < s.config.replicaCount := hinv.selfId_lt hmem
  have hclean := hinv.clean r hmem
  have hdrained := hinv.drained r hmem
  -- the pieces
  set e : LogEntry Op := ⟨c, n, op⟩ with he
  set msg : Message Op := .prepare r.viewNumber (r.log ++ [e]).length c n op r.commitNumber with hmsg
  set out := (r.config.replicas.filter (· ≠ r.selfId)).map (fun dst => (dst, msg)) with hout
  set r1 : Replica Op Output St := r.appendToLog e with hr1
  set r2 : Replica Op Output St := { r1 with acks := Assoc.insert r1.acks r1.opNumber [r1.selfId] } with hr2
  have hr2log : r2.log = r.log ++ [e] := rfl
  have hr2len : r2.log.length = r.log.length + 1 := by rw [hr2log]; simp
  have heq : s.drainOf id (r.prepareRequest c n op) = s.after id r2.clear out [] := by
    show s.drainOf id (r2.sendToOthers (Message.prepare r2.viewNumber r1.opNumber c n op r2.commitNumber)) = _
    rw [System.drainOf_sendToOthers s id r2 _ hdrained hclean.2]
    rfl
  rw [heq]
  -- facts about the new fragment and the old history
  have hout_spec : ∀ x ∈ out, x.2 = msg ∧ x.1 ≠ r.selfId ∧ x.1 < s.config.replicaCount := by
    intro x hx
    obtain ⟨h1, h2, h3⟩ := mem_others hx
    exact ⟨h1, h2, hconf ▸ h3⟩
  have hnew : ∀ v off log, FragNew out [] v off log → v = r.viewNumber ∧ off = r.log.length ∧ log = [e] := by
    intro v off log hf
    rcases hf with ⟨x, hx, hmf⟩ | ⟨_, _, _, _, hst, _⟩
    · have hx2 := (hout_spec x hx).1
      obtain ⟨dst, m⟩ := x
      simp only at hx2; subst hx2
      obtain ⟨rfl, rfl, rfl⟩ := MsgFrag.prepare_inv hmf
      exact ⟨rfl, by simp, rfl⟩
    · simp at hst
  have hnewHolds : ∀ v i e', HoldsNew out [] v i e' → v = r.viewNumber ∧ i = r.log.length ∧ e' = e := by
    intro v i e' h
    obtain ⟨off, log, hf, hle, hget⟩ := h
    obtain ⟨rfl, rfl, rfl⟩ := hnew v off log hf
    have hi : i - r.log.length < 1 := by simpa using (List.getElem?_eq_some_iff.mp hget).1
    have h1 : i < 1 + r.log.length := (Nat.sub_lt_iff_lt_add hle).mp hi
    have hi' : i = r.log.length := Nat.le_antisymm (Nat.le_of_lt_succ (by rw [Nat.add_comm] at h1; exact h1)) hle
    subst hi'
    simp only [Nat.sub_self, List.getElem?_cons_zero, Option.some.injEq] at hget
    exact ⟨rfl, rfl, hget.symm⟩
  have hnoold : ∀ e', ¬ Holds s r.viewNumber r.log.length e' := by
    intro e' ⟨off, log, hf, hle, hget⟩
    have := (hinv.longest r hmem hnr hprim').1 off log (hlnv ▸ hf)
    have := (List.getElem?_eq_some_iff.mp hget).1
    omega
  have hnodvc : ∀ u d, DvcOf s u r.selfId d → u ≤ r.viewNumber :=
    fun u d hd => hinv.dvcBelow u r.selfId d hd r hmem rfl
  have hnoOk : NoPrepareOk out := fun x hx v o q h => by
    have := (hout_spec x hx).1; rw [this] at h; exact nomatch h
  have hex : ∃ x, x ∈ out := others_nonempty msg (hconf ▸ hinv.two) (hconf ▸ hselfN)
  have hmaxlog : ∀ z ∈ s.replicas, z.lastNormalView = r.lastNormalView → z.status ≠ .recovering →
      z.log.length ≤ r.log.length := fun z hz hl hzn => (hinv.longest r hmem hnr hprim').2.1 z hz hl hzn
  refine hinv.after hr {
    self := rfl, conf := rfl, panic := hinv.noPanic r hmem, outbox := rfl, replies := rfl, chosen := rfl,
    local_ := ((hloc.appendToLog e hnr).withAcks _).clear,
    view := Nat.le_refl _, lnv := Nat.le_refl _,
    wf := fun x hx => by rw [(hout_spec x hx).1]; show 0 < (r.log ++ [e]).length; simp,
    okSelf := fun x hx v o q h => by rw [(hout_spec x hx).1] at h; exact (nomatch h),
    oneLogNew := fun v i e1 e2 h h' => ?_,
    oneLogSelf := fun i e1 e2 he1 hh => ?_,
    oneLogOld := fun z hz hne i e1 e2 he1 h => ?_,
    backedSelf := Backed.after_of (hinv.backed.1 r hmem),
    backedOut := fun x hx => by
      rw [(hout_spec x hx).1]; show Backed _ r.viewNumber r.commitNumber
      exact Backed.after_of (hlnv ▸ hinv.backed.1 r hmem),
    survivesOld := fun v' i e0 hc v hlt => ?_,
    survivesNew := fun v' i e0 hc hold => ?_,
    acksSelf := fun _ _ oa hoa => ?_,
    catchingSelf := fun hc => hinv.catching r hmem hc,
    acksHoldSelf := fun dst v o hs => ?_,
    toOthers := fun x hx => by
      obtain ⟨h1, h2, _⟩ := hout_spec x hx
      rw [h1]; show x.1 ≠ s.config.primaryId r.viewNumber; rw [← hprim]; exact h2,
    longestSelf := fun _ _ => ?_,
    longestOld := fun p hp hne hpn hpp => ?_,
    chosenNew := fun dst v log o k hx => by have := (hout_spec _ hx).1; exact (nomatch this),
    dvcCoversNew := fun u q d hd => ?_,
    dvcCoversOk := fun u q d _ y hy o h => by rw [(hout_spec y hy).1] at h; exact (nomatch h),
    dvcBehindNew := fun u q d hd => ?_,
    dvcBelowNew := fun u q d hd => ?_,
    dvcAfterAcksNew := fun u q d hd => ?_,
    dvcAfterAcksOk := fun u q d _ y hy v o h => by rw [(hout_spec y hy).1] at h; exact (nomatch h),
    dvcAfterOwnNew := fun u q d hd => ?_,
    dvcAfterOwnSt := fun _ _ _ _ _ _ h => by simp at h,
    dvcPrimaryNew := fun u q d hd => ?_,
    dvcPrimaryFrag := fun u q d hd hq off log hf => ?_,
    vcBehindSelf := fun h => by simp [hr2, hr1] at h; rw [hn] at h; exact absurd h (by decide),
    primaryStartedNew := fun _ _ h => by simp at h,
    startedOnceNew := fun _ _ h => by simp at h,
    extendsOld := fun v dvcs b hv hb => ?_,
    extendsNew := fun _ _ _ h => by simp at h,
    rrNonceNew := fun dst v n' q stt hx => by have := (hout_spec _ hx).1; exact (nomatch this),
    belowNew := fun x hx z hz => by rw [(hout_spec x hx).1]; trivial,
    recoverySelf := fun h => by simp [hr2, hr1] at h; rw [hn] at h; exact absurd h (by decide),
    recoveryOk := fun _ _ _ _ _ _ _ _ _ _ _ y hy o h => by rw [(hout_spec y hy).1] at h; exact (nomatch h),
    recoveryRR := fun _ _ _ _ dst v n' p stt hx => by have := (hout_spec _ hx).1; exact (nomatch this),
    coveredSelf := fun i hi => ?_,
    agreeSelf := fun z hz hne hl i e1 e2 he1 he2 => ?_,
    startedViewsNew := fun _ _ h => by simp at h,
    fragStartedNew := fun v off log hf hpos => ?_,
    selfStarted := fun _ hpos => (hinv.startedViews.2.2 r hmem hnr (by simpa [hr2, hr1] using hpos)).imp
      fun d hd => started_after_of (by simpa [hr2, hr1] using hd),
    acksStartedNew := fun x hx u o q h => by rw [(hout_spec x hx).1] at h; exact (nomatch h),
    svcPosNew := fun x hx v q h => by rw [(hout_spec x hx).1] at h; exact (nomatch h),
    transferSelf := fun h => by simp [hr2, hr1] at h; rw [hn] at h; exact absurd h (by decide),
    rrPrimaryNew := fun x hx v n' q stt h => by rw [(hout_spec x hx).1] at h; exact (nomatch h),
    rrNotSelfNew := fun x hx v n' p stt h => by rw [(hout_spec x hx).1] at h; exact (nomatch h),
    rrNotSelfSelf := fun h => by simp [hr2, hr1] at h; rw [hn] at h; exact absurd h (by decide),
    senderIdsNew := fun x hx => by rw [(hout_spec x hx).1]; trivial,
    startedIdsNew := fun _ _ h => by simp at h,
    dvcsSelf := fun h => by simp [hr2, hr1] at h; rw [hn] at h; exact absurd h (by decide),
    rrsSelf := fun h => by simp [hr2, hr1] at h; rw [hn] at h; exact absurd h (by decide) }
  · -- oneLogNew
    obtain ⟨rfl, rfl, rfl⟩ := hnewHolds _ _ _ h
    rcases Holds.after.mp h' with h' | h'
    · exact absurd h' (hnoold e2)
    · exact (hnewHolds _ _ _ h').2.2.symm
  · -- oneLogSelf
    simp only [Replica.clear_log, Replica.clear_lastNormalView] at he1 hh
    have he1' : (r.log ++ [e])[i]? = some e1 := he1
    have hh' : Holds (s.after id r2.clear out []) r.lastNormalView i e2 := hh
    rcases List.getElem?_append_singleton he1' with ⟨hi, hget⟩ | ⟨rfl, rfl⟩
    · rcases Holds.after.mp hh' with h | h
      · exact hinv.oneLog.2 r hmem i e1 e2 hget h
      · obtain ⟨_, rfl, _⟩ := hnewHolds _ _ _ h; exact absurd hi (Nat.lt_irrefl _)
    · rcases Holds.after.mp hh' with h | h
      · exact absurd (hlnv ▸ h) (hnoold e2)
      · exact (hnewHolds _ _ _ h).2.2.symm
  · -- oneLogOld
    obtain ⟨hl, rfl, rfl⟩ := hnewHolds _ _ _ h
    by_cases hzr : z.status = .recovering
    · rw [((hinv.local_ z hz).2.2.2.2 hzr).1] at he1; simp at he1
    · have := hmaxlog z hz (hl.trans hlnv.symm) hzr
      exact absurd (List.getElem?_eq_some_iff.mp he1).1 (Nat.not_lt.mpr this)
  · -- survivesOld
    refine ⟨fun dst log o k hx => by have := (hout_spec _ hx).1; exact (nomatch this),
      fun u q d hd => ?_, fun dst n' q stt hx => by have := (hout_spec _ hx).1; exact (nomatch this),
      fun dst log a b k hx => by have := (hout_spec _ hx).1; exact (nomatch this),
      fun dst c' n' op' k hx => ?_, fun hl _ => ?_⟩
    · rcases hd with ⟨dst, hx⟩ | ⟨_, h, _⟩
      · have := (hout_spec _ hx).1; exact nomatch this
      · simp at h
    · have hx2 := (hout_spec _ hx).1
      simp only [hmsg, Message.prepare.injEq] at hx2
      obtain ⟨rfl, hio, _, _, _, _⟩ := hx2
      have h7 := (hinv.survives v' i e0 hc _ (hlnv ▸ hlt)).2.2.2.2.2 r hmem rfl hnr
      have hi : i = r.log.length := by simp at hio; omega
      subst hi
      exact absurd (List.getElem?_eq_some_iff.mp h7).1 (Nat.lt_irrefl _)
    · simp only [Replica.clear_log, Replica.clear_lastNormalView] at hl ⊢
      have h7 := (hinv.survives v' i e0 hc _ (hl ▸ hlt)).2.2.2.2.2 r hmem rfl hnr
      show (r.log ++ [e])[i]? = some e0
      rw [List.getElem?_append_singleton_left (List.getElem?_eq_some_iff.mp h7).1]; exact h7
  · -- survivesNew: nothing new is committed
    exfalso; apply hold
    obtain ⟨hh, hq⟩ := hc
    have hq' := QuorumAcked.after_noOk hnoOk hq
    rcases Holds.after.mp hh with hh | hh
    · exact ⟨hh, hq'⟩
    · obtain ⟨rfl, rfl, rfl⟩ := hnewHolds _ _ _ hh
      exfalso
      obtain ⟨Q, hnd, hlen, hQ⟩ := hq'
      have h2 : 2 ≤ Q.length := Nat.le_trans (by
        show 2 ≤ s.config.replicaCount / 2 + 1
        have h2 : 2 ≤ s.config.replicaCount := hinv.two; omega) hlen
      obtain ⟨q, hqQ, hqne⟩ := exists_ne_of_nodup hnd h2 (s.config.primaryId r.viewNumber)
      rcases (hQ q hqQ).2 with h | ⟨dst, o, hs, hlt⟩
      · exact hqne h
      · have := (hinv.longest r hmem hnr hprim').2.2 dst o q (hlnv ▸ hs)
        exact absurd hlt (Nat.not_lt.mpr this)
  · -- acksSelf
    simp only [Replica.clear_acks, hr2] at hoa
    rcases Assoc.mem_insert hoa with rfl | hoa
    · refine ⟨?_, List.pairwise_singleton _ _, fun q hq => ?_⟩
      · show r1.opNumber ≤ r2.clear.log.length
        rw [Replica.clear_log, hr2len]; simp [hr1, Replica.opNumber]
      · rw [List.mem_singleton] at hq; subst hq
        exact ⟨by simp [hr1]; exact hselfN, Or.inl (by simp [hr1, hr2])⟩
    · obtain ⟨c1, c2, c3⟩ := hinv.acks r hmem hn hp oa hoa
      refine ⟨by rw [Replica.clear_log, hr2len]; exact Nat.le_succ_of_le c1, c2, fun q hq => ⟨(c3 q hq).1, ?_⟩⟩
      rcases (c3 q hq).2 with h | ⟨dst, hs⟩
      · exact Or.inl h
      · exact Or.inr ⟨dst, Sent.after_of hs⟩
  · -- acksHoldSelf
    rcases Sent.after.mp hs with hs | hs
    · obtain ⟨ha, hb⟩ := hinv.acksHold dst v o r.selfId hs r hmem rfl
      exact ⟨ha, fun hl hn' => by rw [Replica.clear_log, hr2len]; exact Nat.le_succ_of_le (hb hl hnr)⟩
    · have := (hout_spec _ hs).1; exact nomatch this
  · -- longestSelf
    refine ⟨fun off log hf => ?_, fun q hq hql hqn => ?_, fun dst o q hs => ?_⟩
    · rw [Replica.clear_log, hr2len]
      rcases Frag.after.mp hf with hf | hf
      · exact Nat.le_succ_of_le ((hinv.longest r hmem hnr hprim').1 off log hf)
      · obtain ⟨_, rfl, rfl⟩ := hnew _ off log hf; simp
    · rw [Replica.clear_log, hr2len]
      rcases mem_after_replicas hinv.ids hr hq with rfl | ⟨hq, _⟩
      · rw [Replica.clear_log, hr2len]
      · exact Nat.le_succ_of_le (hmaxlog q hq hql hqn)
    · rw [Replica.clear_log, hr2len]
      rcases Sent.after.mp hs with hs | hs
      · exact Nat.le_succ_of_le ((hinv.longest r hmem hnr hprim').2.2 dst o q hs)
      · have := (hout_spec _ hs).1; exact nomatch this
  · -- longestOld: no other replica is the primary of this view
    refine ⟨fun off log hf => ?_, fun hl _ => ?_, fun x hx o q h => nomatch ((hout_spec x hx).1.symm.trans h)⟩
    · obtain ⟨hl, _, _⟩ := hnew _ off log hf
      exact absurd (hpp.trans (by rw [hl, ← hlnv, ← hprim'])) hne
    · exact absurd (hpp.trans (by rw [← hl, Replica.clear_lastNormalView, hr2, hr1]; simp; exact hprim'.symm)) hne
  · rcases hd with ⟨dst, hx⟩ | ⟨_, h, _⟩
    · have := (hout_spec _ hx).1; exact nomatch this
    · simp at h
  · rcases hd with ⟨dst, hx⟩ | ⟨_, h, _⟩
    · have := (hout_spec _ hx).1; exact nomatch this
    · simp at h
  · rcases hd with ⟨dst, hx⟩ | ⟨_, h, _⟩
    · have := (hout_spec _ hx).1; exact nomatch this
    · simp at h
  · rcases hd with ⟨dst, hx⟩ | ⟨_, h, _⟩
    · have := (hout_spec _ hx).1; exact nomatch this
    · simp at h
  · rcases hd with ⟨dst, hx⟩ | ⟨_, h, _⟩
    · have := (hout_spec _ hx).1; exact nomatch this
    · simp at h
  · rcases hd with ⟨dst, hx⟩ | ⟨_, h, _⟩
    · have := (hout_spec _ hx).1; exact nomatch this
    · simp at h
  · -- dvcPrimaryFrag: no DoViewChange from this primary for a later view
    obtain ⟨hl, _, _⟩ := hnew _ off log hf
    have hqr : q = r.selfId := by rw [hq, hl]; exact hprim.symm
    subst hqr
    have h1 := hnodvc u d hd
    have h2 := hinv.dvcBehind u _ d hd
    rw [hl] at h2
    exact absurd (Nat.lt_of_lt_of_le h2 h1) (Nat.lt_irrefl _)
  · -- extendsOld
    refine ⟨fun u q d hd => ?_, fun dst n' q stt hx => by have := (hout_spec _ hx).1; exact (nomatch this),
      fun dst log a e' k hx => by have := (hout_spec _ hx).1; exact (nomatch this), fun hl _ => ?_⟩
    · rcases hd with ⟨dst, hx⟩ | ⟨_, h, _⟩
      · have := (hout_spec _ hx).1; exact nomatch this
      · simp at h
    · rw [Replica.clear_log, hr2len]
      exact Nat.le_succ_of_le ((hinv.extendsBase v dvcs b hv hb).2.2.2 r hmem (by simpa [hr2, hr1] using hl) hnr)
  · -- coveredSelf
    rw [Replica.clear_log, hr2len] at hi
    rw [Replica.clear_lastNormalView]
    show ∃ e', Holds (s.after id r2.clear out []) r.lastNormalView i e'
    rcases Nat.lt_or_eq_of_le (Nat.le_of_lt_succ hi) with hlt | rfl
    · exact (hinv.covered r hmem i hlt).imp fun e' he' => Holds.after_of he'
    · obtain ⟨x, hx⟩ := hex
      refine ⟨e, r.log.length, [e], Frag.after.mpr (Or.inr ?_), Nat.le_refl _, by simp⟩
      have hx2 := (hout_spec x hx).1
      obtain ⟨dst, msg'⟩ := x
      simp only at hx2; subst hx2
      have hf : MsgFrag (dst, msg) r.viewNumber ((r.log ++ [e]).length - 1) [e] := MsgFrag.prepare
      have hlen1 : (r.log ++ [e]).length - 1 = r.log.length := by simp
      rw [hlen1] at hf
      exact FragNew.ofMsg hx (hlnv ▸ hf)
  · -- agreeSelf
    rw [Replica.clear_log, hr2log] at he1
    rcases List.getElem?_append_singleton he1 with ⟨hi, hget⟩ | ⟨rfl, rfl⟩
    · exact hinv.agree r hmem z hz (by simpa [hr2, hr1] using hl.symm) i e1 e2 hget he2
    · exfalso
      by_cases hzr : z.status = .recovering
      · rw [((hinv.local_ z hz).2.2.2.2 hzr).1] at he2; simp at he2
      · have := hmaxlog z hz (by simpa [hr2, hr1] using hl) hzr
        exact absurd (List.getElem?_eq_some_iff.mp he2).1 (Nat.not_lt.mpr this)
  · -- fragStartedNew
    obtain ⟨rfl, _, _⟩ := hnew _ off log hf
    exact (hinv.startedViews.2.2 r hmem hnr (hlnv ▸ hpos)).imp fun d hd => started_after_of (hlnv ▸ hd)

/-- `onRequest`. -/
theorem Inv.onRequest (c : ClientId) (n : RequestNumber) (op : Op) (hnr : r.status ≠ .recovering) :
    Inv (s.drainOf id (r.onRequest c n op)) := by
  have h0 := hinv.drainOf_start hr
  unfold Replica.onRequest
  split
  · exact h0
  · rename_i hg
    have hp : r.isPrimary = true := by
      rcases Decidable.em (r.isPrimary = true) with h | h
      · exact h
      · exact absurd (Or.inl (by simpa using h)) hg
    have hn : r.status = .normal := by
      rcases Decidable.em (r.status = .normal) with h | h
      · exact h
      · exact absurd (Or.inr h) hg
    split
    · exact hinv.prepareRequest hr c n op hn hp
    · split
      · exact h0
      · split
        · split
          · -- a reply: nothing the invariant sees
            exact h0
          · exact h0
        · exact hinv.prepareRequest hr c n op hn hp

end Request

end Vsr
