import Vsr.Preserve.Recovery

/-!
The idle step.
-/

namespace Vsr

variable {Op Output St : Type}

@[simp] theorem Replica.waitTimedOut_chosenDoViewChanges (r : Replica Op Output St) :
    r.waitTimedOut.1.chosenDoViewChanges = r.chosenDoViewChanges := rfl

@[simp] theorem Replica.stateTransfer_chosenDoViewChanges (r : Replica Op Output St) :
    r.stateTransfer.chosenDoViewChanges = r.chosenDoViewChanges := rfl

section Links
variable {s : System Op Output St} {id : ReplicaId} (hlt : id < s.replicas.length)
  {r1 : Replica Op Output St} (hinv : Inv (s.drainOf id r1))
include hlt hinv

theorem Inv.drainNoteStable (hnr : r1.status ≠ .recovering) : Inv (s.drainOf id r1.noteStable) := by
  have hloc := hinv.drainOf_local hlt
  refine hinv.drainKeepLog hlt rfl rfl rfl rfl rfl (hinv.drainOf_noPanic hlt) rfl rfl (Or.inr rfl) (Nat.le_refl _)
    hloc.noteStable hnr hnr (hinv.drainOf_backed hlt) (hinv.drainOf_catching hlt)
    (fun hn hp oa hoa => hinv.drainOf_acks hlt hn hp oa hoa) (hinv.drainOf_vcBehind hlt)
    (hinv.drainOf_transfer hlt) (hinv.drainOf_dvcs hlt)

theorem Inv.drainWaitTimedOut (hnr : r1.status ≠ .recovering) : Inv (s.drainOf id r1.waitTimedOut.1) := by
  have hloc := hinv.drainOf_local hlt
  refine hinv.drainKeepLog hlt rfl rfl rfl rfl rfl (hinv.drainOf_noPanic hlt) rfl rfl (Or.inr rfl) (Nat.le_refl _)
    hloc.waitTimedOut hnr hnr (hinv.drainOf_backed hlt) (hinv.drainOf_catching hlt)
    (fun hn hp oa hoa => hinv.drainOf_acks hlt hn hp oa hoa) (hinv.drainOf_vcBehind hlt)
    (hinv.drainOf_transfer hlt) (hinv.drainOf_dvcs hlt)

theorem Inv.drainWithHeardIdle (hnr : r1.status ≠ .recovering) (b : Bool) (k : Nat) :
    Inv (s.drainOf id ({ r1 with heardFromPrimary := b, idlePeriodsWaiting := k } : Replica Op Output St)) := by
  have hloc := hinv.drainOf_local hlt
  refine hinv.drainKeepLog hlt rfl rfl rfl rfl rfl (hinv.drainOf_noPanic hlt) rfl rfl (Or.inr rfl) (Nat.le_refl _)
    (hloc.withHeardIdle b k) hnr hnr (hinv.drainOf_backed hlt) (hinv.drainOf_catching hlt)
    (fun hn hp oa hoa => hinv.drainOf_acks hlt hn hp oa hoa) (hinv.drainOf_vcBehind hlt)
    (hinv.drainOf_transfer hlt) (hinv.drainOf_dvcs hlt)

theorem Inv.drainWithStable (hnr : r1.status ≠ .recovering) (k : Nat) :
    Inv (s.drainOf id ({ r1 with idlePeriodsStable := k } : Replica Op Output St)) := by
  have hloc := hinv.drainOf_local hlt
  refine hinv.drainKeepLog hlt rfl rfl rfl rfl rfl (hinv.drainOf_noPanic hlt) rfl rfl (Or.inr rfl) (Nat.le_refl _)
    (hloc.withStable k) hnr hnr (hinv.drainOf_backed hlt) (hinv.drainOf_catching hlt)
    (fun hn hp oa hoa => hinv.drainOf_acks hlt hn hp oa hoa) (hinv.drainOf_vcBehind hlt)
    (hinv.drainOf_transfer hlt) (hinv.drainOf_dvcs hlt)

/-- A replica in state transfer asking again. -/
theorem Inv.drainStateTransfer' (hst : r1.status = .stateTransfer) :
    Inv (s.drainOf id r1.stateTransfer) := by
  have hloc := hinv.drainOf_local hlt
  have hnr : r1.status ≠ .recovering := by rw [hst]; decide
  have hnp := hinv.drainOf_transfer hlt hst
  unfold Replica.stateTransfer Replica.sendGetState Replica.sendToPrimary
  have h1 : Inv (s.drainOf id ({ r1 with status := .stateTransfer } : Replica Op Output St)) := by
    refine hinv.drainKeepLog hlt rfl rfl rfl rfl rfl (hinv.drainOf_noPanic hlt) rfl rfl (Or.inr rfl) (Nat.le_refl _)
      (hloc.stateTransfer (Or.inr hst)) hnr (fun h => by simp at h) (hinv.drainOf_backed hlt)
      (fun hc => hinv.drainOf_catching hlt hc) (fun hn' => by simp at hn') (fun h => by simp at h)
      (fun _ => hnp) (fun h => by simp at h)
  exact h1.drainSend hlt (MsgOK.getState h1 (s.drainOf_replicas_self _ hlt) _ _)

/-- The primary's re-sends of its uncommitted `Prepare`s. -/
theorem Inv.drainResendPrepares (hn : r1.status = .normal) (hp : r1.isPrimary = true) :
    Inv (s.drainOf id (r1.resendPrepares r1.viewNumber r1.commitNumber)) := by
  have hconf := hinv.drainOf_config hlt
  have hprim : r1.selfId = s.config.primaryId r1.viewNumber := by
    unfold Replica.isPrimary Replica.primaryId at hp; rw [← hconf]; exact of_decide_eq_true hp
  unfold Replica.resendPrepares
  -- every index in the range is within the log
  have hrange : ∀ i ∈ List.range (r1.opNumber - r1.commitNumber), r1.commitNumber + i < r1.log.length := by
    intro i hi
    rw [List.mem_range] at hi
    unfold Replica.opNumber at hi
    have := Nat.lt_sub_iff_add_lt.mp hi
    rw [Nat.add_comm]; exact this
  generalize List.range (r1.opNumber - r1.commitNumber) = l at hrange
  -- the fold keeps the fields the messages use
  suffices ∀ (l : List Nat) (r : Replica Op Output St), (∀ i ∈ l, r1.commitNumber + i < r1.log.length) →
      r.log = r1.log → r.status = .normal → r.viewNumber = r1.viewNumber → r.commitNumber = r1.commitNumber →
      r.selfId = r1.selfId → r.config = r1.config → r.isPrimary = true → Inv (s.drainOf id r) →
      Inv (s.drainOf id (l.foldl (fun r i =>
        match r.log[r1.commitNumber + 1 + i - 1]? with
        | none => r.panic
        | some entry => r.sendToOthers (.prepare r1.viewNumber (r1.commitNumber + 1 + i) entry.clientId
            entry.requestNumber entry.op r1.commitNumber)) r)) from
    this l r1 hrange rfl hn rfl rfl rfl rfl hp hinv
  intro l
  induction l with
  | nil => intro r _ _ _ _ _ _ _ _ h; exact h
  | cons i l ih =>
    intro r hbound hlog hstat hview hcommit hself hconf' hprim' h
    rw [List.foldl_cons]
    have hi : r1.commitNumber + i < r1.log.length := hbound i (List.mem_cons_self ..)
    have hidx : r1.commitNumber + 1 + i - 1 = r1.commitNumber + i := by
      rw [Nat.add_right_comm, Nat.add_sub_cancel]
    have hget : r.log[r1.commitNumber + 1 + i - 1]? = some r1.log[r1.commitNumber + i] := by
      rw [hidx, hlog]; exact List.getElem?_eq_getElem hi
    simp only [hget]
    refine ih _ (fun j hj => hbound j (List.mem_cons_of_mem _ hj)) (by rw [Replica.sendToOthers_log, hlog])
      (by rw [Replica.sendToOthers_status, hstat]) (by rw [Replica.sendToOthers_viewNumber, hview])
      (by rw [Replica.sendToOthers_commitNumber, hcommit]) (by rw [Replica.sendToOthers_selfId, hself])
      (by rw [Replica.sendToOthers_config, hconf']) (by
        unfold Replica.isPrimary Replica.primaryId at hprim' ⊢
        simpa using hprim') ?_
    refine h.drainSendToOthers hlt _ (fun dst hd hne s' h' hr' => ?_)
    have hm := MsgOK.prepareResend h' hr' dst (by simpa using hstat) (by simpa using hprim')
      (o := r1.commitNumber + 1 + i) (e := r1.log[r1.commitNumber + i])
      (Nat.lt_of_lt_of_le (Nat.succ_pos _) (Nat.le_add_right _ _))
      (by rw [Replica.clear_log, hidx, hlog]; exact List.getElem?_eq_getElem hi)
      (by
        rw [Replica.clear_viewNumber, hview, ← h'.config_eq (List.mem_of_getElem? hr')]
        show dst ≠ r.config.primaryId r1.viewNumber
        rw [hconf', hconf, ← hprim, ← hself]
        exact hne)
    simpa [hview, hcommit] using hm

end Links

section Handlers
variable {s : System Op Output St} (hinv : Inv s) {id : ReplicaId} {r : Replica Op Output St}
  (hr : s.replicas[id]? = some r)
include hinv hr

theorem Inv.onIdle (m : Machine Op Output St) : Inv (s.drainOf id (Replica.onIdle m r)) := by
  have hlt := hlt_of_getElem hr
  have h0 := hinv.drainOf_start hr
  have hmem := List.mem_of_getElem? hr
  have hclean := hinv.clean r hmem
  have hloc := hinv.local_ r hmem
  -- `backupIdle` from normal or transfer status
  have hbackup : ∀ r' : Replica Op Output St, Inv (s.drainOf id r') → r'.chosenDoViewChanges = none →
      (r'.status = .normal ∨ r'.status = .stateTransfer) → Inv (s.drainOf id (Replica.onIdle.backupIdle m r')) := by
    intro r' h' hcv hs
    have hnr' : r'.status ≠ .recovering := by rcases hs with hs | hs <;> rw [hs] <;> decide
    unfold Replica.onIdle.backupIdle
    split
    · exact (h'.drainWithHeardIdle hlt hnr' false 0).drainNoteStable hlt (by simpa using hnr')
    · try simp only
      have h2 := (h'.drainWithStable hlt hnr' 0).drainWaitTimedOut hlt (by simpa using hnr')
      generalize hw : ({ r' with idlePeriodsStable := 0 } : Replica Op Output St).waitTimedOut = p at h2 ⊢
      obtain ⟨r'', t⟩ := p
      simp only at h2 ⊢
      have hr'' : r'' = ({ r' with idlePeriodsStable := 0 } : Replica Op Output St).waitTimedOut.1 := by rw [hw]
      cases t
      · exact h2
      · refine h2.startViewChange hlt m _ (Nat.lt_succ_self _) (by rw [hr'']; simpa using hnr') (by rw [hr'']; simp; exact hcv)
  unfold Replica.onIdle
  split
  · rename_i hn
    split
    · rename_i hp
      have h1 := h0.drainNoteStable hlt (by rw [hn]; decide)
      have h2 := h1.drainSendToOthers hlt _ (fun dst hd hne s' h' hr' =>
        MsgOK.commit h' hr' dst (by simpa using hn) (by
          have hconf := hinv.config_eq hmem
          have hprim : r.selfId = s.config.primaryId r.viewNumber := by
            unfold Replica.isPrimary Replica.primaryId at hp; rw [← hconf]; exact of_decide_eq_true hp
          rw [Replica.clear_viewNumber, Replica.noteStable_viewNumber, ← h'.config_eq (List.mem_of_getElem? hr')]
          show dst ≠ r.config.primaryId r.viewNumber
          rw [hconf, ← hprim]
          exact hne))
      have := h2.drainResendPrepares hlt (by simpa using hn) (by
        unfold Replica.isPrimary Replica.primaryId at hp ⊢; simpa using hp)
      simpa using this
    · exact hbackup r h0 hclean.2 (Or.inl hn)
  · exact h0.drainSendToOthers hlt _ (fun dst _ _ s' h' hr' => MsgOK.recovery h' hr' dst _)
  · rename_i hst
    exact hbackup _ (h0.drainStateTransfer' hlt hst) (by simpa using hclean.2) (Or.inr (by simp))
  · rename_i hvc
    have hnr : r.status ≠ .recovering := by rw [hvc]; decide
    try simp only
    have h1 := h0.drainWaitTimedOut hlt hnr
    generalize hw : r.waitTimedOut = p at h1 ⊢
    obtain ⟨r', t⟩ := p
    simp only at h1 ⊢
    have hr' : r' = r.waitTimedOut.1 := by rw [hw]
    have hnr' : r'.status ≠ .recovering := by rw [hr']; simpa using hnr
    have hvc' : r'.status = .viewChange := by rw [hr']; simpa using hvc
    have hcv' : r'.chosenDoViewChanges = none := by rw [hr']; simpa using hclean.2
    cases t
    · simp only [Bool.false_eq_true, if_false]
      split
      · unfold Replica.sendGetState Replica.sendToPrimary
        exact h1.drainSend hlt (MsgOK.getState h1 (s.drainOf_replicas_self _ hlt) _ _)
      · try simp only
        have hpos : 0 < r'.viewNumber := Nat.lt_of_le_of_lt (Nat.zero_le _) (h1.drainOf_vcBehind hlt hvc')
        have h2 := h1.drainSendToOthers hlt _ (fun dst _ _ s' h' hr'' => MsgOK.startViewChange h' hr'' dst hpos)
        split
        · exact h2.sendDoViewChange hlt m (by simpa using hvc') (by rw [Replica.sendToOthers_eq_withOutbox]; exact hcv')
        · exact h2
    · exact h1.startViewChange hlt m _ (Nat.lt_succ_self _) hnr' hcv'

end Handlers

end Vsr
