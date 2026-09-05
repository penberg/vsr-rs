import Vsr.Local

/-!
Step two of the safety proof: every message ever sent is well formed. The
lengths and numbers a message carries agree with one another, which is
what the Rust asserts on receipt. Every sender satisfies the local
invariant, so every handler only ever sends well-formed messages.
-/

namespace Vsr

/-- Well-formed messages: the shape facts a receiver relies on. -/
def WF {Op : Type} : Message Op → Prop
  | .prepare _ o _ _ _ _ => 0 < o
  | .newState _ log a b k => log.length = b - a ∧ a ≤ b ∧ k ≤ b
  | .doViewChange v _ l log o k => log.length = o ∧ k ≤ o ∧ l ≤ v
  | .startView _ log o k => log.length = o ∧ k ≤ o
  | .recoveryResponse _ _ _ (some st) => st.commitNumber ≤ st.log.length
  | _ => True

namespace Replica

variable {Op Output St : Type} (m : Machine Op Output St)

/-- Everything in the outbox is well formed. -/
def OutboxWF (r : Replica Op Output St) : Prop := ∀ x ∈ r.outbox, WF x.2

theorem OutboxWF.new (id : ReplicaId) (config : Config) (sm : St) :
    OutboxWF (new id config sm : Replica Op Output St) := by
  intro x hx
  have : (Replica.new id config sm : Replica Op Output St).outbox = [] := rfl
  rw [this] at hx; simp at hx



section Helpers
variable {r : Replica Op Output St} (ho : OutboxWF r)
include ho

theorem OutboxWF.send (to : ReplicaId) {msg : Message Op} (hm : WF msg) :
    OutboxWF (r.send to msg) := by
  intro x hx
  simp only [send_outbox, List.mem_append, List.mem_singleton] at hx
  rcases hx with hx | rfl
  · exact ho x hx
  · exact hm

theorem OutboxWF.sendToPrimary {msg : Message Op} (hm : WF msg) : OutboxWF (r.sendToPrimary msg) :=
  ho.send _ hm

theorem OutboxWF.sendToOthers {msg : Message Op} (hm : WF msg) : OutboxWF (r.sendToOthers msg) := by
  intro x hx
  rcases mem_sendToOthers_outbox r hx with hx | hx
  · exact ho x hx
  · rw [hx]; exact hm

theorem OutboxWF.sendGetState (n : OpNumber) : OutboxWF (r.sendGetState n) := ho.sendToPrimary trivial
theorem OutboxWF.sendPrepareOk : OutboxWF r.sendPrepareOk := ho.sendToPrimary trivial
theorem OutboxWF.sendRecovery : OutboxWF r.sendRecovery := ho.sendToOthers trivial

theorem OutboxWF.sendStartView (hl : LocalInv r) (to : ReplicaId) : OutboxWF (r.sendStartView to) :=
  ho.send to ⟨rfl, hl.1⟩

theorem OutboxWF.panic : OutboxWF r.panic := by simpa [OutboxWF] using ho
theorem OutboxWF.appendToLog (entry : LogEntry Op) : OutboxWF (r.appendToLog entry) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.installLog (log : List (LogEntry Op)) : OutboxWF (r.installLog log) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.commitUpTo (n : CommitNumber) (reply : Bool) :
    OutboxWF (Replica.commitUpTo m r n reply) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.clearViewChangeState : OutboxWF r.clearViewChangeState := by
  simpa [OutboxWF] using ho
theorem OutboxWF.enterNormal : OutboxWF r.enterNormal := by simpa [OutboxWF] using ho
theorem OutboxWF.addAcksForUncommitted : OutboxWF r.addAcksForUncommitted := by
  simpa [OutboxWF] using ho
theorem OutboxWF.waitTimedOut : OutboxWF r.waitTimedOut.1 := by simpa [OutboxWF] using ho
theorem OutboxWF.stateTransfer : OutboxWF r.stateTransfer := by
  unfold Replica.stateTransfer
  exact OutboxWF.sendGetState (by simpa [OutboxWF] using ho) _
theorem OutboxWF.catchUpWithView (v : ViewNumber) : OutboxWF (r.catchUpWithView v) := by
  unfold Replica.catchUpWithView
  split
  · exact ho
  · exact OutboxWF.sendGetState (by simpa [OutboxWF] using ho) _

theorem OutboxWF.withHeard (b : Bool) :
    OutboxWF ({ r with heardFromPrimary := b } : Replica Op Output St) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.noteStable : OutboxWF r.noteStable := by simpa [OutboxWF] using ho
theorem OutboxWF.withStable (n : Nat) :
    OutboxWF ({ r with idlePeriodsStable := n } : Replica Op Output St) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.withHeardIdle (b : Bool) (n : Nat) :
    OutboxWF ({ r with heardFromPrimary := b, idlePeriodsWaiting := n } : Replica Op Output St) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.withAcks (a : List (OpNumber × List ReplicaId)) :
    OutboxWF ({ r with acks := a } : Replica Op Output St) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.withReplies (x : List (Reply Output)) :
    OutboxWF ({ r with replies := x } : Replica Op Output St) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.withDoViewChangeFrom (x : List (ReplicaId × DoViewChange Op)) :
    OutboxWF ({ r with doViewChangeFrom := x } : Replica Op Output St) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.withChosen (x : Option (List (ReplicaId × DoViewChange Op))) :
    OutboxWF ({ r with chosenDoViewChanges := x } : Replica Op Output St) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.withDoViewChangeSent (b : Bool) :
    OutboxWF ({ r with doViewChangeSent := b } : Replica Op Output St) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.withStartViewChangeFrom (x : List ReplicaId) :
    OutboxWF ({ r with startViewChangeFrom := x } : Replica Op Output St) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.withRecoveryResponses (x : List (ReplicaId × RecoveryResponse Op)) :
    OutboxWF ({ r with recoveryResponses := x } : Replica Op Output St) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.withViewNumber (v : ViewNumber) :
    OutboxWF ({ r with viewNumber := v } : Replica Op Output St) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.withRecoveryResponsesView (x : List (ReplicaId × RecoveryResponse Op)) (v : ViewNumber) :
    OutboxWF ({ r with recoveryResponses := x, viewNumber := v } : Replica Op Output St) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.withStatus (st : Status) :
    OutboxWF ({ r with status := st } : Replica Op Output St) := by
  simpa [OutboxWF] using ho
theorem OutboxWF.foldl_appendToLog (l : List (LogEntry Op)) :
    OutboxWF (l.foldl Replica.appendToLog r) := by
  induction l generalizing r with
  | nil => exact ho
  | cons e l ih => exact ih (ho.appendToLog e)

theorem OutboxWF.resendPrepares (v : ViewNumber) (c : CommitNumber) :
    OutboxWF (r.resendPrepares v c) := by
  unfold Replica.resendPrepares
  generalize List.range (r.opNumber - c) = l
  induction l generalizing r with
  | nil => exact ho
  | cons i l ih =>
    rw [List.foldl_cons]
    apply ih
    dsimp only
    split
    · exact ho.panic
    · exact ho.sendToOthers (by
        show 0 < c + 1 + i
        exact Nat.lt_of_lt_of_le (Nat.succ_pos c) (Nat.le_add_right _ _))

theorem OutboxWF.acceptFromPrimary (v : ViewNumber) : OutboxWF (r.acceptFromPrimary v).1 := by
  unfold Replica.acceptFromPrimary
  split
  · exact ho
  · split
    · exact ho.catchUpWithView v
    · try simp only
      split
      · exact ho.withHeard true
      · exact ho.withHeard true
      · exact ho.withHeard true
      · exact (ho.withHeard true).catchUpWithView v

end Helpers

/-! ### View changes -/

section ViewChange
variable {r : Replica Op Output St} (hl : LocalInv r) (ho : OutboxWF r)
include hl ho

theorem OutboxWF.foldl_sendStartView (l : List ReplicaId) :
    OutboxWF (l.foldl (fun r to => r.sendStartView to) r) := by
  induction l generalizing r with
  | nil => exact ho
  | cons to l ih => exact ih (hl.sendStartView to) (ho.sendStartView hl to)

theorem OutboxWF.recordDoViewChange (replicaId : ReplicaId) (dvc : DoViewChange Op)
    (hn : r.status ≠ .recovering) : OutboxWF (Replica.recordDoViewChange m r replicaId dvc) := by
  unfold Replica.recordDoViewChange
  try simp only
  have hl' := hl.withDoViewChangeFrom (Assoc.insert r.doViewChangeFrom replicaId dvc)
  have ho' := ho.withDoViewChangeFrom (Assoc.insert r.doViewChangeFrom replicaId dvc)
  split
  · exact ho'
  · split
    · exact ho'.panic
    · apply OutboxWF.foldl_sendStartView
      · exact (((hl'.withChosen _).installLog _ hn).commitUpTo m _ _).enterNormal.withAcks []
          |>.addAcksForUncommitted
      · exact (((ho'.withChosen _).installLog _).commitUpTo m _ _).enterNormal.withAcks []
          |>.addAcksForUncommitted

theorem OutboxWF.sendDoViewChange (hn : r.status ≠ .recovering) :
    OutboxWF (Replica.sendDoViewChange m r) := by
  unfold Replica.sendDoViewChange
  try simp only
  split
  · exact OutboxWF.recordDoViewChange m hl ho _ _ hn
  · exact ho.send _ ⟨rfl, hl.1, hl.2.1⟩

theorem OutboxWF.maybeSendDoViewChange (hn : r.status ≠ .recovering) :
    OutboxWF (Replica.maybeSendDoViewChange m r) := by
  unfold Replica.maybeSendDoViewChange
  split
  · exact ho
  · try simp only
    split
    · exact ho
    · exact OutboxWF.sendDoViewChange m (hl.withDoViewChangeSent true) (ho.withDoViewChangeSent true) hn

theorem OutboxWF.startViewChange (v : ViewNumber) (hv : r.viewNumber ≤ v) :
    OutboxWF (Replica.startViewChange m r v) := by
  unfold Replica.startViewChange
  try simp only
  refine OutboxWF.maybeSendDoViewChange m ?_ ?_ (by simp)
  · refine LocalInv.sendToOthers ?_ _
    obtain ⟨h1, h2, _, _, _⟩ := hl
    refine ⟨?_, ?_, ?_, ?_, ?_⟩
    · simpa using h1
    · simp only [clearViewChangeState_lastNormalView]; exact Nat.le_trans h2 hv
    · simp
    · simp
    · simp
  · exact OutboxWF.sendToOthers (by simpa [OutboxWF] using ho) trivial

theorem OutboxWF.noteStartViewChange (replicaId : ReplicaId) (hn : r.status ≠ .recovering) :
    OutboxWF (Replica.noteStartViewChange m r replicaId) :=
  OutboxWF.maybeSendDoViewChange m (hl.withStartViewChangeFrom _) (ho.withStartViewChangeFrom _) hn

end ViewChange

/-! ### The handlers -/

section Handlers
variable {r : Replica Op Output St} (hl : LocalInv r) (ho : OutboxWF r)
include hl ho

omit hl in
theorem OutboxWF.prepareRequest (clientId : ClientId) (requestNumber : RequestNumber) (op : Op) :
    OutboxWF (r.prepareRequest clientId requestNumber op) := by
  unfold Replica.prepareRequest
  try simp only
  exact ((ho.appendToLog _).withAcks _).sendToOthers (by simp [WF, Replica.opNumber])

omit hl in
theorem OutboxWF.onRequest (clientId : ClientId) (requestNumber : RequestNumber) (op : Op) :
    OutboxWF (r.onRequest clientId requestNumber op) := by
  unfold Replica.onRequest
  split
  · exact ho
  · split
    · exact ho.prepareRequest _ _ _
    · split
      · exact ho
      · split
        · split
          · exact ho.withReplies _
          · exact ho
        · exact ho.prepareRequest _ _ _

omit hl in
theorem OutboxWF.onPrepare (v : ViewNumber) (o : OpNumber) (entry : LogEntry Op) (c : CommitNumber) :
    OutboxWF (Replica.onPrepare m r v o entry c) := by
  unfold Replica.onPrepare
  try simp only
  have hacc := ho.acceptFromPrimary v
  generalize r.acceptFromPrimary v = p at hacc
  obtain ⟨r', accept⟩ := p
  simp only at hacc
  cases accept
  · simpa using hacc
  · simp only [Bool.not_true, Bool.false_eq_true, if_false]
    split
    · exact hacc.stateTransfer
    · refine OutboxWF.sendPrepareOk (OutboxWF.commitUpTo m ?_ _ _)
      split
      · exact hacc.appendToLog _
      · exact hacc

omit hl in
theorem OutboxWF.onPrepareOk (v : ViewNumber) (o : OpNumber) (replicaId : ReplicaId) :
    OutboxWF (Replica.onPrepareOk m r v o replicaId) := by
  unfold Replica.onPrepareOk
  split
  · exact ho
  · split
    · exact ho
    · split
      · exact ho
      · try simp only
        split
        · exact ho.withAcks _
        · exact ((ho.withAcks _).commitUpTo m _ _).withAcks _

omit hl in
theorem OutboxWF.onCommit (v : ViewNumber) (c : CommitNumber) : OutboxWF (Replica.onCommit m r v c) := by
  unfold Replica.onCommit
  try simp only
  have hacc := ho.acceptFromPrimary v
  generalize r.acceptFromPrimary v = p at hacc
  obtain ⟨r', accept⟩ := p
  simp only at hacc
  cases accept
  · simpa using hacc
  · simp only [Bool.not_true, Bool.false_eq_true, if_false]
    split
    · exact hacc.stateTransfer
    · exact hacc.commitUpTo m _ _

theorem OutboxWF.onGetState (replicaId : ReplicaId) (v : ViewNumber) (o : OpNumber) :
    OutboxWF (r.onGetState replicaId v o) := by
  unfold Replica.onGetState
  split
  · exact ho
  · rename_i hg
    refine ho.send _ ⟨List.length_drop, ?_, hl.1⟩
    exact Nat.le_of_not_lt (fun h => hg (Or.inr (Or.inr h)))

omit hl in
theorem OutboxWF.onNewState (v : ViewNumber) (log : List (LogEntry Op)) (a b : OpNumber)
    (c : CommitNumber) : OutboxWF (Replica.onNewState m r v log a b c) := by
  unfold Replica.onNewState
  split
  · exact ho
  · split
    · exact ho.panic
    · try simp only
      have ho' := ho.withHeard true
      split
      · split
        · exact ho'
        · try simp only
          have ho'' := ho'.foldl_appendToLog (log.drop (r.opNumber - a))
          split
          · exact ho''.panic
          · exact ((ho''.commitUpTo m _ _).withStatus .normal).sendPrepareOk
      · split
        · exact ho'
        · split
          · exact ho'
          · try simp only
            split
            · exact (ho'.installLog _).panic
            · exact ((ho'.installLog _).commitUpTo m _ _).enterNormal.sendPrepareOk
      · exact ho'

theorem OutboxWF.onStartViewChange (v : ViewNumber) (replicaId : ReplicaId)
    (hn : r.status ≠ .recovering) : OutboxWF (Replica.onStartViewChange m r v replicaId) := by
  unfold Replica.onStartViewChange
  split
  · exact ho
  · rename_i hlt
    split
    · exact OutboxWF.noteStartViewChange m (hl.startViewChange m v (Nat.le_of_not_lt hlt))
        (OutboxWF.startViewChange m hl ho v (Nat.le_of_not_lt hlt)) _ (startViewChange_ne_recovering m r v)
    · split
      · split
        · exact ho.sendStartView hl _
        · exact ho
      · exact OutboxWF.noteStartViewChange m hl ho _ hn

theorem OutboxWF.onDoViewChange (v : ViewNumber) (replicaId : ReplicaId) (dvc : DoViewChange Op)
    (hn : r.status ≠ .recovering) : OutboxWF (Replica.onDoViewChange m r v replicaId dvc) := by
  unfold Replica.onDoViewChange
  split
  · exact ho
  · rename_i hge
    have hv : r.viewNumber ≤ v := Nat.le_of_not_lt (fun hlt => hge (Or.inl hlt))
    split
    · exact OutboxWF.recordDoViewChange m (hl.startViewChange m v hv)
        (OutboxWF.startViewChange m hl ho v hv) _ _ (startViewChange_ne_recovering m r v)
    · split
      · exact ho.sendStartView hl _
      · exact OutboxWF.recordDoViewChange m hl ho _ _ hn

omit hl in
theorem OutboxWF.onStartView (v : ViewNumber) (log : List (LogEntry Op)) (c : CommitNumber) :
    OutboxWF (Replica.onStartView m r v log c) := by
  unfold Replica.onStartView
  split
  · exact ho
  · try simp only
    exact ((((ho.withViewNumber v).installLog _).commitUpTo m _ _).enterNormal.withAcks []).sendPrepareOk

theorem OutboxWF.onRecovery (replicaId : ReplicaId) (nonce : Nat) (v : ViewNumber) :
    OutboxWF (Replica.onRecovery m r replicaId nonce v) := by
  unfold Replica.onRecovery
  split
  · rename_i hc; exact OutboxWF.startViewChange m hl ho v (Nat.le_of_lt hc.1)
  · split
    · exact ho
    · try simp only
      refine ho.send _ ?_
      by_cases hp : r.isPrimary = true <;> simp [hp, WF, hl.1]

omit hl in
theorem OutboxWF.onRecoveryResponse (v : ViewNumber) (nonce : Nat) (replicaId : ReplicaId)
    (state : Option (RecoveryState Op)) :
    OutboxWF (Replica.onRecoveryResponse m r v nonce replicaId state) := by
  unfold Replica.onRecoveryResponse
  split
  · exact ho
  · try simp only
    have ho' := ho.withRecoveryResponses (Assoc.insert r.recoveryResponses replicaId ⟨v, state⟩)
    split
    · exact ho'
    · split
      · exact ho'
      · split
        · split
          · exact ho'
          · try simp only
            exact (((ho.withRecoveryResponsesView _ _).installLog _).commitUpTo m _ _).enterNormal
        · exact ho'

theorem OutboxWF.onIdle : OutboxWF (Replica.onIdle m r) := by
  unfold Replica.onIdle
  split
  · split
    · refine OutboxWF.resendPrepares ?_ _ _
      exact ho.noteStable.sendToOthers trivial
    · exact backupIdle hl ho
  · exact ho.sendRecovery
  · exact backupIdle (hl.stateTransfer (Or.inr (by assumption))) ho.stateTransfer
  · rename_i hs
    try simp only
    have hw := ho.waitTimedOut
    have hlw := hl.waitTimedOut
    have hws : r.waitTimedOut.1.status = r.status := waitTimedOut_status r
    generalize r.waitTimedOut = p at hw hlw hws ⊢
    obtain ⟨r', t⟩ := p
    simp only at hw hlw hws ⊢
    cases t
    · simp only [Bool.false_eq_true, if_false]
      split
      · exact hw.sendGetState _
      · try simp only
        split
        · exact OutboxWF.sendDoViewChange m (hlw.sendToOthers _) (hw.sendToOthers trivial) (by simp [hws, hs])
        · exact hw.sendToOthers trivial
    · exact OutboxWF.startViewChange m hlw hw _ (Nat.le_succ _)
where
  backupIdle {r : Replica Op Output St} (hl : LocalInv r) (ho : OutboxWF r) :
      OutboxWF (Replica.onIdle.backupIdle m r) := by
    unfold Replica.onIdle.backupIdle
    split
    · exact (ho.withHeardIdle false 0).noteStable
    · try simp only
      have hw := (ho.withStable 0).waitTimedOut
      have hlw := (hl.withStable 0).waitTimedOut
      generalize ({ r with idlePeriodsStable := 0 } : Replica Op Output St).waitTimedOut = p at hw hlw ⊢
      obtain ⟨r', t⟩ := p
      simp only at hw hlw ⊢
      cases t
      · exact hw
      · exact OutboxWF.startViewChange m hlw hw _ (Nat.le_succ _)

theorem OutboxWF.onMessage (msg : Message Op) : OutboxWF (Replica.onMessage m r msg) := by
  unfold Replica.onMessage
  split
  · exact ho
  · rename_i hc
    have hn : isRecoveryResponse msg = false → r.status ≠ .recovering := fun hm hs => hc ⟨hs, hm⟩
    split
    · exact OutboxWF.onRequest ho _ _ _
    · exact OutboxWF.onPrepare m ho _ _ _ _
    · exact OutboxWF.onPrepareOk m ho _ _ _
    · exact OutboxWF.onCommit m ho _ _
    · exact OutboxWF.onGetState hl ho _ _ _
    · exact OutboxWF.onNewState m ho _ _ _ _ _
    · exact OutboxWF.onStartViewChange m hl ho _ _ (hn rfl)
    · split
      · exact ho.panic
      · exact OutboxWF.onDoViewChange m hl ho _ _ _ (hn rfl)
    · split
      · exact ho.panic
      · exact OutboxWF.onStartView m ho _ _ _
    · exact OutboxWF.onRecovery m hl ho _ _ _
    · exact OutboxWF.onRecoveryResponse m ho _ _ _ _

end Handlers

theorem OutboxWF.recover (id : ReplicaId) (config : Config) (sm : St) (v : ViewNumber) (nonce : Nat) :
    OutboxWF (Replica.recover id config sm v nonce : Replica Op Output St) := by
  unfold Replica.recover
  apply OutboxWF.sendRecovery
  intro x hx
  simp [Replica.new] at hx

end Replica

end Vsr
