import Vsr.Preserve.ViewChange

/-!
Recovery: `onRecovery`, `onRecoveryResponse`, and the recover step.
-/

namespace Vsr

variable {Op Output St : Type}

section Handlers
variable {s : System Op Output St} (hinv : Inv s) {id : ReplicaId} {r : Replica Op Output St}
  (hr : s.replicas[id]? = some r)
include hinv hr

theorem Inv.onRecovery (m : Machine Op Output St) {q : ReplicaId} {n : Nat} {v : ViewNumber} {dst : ReplicaId}
    (hnr : r.status ≠ .recovering) (hsent : Sent s dst (.recovery q n v)) :
    Inv (s.drainOf id (Replica.onRecovery m r q n v)) := by
  have hlt := hlt_of_getElem hr
  have h0 := hinv.drainOf_start hr
  have hmem := List.mem_of_getElem? hr
  have hclean := hinv.clean r hmem
  unfold Replica.onRecovery
  split
  · rename_i hc; exact h0.startViewChange hlt m v hc.1 hnr hclean.2
  · split
    · exact h0
    · rename_i hn
      have hn' : r.status = .normal := of_not_not hn
      try simp only
      refine h0.drainSend hlt (MsgOK.recoveryResponse h0 (s.drainOf_replicas_self r hlt) q hn' ⟨dst, q, v, Sent.after_of hsent⟩ ?_)
      intro z hz hzr _ hself
      rcases mem_after_replicas hinv.ids hr hz with rfl | ⟨hz, hne⟩
      · exact hnr (by simpa using hzr)
      · exact hne hself.symm

/-- The recovering replica records a response. -/
theorem Inv.recordRR (v : ViewNumber) (n : Nat) (q : ReplicaId) (st : Option (RecoveryState Op)) {dst : ReplicaId}
    (hrec : r.status = .recovering) (hn : n = r.recoveryNonce) (hsent : Sent s dst (.recoveryResponse v n q st)) :
    Inv (s.drainOf id ({ r with recoveryResponses := Assoc.insert r.recoveryResponses q ⟨v, st⟩ } : Replica Op Output St)) := by
  have hlt := hlt_of_getElem hr
  have h0 := hinv.drainOf_start hr
  have hmem := List.mem_of_getElem? hr
  have hloc := hinv.local_ r hmem
  have hclean := hinv.clean r hmem
  have hlog : r.log = [] := (hloc.2.2.2.2 hrec).1
  have hk : r.commitNumber = 0 := (hloc.2.2.2.2 hrec).2
  have hdrain : s.drainOf id r = s.after id r.clear [] [] := by
    simp only [System.drainOf, Replica.startedList, hinv.drained r hmem, hclean.2]
  refine h0.drainReplace hlt rfl rfl ?_
  refine StepOK.replace h0 (s.drainOf_replicas_self r hlt) rfl rfl (hinv.noPanic r hmem) rfl rfl rfl
    (hloc.withRecoveryResponses _).clear (Nat.le_refl _) (Nat.le_refl _) ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_
  · intro i e e' he; simp [hlog] at he
  · show Backed _ r.lastNormalView r.commitNumber; rw [hk]; intro i hi; simp at hi
  · intro _ _ _ _ _ hn'; exact absurd hrec hn'
  · intro hn'; exact absurd (hrec.symm.trans hn') (by decide)
  · intro hc; exact hinv.catching r hmem hc
  · intro dst' v' o hs
    refine ⟨?_, fun _ hn' => absurd hrec hn'⟩
    rw [hdrain] at hs
    exact (hinv.acksHold dst' v' o r.selfId (Sent.after_nil.mp hs) r hmem rfl).1
  · intro hn'; exact absurd hrec hn'
  · intro _ _ _ _ _ _ hn'; exact absurd hrec hn'
  · intro hs; exact absurd (hrec.symm.trans hs) (by decide)
  · intro _ _ _ _ _ _ hn'; exact absurd hrec hn'
  · intro _ dst' v' n' p stt hs hn' dst'' o hs'
    rw [hdrain] at hs hs'
    exact hinv.recoveryCovers r hmem hrec dst' v' n' p stt (Sent.after_nil.mp hs) hn' dst'' o (Sent.after_nil.mp hs')
  · intro i hi; simp [hlog] at hi
  · intro z hz _ _ i e e' he; simp [hlog] at he
  · intro hn'; exact absurd hrec hn'
  · intro hs; exact absurd (hrec.symm.trans hs) (by decide)
  · intro _ dst' v' n' p stt hs hn'
    rw [hdrain] at hs
    exact hinv.rrNotSelf dst' v' n' p stt (Sent.after_nil.mp hs) r hmem hrec hn'
  · intro hs; exact absurd (hrec.symm.trans hs) (by decide)
  · intro _ x resp hx
    have hx' : (x, resp) ∈ Assoc.insert r.recoveryResponses q ⟨v, st⟩ := hx
    rcases Assoc.mem_insert hx' with h | h
    · obtain ⟨rfl, rfl⟩ := Prod.mk.inj h
      exact ⟨dst, by rw [hdrain]; rw [hn] at hsent; exact Sent.after_of hsent⟩
    · obtain ⟨dst', hs⟩ := hinv.recordedRRs r hmem hrec x resp h
      exact ⟨dst', by rw [hdrain]; exact Sent.after_of hs⟩

theorem Inv.onRecoveryResponse (m : Machine Op Output St) {v : ViewNumber} {n : Nat} {q : ReplicaId}
    {st : Option (RecoveryState Op)} {dst : ReplicaId} (hsent : Sent s dst (.recoveryResponse v n q st)) :
    Inv (s.drainOf id (Replica.onRecoveryResponse m r v n q st)) := by
  have hlt := hlt_of_getElem hr
  have h0 := hinv.drainOf_start hr
  have hmem := List.mem_of_getElem? hr
  have hloc := hinv.local_ r hmem
  have hclean := hinv.clean r hmem
  have hconf := hinv.config_eq hmem
  unfold Replica.onRecoveryResponse
  split
  · exact h0
  · rename_i hg
    have hrec : r.status = .recovering := by
      rcases Decidable.em (r.status = .recovering) with h | h
      · exact h
      · exact absurd (Or.inl h) hg
    have hn : n = r.recoveryNonce := by
      rcases Decidable.em (n = r.recoveryNonce) with h | h
      · exact h
      · exact absurd (Or.inr h) hg
    have hlog : r.log = [] := (hloc.2.2.2.2 hrec).1
    have hk : r.commitNumber = 0 := (hloc.2.2.2.2 hrec).2
    try simp only
    have h1 := hinv.recordRR hr v n q st hrec hn hsent
    set r2 : Replica Op Output St := { r with recoveryResponses := Assoc.insert r.recoveryResponses q ⟨v, st⟩ } with hr2
    split
    · exact h1
    · try simp only
      split
      · exact h1
      · rename_i hlatest
        set latest := r2.recoveryResponses.foldl (fun acc (p : ReplicaId × RecoveryResponse Op) => max acc p.2.viewNumber) 0 with hlatestdef
        have hvle : r.viewNumber ≤ latest := Nat.le_of_not_lt hlatest
        split
        · rename_i pv state hlook
          split
          · exact h1
          · rename_i hpv
            have hpv' : pv = latest := of_not_not hpv
            subst hpv'
            try simp only
            -- the response adopted was sent by the primary of `latest`
            have hmemresp : (r2.config.primaryId latest, (⟨latest, some state⟩ : RecoveryResponse Op)) ∈ r2.recoveryResponses :=
              Assoc.lookup_some_mem hlook
            have hmem2 : r2.clear ∈ (s.drainOf id r2).replicas := drainOf_mem id r2 hlt
            obtain ⟨dst', hrr⟩ := h1.recordedRRs r2.clear hmem2 hrec _ _ hmemresp
            have hrc : r2.config = s.config := hconf
            have hrr' : Sent (s.drainOf id r2) dst' (.recoveryResponse latest r.recoveryNonce (s.config.primaryId latest) (some state)) := by
              rw [hrc] at hrr; exact hrr
            have hwf := h1.wf _ hrr'
            have hstate : state.commitNumber ≤ state.log.length := hwf
            have hnp : r.selfId ≠ s.config.primaryId latest := by
              intro h
              exact h1.rrNotSelf dst' latest r.recoveryNonce (s.config.primaryId latest) (some state) hrr' r2.clear hmem2 hrec rfl h.symm
            have hL : ∀ i e, state.log[i]? = some e → Holds (s.drainOf id r2) latest i e :=
              fun i e hi => ⟨0, state.log, .recovery hrr', Nat.zero_le _, by simpa using hi⟩
            have hsurv : ∀ v' i e, Committed (s.drainOf id r2) v' i e → v' < latest → state.log[i]? = some e :=
              fun v' i e hc hlt' => (h1.survives v' i e hc latest hlt').2.2.1 dst' _ _ state hrr'
            have hvpos : 0 < latest → ∃ dvcs, (latest, dvcs) ∈ (s.drainOf id r2).started :=
              fun hpos => h1.startedViews.2.1 latest 0 state.log (.recovery hrr') hpos
            -- the install
            set r3 : Replica Op Output St := { r2 with recoveryResponses := [], viewNumber := latest } with hr3
            have hk3 : r3.commitNumber ≤ r3.log.length := by
              show r.commitNumber ≤ r.log.length; rw [hk]; exact Nat.zero_le _
            have hinst : r3.installLog state.log = { r3 with
                clientTable := Replica.rebuildClientTable r3.commitNumber r3.clientTable 0 state.log [], log := state.log } := by
              unfold Replica.installLog
              rw [if_neg (Nat.not_lt.mpr (by show r.commitNumber ≤ _; rw [hk]; exact Nat.zero_le _))]
            have hlocF : Replica.LocalInv (Replica.commitUpTo m (r3.installLog state.log) state.commitNumber false).enterNormal :=
              Replica.LocalInv.install_then_normal m r3 hk3 state.log state.commitNumber false
            show Inv (s.drainOf id (Replica.commitUpTo m (r3.installLog state.log) state.commitNumber false).enterNormal)
            rw [hinst] at hlocF ⊢
            set r4 : Replica Op Output St := { r3 with
                clientTable := Replica.rebuildClientTable r3.commitNumber r3.clientTable 0 state.log [], log := state.log } with hr4
            have hk4 : r4.commitNumber ≤ r4.log.length := by
              show r.commitNumber ≤ state.log.length; rw [hk]; exact Nat.zero_le _
            refine h1.drainReplace hlt (by simp [hr4, hr3, hr2]) (by simp [Replica.startedList, hr4, hr3, hr2, hclean.2]) ?_
            refine StepOK.install h1 (s.drainOf_replicas_self r2 hlt) (v := latest) (L := state.log) rfl
              (by simp [hr4, hr3]) (by simp [hr4, hr3]) (by simp [hr4]) rfl (by simp [hr4, hr3, hr2])
              (by simp [hr4, hr3, hr2]) (by simp [hr4, hr3, hr2]) ?_ rfl rfl rfl
              hlocF.clear hvle (Nat.le_trans hloc.2.1 hvle)
              hL ?_ hsurv (by simpa using hnp) ?_ ?_ ?_ hvpos
            · show (Replica.commitUpTo m r4 state.commitNumber false).panicked = false
              rw [commitUpTo_panicked m r4 state.commitNumber false hk4 (by show _ ≤ state.log.length; exact hstate)]
              show r.panicked = false; exact hinv.noPanic r hmem
            · show Backed _ latest (Replica.commitUpTo m r4 state.commitNumber false).commitNumber
              refine (Backed.max ?_ (h1.backed.2 dst' _ hrr')).downward (commitUpTo_le_max m r4 _ false)
              show Backed _ latest r.commitNumber; rw [hk]; intro i hi; simp at hi
            · intro dst'' o hs
              exact h1.recoveryCovers r2.clear hmem2 hrec dst' latest r.recoveryNonce _ state hrr' rfl dst'' o hs
            · intro p hp hne hpn hpp hl
              have := (h1.longest p hp hpn hpp).1 0 state.log (by rw [hl]; exact .recovery hrr')
              simpa using this
            · intro dvcs b hst hb
              exact (h1.extendsBase latest dvcs b hst hb).2.1 dst' _ _ state hrr'
        · exact h1

end Handlers

/-- The recover step, with a fresh nonce. -/
theorem Inv.recover {s : System Op Output St} (hinv : Inv s) {id : ReplicaId} {r : Replica Op Output St}
    (hr : s.replicas[id]? = some r) (sm : St) (n : Nat) (hfresh : NonceFresh s n) :
    Inv (s.drainOf id (Replica.recover id s.config sm r.viewNumber n)) := by
  have hlt := hlt_of_getElem hr
  have h0 := hinv.drainOf_start hr
  have hmem := List.mem_of_getElem? hr
  have hclean := hinv.clean r hmem
  have hself : r.selfId = id := (hinv.ids id r hr).1
  have hconf : r.config = s.config := (hinv.ids id r hr).2
  set R : Replica Op Output St :=
    ({ Replica.new id s.config sm with
      status := .recovering
      viewNumber := r.viewNumber
      lastNormalView := r.viewNumber
      recoveryNonce := n } : Replica Op Output St) with hR
  have hunf : Replica.recover id s.config sm r.viewNumber n =
      R.sendToOthers (.recovery R.selfId R.recoveryNonce R.viewNumber) := rfl
  rw [hunf]
  have h1 : Inv (s.drainOf id R) := by
    refine h0.drainReplace hlt (by rw [hinv.drained r hmem]; rfl) (by simp [Replica.startedList, hclean.2, hR, Replica.new]) ?_
    refine StepOK.recover h0 (s.drainOf_replicas_self r hlt) (n := n) rfl rfl rfl rfl rfl rfl (by simp [hR, Replica.new, hself])
      (by simp [hR, Replica.new, hconf]) rfl rfl rfl rfl rfl (by simp [Replica.LocalInv, hR, Replica.new]) rfl ?_
    intro dst i v hs
    exact hfresh dst i v (by
      have hdrain : s.drainOf id r = s.after id r.clear [] [] := by
        simp only [System.drainOf, Replica.startedList, hinv.drained r hmem, hclean.2]
      rw [hdrain] at hs; exact Sent.after_nil.mp hs)
  exact h1.drainSendToOthers hlt _ (fun dst _ _ s' h' hr' => MsgOK.recovery h' hr' dst n)

end Vsr
