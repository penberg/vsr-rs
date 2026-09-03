import Vsr.Frame

/-!
Step one of the safety proof: the facts about a single replica that every
handler preserves on its own, with no assumption about the messages it is
handed. They are the base the system-level invariant builds on.
-/

namespace Vsr.Replica

variable {Op Output St : Type} (m : Machine Op Output St)

/-- What holds of every replica, whatever it has been sent:
the commit number is within the log; the last normal view is not ahead of
the view; in normal status and state transfer it is the view; a replica
catching up is in view-change status; a recovering replica holds nothing. -/
def LocalInv (r : Replica Op Output St) : Prop :=
  r.commitNumber ≤ r.log.length ∧
  r.lastNormalView ≤ r.viewNumber ∧
  (r.status = .normal ∨ r.status = .stateTransfer → r.lastNormalView = r.viewNumber) ∧
  (r.catchingUp = true → r.status = .viewChange) ∧
  (r.status = .recovering → r.log = [] ∧ r.commitNumber = 0)

theorem LocalInv.new (id : ReplicaId) (config : Config) (sm : St) :
    LocalInv (new id config sm : Replica Op Output St) := by
  simp [LocalInv]

theorem LocalInv.recover (id : ReplicaId) (config : Config) (sm : St) (v : ViewNumber) (nonce : Nat) :
    LocalInv (recover id config sm v nonce : Replica Op Output St) := by
  simp [LocalInv]

/-- `acceptFromPrimary` says yes only to a normal backup. -/
theorem acceptFromPrimary_true (r : Replica Op Output St) (v : ViewNumber)
    (h : (r.acceptFromPrimary v).2 = true) : (r.acceptFromPrimary v).1.status = .normal := by
  unfold Replica.acceptFromPrimary at h ⊢
  by_cases h1 : v < r.viewNumber
  · simp [h1] at h
  · by_cases h2 : v > r.viewNumber
    · simp [h1, h2] at h
    · simp only [h1, h2, if_false] at h ⊢
      cases hs : r.status
      · rfl
      · simp [hs] at h
      · simp [hs] at h
      · simp [hs] at h

/-- Status after `startViewChange` and the helpers it calls: still in the
view change, or normal if this replica was the new primary and had a
quorum of votes already. Never recovering. -/
theorem foldl_sendStartView_status (r : Replica Op Output St) (l : List ReplicaId) :
    (l.foldl (fun r to => r.sendStartView to) r).status = r.status :=
  foldl_proj Replica.status (fun r to => r.sendStartView to) (fun _ _ => rfl) l r

theorem recordDoViewChange_status (r : Replica Op Output St) (id : ReplicaId) (vote : Vote Op) :
    (Replica.recordDoViewChange m r id vote).status = r.status ∨
    (Replica.recordDoViewChange m r id vote).status = .normal := by
  unfold Replica.recordDoViewChange
  try simp only
  split
  · left; rfl
  · split
    · left; rfl
    · right; rw [foldl_sendStartView_status]; simp

theorem sendDoViewChange_status (r : Replica Op Output St) :
    (Replica.sendDoViewChange m r).status = r.status ∨ (Replica.sendDoViewChange m r).status = .normal := by
  unfold Replica.sendDoViewChange
  try simp only
  split
  · exact recordDoViewChange_status m _ _ _
  · left; rfl

theorem maybeSendDoViewChange_status (r : Replica Op Output St) :
    (Replica.maybeSendDoViewChange m r).status = r.status ∨
    (Replica.maybeSendDoViewChange m r).status = .normal := by
  unfold Replica.maybeSendDoViewChange
  split
  · left; rfl
  · try simp only
    split
    · left; rfl
    · exact sendDoViewChange_status m _

theorem startViewChange_status (r : Replica Op Output St) (v : ViewNumber) :
    (Replica.startViewChange m r v).status = .viewChange ∨
    (Replica.startViewChange m r v).status = .normal := by
  unfold Replica.startViewChange
  try simp only
  refine Or.imp ?_ id (maybeSendDoViewChange_status m _)
  intro h; rw [h]; simp

theorem startViewChange_ne_recovering (r : Replica Op Output St) (v : ViewNumber) :
    (Replica.startViewChange m r v).status ≠ .recovering := by
  rcases startViewChange_status m r v with h | h <;> rw [h] <;> decide

/-! ### Helpers that only send or bookkeep -/

section Frame
variable {r : Replica Op Output St} (h : LocalInv r)
include h

theorem LocalInv.send (to : ReplicaId) (msg : Message Op) : LocalInv (r.send to msg) := by
  simpa [LocalInv] using h
theorem LocalInv.sendToPrimary (msg : Message Op) : LocalInv (r.sendToPrimary msg) := by
  simpa [LocalInv] using h
theorem LocalInv.sendToOthers (msg : Message Op) : LocalInv (r.sendToOthers msg) := by
  simpa [LocalInv] using h
theorem LocalInv.sendGetState (n : OpNumber) : LocalInv (r.sendGetState n) := by
  simpa [LocalInv] using h
theorem LocalInv.sendPrepareOk : LocalInv r.sendPrepareOk := by simpa [LocalInv] using h
theorem LocalInv.sendStartView (to : ReplicaId) : LocalInv (r.sendStartView to) := by
  simpa [LocalInv] using h
theorem LocalInv.sendRecovery : LocalInv r.sendRecovery := by simpa [LocalInv] using h
theorem LocalInv.panic : LocalInv r.panic := by simpa [LocalInv] using h
theorem LocalInv.clearViewChangeState : LocalInv r.clearViewChangeState := by
  simpa [LocalInv] using h
theorem LocalInv.addAcksForUncommitted : LocalInv r.addAcksForUncommitted := by
  simpa [LocalInv] using h
theorem LocalInv.waitTimedOut : LocalInv r.waitTimedOut.1 := by simpa [LocalInv] using h
theorem LocalInv.resendPrepares (v : ViewNumber) (c : CommitNumber) :
    LocalInv (r.resendPrepares v c) := by
  simpa [LocalInv] using h

theorem LocalInv.withHeard (b : Bool) :
    LocalInv ({ r with heardFromPrimary := b } : Replica Op Output St) := by
  simpa [LocalInv] using h
theorem LocalInv.withHeardIdle (b : Bool) (n : Nat) :
    LocalInv ({ r with heardFromPrimary := b, idlePeriodsWaiting := n } : Replica Op Output St) := by
  simpa [LocalInv] using h
theorem LocalInv.withAcks (a : List (OpNumber × List ReplicaId)) :
    LocalInv ({ r with acks := a } : Replica Op Output St) := by
  simpa [LocalInv] using h
theorem LocalInv.withReplies (x : List (Reply Output)) :
    LocalInv ({ r with replies := x } : Replica Op Output St) := by
  simpa [LocalInv] using h
theorem LocalInv.withVotes (x : List (ReplicaId × Vote Op)) :
    LocalInv ({ r with doViewChangeVotes := x } : Replica Op Output St) := by
  simpa [LocalInv] using h
theorem LocalInv.withDoViewChangeSent (b : Bool) :
    LocalInv ({ r with doViewChangeSent := b } : Replica Op Output St) := by
  simpa [LocalInv] using h
theorem LocalInv.withStartViewChangeFrom (x : List ReplicaId) :
    LocalInv ({ r with startViewChangeFrom := x } : Replica Op Output St) := by
  simpa [LocalInv] using h
theorem LocalInv.withRecoveryResponses (x : List (ReplicaId × RecoveryResponse Op)) :
    LocalInv ({ r with recoveryResponses := x } : Replica Op Output St) := by
  simpa [LocalInv] using h

theorem LocalInv.commitUpTo (n : CommitNumber) (reply : Bool) :
    LocalInv (Replica.commitUpTo m r n reply) := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := h
  refine ⟨commitUpTo_commit_le m r reply n h1, ?_, ?_, ?_, ?_⟩
  · simpa using h2
  · simpa using h3
  · simpa using h4
  · simp only [commitUpTo_status, commitUpTo_log]
    intro hrec
    have hlog := (h5 hrec).1
    have hle := commitUpTo_commit_le m r reply n h1
    rw [commitUpTo_log, hlog] at hle
    exact ⟨hlog, Nat.le_zero.mp hle⟩

theorem LocalInv.enterNormal : LocalInv r.enterNormal := by
  obtain ⟨h1, _, _, _, _⟩ := h
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · simpa using h1
  · simp
  · simp
  · simp
  · simp

theorem LocalInv.stateTransfer (hn : r.status = .normal ∨ r.status = .stateTransfer) :
    LocalInv r.stateTransfer := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := h
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · simpa using h1
  · simpa using h2
  · simp only [stateTransfer_lastNormalView, stateTransfer_viewNumber]
    intro _; exact h3 hn
  · simp only [stateTransfer_catchingUp, stateTransfer_status]
    intro hc; have := h4 hc
    rcases hn with hn | hn <;> rw [hn] at this <;> exact Status.noConfusion this
  · simp

theorem LocalInv.appendToLog (entry : LogEntry Op) (hn : r.status ≠ .recovering) :
    LocalInv (r.appendToLog entry) := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := h
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · simp only [appendToLog_commitNumber, appendToLog_log, List.length_append, List.length_singleton]
    exact Nat.le_succ_of_le h1
  · simpa using h2
  · simpa using h3
  · simpa using h4
  · simp only [appendToLog_status]; intro hr; exact absurd hr hn

theorem LocalInv.installLog (log : List (LogEntry Op)) (hn : r.status ≠ .recovering) :
    LocalInv (r.installLog log) := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := h
  refine ⟨installLog_commit_le r log h1, ?_, ?_, ?_, ?_⟩
  · simpa using h2
  · simpa using h3
  · simpa using h4
  · simp only [installLog_status]; intro hr; exact absurd hr hn

theorem LocalInv.catchUpWithView (v : ViewNumber) (hv : r.viewNumber ≤ v) :
    LocalInv (r.catchUpWithView v) := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := h
  by_cases hc : (r.viewNumber = v ∧ r.catchingUp = true)
  · have heq : r.catchUpWithView v = r := by unfold Replica.catchUpWithView; rw [if_pos hc]
    rw [heq]; exact ⟨h1, h2, h3, h4, h5⟩
  · refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;>
      simp only [catchUpWithView_status, catchUpWithView_viewNumber, catchUpWithView_catchingUp,
        catchUpWithView_lastNormalView, catchUpWithView_commitNumber, catchUpWithView_log, if_neg hc]
    · exact h1
    · exact Nat.le_trans h2 hv
    · intro hs; rcases hs with hs | hs <;> exact Status.noConfusion hs
    · simp
    · intro hs; exact Status.noConfusion hs

theorem LocalInv.acceptFromPrimary (v : ViewNumber) : LocalInv (r.acceptFromPrimary v).1 := by
  unfold Replica.acceptFromPrimary
  split
  · exact h
  · rename_i hlt
    split
    · exact h.catchUpWithView v (Nat.le_of_not_lt hlt)
    · try simp only
      split
      · exact h.withHeard true
      · exact h.withHeard true
      · exact h.withHeard true
      · exact (h.withHeard true).catchUpWithView v (Nat.le_of_not_lt hlt)

end Frame

/-! ### View changes -/

section ViewChange
variable {r : Replica Op Output St} (h : LocalInv r)
include h

theorem LocalInv.recordDoViewChange (replicaId : ReplicaId) (vote : Vote Op)
    (hn : r.status ≠ .recovering) : LocalInv (Replica.recordDoViewChange m r replicaId vote) := by
  unfold Replica.recordDoViewChange
  try simp only
  have h' := h.withVotes (Assoc.insert r.doViewChangeVotes replicaId vote)
  split
  · exact h'
  · split
    · exact h'.panic
    · apply sendToOthers_fold
      exact ((h'.installLog _ hn).commitUpTo m _ _).enterNormal.withAcks [] |>.addAcksForUncommitted
where
  /-- A fold of `sendStartView` keeps the invariant. -/
  sendToOthers_fold {r : Replica Op Output St} (l : List ReplicaId) (h : LocalInv r) :
      LocalInv (l.foldl (fun r to => r.sendStartView to) r) := by
    induction l generalizing r with
    | nil => exact h
    | cons to l ih => exact ih (h.sendStartView to)

theorem LocalInv.sendDoViewChange (hn : r.status ≠ .recovering) :
    LocalInv (Replica.sendDoViewChange m r) := by
  unfold Replica.sendDoViewChange
  try simp only
  split
  · exact h.recordDoViewChange m _ _ hn
  · exact h.send _ _

theorem LocalInv.maybeSendDoViewChange (hn : r.status ≠ .recovering) :
    LocalInv (Replica.maybeSendDoViewChange m r) := by
  unfold Replica.maybeSendDoViewChange
  split
  · exact h
  · try simp only
    split
    · exact h
    · exact (h.withDoViewChangeSent true).sendDoViewChange m hn

theorem LocalInv.startViewChange (v : ViewNumber) (hv : r.viewNumber ≤ v) :
    LocalInv (Replica.startViewChange m r v) := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := h
  unfold Replica.startViewChange
  try simp only
  refine LocalInv.maybeSendDoViewChange m ?_ (by simp)
  refine LocalInv.sendToOthers ?_ _
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · simpa using h1
  · simp only [clearViewChangeState_lastNormalView]; exact Nat.le_trans h2 hv
  · simp
  · simp
  · simp

theorem LocalInv.noteStartViewChange (replicaId : ReplicaId) (hn : r.status ≠ .recovering) :
    LocalInv (Replica.noteStartViewChange m r replicaId) :=
  (h.withStartViewChangeFrom _).maybeSendDoViewChange m hn

end ViewChange

/-! ### The handlers -/

section Handlers
variable {r : Replica Op Output St} (h : LocalInv r)
include h

theorem LocalInv.prepareRequest (clientId : ClientId) (requestNumber : RequestNumber) (op : Op)
    (hn : r.status ≠ .recovering) : LocalInv (r.prepareRequest clientId requestNumber op) := by
  unfold Replica.prepareRequest
  try simp only
  exact ((h.appendToLog _ hn).withAcks _).sendToOthers _

theorem LocalInv.onRequest (clientId : ClientId) (requestNumber : RequestNumber) (op : Op)
    (hn : r.status ≠ .recovering) : LocalInv (r.onRequest clientId requestNumber op) := by
  unfold Replica.onRequest
  split
  · exact h
  · split
    · exact h.prepareRequest _ _ _ hn
    · split
      · exact h
      · split
        · split
          · exact h.withReplies _
          · exact h
        · exact h.prepareRequest _ _ _ hn

theorem LocalInv.onPrepare (v : ViewNumber) (o : OpNumber) (entry : LogEntry Op) (c : CommitNumber) :
    LocalInv (Replica.onPrepare m r v o entry c) := by
  unfold Replica.onPrepare
  try simp only
  have hacc := h.acceptFromPrimary v
  have hst := acceptFromPrimary_true r v
  generalize r.acceptFromPrimary v = p at hacc hst
  obtain ⟨r', accept⟩ := p
  simp only at hacc hst
  cases accept
  · simpa using hacc
  · simp only [Bool.not_true, Bool.false_eq_true, if_false]
    have hn : r'.status = .normal := hst rfl
    have hnr : r'.status ≠ .recovering := by rw [hn]; decide
    split
    · exact hacc.stateTransfer (Or.inl hn)
    · refine LocalInv.sendPrepareOk (LocalInv.commitUpTo m ?_ _ _)
      split
      · exact hacc.appendToLog _ hnr
      · exact hacc

theorem LocalInv.onPrepareOk (v : ViewNumber) (o : OpNumber) (replicaId : ReplicaId) :
    LocalInv (Replica.onPrepareOk m r v o replicaId) := by
  unfold Replica.onPrepareOk
  split
  · exact h
  · split
    · exact h
    · split
      · exact h
      · try simp only
        split
        · exact h.withAcks _
        · exact ((h.withAcks _).commitUpTo m _ _).withAcks _

theorem LocalInv.onCommit (v : ViewNumber) (c : CommitNumber) : LocalInv (Replica.onCommit m r v c) := by
  unfold Replica.onCommit
  try simp only
  have hacc := h.acceptFromPrimary v
  have hst := acceptFromPrimary_true r v
  generalize r.acceptFromPrimary v = p at hacc hst
  obtain ⟨r', accept⟩ := p
  simp only at hacc hst
  cases accept
  · simpa using hacc
  · simp only [Bool.not_true, Bool.false_eq_true, if_false]
    split
    · exact hacc.stateTransfer (Or.inl (hst rfl))
    · exact hacc.commitUpTo m _ _

theorem LocalInv.onGetState (replicaId : ReplicaId) (v : ViewNumber) (o : OpNumber) :
    LocalInv (r.onGetState replicaId v o) := by
  unfold Replica.onGetState
  split
  · exact h
  · exact h.send _ _

theorem LocalInv.onNewState (v : ViewNumber) (log : List (LogEntry Op)) (a b : OpNumber)
    (c : CommitNumber) (hn : r.status ≠ .recovering) : LocalInv (Replica.onNewState m r v log a b c) := by
  unfold Replica.onNewState
  split
  · exact h
  · split
    · exact h.panic
    · try simp only
      have h' := h.withHeard true
      split
      · rename_i hst
        split
        · exact h'
        · try simp only
          have h'' : LocalInv ((log.drop (r.opNumber - a)).foldl Replica.appendToLog
              { r with heardFromPrimary := true }) := by
            apply foldl_appendToLog_inv _ h'
            simpa using hn
          split
          · exact h''.panic
          · refine LocalInv.sendPrepareOk ?_
            have h3 := h''.commitUpTo m c false
            obtain ⟨h1, h2, h3, h4, h5⟩ := h3
            refine ⟨h1, h2, ?_, ?_, ?_⟩
            · intro _
              simp only [commitUpTo_lastNormalView, commitUpTo_viewNumber, commitUpTo_status,
                foldl_appendToLog_lastNormalView, foldl_appendToLog_viewNumber,
                foldl_appendToLog_status] at h3 ⊢
              try simp only at h3
              exact h3 (Or.inr hst)
            · simp only [commitUpTo_catchingUp, foldl_appendToLog_catchingUp] at h4 ⊢
              intro hc; have := h4 hc
              simp only [commitUpTo_status, foldl_appendToLog_status] at this
              try simp only at this
              rw [hst] at this; exact Status.noConfusion this
            · intro hs; exact Status.noConfusion hs
      · split
        · exact h'
        · split
          · exact h'
          · try simp only
            split
            · exact (h'.installLog _ (by simpa using hn)).panic
            · exact ((h'.installLog _ (by simpa using hn)).commitUpTo m _ _).enterNormal.sendPrepareOk
      · exact h'
where
  foldl_appendToLog_inv {r : Replica Op Output St} (l : List (LogEntry Op)) (h : LocalInv r)
      (hn : r.status ≠ .recovering) : LocalInv (l.foldl Replica.appendToLog r) := by
    induction l generalizing r with
    | nil => exact h
    | cons e l ih => exact ih (h.appendToLog e hn) (by simpa using hn)

/- The shape of every path that ends in `enterNormal`: whatever the
intermediate state, installing a log and committing keeps the commit
number within the log, and `enterNormal` settles the rest. -/
omit h in
theorem LocalInv.install_then_normal (r : Replica Op Output St) (h1 : r.commitNumber ≤ r.log.length)
    (log : List (LogEntry Op)) (c : CommitNumber) (reply : Bool) :
    LocalInv (Replica.commitUpTo m (r.installLog log) c reply).enterNormal := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · simpa using commitUpTo_commit_le m _ reply c (installLog_commit_le _ log h1)
  · simp
  · simp
  · simp
  · simp

theorem LocalInv.onStartViewChange (v : ViewNumber) (replicaId : ReplicaId)
    (hn : r.status ≠ .recovering) : LocalInv (Replica.onStartViewChange m r v replicaId) := by
  unfold Replica.onStartViewChange
  split
  · exact h
  · rename_i hlt
    split
    · exact (h.startViewChange m v (Nat.le_of_not_lt hlt)).noteStartViewChange m _
        (startViewChange_ne_recovering m r v)
    · split
      · split
        · exact h.sendStartView _
        · exact h
      · exact h.noteStartViewChange m _ hn

theorem LocalInv.onDoViewChange (v : ViewNumber) (replicaId : ReplicaId) (vote : Vote Op)
    (hn : r.status ≠ .recovering) : LocalInv (Replica.onDoViewChange m r v replicaId vote) := by
  unfold Replica.onDoViewChange
  split
  · exact h
  · rename_i hge
    split
    · exact (h.startViewChange m v (Nat.le_of_not_lt (fun hlt => hge (Or.inl hlt)))).recordDoViewChange
        m _ _ (startViewChange_ne_recovering m r v)
    · split
      · exact h.sendStartView _
      · exact h.recordDoViewChange m _ _ hn

theorem LocalInv.onStartView (v : ViewNumber) (log : List (LogEntry Op)) (c : CommitNumber) :
    LocalInv (Replica.onStartView m r v log c) := by
  unfold Replica.onStartView
  split
  · exact h
  · try simp only
    refine LocalInv.sendPrepareOk (LocalInv.withAcks ?_ [])
    refine LocalInv.install_then_normal m _ ?_ log c false
    exact h.1

theorem LocalInv.onRecovery (replicaId : ReplicaId) (nonce : Nat) (v : ViewNumber) :
    LocalInv (Replica.onRecovery m r replicaId nonce v) := by
  unfold Replica.onRecovery
  split
  · rename_i hc; exact h.startViewChange m v (Nat.le_of_lt hc.1)
  · split
    · exact h
    · exact h.send _ _

theorem LocalInv.onRecoveryResponse (v : ViewNumber) (nonce : Nat) (replicaId : ReplicaId)
    (state : Option (RecoveryState Op)) :
    LocalInv (Replica.onRecoveryResponse m r v nonce replicaId state) := by
  unfold Replica.onRecoveryResponse
  split
  · exact h
  · try simp only
    have h' := h.withRecoveryResponses (Assoc.insert r.recoveryResponses replicaId ⟨v, state⟩)
    split
    · exact h'
    · split
      · exact h'
      · split
        · split
          · exact h'
          · try simp only
            refine LocalInv.install_then_normal m _ ?_ _ _ _
            exact h.1
        · exact h'

theorem LocalInv.onIdle : LocalInv (Replica.onIdle m r) := by
  unfold Replica.onIdle
  split
  · split
    · exact (h.sendToOthers _).resendPrepares _ _
    · rename_i hs _; exact backupIdle h (Or.inl hs)
  · exact h.sendRecovery
  · rename_i hs; exact backupIdle (h.stateTransfer (Or.inr hs)) (by simp)
  · rename_i hs
    try simp only
    have hw := h.waitTimedOut
    have hws : r.waitTimedOut.1.status = r.status := waitTimedOut_status r
    generalize r.waitTimedOut = p at hw hws ⊢
    obtain ⟨r', t⟩ := p
    simp only at hw hws ⊢
    cases t
    · simp only [Bool.false_eq_true, if_false]
      split
      · exact hw.sendGetState _
      · try simp only
        split
        · exact (hw.sendToOthers _).sendDoViewChange m (by simp [hws, hs])
        · exact hw.sendToOthers _
    · exact hw.startViewChange m _ (Nat.le_succ _)
where
  backupIdle {r : Replica Op Output St} (h : LocalInv r)
      (hs : r.status = .normal ∨ r.status = .stateTransfer) :
      LocalInv (Replica.onIdle.backupIdle m r) := by
    unfold Replica.onIdle.backupIdle
    split
    · exact h.withHeardIdle false 0
    · try simp only
      have hw := h.waitTimedOut
      generalize r.waitTimedOut = p at hw ⊢
      obtain ⟨r', t⟩ := p
      simp only at hw ⊢
      cases t
      · exact hw
      · exact hw.startViewChange m _ (Nat.le_succ _)

theorem LocalInv.onMessage (msg : Message Op) : LocalInv (Replica.onMessage m r msg) := by
  unfold Replica.onMessage
  split
  · exact h
  · rename_i hc
    have hn : isRecoveryResponse msg = false → r.status ≠ .recovering := fun hm hs => hc ⟨hs, hm⟩
    split
    · exact LocalInv.onRequest h _ _ _ (hn rfl)
    · exact LocalInv.onPrepare m h _ _ _ _
    · exact LocalInv.onPrepareOk m h _ _ _
    · exact LocalInv.onCommit m h _ _
    · exact LocalInv.onGetState h _ _ _
    · exact LocalInv.onNewState m h _ _ _ _ _ (hn rfl)
    · exact LocalInv.onStartViewChange m h _ _ (hn rfl)
    · split
      · exact LocalInv.panic h
      · exact LocalInv.onDoViewChange m h _ _ _ (hn rfl)
    · split
      · exact LocalInv.panic h
      · exact LocalInv.onStartView m h _ _ _
    · exact LocalInv.onRecovery m h _ _ _
    · exact LocalInv.onRecoveryResponse m h _ _ _ _

end Handlers

end Vsr.Replica
