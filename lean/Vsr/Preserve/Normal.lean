import Vsr.Preserve.Replace
import Vsr.Preserve.Assoc

/-!
Normal operation and state transfer: `onGetState`, `onCommit`, `onPrepare`,
`onPrepareOk`, `onNewState`, and the helpers they share.
-/

namespace Vsr

variable {Op Output St : Type}

/-! ### Committing -/

theorem commitUpTo_go_add_le (m : Machine Op Output St) (reply : Bool) :
    ∀ (n : Nat) (r : Replica Op Output St),
      (Replica.commitUpTo.go m reply n r).commitNumber ≤ r.commitNumber + n := by
  intro n
  induction n with
  | zero => intro r; exact Nat.le_refl _
  | succ n ih =>
    intro r
    rw [Replica.commitUpTo_go_succ]
    split
    · show (r.panic).commitNumber ≤ r.commitNumber + (n + 1)
      exact Nat.le_add_right _ _
    · rename_i entry _
      have hxc : (if reply then { (Replica.commitOp m r entry).1 with
          replies := (Replica.commitOp m r entry).1.replies ++ [(Replica.commitOp m r entry).2] }
        else (Replica.commitOp m r entry).1).commitNumber = r.commitNumber + 1 := by
        split <;> rfl
      have hih := ih (if reply then { (Replica.commitOp m r entry).1 with
          replies := (Replica.commitOp m r entry).1.replies ++ [(Replica.commitOp m r entry).2] }
        else (Replica.commitOp m r entry).1)
      rw [hxc] at hih
      have heq : r.commitNumber + 1 + n = r.commitNumber + (n + 1) := by
        rw [Nat.add_assoc, Nat.add_comm 1 n]
      exact heq ▸ hih

theorem commitUpTo_le_max (m : Machine Op Output St) (r : Replica Op Output St) (k : Nat) (reply : Bool) :
    (Replica.commitUpTo m r k reply).commitNumber ≤ max r.commitNumber k := by
  unfold Replica.commitUpTo
  have hih := commitUpTo_go_add_le m reply (k - r.commitNumber) r
  have hmax : r.commitNumber + (k - r.commitNumber) = max r.commitNumber k := by
    rcases Nat.le_total r.commitNumber k with h | h
    · rw [Nat.add_sub_cancel' h, Nat.max_eq_right h]
    · rw [Nat.sub_eq_zero_of_le h, Nat.add_zero, Nat.max_eq_left h]
  exact hmax ▸ hih

theorem commitUpTo_go_panicked (m : Machine Op Output St) (reply : Bool) :
    ∀ (n : Nat) (r : Replica Op Output St),
      r.commitNumber + n ≤ r.log.length →
      (Replica.commitUpTo.go m reply n r).panicked = r.panicked := by
  intro n
  induction n with
  | zero => intro r _; rfl
  | succ n ih =>
    intro r hle
    rw [Replica.commitUpTo_go_succ]
    have hlt : r.commitNumber < r.log.length :=
      Nat.lt_of_lt_of_le (Nat.lt_add_of_pos_right (Nat.succ_pos n)) hle
    split
    · rename_i heq
      rw [List.getElem?_eq_getElem hlt] at heq
      exact absurd heq (Option.some_ne_none _)
    · rename_i entry _
      have heq2 : r.commitNumber + 1 + n = r.commitNumber + (n + 1) := by
        rw [Nat.add_assoc, Nat.add_comm 1 n]
      split
      · rw [ih _ ?_]
        · simp
        · simp only [Replica.withReplies_commitNumber, Replica.withReplies_log, Replica.commitOp_commitNumber,
            Replica.commitOp_log]
          rw [heq2]; exact hle
      · rw [ih _ ?_]
        · simp
        · simp only [Replica.commitOp_commitNumber, Replica.commitOp_log]
          rw [heq2]; exact hle

theorem commitUpTo_panicked (m : Machine Op Output St) (r : Replica Op Output St) (k : Nat) (reply : Bool)
    (hc : r.commitNumber ≤ r.log.length) (hk : k ≤ r.log.length) :
    (Replica.commitUpTo m r k reply).panicked = r.panicked := by
  unfold Replica.commitUpTo
  apply commitUpTo_go_panicked
  have hmax : r.commitNumber + (k - r.commitNumber) = max r.commitNumber k := by
    rcases Nat.le_total r.commitNumber k with h | h
    · rw [Nat.add_sub_cancel' h, Nat.max_eq_right h]
    · rw [Nat.sub_eq_zero_of_le h, Nat.add_zero, Nat.max_eq_left h]
  rw [hmax]; exact Nat.max_le.mpr ⟨hc, hk⟩

theorem Backed.downward {s : System Op Output St} {v m n} (h : Backed s v n) (hle : m ≤ n) :
    Backed s v m := fun i hi => h i (Nat.lt_of_lt_of_le hi hle)

theorem Backed.max {s : System Op Output St} {v a b} (ha : Backed s v a) (hb : Backed s v b) :
    Backed s v (max a b) := by
  intro i hi
  have : i < a ∨ i < b := by omega
  rcases this with h | h
  · exact ha i h
  · exact hb i h

/-- `Backed` in the drained view, from `Backed` in the cluster. -/
theorem Backed.drainOf {s : System Op Output St} {v k} (h : Backed s v k) (id : ReplicaId) (r : Replica Op Output St) :
    Backed (s.drainOf id r) v k :=
  Backed.after_of h

theorem Replica.LocalInv.of_clear {r : Replica Op Output St} (h : Replica.LocalInv r.clear) : Replica.LocalInv r := h

theorem Replica.foldl_appendToLog_selfId (r : Replica Op Output St) (l : List (LogEntry Op)) :
    (l.foldl Replica.appendToLog r).selfId = r.selfId :=
  foldl_proj Replica.selfId Replica.appendToLog (fun _ _ => rfl) _ _
theorem Replica.foldl_appendToLog_config (r : Replica Op Output St) (l : List (LogEntry Op)) :
    (l.foldl Replica.appendToLog r).config = r.config :=
  foldl_proj Replica.config Replica.appendToLog (fun _ _ => rfl) _ _
theorem Replica.foldl_appendToLog_panicked (r : Replica Op Output St) (l : List (LogEntry Op)) :
    (l.foldl Replica.appendToLog r).panicked = r.panicked :=
  foldl_proj Replica.panicked Replica.appendToLog (fun _ _ => rfl) _ _
theorem Replica.foldl_appendToLog_outbox (r : Replica Op Output St) (l : List (LogEntry Op)) :
    (l.foldl Replica.appendToLog r).outbox = r.outbox :=
  foldl_proj Replica.outbox Replica.appendToLog (fun _ _ => rfl) _ _
theorem Replica.foldl_appendToLog_chosen (r : Replica Op Output St) (l : List (LogEntry Op)) :
    (l.foldl Replica.appendToLog r).chosenDoViewChanges = r.chosenDoViewChanges :=
  foldl_proj Replica.chosenDoViewChanges Replica.appendToLog (fun _ _ => rfl) _ _
theorem Replica.foldl_appendToLog_recoveryNonce (r : Replica Op Output St) (l : List (LogEntry Op)) :
    (l.foldl Replica.appendToLog r).recoveryNonce = r.recoveryNonce :=
  foldl_proj Replica.recoveryNonce Replica.appendToLog (fun _ _ => rfl) _ _
theorem Replica.foldl_appendToLog_acks (r : Replica Op Output St) (l : List (LogEntry Op)) :
    (l.foldl Replica.appendToLog r).acks = r.acks :=
  foldl_proj Replica.acks Replica.appendToLog (fun _ _ => rfl) _ _

@[simp] theorem Replica.enterNormal_recoveryNonce (r : Replica Op Output St) : r.enterNormal.recoveryNonce = r.recoveryNonce := rfl
@[simp] theorem Replica.enterNormal_chosenDoViewChanges (r : Replica Op Output St) :
    r.enterNormal.chosenDoViewChanges = r.chosenDoViewChanges := rfl
@[simp] theorem Replica.enterNormal_acks (r : Replica Op Output St) : r.enterNormal.acks = r.acks := rfl
@[simp] theorem Replica.enterNormal_replies (r : Replica Op Output St) : r.enterNormal.replies = r.replies := rfl
@[simp] theorem Replica.clearViewChangeState_selfId (r : Replica Op Output St) : r.clearViewChangeState.selfId = r.selfId := rfl
@[simp] theorem Replica.clearViewChangeState_config (r : Replica Op Output St) : r.clearViewChangeState.config = r.config := rfl
@[simp] theorem Replica.clearViewChangeState_panicked (r : Replica Op Output St) : r.clearViewChangeState.panicked = r.panicked := rfl
@[simp] theorem Replica.clearViewChangeState_recoveryNonce (r : Replica Op Output St) :
    r.clearViewChangeState.recoveryNonce = r.recoveryNonce := rfl
@[simp] theorem Replica.clearViewChangeState_chosenDoViewChanges (r : Replica Op Output St) :
    r.clearViewChangeState.chosenDoViewChanges = r.chosenDoViewChanges := rfl
@[simp] theorem Replica.clearViewChangeState_replies (r : Replica Op Output St) : r.clearViewChangeState.replies = r.replies := rfl
@[simp] theorem Replica.clearViewChangeState_acks (r : Replica Op Output St) : r.clearViewChangeState.acks = r.acks := rfl

/-! ### One change that keeps the log -/

section KeepLog
variable {s : System Op Output St} {id : ReplicaId} (hlt : id < s.replicas.length)
  {r1 r2 : Replica Op Output St} (hinv : Inv (s.drainOf id r1))
include hlt hinv

/-- The invariant of the drained view, about `r1` itself. -/
theorem Inv.drainOf_local : Replica.LocalInv r1 := (hinv.local_ r1.clear (drainOf_mem id r1 hlt)).of_clear
theorem Inv.drainOf_noPanic : r1.panicked = false := hinv.noPanic r1.clear (drainOf_mem id r1 hlt)
theorem Inv.drainOf_selfId : r1.selfId = id := (hinv.ids id r1.clear (s.drainOf_replicas_self r1 hlt)).1
theorem Inv.drainOf_config : r1.config = s.config := (hinv.ids id r1.clear (s.drainOf_replicas_self r1 hlt)).2
theorem Inv.drainOf_selfIdLt : r1.selfId < s.config.replicaCount :=
  hinv.selfId_lt (r := r1.clear) (drainOf_mem id r1 hlt)
theorem Inv.drainOf_backed : Backed (s.drainOf id r1) r1.lastNormalView r1.commitNumber :=
  hinv.backed.1 r1.clear (drainOf_mem id r1 hlt)
theorem Inv.drainOf_catching : r1.catchingUp = true → r1.selfId ≠ r1.config.primaryId r1.viewNumber :=
  hinv.catching r1.clear (drainOf_mem id r1 hlt)
theorem Inv.drainOf_vcBehind : r1.status = .viewChange → r1.lastNormalView < r1.viewNumber :=
  hinv.vcBehind r1.clear (drainOf_mem id r1 hlt)
theorem Inv.drainOf_transfer : r1.status = .stateTransfer → r1.selfId ≠ s.config.primaryId r1.viewNumber :=
  hinv.transferNotPrimary r1.clear (drainOf_mem id r1 hlt)
theorem Inv.drainOf_dvcs : r1.status = .viewChange →
    (r1.doViewChangeFrom.map Prod.fst).Pairwise (· < ·) ∧
    ∀ x d, (x, d) ∈ r1.doViewChangeFrom → x < s.config.replicaCount ∧
      ((∃ dst, Sent (s.drainOf id r1) dst (.doViewChange r1.viewNumber x d.lastNormalView d.log d.log.length d.commitNumber)) ∨
        (x = r1.selfId ∧ d = ⟨r1.lastNormalView, r1.log, r1.commitNumber⟩)) :=
  hinv.recordedDvcs r1.clear (drainOf_mem id r1 hlt)
theorem Inv.drainOf_acks : r1.status = .normal → r1.isPrimary = true → ∀ oa ∈ r1.acks, oa.1 ≤ r1.log.length ∧
    oa.2.Pairwise (· < ·) ∧ ∀ q ∈ oa.2, q < s.config.replicaCount ∧
      (q = r1.selfId ∨ ∃ dst, Sent (s.drainOf id r1) dst (.prepareOk r1.viewNumber oa.1 q)) :=
  hinv.acks r1.clear (drainOf_mem id r1 hlt)

/-- A change that keeps the log, last normal view, and identity, sends
nothing, and starts nothing. -/
theorem Inv.drainKeepLog (hlog : r2.log = r1.log) (hlnv : r2.lastNormalView = r1.lastNormalView)
    (hself : r2.selfId = r1.selfId) (hconf : r2.config = r1.config) (hnonce : r2.recoveryNonce = r1.recoveryNonce)
    (hpanic : r2.panicked = false) (hout : r2.outbox = r1.outbox) (hcv : r2.chosenDoViewChanges = r1.chosenDoViewChanges)
    (hviewst : r1.chosenDoViewChanges = none ∨ r2.viewNumber = r1.viewNumber)
    (hview : r1.viewNumber ≤ r2.viewNumber) (hloc : Replica.LocalInv r2)
    (hnr : r1.status ≠ .recovering) (hnr' : r2.status ≠ .recovering)
    (hbacked : Backed (s.drainOf id r1) r1.lastNormalView r2.commitNumber)
    (hcatch : r2.catchingUp = true → r2.selfId ≠ r2.config.primaryId r2.viewNumber)
    (hacks : r2.status = .normal → r2.isPrimary = true → ∀ oa ∈ r2.acks, oa.1 ≤ r2.log.length ∧
      oa.2.Pairwise (· < ·) ∧ ∀ q ∈ oa.2, q < s.config.replicaCount ∧
        (q = r2.selfId ∨ ∃ dst, Sent (s.drainOf id r1) dst (.prepareOk r2.viewNumber oa.1 q)))
    (hvc : r2.status = .viewChange → r2.lastNormalView < r2.viewNumber)
    (htr : r2.status = .stateTransfer → r2.selfId ≠ s.config.primaryId r2.viewNumber)
    (hdvcs : r2.status = .viewChange →
      (r2.doViewChangeFrom.map Prod.fst).Pairwise (· < ·) ∧
      ∀ x d, (x, d) ∈ r2.doViewChangeFrom → x < s.config.replicaCount ∧
        ((∃ dst, Sent (s.drainOf id r1) dst (.doViewChange r2.viewNumber x d.lastNormalView d.log d.log.length d.commitNumber)) ∨
          (x = r2.selfId ∧ d = ⟨r2.lastNormalView, r2.log, r2.commitNumber⟩))) :
    Inv (s.drainOf id r2) := by
  have hst : r2.startedList = r1.startedList := by
    unfold Replica.startedList
    rw [hcv]
    rcases hviewst with h | h
    · rw [h]
    · rw [h]
  refine hinv.drainReplace hlt hout hst ?_
  refine StepOK.keepLog hinv (s.drainOf_replicas_self r1 hlt) hlog hlnv hself hconf hnonce hpanic rfl rfl rfl
    hview hloc.clear hnr hnr' hbacked hcatch hacks hvc htr hdvcs

/-- Committing up to a backed bound within the log. -/
theorem Inv.drainCommit (m : Machine Op Output St) (k : Nat) (reply : Bool)
    (hnr : r1.status ≠ .recovering) (hnvc : r1.status ≠ .viewChange) (hk : k ≤ r1.log.length)
    (hbacked : Backed (s.drainOf id r1) r1.lastNormalView k) :
    Inv (s.drainOf id (Replica.commitUpTo m r1 k reply)) := by
  have hloc := hinv.drainOf_local hlt
  refine hinv.drainKeepLog hlt (by simp) (by simp) (by simp) (by simp) (by simp)
    (by rw [commitUpTo_panicked m r1 k reply hloc.1 hk]; exact hinv.drainOf_noPanic hlt)
    (by simp) (by simp) (Or.inr (by simp)) (by simp) (hloc.commitUpTo m k reply) hnr (by simpa using hnr)
    ((Backed.max (hinv.backed.1 r1.clear (drainOf_mem id r1 hlt)) hbacked).downward (commitUpTo_le_max m r1 k reply))
    (by simpa using hinv.catching r1.clear (drainOf_mem id r1 hlt))
    (by
      intro hn hp oa hoa
      simp only [Replica.commitUpTo_status] at hn
      simp only [Replica.commitUpTo_acks] at hoa
      have hp' : r1.isPrimary = true := by
        unfold Replica.isPrimary Replica.primaryId at hp ⊢
        simpa using hp
      have := hinv.acks r1.clear (drainOf_mem id r1 hlt) hn hp' oa hoa
      simpa using this)
    (by simpa using hinv.vcBehind r1.clear (drainOf_mem id r1 hlt))
    (by simpa using hinv.transferNotPrimary r1.clear (drainOf_mem id r1 hlt))
    (fun hs => absurd (by simpa using hs) hnvc)

/-- Marking the primary heard from. -/
theorem Inv.drainHeard (b : Bool) (hnr : r1.status ≠ .recovering) :
    Inv (s.drainOf id ({ r1 with heardFromPrimary := b } : Replica Op Output St)) := by
  have hloc := hinv.drainOf_local hlt
  refine hinv.drainKeepLog hlt rfl rfl rfl rfl rfl (hinv.drainOf_noPanic hlt) rfl rfl (Or.inr rfl) (Nat.le_refl _)
    (hloc.withHeard b) hnr hnr (hinv.backed.1 r1.clear (drainOf_mem id r1 hlt))
    (hinv.catching r1.clear (drainOf_mem id r1 hlt)) ?_ (hinv.vcBehind r1.clear (drainOf_mem id r1 hlt))
    (hinv.transferNotPrimary r1.clear (drainOf_mem id r1 hlt)) (hinv.drainOf_dvcs hlt)
  intro hn hp oa hoa
  exact hinv.acks r1.clear (drainOf_mem id r1 hlt) hn hp oa hoa

end KeepLog

/-! ### State transfer and catching up -/

section Transfer
variable {s : System Op Output St} {id : ReplicaId} (hlt : id < s.replicas.length)
  {r1 : Replica Op Output St} (hinv : Inv (s.drainOf id r1))
include hlt hinv

/-- A normal backup entering state transfer and asking for the log. -/
theorem Inv.drainStateTransfer (hn : r1.status = .normal) (hnp : r1.selfId ≠ s.config.primaryId r1.viewNumber) :
    Inv (s.drainOf id r1.stateTransfer) := by
  have hloc := hinv.drainOf_local hlt
  have hnr : r1.status ≠ .recovering := by rw [hn]; decide
  unfold Replica.stateTransfer Replica.sendGetState Replica.sendToPrimary
  have h1 : Inv (s.drainOf id ({ r1 with status := .stateTransfer } : Replica Op Output St)) := by
    refine hinv.drainKeepLog hlt rfl rfl rfl rfl rfl (hinv.drainOf_noPanic hlt) rfl rfl (Or.inr rfl) (Nat.le_refl _)
      (hloc.stateTransfer (Or.inl hn)) hnr (fun h => by simp at h) (hinv.backed.1 r1.clear (drainOf_mem id r1 hlt))
      (fun hc => hinv.catching r1.clear (drainOf_mem id r1 hlt) hc) (fun hn' => by simp at hn') (fun h => by simp at h)
      (fun _ => hnp) (fun h => by simp at h)
  exact h1.drainSend hlt (MsgOK.getState h1 (s.drainOf_replicas_self _ hlt) _ _)

/-- Catching up with a view. -/
theorem Inv.drainCatchUp (v : ViewNumber) (hv : r1.viewNumber ≤ v) (hnr : r1.status ≠ .recovering)
    (hnp : r1.selfId ≠ s.config.primaryId v) (hvs : r1.viewNumber < v ∨ r1.status = .viewChange)
    (hcv : r1.chosenDoViewChanges = none) :
    Inv (s.drainOf id (r1.catchUpWithView v)) := by
  have hloc := hinv.drainOf_local hlt
  have hconf := hinv.drainOf_config hlt
  unfold Replica.catchUpWithView
  split
  · exact hinv
  · rename_i hc
    unfold Replica.sendGetState Replica.sendToPrimary
    have h1 : Inv (s.drainOf id ({ r1.clearViewChangeState with viewNumber := v, status := Status.viewChange, catchingUp := true, idlePeriodsWaiting := 0 } : Replica Op Output St)) := by
      refine hinv.drainKeepLog hlt rfl rfl rfl rfl rfl (hinv.drainOf_noPanic hlt) rfl rfl (Or.inl ?_) hv
        ?_ hnr (fun h => by simp at h) (hinv.backed.1 r1.clear (drainOf_mem id r1 hlt))
        (fun _ => by show r1.selfId ≠ r1.config.primaryId v; rw [hconf]; exact hnp)
        (fun hn' => by simp at hn') ?_ (fun h => by simp at h)
        (fun _ => ⟨by simp [Replica.clearViewChangeState], fun x d hd => by simp [Replica.clearViewChangeState] at hd⟩)
      · exact hcv
      · obtain ⟨h1, h2, h3, h4, h5⟩ := hloc
        refine ⟨h1, Nat.le_trans h2 hv, ?_, fun _ => rfl, ?_⟩
        · rintro (h | h) <;> exact Status.noConfusion h
        · intro h; exact Status.noConfusion h
      · intro _
        show r1.lastNormalView < v
        rcases hvs with hlt' | hvc
        · exact Nat.lt_of_le_of_lt hloc.2.1 hlt'
        · exact Nat.lt_of_lt_of_le (hinv.vcBehind r1.clear (drainOf_mem id r1 hlt) hvc) hv
    exact h1.drainSend hlt (MsgOK.getState h1 (s.drainOf_replicas_self _ hlt) _ _)

/-- `acceptFromPrimary`: the replica afterwards keeps the invariant, and if
it accepted, it is a normal backup in the message's view and changed only
its `heardFromPrimary` flag. -/
theorem Inv.drainAccept (v : ViewNumber) (hnr : r1.status ≠ .recovering)
    (hnp : r1.selfId ≠ s.config.primaryId v) (hcv : r1.chosenDoViewChanges = none) :
    Inv (s.drainOf id (r1.acceptFromPrimary v).1) ∧
      ((r1.acceptFromPrimary v).2 = true →
        (r1.acceptFromPrimary v).1 = { r1 with heardFromPrimary := true } ∧ r1.status = .normal ∧
          v = r1.viewNumber ∧ r1.isPrimary = false) := by
  unfold Replica.acceptFromPrimary
  split
  · exact ⟨hinv, fun h => by simp at h⟩
  · rename_i hlt'
    split
    · rename_i hgt
      exact ⟨hinv.drainCatchUp hlt v (Nat.le_of_lt hgt) hnr hnp (Or.inl hgt) hcv, fun h => by simp at h⟩
    · rename_i hgt'
      have hv : v = r1.viewNumber := Nat.le_antisymm (Nat.le_of_not_lt hgt') (Nat.le_of_not_lt hlt')
      have h1 := hinv.drainHeard hlt true hnr
      try simp only
      split
      · rename_i hn
        refine ⟨h1, fun hacc => ⟨rfl, hn, hv, ?_⟩⟩
        have h' : ({ r1 with heardFromPrimary := true } : Replica Op Output St).isPrimary = false := by
          simpa using hacc
        exact h'
      · exact ⟨h1, fun h => by simp at h⟩
      · exact ⟨h1, fun h => by simp at h⟩
      · rename_i hvc
        refine ⟨?_, fun h => by simp at h⟩
        refine h1.drainCatchUp hlt v (hv ▸ Nat.le_refl _) (by simpa using hnr) hnp (Or.inr (by simpa using hvc)) hcv

end Transfer


/-! ### Appending at a backup -/

theorem List.getElem?_append_singleton {α : Type} {l : List α} {e x : α} {i : Nat}
    (h : (l ++ [e])[i]? = some x) : (i < l.length ∧ l[i]? = some x) ∨ (i = l.length ∧ x = e) := by
  by_cases hi : i < l.length
  · rw [List.getElem?_append_left hi] at h; exact Or.inl ⟨hi, h⟩
  · rw [List.getElem?_append_right (Nat.le_of_not_lt hi)] at h
    have hlen : i - l.length < 1 := by simpa using (List.getElem?_eq_some_iff.mp h).1
    have : i = l.length := by omega
    subst this
    simp at h
    exact Or.inr ⟨rfl, h.symm⟩

theorem List.getElem?_append_singleton_left {α : Type} {l : List α} {e : α} {i : Nat} (hi : i < l.length) :
    (l ++ [e])[i]? = l[i]? := List.getElem?_append_left hi

/-- Appending, at a backup, an entry the view holds at the end of the log. -/
theorem StepOK.append {s : System Op Output St} (hinv : Inv s) {id : ReplicaId} {r r' : Replica Op Output St}
    (hr : s.replicas[id]? = some r) {e : LogEntry Op}
    (hlog : r'.log = r.log ++ [e]) (hlnv : r'.lastNormalView = r.lastNormalView) (hstat : r'.status = r.status)
    (hview : r'.viewNumber = r.viewNumber) (hcatch : r'.catchingUp = r.catchingUp)
    (hcommit : r'.commitNumber = r.commitNumber)
    (hself : r'.selfId = r.selfId) (hconf : r'.config = r.config) (hnonce : r'.recoveryNonce = r.recoveryNonce)
    (hpanic : r'.panicked = false) (hout : r'.outbox = []) (hreplies : r'.replies = [])
    (hcv : r'.chosenDoViewChanges = none) (hloc : Replica.LocalInv r') (hnr : r.status ≠ .recovering)
    (hnvc : r.status ≠ .viewChange)
    (hnp : r.selfId ≠ s.config.primaryId r.lastNormalView)
    (he : Holds s r.lastNormalView r.log.length e)
    (hbound : ∀ p ∈ s.replicas, p.selfId ≠ r.selfId → p.status ≠ .recovering →
      p.selfId = s.config.primaryId p.lastNormalView → p.lastNormalView = r.lastNormalView →
      r.log.length + 1 ≤ p.log.length) :
    StepOK s id r r' [] [] := by
  have hmem : r ∈ s.replicas := List.mem_of_getElem? hr
  have hconf' : r'.config = s.config := hconf.trans (hinv.config_eq hmem)
  have hlen : r'.log.length = r.log.length + 1 := by rw [hlog]; simp
  have hnr' : r'.status ≠ .recovering := hstat ▸ hnr
  refine StepOK.replace hinv hr hself hconf hpanic hout hreplies hcv hloc (hview ▸ Nat.le_refl _)
    (hlnv ▸ Nat.le_refl _) ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_
    (fun hs => absurd (hstat ▸ hs) hnvc) (fun hs => absurd (hstat ▸ hs) hnr)
  · intro i e1 e2 he1 hh
    rw [hlnv] at hh; rw [hlog] at he1
    rcases List.getElem?_append_singleton he1 with ⟨_, he1⟩ | ⟨rfl, rfl⟩
    · exact hinv.oneLog.2 r hmem i e1 e2 he1 hh
    · exact hinv.oneLog.1 _ _ e1 e2 he hh
  · rw [hlnv, hcommit]; exact hinv.backed.1 r hmem
  · intro v' i e0 hc hlt _
    have h7 := (hinv.survives v' i e0 hc _ (hlnv ▸ hlt)).2.2.2.2.2 r hmem rfl hnr
    rw [hlog, List.getElem?_append_singleton_left (List.getElem?_eq_some_iff.mp h7).1]; exact h7
  · intro hn hp
    exfalso; apply hnp
    have hn' : r.status = .normal := hstat ▸ hn
    have hl : r.lastNormalView = r.viewNumber := (hinv.local_ r hmem).2.2.1 (Or.inl hn')
    unfold Replica.isPrimary Replica.primaryId at hp
    rw [hconf', hview, hself] at hp; rw [hl]; exact of_decide_eq_true hp
  · intro hc; rw [hself, hconf, hview]; exact hinv.catching r hmem (hcatch ▸ hc)
  · intro dst v o hs
    obtain ⟨ha, hb⟩ := hinv.acksHold dst v o r'.selfId hs r hmem hself.symm
    exact ⟨hlnv ▸ ha, fun hl _ => by rw [hlen]; exact Nat.le_succ_of_le (hb (hlnv ▸ hl) hnr)⟩
  · intro _ hp; rw [hlnv, hself] at hp; exact absurd hp hnp
  · intro p hp hne hpn hpp hl _; rw [hlen]; exact hbound p hp hne hpn hpp (hlnv ▸ hl).symm
  · intro hs; rw [hlnv, hview]; exact hinv.vcBehind r hmem (hstat ▸ hs)
  · intro v dvcs b hv hb hl _; rw [hlen]
    exact Nat.le_succ_of_le ((hinv.extendsBase v dvcs b hv hb).2.2.2 r hmem (hlnv ▸ hl) hnr)
  · intro hrec; exact absurd hrec hnr'
  · intro i hi
    rw [hlnv]; rw [hlen] at hi
    rcases Nat.lt_or_eq_of_le (Nat.le_of_lt_succ hi) with hlt | rfl
    · exact hinv.covered r hmem i hlt
    · exact ⟨e, he⟩
  · intro z hz _ hl i e1 e2 he1 he2
    rw [hlog] at he1
    rcases List.getElem?_append_singleton he1 with ⟨_, he1⟩ | ⟨rfl, rfl⟩
    · exact hinv.agree r hmem z hz (hlnv ▸ hl).symm i e1 e2 he1 he2
    · exact (hinv.oneLog.2 z hz _ e2 e1 he2 ((hlnv ▸ hl : z.lastNormalView = r.lastNormalView) ▸ he)).symm
  · intro _ hpos; rw [hlnv] at hpos ⊢; exact hinv.startedViews.2.2 r hmem hnr hpos
  · intro hs; rw [hself, hview]; exact hinv.transferNotPrimary r hmem (hstat ▸ hs)
  · intro hrec; exact absurd hrec hnr'

section Append
variable {s : System Op Output St} {id : ReplicaId} (hlt : id < s.replicas.length)
  {r1 : Replica Op Output St} (hinv : Inv (s.drainOf id r1))
include hlt hinv

theorem Inv.drainAppend (e : LogEntry Op) (hnr : r1.status ≠ .recovering) (hnvc : r1.status ≠ .viewChange)
    (hnp : r1.selfId ≠ s.config.primaryId r1.lastNormalView)
    (he : Holds (s.drainOf id r1) r1.lastNormalView r1.log.length e)
    (hbound : ∀ p ∈ (s.drainOf id r1).replicas, p.selfId ≠ r1.selfId → p.status ≠ .recovering →
      p.selfId = s.config.primaryId p.lastNormalView → p.lastNormalView = r1.lastNormalView →
      r1.log.length + 1 ≤ p.log.length) :
    Inv (s.drainOf id (r1.appendToLog e)) := by
  have hloc := hinv.drainOf_local hlt
  refine hinv.drainReplace hlt rfl rfl ?_
  exact StepOK.append hinv (s.drainOf_replicas_self r1 hlt) (by simp) (by simp) (by simp) (by simp) (by simp)
    (by simp) (by simp) (by simp) rfl (by simpa using hinv.drainOf_noPanic hlt) rfl rfl rfl
    (hloc.appendToLog e hnr).clear hnr hnvc hnp he hbound

end Append

/-! ### The handlers -/

section Handlers
variable {s : System Op Output St} (hinv : Inv s) {id : ReplicaId} {r : Replica Op Output St}
  (hr : s.replicas[id]? = some r)
include hinv hr

omit hinv in
theorem hlt_of_getElem : id < s.replicas.length := (List.getElem?_eq_some_iff.mp hr).1

/-- `onGetState`. -/
theorem Inv.onGetState (q : ReplicaId) (v : ViewNumber) (o : OpNumber) :
    Inv (s.drainOf id (r.onGetState q v o)) := by
  have hlt := hlt_of_getElem hr
  have h0 := hinv.drainOf_start hr
  unfold Replica.onGetState
  split
  · exact h0
  · rename_i hg
    have hn : r.status = .normal := by
      rcases Decidable.em (r.status = .normal) with h | h
      · exact h
      · exact absurd (Or.inl h) hg
    have hv : v = r.viewNumber := by
      rcases Decidable.em (v = r.viewNumber) with h | h
      · exact h
      · exact absurd (Or.inr (Or.inl h)) hg
    have ho : o ≤ r.opNumber := Nat.le_of_not_lt fun h => hg (Or.inr (Or.inr h))
    subst hv
    exact h0.drainSend hlt (MsgOK.newState h0 (s.drainOf_replicas_self r hlt) q hn ho)

/-- `onCommit`, on a `Commit` that was sent: it is backed and not for the
primary. -/
theorem Inv.onCommit (m : Machine Op Output St) (v : ViewNumber) (k : CommitNumber)
    (hnr : r.status ≠ .recovering) (hnp : id ≠ s.config.primaryId v) (hbacked : Backed s v k) :
    Inv (s.drainOf id (Replica.onCommit m r v k)) := by
  have hlt := hlt_of_getElem hr
  have h0 := hinv.drainOf_start hr
  have hself : r.selfId = id := (hinv.ids id r hr).1
  unfold Replica.onCommit
  try simp only
  have hnp' : r.selfId ≠ s.config.primaryId v := by rw [hself]; exact hnp
  obtain ⟨hacc, hfacts⟩ := h0.drainAccept hlt v hnr hnp' (hinv.clean r (List.mem_of_getElem? hr)).2
  generalize r.acceptFromPrimary v = p at hacc hfacts
  obtain ⟨r', accept⟩ := p
  simp only at hacc hfacts
  cases accept
  · simpa using hacc
  · simp only [Bool.not_true, Bool.false_eq_true, if_false]
    obtain ⟨rfl, hn, hv, hnotp⟩ := hfacts rfl
    have hlnv : r.lastNormalView = r.viewNumber := (hinv.local_ r (List.mem_of_getElem? hr)).2.2.1 (Or.inl hn)
    split
    · exact hacc.drainStateTransfer hlt hn (fun h => hnp' (by rw [hv]; exact h))
    · rename_i hle
      refine hacc.drainCommit hlt m k false (by simpa using hnr) (by simp; rw [hn]; decide) (Nat.le_of_not_lt hle) ?_
      show Backed _ r.lastNormalView k
      rw [hlnv, ← hv]
      exact hbacked.drainOf id _

/-- `onPrepare`, on a `Prepare` that was sent: it is backed, a fragment of
its view, and not for the primary. -/
theorem Inv.onPrepare (m : Machine Op Output St) {v : ViewNumber} {o : OpNumber} {c : ClientId}
    {n : RequestNumber} {op : Op} {k : CommitNumber} {dst : ReplicaId}
    (hnr : r.status ≠ .recovering) (hnp : id ≠ s.config.primaryId v)
    (hsent : Sent s dst (.prepare v o c n op k)) :
    Inv (s.drainOf id (Replica.onPrepare m r v o ⟨c, n, op⟩ k)) := by
  have hlt := hlt_of_getElem hr
  have h0 := hinv.drainOf_start hr
  have hself : r.selfId = id := (hinv.ids id r hr).1
  have hmem := List.mem_of_getElem? hr
  have hnp' : r.selfId ≠ s.config.primaryId v := by rw [hself]; exact hnp
  have hbacked : Backed s v k := hinv.backed.2 dst _ hsent
  have hfrag : Frag s v (o - 1) [⟨c, n, op⟩] := .prepare hsent
  unfold Replica.onPrepare
  try simp only
  obtain ⟨hacc, hfacts⟩ := h0.drainAccept hlt v hnr hnp' (hinv.clean r hmem).2
  generalize r.acceptFromPrimary v = p at hacc hfacts
  obtain ⟨r', accept⟩ := p
  simp only at hacc hfacts
  cases accept
  · simpa using hacc
  · simp only [Bool.not_true, Bool.false_eq_true, if_false]
    obtain ⟨rfl, hn, hv, hnotp⟩ := hfacts rfl
    have hlnv : r.lastNormalView = r.viewNumber := (hinv.local_ r hmem).2.2.1 (Or.inl hn)
    have hnp2 : r.selfId ≠ s.config.primaryId r.lastNormalView := by rw [hlnv, ← hv]; exact hnp'
    split
    · exact hacc.drainStateTransfer hlt hn (fun h => hnp' (by rw [hv]; exact h))
    · rename_i hle
      have hle' : o ≤ r.log.length + 1 := Nat.le_of_not_lt hle
      -- the replica after the possible append
      have hmid : ∀ r2 : Replica Op Output St,
          Inv (s.drainOf id r2) → r2.status = .normal → r2.lastNormalView = r.lastNormalView →
          r2.log.length ≤ r.log.length + 1 →
          Inv (s.drainOf id (Replica.commitUpTo m r2 (min k r2.opNumber) false).sendPrepareOk) := by
        intro r2 h2 hn2 hl2 _
        have h3 : Inv (s.drainOf id (Replica.commitUpTo m r2 (min k r2.opNumber) false)) := by
          refine h2.drainCommit hlt m _ false (by rw [hn2]; decide) (by rw [hn2]; decide) (Nat.min_le_right _ _) ?_
          rw [hl2, hlnv, ← hv]
          exact (hbacked.drainOf id r2).downward (Nat.min_le_left _ _)
        unfold Replica.sendPrepareOk Replica.sendToPrimary
        exact h3.drainSend hlt (MsgOK.prepareOk h3 (s.drainOf_replicas_self _ hlt) _ (by simpa using hn2))
      split
      · rename_i heq
        -- append: the entry is the view's at the end of the log
        have h2 : Inv (s.drainOf id (({ r with heardFromPrimary := true } : Replica Op Output St).appendToLog ⟨c, n, op⟩)) := by
          refine hacc.drainAppend hlt ⟨c, n, op⟩ (by simpa using hnr) (by simp; rw [hn]; decide) (by simpa using hnp2) ?_ ?_
          · have ho1 : o - 1 = r.log.length := by
              have : o = r.log.length + 1 := heq
              rw [this, Nat.add_sub_cancel]
            refine ⟨o - 1, [⟨c, n, op⟩], Frag.after_of (by show Frag s r.lastNormalView _ _; rw [hlnv, ← hv]; exact hfrag), ?_, ?_⟩
            · show o - 1 ≤ r.log.length
              rw [ho1]
            · show [(⟨c, n, op⟩ : LogEntry Op)][r.log.length - (o - 1)]? = some ⟨c, n, op⟩
              rw [ho1, Nat.sub_self]; rfl
          · intro p hp hne hpn hpp hl
            have h1 := (hacc.longest p hp hpn hpp).1 (o - 1) [⟨c, n, op⟩]
              (Frag.after_of (by rw [hl]; show Frag s r.lastNormalView _ _; rw [hlnv, ← hv]; exact hfrag))
            simp only [List.length_singleton] at h1
            have ho1 : o - 1 = r.log.length := by
              have : o = r.log.length + 1 := heq
              rw [this, Nat.add_sub_cancel]
            rw [ho1] at h1; exact h1
        exact hmid _ h2 (by simpa using hn) (by simp) (by simp)
      · exact hmid _ hacc (by simpa using hn) (by simp) (by simp)

/-- `onPrepareOk`, on a `PrepareOk` that was sent. -/
theorem Inv.onPrepareOk (m : Machine Op Output St) {v : ViewNumber} {o : OpNumber} {q : ReplicaId} {dst : ReplicaId}
    (hsent : Sent s dst (.prepareOk v o q)) :
    Inv (s.drainOf id (Replica.onPrepareOk m r v o q)) := by
  have hlt := hlt_of_getElem hr
  have h0 := hinv.drainOf_start hr
  have hmem := List.mem_of_getElem? hr
  have hconf := hinv.config_eq hmem
  have hqN : q < s.config.replicaCount := hinv.senderIds dst _ hsent
  unfold Replica.onPrepareOk
  split
  · exact h0
  · rename_i hg
    have hv : v = r.viewNumber := by
      rcases Decidable.em (v = r.viewNumber) with h | h
      · exact h
      · exact absurd (Or.inl h) hg
    have hp : r.isPrimary = true := by
      rcases Decidable.em (r.isPrimary = true) with h | h
      · exact h
      · exact absurd (Or.inr (Or.inl (by simpa using h))) hg
    have hn : r.status = .normal := by
      rcases Decidable.em (r.status = .normal) with h | h
      · exact h
      · exact absurd (Or.inr (Or.inr h)) hg
    have hnr : r.status ≠ .recovering := by rw [hn]; decide
    have hlnv : r.lastNormalView = r.viewNumber := (hinv.local_ r hmem).2.2.1 (Or.inl hn)
    have hprim : r.selfId = s.config.primaryId r.viewNumber := by
      unfold Replica.isPrimary Replica.primaryId at hp; rw [← hconf]; exact of_decide_eq_true hp
    subst hv
    split
    · exact h0
    · rename_i hko
      split
      · exact h0
      · rename_i ackedBy hlook
        try simp only
        have hmemacks : (o, ackedBy) ∈ r.acks := Assoc.lookup_some_mem hlook
        obtain ⟨hole, hsorted, hmembers⟩ := hinv.acks r hmem hn hp (o, ackedBy) hmemacks
        generalize hins : NatSet.insert ackedBy q = p
        obtain ⟨ackedBy', fresh⟩ := p
        simp only
        -- the acknowledgement set after the insert
        have hsorted' : ackedBy'.Pairwise (· < ·) := by
          have := NatSet.insert_sorted q hsorted; rw [hins] at this; exact this
        have hmembers' : ∀ x ∈ ackedBy', x < s.config.replicaCount ∧
            (x = r.selfId ∨ ∃ dst', Sent s dst' (.prepareOk r.viewNumber o x)) := by
          intro x hx
          have hx' : x ∈ (NatSet.insert ackedBy q).1 := by rw [hins]; exact hx
          rcases NatSet.mem_insert hx' with hx' | rfl
          · exact hmembers x hx'
          · exact ⟨hqN, Or.inr ⟨dst, hsent⟩⟩
        -- the replica with the acknowledgement recorded
        have h1 : Inv (s.drainOf id ({ r with acks := Assoc.update r.acks o fun _ => ackedBy' } : Replica Op Output St)) := by
          refine h0.drainKeepLog hlt rfl rfl rfl rfl rfl (hinv.noPanic r hmem) rfl rfl (Or.inr rfl) (Nat.le_refl _)
            ((hinv.local_ r hmem).withAcks _) hnr hnr (hinv.backed.1 r hmem |>.drainOf id r)
            (hinv.catching r hmem) ?_ (hinv.vcBehind r hmem) (hinv.transferNotPrimary r hmem)
            (fun hs => by rw [hn] at hs; exact absurd hs (by decide))
          intro _ _ oa hoa
          have hoa' : oa ∈ Assoc.update r.acks o fun _ => ackedBy' := hoa
          obtain ⟨v0, hv0, hif, hnif⟩ := Assoc.mem_update hoa'
          obtain ⟨c1, c2, c3⟩ := hinv.acks r hmem hn hp (oa.1, v0) hv0
          by_cases hoo : o = oa.1
          · rw [hif hoo]
            refine ⟨c1, hsorted', fun x hx => ⟨(hmembers' x hx).1, ?_⟩⟩
            rcases (hmembers' x hx).2 with h | ⟨dst', h⟩
            · exact Or.inl h
            · exact Or.inr ⟨dst', by rw [← hoo]; exact Sent.after_of h⟩
          · rw [hnif hoo]
            exact ⟨c1, c2, fun x hx => ⟨(c3 x hx).1, (c3 x hx).2.imp (fun h => h) (fun ⟨d, h⟩ => ⟨d, Sent.after_of h⟩)⟩⟩
        split
        · exact h1
        · rename_i hq
          have hfresh : fresh = true := by
            rcases fresh with _ | _
            · exact absurd (Or.inl rfl) hq
            · rfl
          have hquorum : ackedBy'.length = s.config.quorum := by
            rcases Decidable.em (ackedBy'.length = r.config.quorum) with h | h
            · rw [← hconf]; exact h
            · exact absurd (Or.inr h) hq
          -- the ops up to `o` are committed
          have hbacked : Backed s r.viewNumber o := by
            intro j hj
            have hjl : j < r.log.length := Nat.lt_of_lt_of_le hj hole
            obtain ⟨e0, he0⟩ := hinv.covered r hmem j hjl
            have hje : r.log[j]? = some r.log[j] := List.getElem?_eq_getElem hjl
            have heq := hinv.oneLog.2 r hmem j _ e0 hje he0
            rw [← hlnv]
            refine ⟨e0, r.lastNormalView, Nat.le_refl _, ⟨he0, ?_⟩, he0⟩
            refine ⟨ackedBy', hsorted'.imp (fun h => Nat.ne_of_lt h), ?_, fun x hx => ⟨(hmembers' x hx).1, ?_⟩⟩
            · rw [hquorum]
            · rcases (hmembers' x hx).2 with h | ⟨dst', h⟩
              · left; rw [h, hlnv]; exact hprim
              · right; exact ⟨dst', o, hlnv ▸ h, hj⟩
          have h2 : Inv (s.drainOf id (Replica.commitUpTo m
              ({ r with acks := Assoc.update r.acks o fun _ => ackedBy' } : Replica Op Output St) o true)) :=
            h1.drainCommit hlt m o true hnr (by rw [hn]; decide) hole (by show Backed _ r.lastNormalView o; rw [hlnv]; exact hbacked.drainOf id _)
          refine h2.drainKeepLog hlt (by simp) (by simp) (by simp) (by simp) (by simp)
            (by simpa using h2.drainOf_noPanic hlt) (by simp) (by simp) (Or.inr (by simp)) (by simp)
            ?_ (by simpa using hnr) (by simpa using hnr) (h2.drainOf_backed hlt)
            (h2.drainOf_catching hlt) ?_ (h2.drainOf_vcBehind hlt) (h2.drainOf_transfer hlt)
            (fun hs => by simp at hs; rw [hn] at hs; exact absurd hs (by decide))
          · exact ((h2.drainOf_local hlt).withAcks _)
          · intro hn' hp' oa hoa
            have hoa' : oa ∈ (Replica.commitUpTo m ({ r with acks := Assoc.update r.acks o fun _ => ackedBy' } :
                Replica Op Output St) o true).acks := List.mem_of_mem_filter hoa
            exact h2.drainOf_acks hlt hn' hp' oa hoa'

omit hinv hr in
/-- Appending several entries the view holds past the end of the log. -/
theorem Inv.drainAppendMany {s : System Op Output St} {id : ReplicaId} (hlt : id < s.replicas.length)
    (L : List (LogEntry Op)) : ∀ (r1 : Replica Op Output St), Inv (s.drainOf id r1) →
      r1.status ≠ .recovering → r1.status ≠ .viewChange → r1.selfId ≠ s.config.primaryId r1.lastNormalView →
      (∀ j e, L[j]? = some e → Holds (s.drainOf id r1) r1.lastNormalView (r1.log.length + j) e) →
      (∀ p ∈ (s.drainOf id r1).replicas, p.selfId ≠ r1.selfId → p.status ≠ .recovering →
        p.selfId = s.config.primaryId p.lastNormalView → p.lastNormalView = r1.lastNormalView →
        r1.log.length + L.length ≤ p.log.length) →
      Inv (s.drainOf id (L.foldl Replica.appendToLog r1)) := by
  induction L with
  | nil => intro r1 h _ _ _ _ _; exact h
  | cons e L ih =>
    intro r1 h hnr hnvc hnp hholds hbound
    rw [List.foldl_cons]
    have h1 : Inv (s.drainOf id (r1.appendToLog e)) := by
      refine h.drainAppend hlt e hnr hnvc hnp (by simpa using hholds 0 e rfl) ?_
      intro p hp hne hpn hpp hl
      have := hbound p hp hne hpn hpp hl
      simp only [List.length_cons] at this; omega
    refine ih (r1.appendToLog e) h1 (by simpa using hnr) (by simpa using hnvc) (by simpa using hnp) ?_ ?_
    · intro j e' hj
      have := hholds (j + 1) e' (by simpa using hj)
      simp only [Replica.appendToLog_log, List.length_append, List.length_singleton, Replica.appendToLog_lastNormalView]
      rw [Nat.add_assoc, Nat.add_comm 1 j]
      exact Holds.mono (s := s.drainOf id r1) (s' := s.drainOf id (r1.appendToLog e)) (fun x hx => hx)
        (fun x hx => hx) this
    · intro p hp hne hpn hpp hl
      simp only [Replica.appendToLog_log, List.length_append, List.length_singleton,
        Replica.appendToLog_lastNormalView, Replica.appendToLog_selfId] at hne hl ⊢
      -- `p` is an old replica, also in the view before the append
      have hp' : p ∈ (s.drainOf id r1).replicas := by
        simp only [System.drainOf, System.after_replicas] at hp ⊢
        obtain ⟨j, hj⟩ := List.mem_iff_getElem?.mp hp
        have hji : j ≠ id := by
          intro hji; subst hji
          rw [List.getElem?_set_self hlt] at hj
          exact hne (by rw [← Option.some.inj hj]; rfl)
        rw [List.getElem?_set_ne (Ne.symm hji)] at hj
        exact List.mem_of_getElem? (by rw [List.getElem?_set_ne (Ne.symm hji)]; exact hj)
      have := hbound p hp' hne hpn hpp hl
      simp only [List.length_cons] at this; omega

/-- `onNewState`, on a `NewState` that was sent. -/
theorem Inv.onNewState (m : Machine Op Output St) {v : ViewNumber} {log : List (LogEntry Op)}
    {a b : OpNumber} {k : CommitNumber} {dst : ReplicaId} (hnr : r.status ≠ .recovering)
    (hsent : Sent s dst (.newState v log a b k)) :
    Inv (s.drainOf id (Replica.onNewState m r v log a b k)) := by
  have hlt := hlt_of_getElem hr
  have h0 := hinv.drainOf_start hr
  have hmem := List.mem_of_getElem? hr
  have hconf := hinv.config_eq hmem
  have hwf := hinv.wf _ hsent
  obtain ⟨hwf1, hwf2, hwf3⟩ := hwf
  have hbacked : Backed s v k := hinv.backed.2 dst _ hsent
  have hfrag : Frag s v a log := .newState hsent
  have hloc := hinv.local_ r hmem
  unfold Replica.onNewState
  split
  · exact h0
  · rename_i hvv
    have hv : v = r.viewNumber := by
      rcases Decidable.em (v = r.viewNumber) with h | h
      · exact h
      · exact absurd h hvv
    split
    · rename_i hlen; exact absurd hwf1 hlen
    · try simp only
      have h1 := h0.drainHeard hlt true hnr
      split
      · -- state transfer: append the missing suffix
        rename_i hst
        have hst' : r.status = .stateTransfer := hst
        have hlnv : r.lastNormalView = r.viewNumber := hloc.2.2.1 (Or.inr hst')
        have hnp : r.selfId ≠ s.config.primaryId r.viewNumber := hinv.transferNotPrimary r hmem hst'
        split
        · exact h1
        · rename_i hrange
          have ha : a ≤ r.log.length := Nat.le_of_not_lt fun h => hrange (Or.inl h)
          have hb : r.log.length < b := Nat.lt_of_not_le fun h => hrange (Or.inr h)
          try simp only
          have hop : ({ r with heardFromPrimary := true } : Replica Op Output St).opNumber = r.log.length := rfl
          simp only [hop]
          have hdroplen : (log.drop (r.log.length - a)).length = b - r.log.length := by
            rw [List.length_drop, hwf1]; exact Nat.sub_sub_sub_cancel_right ha
          have h2 : Inv (s.drainOf id ((log.drop (r.log.length - a)).foldl Replica.appendToLog
              ({ r with heardFromPrimary := true } : Replica Op Output St))) := by
            refine Inv.drainAppendMany hlt _ _ h1 (by simpa using hnr) (by simp; rw [hst']; decide)
              (by simpa using (hlnv ▸ hnp : r.selfId ≠ s.config.primaryId r.lastNormalView)) ?_ ?_
            · intro j e hj
              rw [List.getElem?_drop] at hj
              refine Holds.after_of ⟨a, log, (by show Frag s r.lastNormalView a log; rw [hlnv, ← hv]; exact hfrag),
                Nat.le_add_right_of_le ha, ?_⟩
              show log[r.log.length + j - a]? = some e
              rw [Nat.sub_add_comm ha]; exact hj
            · intro p hp hne hpn hpp hl
              have := (h1.longest p hp hpn hpp).1 a log (Frag.after_of (by rw [hl]; show Frag s r.lastNormalView _ _; rw [hlnv, ← hv]; exact hfrag))
              rw [hwf1, Nat.add_sub_cancel' hwf2] at this
              rw [hdroplen]
              show r.log.length + (b - r.log.length) ≤ p.log.length
              rw [Nat.add_sub_cancel' (Nat.le_of_lt hb)]; exact this
          split
          · rename_i hne
            exfalso; apply hne
            show (_ : Replica Op Output St).log.length = b
            rw [Replica.foldl_appendToLog_log, List.length_append, hdroplen]
            simp only; omega
          · have hlog3 : ((log.drop (r.log.length - a)).foldl Replica.appendToLog
                ({ r with heardFromPrimary := true } : Replica Op Output St)).log.length = b := by
              rw [Replica.foldl_appendToLog_log, List.length_append, hdroplen]; simp only; omega
            have h3 : Inv (s.drainOf id (Replica.commitUpTo m ((log.drop (r.log.length - a)).foldl Replica.appendToLog
                ({ r with heardFromPrimary := true } : Replica Op Output St)) k false)) := by
              refine h2.drainCommit hlt m k false (by rw [Replica.foldl_appendToLog_status]; simpa using hnr)
                (by rw [Replica.foldl_appendToLog_status]; simp; rw [hst']; decide) (by rw [hlog3]; exact hwf3) ?_
              rw [Replica.foldl_appendToLog_lastNormalView]
              show Backed _ r.lastNormalView k
              rw [hlnv, ← hv]; exact hbacked.drainOf id _
            have h4 : Inv (s.drainOf id ({ Replica.commitUpTo m ((log.drop (r.log.length - a)).foldl Replica.appendToLog
                ({ r with heardFromPrimary := true } : Replica Op Output St)) k false with status := .normal } :
                Replica Op Output St)) := by
              refine h3.drainKeepLog hlt rfl rfl rfl rfl rfl (h3.drainOf_noPanic hlt) rfl rfl (Or.inr rfl) (Nat.le_refl _)
                ?_ (by rw [Replica.commitUpTo_status, Replica.foldl_appendToLog_status]; simpa using hnr)
                (by simp) (h3.drainOf_backed hlt) (h3.drainOf_catching hlt)
                ?_ (fun h => by simp at h) (fun h => by simp at h) (fun h => by simp at h)
              · obtain ⟨l1, l2, l3, l4, l5⟩ := h3.drainOf_local hlt
                have hcf : r.catchingUp = false := by
                  rcases h : r.catchingUp
                  · rfl
                  · exact absurd (hst'.symm.trans (hloc.2.2.2.1 h)) (by decide)
                refine ⟨l1, l2, ?_, ?_, ?_⟩
                · intro _; simp only [Replica.commitUpTo_lastNormalView, Replica.commitUpTo_viewNumber,
                    Replica.foldl_appendToLog_lastNormalView, Replica.foldl_appendToLog_viewNumber]; exact hlnv
                · intro hc; simp only [Replica.commitUpTo_catchingUp, Replica.foldl_appendToLog_catchingUp] at hc
                  rw [show ({ r with heardFromPrimary := true } : Replica Op Output St).catchingUp = r.catchingUp from rfl,
                    hcf] at hc
                  exact absurd hc (by decide)
                · intro h; simp at h
              · intro _ hp
                exfalso; apply hnp
                unfold Replica.isPrimary Replica.primaryId at hp
                simp only [Replica.commitUpTo_selfId, Replica.commitUpTo_config, Replica.commitUpTo_viewNumber,
                  Replica.foldl_appendToLog_viewNumber, Replica.foldl_appendToLog_selfId,
                  Replica.foldl_appendToLog_config] at hp
                rw [← hconf]
                exact of_decide_eq_true hp
            unfold Replica.sendPrepareOk Replica.sendToPrimary
            exact h4.drainSend hlt (MsgOK.prepareOk h4 (s.drainOf_replicas_self _ hlt) _ rfl)
      · -- view change: catching up
        rename_i hst
        have hvc : r.status = .viewChange := hst
        have hvcb : r.lastNormalView < r.viewNumber := hinv.vcBehind r hmem hvc
        split
        · exact h1
        · rename_i hcatch
          have hcatch' : r.catchingUp = true := by simpa using hcatch
          have hnp : r.selfId ≠ s.config.primaryId r.viewNumber := by
            have := hinv.catching r hmem hcatch'; rw [hconf] at this; exact this
          split
          · exact h1
          · rename_i hak
            have hak' : a = r.commitNumber := by simpa using (of_not_not hak)
            try simp only
            -- the view was started, so it has a StartView holding every earlier commit
            have hvpos : 0 < v := by rw [hv]; exact Nat.lt_of_le_of_lt (Nat.zero_le _) hvcb
            obtain ⟨dvcs, hstd⟩ := hinv.startedViews.2.1 v a log hfrag hvpos
            obtain ⟨dst0, L0, o0, k0, hsv0⟩ := hinv.startedViews.1 v dvcs hstd
            have hsvholds : ∀ i e, Committed s (r.lastNormalView) i e → L0[i]? = some e := by
              intro i e hc
              exact (hinv.survives _ i e hc v (hv ▸ hvcb)).1 dst0 L0 o0 k0 hsv0
            -- the committed prefix is what the view holds there
            have hprefix : ∀ i, i < r.commitNumber → ∃ e, r.log[i]? = some e ∧ Holds s v i e ∧
                ∀ v' e', Committed s v' i e' → e' = e := by
              intro i hi
              obtain ⟨e, v', hget, _, hc, _⟩ := hinv.committed_entry hmem hi
              refine ⟨e, hget, ?_, fun v'' e' hc' => hinv.committed_unique hc' hc⟩
              have hsv := (hinv.survives v' i e hc v (Nat.lt_of_le_of_lt (by assumption) (hv ▸ hvcb))).1 dst0 L0 o0 k0 hsv0
              exact ⟨0, L0, .startView hsv0, Nat.zero_le _, by simpa using hsv⟩
            -- the new log
            set L := r.log.take a ++ log with hL
            have hLlen : L.length = b := by
              rw [hL, List.length_append, List.length_take, hwf1, hak']
              rw [Nat.min_eq_left hloc.1]; exact Nat.add_sub_cancel' (hak' ▸ hwf2)
            have hkL : r.commitNumber ≤ L.length := by rw [hLlen, ← hak']; exact hwf2
            have hinst : ({ r with heardFromPrimary := true } : Replica Op Output St).installLog L =
                { ({ r with heardFromPrimary := true } : Replica Op Output St) with
                    clientTable := Replica.rebuildClientTable r.commitNumber r.clientTable 0 L [], log := L } := by
              unfold Replica.installLog
              rw [if_neg (Nat.not_lt.mpr hkL)]
            rw [hinst]
            split
            · rename_i hne; exfalso; apply hne; show L.length = b; exact hLlen
            · have hLget : ∀ i e, L[i]? = some e → (i < r.commitNumber ∧ r.log[i]? = some e) ∨
                  (r.commitNumber ≤ i ∧ log[i - r.commitNumber]? = some e) := by
                intro i e hi
                rw [hL] at hi
                by_cases hia : i < (r.log.take a).length
                · rw [List.getElem?_append_left hia] at hi
                  rw [List.length_take, hak', Nat.min_eq_left hloc.1] at hia
                  rw [List.getElem?_take_of_lt (hak' ▸ hia)] at hi
                  exact Or.inl ⟨hia, hi⟩
                · rw [List.getElem?_append_right (Nat.le_of_not_lt hia)] at hi
                  rw [List.length_take, hak', Nat.min_eq_left hloc.1] at hia hi
                  exact Or.inr ⟨Nat.le_of_not_lt hia, hi⟩
              have hLholds : ∀ i e, L[i]? = some e → Holds s v i e := by
                intro i e hi
                rcases hLget i e hi with ⟨hlt', hget⟩ | ⟨hge, hget⟩
                · obtain ⟨e', hget', hh, _⟩ := hprefix i hlt'
                  rw [hget] at hget'; obtain rfl := Option.some.inj hget'; exact hh
                · exact ⟨a, log, hfrag, hak' ▸ hge, hak' ▸ hget⟩
              have hLsurv : ∀ v' i e, Committed s v' i e → v' < v → L[i]? = some e := by
                intro v' i e hc hlt'
                by_cases hi : i < r.commitNumber
                · obtain ⟨e', hget', _, huniq⟩ := hprefix i hi
                  rw [hL, List.getElem?_append_left (by rw [List.length_take, hak', Nat.min_eq_left hloc.1]; exact hi),
                    List.getElem?_take_of_lt (hak' ▸ hi), hget', huniq v' e hc]
                · have hge := Nat.le_of_not_lt hi
                  rw [hL, List.getElem?_append_right (by rw [List.length_take, hak', Nat.min_eq_left hloc.1]; exact hge),
                    List.length_take, hak', Nat.min_eq_left hloc.1]
                  have := (hinv.survives v' i e hc v hlt').2.2.2.1 dst log a b k hsent (hak' ▸ hge)
                  rw [hak'] at this; exact this
              -- the commit afterwards
              have hbk : Backed s v r.commitNumber := by
                intro i hi
                obtain ⟨e, v', hget, hle, hc, _⟩ := hinv.committed_entry hmem hi
                obtain ⟨e', hget', hh, _⟩ := hprefix i hi
                rw [hget] at hget'; obtain rfl := Option.some.inj hget'
                exact ⟨e, v', Nat.le_trans hle (Nat.le_of_lt (hv ▸ hvcb)), hc, hh⟩
              set r3 : Replica Op Output St := { ({ r with heardFromPrimary := true } : Replica Op Output St) with
                  clientTable := Replica.rebuildClientTable r.commitNumber r.clientTable 0 L [], log := L } with hr3
              have hr3log : r3.log = L := rfl
              have hr3k : r3.commitNumber = r.commitNumber := rfl
              have hloc3 : Replica.LocalInv r3 := by
                refine ⟨hkL, hloc.2.1, fun h => ?_, fun _ => hvc, fun h => ?_⟩
                · have h' : r.status = .normal ∨ r.status = .stateTransfer := h
                  rw [hvc] at h'; rcases h' with h' | h' <;> exact absurd h' (by decide)
                · have h' : r.status = .recovering := h
                  rw [hvc] at h'; exact absurd h' (by decide)
              have hdrain : s.drainOf id ({ r with heardFromPrimary := true } : Replica Op Output St) =
                  s.after id ({ r with heardFromPrimary := true } : Replica Op Output St).clear [] [] := by
                simp only [System.drainOf, Replica.startedList, hinv.drained r hmem, (hinv.clean r hmem).2]
              have h5 : Inv (s.drainOf id (Replica.commitUpTo m r3 k false).enterNormal) := by
                refine h1.drainReplace hlt (by simp [hr3]) (by simp [Replica.startedList, hr3]) ?_
                refine StepOK.install h1 (s.drainOf_replicas_self _ hlt) (v := r.viewNumber) (L := L) (by simp)
                  (by simp [hr3]) (by simp [hr3]) (by simp [hr3]) (by simp) (by simp [hr3]) (by simp [hr3])
                  (by simp [hr3]) ?_ rfl rfl rfl ?_ (by simp) hloc.2.1
                  ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_
                · -- no panic
                  simp only [Replica.clear_panicked, Replica.enterNormal_panicked]
                  rw [commitUpTo_panicked m r3 k false (hr3k ▸ hkL) (hr3log ▸ hLlen ▸ hwf3)]
                  exact hinv.noPanic r hmem
                · exact (hloc3.commitUpTo m k false).enterNormal.clear
                · intro i e hi
                  exact Holds.after_of (hv ▸ hLholds i e hi)
                · simp only [Replica.clear_commitNumber, Replica.enterNormal_commitNumber]
                  exact Backed.after_of ((Backed.max (hv ▸ hbk) (hv ▸ hbacked)).downward (commitUpTo_le_max m r3 k false))
                · intro v' i e hc hlt'
                  rw [hdrain] at hc
                  exact hLsurv v' i e (Committed.after_nil.mp hc) (hv ▸ hlt')
                · exact hnp
                · intro dst' o hs
                  have := (h1.acksHold dst' r.viewNumber o r.selfId (by simpa using hs) _ (drainOf_mem id _ hlt) rfl).1
                  exact absurd (Nat.lt_of_lt_of_le hvcb this) (Nat.lt_irrefl _)
                · intro p hp hne hpn hpp hl
                  have := (h1.longest p hp hpn hpp).1 a log (Frag.after_of (by rw [hl, ← hv]; exact hfrag))
                  rw [hLlen]; omega
                · intro dvcs' b' hst' hb'
                  rw [hLlen]
                  exact (h1.extendsBase _ dvcs' b' hst' hb').2.2.1 dst log a b k (Sent.after_of (hv ▸ hsent))
                · intro _; exact ⟨dvcs, started_after_of (hv ▸ hstd)⟩
              unfold Replica.sendPrepareOk Replica.sendToPrimary
              exact h5.drainSend hlt (MsgOK.prepareOk h5 (s.drainOf_replicas_self _ hlt) _ rfl)
      · exact h1

end Handlers

end Vsr
