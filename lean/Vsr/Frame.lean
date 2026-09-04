import Vsr.Replica

/-!
Frame lemmas: what each helper of `Replica` leaves alone, and what it
does to the few fields the invariants talk about. With these as `simp`
lemmas a goal about a handler stays a goal about fields, instead of
unfolding into a literal of every field of the replica.
-/

namespace Vsr

/-- A fold whose step preserves a projection preserves it overall. -/
theorem foldl_proj {α β γ : Type} (p : α → γ) (f : α → β → α)
    (h : ∀ a b, p (f a b) = p a) : ∀ (l : List β) (a : α), p (l.foldl f a) = p a
  | [], _ => rfl
  | b :: l, a => by rw [List.foldl_cons, foldl_proj p f h l, h]

namespace Replica

variable {Op Output St : Type} (m : Machine Op Output St) (r : Replica Op Output St)

/-! ### `panic` -/

@[simp] theorem panic_status : r.panic.status = r.status := rfl
@[simp] theorem panic_viewNumber : r.panic.viewNumber = r.viewNumber := rfl
@[simp] theorem panic_lastNormalView : r.panic.lastNormalView = r.lastNormalView := rfl
@[simp] theorem panic_commitNumber : r.panic.commitNumber = r.commitNumber := rfl
@[simp] theorem panic_log : r.panic.log = r.log := rfl
@[simp] theorem panic_catchingUp : r.panic.catchingUp = r.catchingUp := rfl
@[simp] theorem panic_selfId : r.panic.selfId = r.selfId := rfl
@[simp] theorem panic_config : r.panic.config = r.config := rfl

/-! ### Sending -/

section Send
variable (to : ReplicaId) (msg : Message Op)

@[simp] theorem send_status : (r.send to msg).status = r.status := rfl
@[simp] theorem send_viewNumber : (r.send to msg).viewNumber = r.viewNumber := rfl
@[simp] theorem send_lastNormalView : (r.send to msg).lastNormalView = r.lastNormalView := rfl
@[simp] theorem send_commitNumber : (r.send to msg).commitNumber = r.commitNumber := rfl
@[simp] theorem send_log : (r.send to msg).log = r.log := rfl
@[simp] theorem send_catchingUp : (r.send to msg).catchingUp = r.catchingUp := rfl
@[simp] theorem send_selfId : (r.send to msg).selfId = r.selfId := rfl
@[simp] theorem send_config : (r.send to msg).config = r.config := rfl
@[simp] theorem send_panicked : (r.send to msg).panicked = r.panicked := rfl

@[simp] theorem sendToPrimary_status : (r.sendToPrimary msg).status = r.status := rfl
@[simp] theorem sendToPrimary_viewNumber : (r.sendToPrimary msg).viewNumber = r.viewNumber := rfl
@[simp] theorem sendToPrimary_lastNormalView :
    (r.sendToPrimary msg).lastNormalView = r.lastNormalView := rfl
@[simp] theorem sendToPrimary_commitNumber : (r.sendToPrimary msg).commitNumber = r.commitNumber := rfl
@[simp] theorem sendToPrimary_log : (r.sendToPrimary msg).log = r.log := rfl
@[simp] theorem sendToPrimary_catchingUp : (r.sendToPrimary msg).catchingUp = r.catchingUp := rfl
@[simp] theorem sendToPrimary_panicked : (r.sendToPrimary msg).panicked = r.panicked := rfl

@[simp] theorem sendToOthers_status : (r.sendToOthers msg).status = r.status := by
  unfold sendToOthers; exact foldl_proj Replica.status (fun r to => r.send to msg) (fun _ _ => rfl) _ r
@[simp] theorem sendToOthers_viewNumber : (r.sendToOthers msg).viewNumber = r.viewNumber := by
  unfold sendToOthers; exact foldl_proj Replica.viewNumber (fun r to => r.send to msg) (fun _ _ => rfl) _ r
@[simp] theorem sendToOthers_lastNormalView :
    (r.sendToOthers msg).lastNormalView = r.lastNormalView := by
  unfold sendToOthers; exact foldl_proj Replica.lastNormalView (fun r to => r.send to msg) (fun _ _ => rfl) _ r
@[simp] theorem sendToOthers_commitNumber : (r.sendToOthers msg).commitNumber = r.commitNumber := by
  unfold sendToOthers; exact foldl_proj Replica.commitNumber (fun r to => r.send to msg) (fun _ _ => rfl) _ r
@[simp] theorem sendToOthers_log : (r.sendToOthers msg).log = r.log := by
  unfold sendToOthers; exact foldl_proj Replica.log (fun r to => r.send to msg) (fun _ _ => rfl) _ r
@[simp] theorem sendToOthers_catchingUp : (r.sendToOthers msg).catchingUp = r.catchingUp := by
  unfold sendToOthers; exact foldl_proj Replica.catchingUp (fun r to => r.send to msg) (fun _ _ => rfl) _ r
@[simp] theorem sendToOthers_selfId : (r.sendToOthers msg).selfId = r.selfId := by
  unfold sendToOthers; exact foldl_proj Replica.selfId (fun r to => r.send to msg) (fun _ _ => rfl) _ r
@[simp] theorem sendToOthers_config : (r.sendToOthers msg).config = r.config := by
  unfold sendToOthers; exact foldl_proj Replica.config (fun r to => r.send to msg) (fun _ _ => rfl) _ r
@[simp] theorem sendToOthers_panicked : (r.sendToOthers msg).panicked = r.panicked := by
  unfold sendToOthers; exact foldl_proj Replica.panicked (fun r to => r.send to msg) (fun _ _ => rfl) _ r

variable (n : Nat)

@[simp] theorem sendGetState_status : (r.sendGetState n).status = r.status := rfl
@[simp] theorem sendGetState_viewNumber : (r.sendGetState n).viewNumber = r.viewNumber := rfl
@[simp] theorem sendGetState_lastNormalView : (r.sendGetState n).lastNormalView = r.lastNormalView := rfl
@[simp] theorem sendGetState_commitNumber : (r.sendGetState n).commitNumber = r.commitNumber := rfl
@[simp] theorem sendGetState_log : (r.sendGetState n).log = r.log := rfl
@[simp] theorem sendGetState_catchingUp : (r.sendGetState n).catchingUp = r.catchingUp := rfl
@[simp] theorem sendGetState_panicked : (r.sendGetState n).panicked = r.panicked := rfl

@[simp] theorem sendPrepareOk_status : r.sendPrepareOk.status = r.status := rfl
@[simp] theorem sendPrepareOk_viewNumber : r.sendPrepareOk.viewNumber = r.viewNumber := rfl
@[simp] theorem sendPrepareOk_lastNormalView : r.sendPrepareOk.lastNormalView = r.lastNormalView := rfl
@[simp] theorem sendPrepareOk_commitNumber : r.sendPrepareOk.commitNumber = r.commitNumber := rfl
@[simp] theorem sendPrepareOk_log : r.sendPrepareOk.log = r.log := rfl
@[simp] theorem sendPrepareOk_catchingUp : r.sendPrepareOk.catchingUp = r.catchingUp := rfl
@[simp] theorem sendPrepareOk_panicked : r.sendPrepareOk.panicked = r.panicked := rfl

@[simp] theorem sendStartView_status : (r.sendStartView to).status = r.status := rfl
@[simp] theorem sendStartView_viewNumber : (r.sendStartView to).viewNumber = r.viewNumber := rfl
@[simp] theorem sendStartView_lastNormalView : (r.sendStartView to).lastNormalView = r.lastNormalView := rfl
@[simp] theorem sendStartView_commitNumber : (r.sendStartView to).commitNumber = r.commitNumber := rfl
@[simp] theorem sendStartView_log : (r.sendStartView to).log = r.log := rfl
@[simp] theorem sendStartView_catchingUp : (r.sendStartView to).catchingUp = r.catchingUp := rfl
@[simp] theorem sendStartView_selfId : (r.sendStartView to).selfId = r.selfId := rfl
@[simp] theorem sendStartView_config : (r.sendStartView to).config = r.config := rfl
@[simp] theorem sendStartView_panicked : (r.sendStartView to).panicked = r.panicked := rfl

@[simp] theorem sendRecovery_status : r.sendRecovery.status = r.status := sendToOthers_status _ _
@[simp] theorem sendRecovery_viewNumber : r.sendRecovery.viewNumber = r.viewNumber :=
  sendToOthers_viewNumber _ _
@[simp] theorem sendRecovery_lastNormalView : r.sendRecovery.lastNormalView = r.lastNormalView :=
  sendToOthers_lastNormalView _ _
@[simp] theorem sendRecovery_commitNumber : r.sendRecovery.commitNumber = r.commitNumber :=
  sendToOthers_commitNumber _ _
@[simp] theorem sendRecovery_log : r.sendRecovery.log = r.log := sendToOthers_log _ _
@[simp] theorem sendRecovery_catchingUp : r.sendRecovery.catchingUp = r.catchingUp :=
  sendToOthers_catchingUp _ _
@[simp] theorem sendRecovery_panicked : r.sendRecovery.panicked = r.panicked :=
  sendToOthers_panicked _ _

end Send

/-! ### The log and the client table -/

section Log
variable (entry : LogEntry Op) (log : List (LogEntry Op))

@[simp] theorem appendToLog_status : (r.appendToLog entry).status = r.status := rfl
@[simp] theorem appendToLog_viewNumber : (r.appendToLog entry).viewNumber = r.viewNumber := rfl
@[simp] theorem appendToLog_lastNormalView : (r.appendToLog entry).lastNormalView = r.lastNormalView := rfl
@[simp] theorem appendToLog_commitNumber : (r.appendToLog entry).commitNumber = r.commitNumber := rfl
@[simp] theorem appendToLog_log : (r.appendToLog entry).log = r.log ++ [entry] := rfl
@[simp] theorem appendToLog_catchingUp : (r.appendToLog entry).catchingUp = r.catchingUp := rfl
@[simp] theorem appendToLog_selfId : (r.appendToLog entry).selfId = r.selfId := rfl
@[simp] theorem appendToLog_config : (r.appendToLog entry).config = r.config := rfl
@[simp] theorem appendToLog_panicked : (r.appendToLog entry).panicked = r.panicked := rfl

theorem foldl_appendToLog_status (l : List (LogEntry Op)) :
    (l.foldl appendToLog r).status = r.status := foldl_proj Replica.status appendToLog (fun _ _ => rfl) _ _
theorem foldl_appendToLog_viewNumber (l : List (LogEntry Op)) :
    (l.foldl appendToLog r).viewNumber = r.viewNumber :=
  foldl_proj Replica.viewNumber appendToLog (fun _ _ => rfl) _ _
theorem foldl_appendToLog_lastNormalView (l : List (LogEntry Op)) :
    (l.foldl appendToLog r).lastNormalView = r.lastNormalView :=
  foldl_proj Replica.lastNormalView appendToLog (fun _ _ => rfl) _ _
theorem foldl_appendToLog_commitNumber (l : List (LogEntry Op)) :
    (l.foldl appendToLog r).commitNumber = r.commitNumber :=
  foldl_proj Replica.commitNumber appendToLog (fun _ _ => rfl) _ _
theorem foldl_appendToLog_catchingUp (l : List (LogEntry Op)) :
    (l.foldl appendToLog r).catchingUp = r.catchingUp :=
  foldl_proj Replica.catchingUp appendToLog (fun _ _ => rfl) _ _
theorem foldl_appendToLog_log : ∀ (l : List (LogEntry Op)) (r : Replica Op Output St),
    (l.foldl appendToLog r).log = r.log ++ l
  | [], r => by simp
  | e :: l, r => by rw [List.foldl_cons, foldl_appendToLog_log l, appendToLog_log, List.append_assoc]; rfl

@[simp] theorem installLog_status : (r.installLog log).status = r.status := by
  unfold installLog; split <;> rfl
@[simp] theorem installLog_viewNumber : (r.installLog log).viewNumber = r.viewNumber := by
  unfold installLog; split <;> rfl
@[simp] theorem installLog_lastNormalView : (r.installLog log).lastNormalView = r.lastNormalView := by
  unfold installLog; split <;> rfl
@[simp] theorem installLog_commitNumber : (r.installLog log).commitNumber = r.commitNumber := by
  unfold installLog; split <;> rfl
@[simp] theorem installLog_catchingUp : (r.installLog log).catchingUp = r.catchingUp := by
  unfold installLog; split <;> rfl
@[simp] theorem installLog_selfId : (r.installLog log).selfId = r.selfId := by
  unfold installLog; split <;> rfl
@[simp] theorem installLog_config : (r.installLog log).config = r.config := by
  unfold installLog; split <;> rfl
theorem installLog_log :
    (r.installLog log).log = if log.length < r.commitNumber then r.log else log := by
  unfold installLog; split <;> rfl

/-- Installing a log keeps the commit number within the log: a log too
short is refused (the panic keeps the old one). -/
theorem installLog_commit_le (h : r.commitNumber ≤ r.log.length) :
    (r.installLog log).commitNumber ≤ (r.installLog log).log.length := by
  unfold installLog
  split
  · simpa using h
  · rename_i hn; exact Nat.le_of_not_lt hn

end Log

/-! ### Committing -/

section Commit
variable (entry : LogEntry Op) (reply : Bool) (n : Nat)

@[simp] theorem commitOp_status : (commitOp m r entry).1.status = r.status := rfl
@[simp] theorem commitOp_viewNumber : (commitOp m r entry).1.viewNumber = r.viewNumber := rfl
@[simp] theorem commitOp_lastNormalView : (commitOp m r entry).1.lastNormalView = r.lastNormalView := rfl
@[simp] theorem commitOp_commitNumber : (commitOp m r entry).1.commitNumber = r.commitNumber + 1 := rfl
@[simp] theorem commitOp_log : (commitOp m r entry).1.log = r.log := rfl
@[simp] theorem commitOp_catchingUp : (commitOp m r entry).1.catchingUp = r.catchingUp := rfl
@[simp] theorem commitOp_selfId : (commitOp m r entry).1.selfId = r.selfId := rfl
@[simp] theorem commitOp_config : (commitOp m r entry).1.config = r.config := rfl
@[simp] theorem commitOp_panicked : (commitOp m r entry).1.panicked = r.panicked := rfl

section Replies
variable (x : List (Reply Output))
@[simp] theorem withReplies_status : ({ r with replies := x } : Replica Op Output St).status = r.status := rfl
@[simp] theorem withReplies_viewNumber :
    ({ r with replies := x } : Replica Op Output St).viewNumber = r.viewNumber := rfl
@[simp] theorem withReplies_lastNormalView :
    ({ r with replies := x } : Replica Op Output St).lastNormalView = r.lastNormalView := rfl
@[simp] theorem withReplies_commitNumber :
    ({ r with replies := x } : Replica Op Output St).commitNumber = r.commitNumber := rfl
@[simp] theorem withReplies_log : ({ r with replies := x } : Replica Op Output St).log = r.log := rfl
@[simp] theorem withReplies_catchingUp :
    ({ r with replies := x } : Replica Op Output St).catchingUp = r.catchingUp := rfl
@[simp] theorem withReplies_panicked :
    ({ r with replies := x } : Replica Op Output St).panicked = r.panicked := rfl
end Replies

/-- One round of `commitUpTo.go`, spelled out. -/
theorem commitUpTo_go_succ : commitUpTo.go m reply (n + 1) r =
    match r.log[r.commitNumber]? with
    | none => r.panic
    | some entry =>
      let r' := (commitOp m r entry).1
      let response := (commitOp m r entry).2
      commitUpTo.go m reply n (if reply then { r' with replies := r'.replies ++ [response] } else r') := by
  rfl

/-- A property preserved by one commit round, and by panicking, is
preserved by `commitUpTo.go`. -/
theorem commitUpTo_go_preserves (P : Replica Op Output St → Prop)
    (hpanic : ∀ r, P r → P r.panic)
    (hstep : ∀ r entry, r.log[r.commitNumber]? = some entry → P r →
      P (if reply then { (commitOp m r entry).1 with
            replies := (commitOp m r entry).1.replies ++ [(commitOp m r entry).2] }
          else (commitOp m r entry).1)) :
    ∀ (n : Nat) (r : Replica Op Output St), P r → P (commitUpTo.go m reply n r)
  | 0, _, h => h
  | n + 1, r, h => by
    rw [commitUpTo_go_succ]
    split
    · exact hpanic r h
    · rename_i entry heq
      exact commitUpTo_go_preserves P hpanic hstep n _ (hstep r entry heq h)

/-- The fields a commit round leaves alone. -/
theorem commitUpTo_go_proj {γ : Type} (p : Replica Op Output St → γ)
    (hpanic : ∀ r, p r.panic = p r)
    (hcommit : ∀ r entry, p (commitOp m r entry).1 = p r)
    (hreply : ∀ r response, p { r with replies := r.replies ++ [response] } = p r) :
    ∀ (n : Nat) (r : Replica Op Output St), p (commitUpTo.go m reply n r) = p r
  | 0, _ => rfl
  | n + 1, r => by
    rw [commitUpTo_go_succ]
    split
    · exact hpanic r
    · rename_i entry _
      rw [commitUpTo_go_proj p hpanic hcommit hreply n]
      split
      · rw [hreply, hcommit]
      · rw [hcommit]

@[simp] theorem commitUpTo_status : (commitUpTo m r n reply).status = r.status :=
  commitUpTo_go_proj m reply Replica.status (fun _ => rfl) (fun _ _ => rfl) (fun _ _ => rfl) _ _
@[simp] theorem commitUpTo_viewNumber : (commitUpTo m r n reply).viewNumber = r.viewNumber :=
  commitUpTo_go_proj m reply Replica.viewNumber (fun _ => rfl) (fun _ _ => rfl) (fun _ _ => rfl) _ _
@[simp] theorem commitUpTo_lastNormalView : (commitUpTo m r n reply).lastNormalView = r.lastNormalView :=
  commitUpTo_go_proj m reply Replica.lastNormalView (fun _ => rfl) (fun _ _ => rfl) (fun _ _ => rfl) _ _
@[simp] theorem commitUpTo_log : (commitUpTo m r n reply).log = r.log :=
  commitUpTo_go_proj m reply Replica.log (fun _ => rfl) (fun _ _ => rfl) (fun _ _ => rfl) _ _
@[simp] theorem commitUpTo_catchingUp : (commitUpTo m r n reply).catchingUp = r.catchingUp :=
  commitUpTo_go_proj m reply Replica.catchingUp (fun _ => rfl) (fun _ _ => rfl) (fun _ _ => rfl) _ _
@[simp] theorem commitUpTo_selfId : (commitUpTo m r n reply).selfId = r.selfId :=
  commitUpTo_go_proj m reply Replica.selfId (fun _ => rfl) (fun _ _ => rfl) (fun _ _ => rfl) _ _
@[simp] theorem commitUpTo_config : (commitUpTo m r n reply).config = r.config :=
  commitUpTo_go_proj m reply Replica.config (fun _ => rfl) (fun _ _ => rfl) (fun _ _ => rfl) _ _
@[simp] theorem commitUpTo_acks : (commitUpTo m r n reply).acks = r.acks :=
  commitUpTo_go_proj m reply Replica.acks (fun _ => rfl) (fun _ _ => rfl) (fun _ _ => rfl) _ _
@[simp] theorem commitUpTo_recoveryNonce : (commitUpTo m r n reply).recoveryNonce = r.recoveryNonce :=
  commitUpTo_go_proj m reply Replica.recoveryNonce (fun _ => rfl) (fun _ _ => rfl) (fun _ _ => rfl) _ _
@[simp] theorem commitUpTo_chosenVotes : (commitUpTo m r n reply).chosenVotes = r.chosenVotes :=
  commitUpTo_go_proj m reply Replica.chosenVotes (fun _ => rfl) (fun _ _ => rfl) (fun _ _ => rfl) _ _

/-- A commit round only commits an entry that exists, so the commit number
stays within the log. -/
theorem commitUpTo_commit_le (h : r.commitNumber ≤ r.log.length) :
    (commitUpTo m r n reply).commitNumber ≤ (commitUpTo m r n reply).log.length := by
  rw [commitUpTo_log]
  refine commitUpTo_go_preserves m reply (fun r' => r'.commitNumber ≤ r.log.length ∧ r'.log = r.log)
    ?_ ?_ _ r ⟨h, rfl⟩ |>.1
  · intro r' ⟨h1, h2⟩; exact ⟨h1, h2⟩
  · intro r' entry heq ⟨h1, h2⟩
    have hlt : r'.commitNumber < r'.log.length := by
      rcases Nat.lt_or_ge r'.commitNumber r'.log.length with hlt | hge
      · exact hlt
      · rw [List.getElem?_eq_none hge] at heq; simp at heq
    rw [h2] at hlt
    split <;> simp only [commitOp] <;> exact ⟨hlt, h2⟩

theorem commitUpTo_mono' : r.commitNumber ≤ (commitUpTo m r n reply).commitNumber := by
  refine commitUpTo_go_preserves m reply (fun r' => r.commitNumber ≤ r'.commitNumber) ?_ ?_ _ r
    (Nat.le_refl _)
  · intro r' h; simpa using h
  · intro r' entry _ h; split <;> simp only [commitOp] <;> exact Nat.le_succ_of_le h

end Commit

/-! ### View change bookkeeping -/

@[simp] theorem clearViewChangeState_status : r.clearViewChangeState.status = r.status := rfl
@[simp] theorem clearViewChangeState_viewNumber : r.clearViewChangeState.viewNumber = r.viewNumber := rfl
@[simp] theorem clearViewChangeState_lastNormalView :
    r.clearViewChangeState.lastNormalView = r.lastNormalView := rfl
@[simp] theorem clearViewChangeState_commitNumber :
    r.clearViewChangeState.commitNumber = r.commitNumber := rfl
@[simp] theorem clearViewChangeState_log : r.clearViewChangeState.log = r.log := rfl
@[simp] theorem clearViewChangeState_catchingUp : r.clearViewChangeState.catchingUp = r.catchingUp := rfl

@[simp] theorem enterNormal_status : r.enterNormal.status = .normal := rfl
@[simp] theorem enterNormal_viewNumber : r.enterNormal.viewNumber = r.viewNumber := rfl
@[simp] theorem enterNormal_lastNormalView : r.enterNormal.lastNormalView = r.viewNumber := rfl
@[simp] theorem enterNormal_commitNumber : r.enterNormal.commitNumber = r.commitNumber := rfl
@[simp] theorem enterNormal_log : r.enterNormal.log = r.log := rfl
@[simp] theorem enterNormal_catchingUp : r.enterNormal.catchingUp = false := rfl
@[simp] theorem enterNormal_selfId : r.enterNormal.selfId = r.selfId := rfl
@[simp] theorem enterNormal_config : r.enterNormal.config = r.config := rfl
@[simp] theorem enterNormal_panicked : r.enterNormal.panicked = r.panicked := rfl

@[simp] theorem stateTransfer_status : r.stateTransfer.status = .stateTransfer := rfl
@[simp] theorem stateTransfer_viewNumber : r.stateTransfer.viewNumber = r.viewNumber := rfl
@[simp] theorem stateTransfer_lastNormalView : r.stateTransfer.lastNormalView = r.lastNormalView := rfl
@[simp] theorem stateTransfer_commitNumber : r.stateTransfer.commitNumber = r.commitNumber := rfl
@[simp] theorem stateTransfer_log : r.stateTransfer.log = r.log := rfl
@[simp] theorem stateTransfer_catchingUp : r.stateTransfer.catchingUp = r.catchingUp := rfl
@[simp] theorem stateTransfer_panicked : r.stateTransfer.panicked = r.panicked := rfl

section CatchUp
variable (v : ViewNumber)

theorem catchUpWithView_status : (r.catchUpWithView v).status =
    if r.viewNumber = v ∧ r.catchingUp then r.status else .viewChange := by
  unfold catchUpWithView; split <;> rfl
theorem catchUpWithView_viewNumber : (r.catchUpWithView v).viewNumber =
    if r.viewNumber = v ∧ r.catchingUp then r.viewNumber else v := by
  unfold catchUpWithView; split <;> rfl
theorem catchUpWithView_catchingUp : (r.catchUpWithView v).catchingUp =
    if r.viewNumber = v ∧ r.catchingUp then r.catchingUp else true := by
  unfold catchUpWithView; split <;> rfl
@[simp] theorem catchUpWithView_lastNormalView :
    (r.catchUpWithView v).lastNormalView = r.lastNormalView := by
  unfold catchUpWithView; split <;> rfl
@[simp] theorem catchUpWithView_commitNumber : (r.catchUpWithView v).commitNumber = r.commitNumber := by
  unfold catchUpWithView; split <;> rfl
@[simp] theorem catchUpWithView_log : (r.catchUpWithView v).log = r.log := by
  unfold catchUpWithView; split <;> rfl
@[simp] theorem catchUpWithView_panicked : (r.catchUpWithView v).panicked = r.panicked := by
  unfold catchUpWithView; split <;> rfl

end CatchUp

@[simp] theorem addAcksForUncommitted_status : r.addAcksForUncommitted.status = r.status := rfl
@[simp] theorem addAcksForUncommitted_viewNumber :
    r.addAcksForUncommitted.viewNumber = r.viewNumber := rfl
@[simp] theorem addAcksForUncommitted_lastNormalView :
    r.addAcksForUncommitted.lastNormalView = r.lastNormalView := rfl
@[simp] theorem addAcksForUncommitted_commitNumber :
    r.addAcksForUncommitted.commitNumber = r.commitNumber := rfl
@[simp] theorem addAcksForUncommitted_log : r.addAcksForUncommitted.log = r.log := rfl
@[simp] theorem addAcksForUncommitted_catchingUp :
    r.addAcksForUncommitted.catchingUp = r.catchingUp := rfl
@[simp] theorem addAcksForUncommitted_selfId : r.addAcksForUncommitted.selfId = r.selfId := rfl
@[simp] theorem addAcksForUncommitted_config : r.addAcksForUncommitted.config = r.config := rfl
@[simp] theorem addAcksForUncommitted_panicked : r.addAcksForUncommitted.panicked = r.panicked := rfl

@[simp] theorem noteStable_status : r.noteStable.status = r.status := rfl
@[simp] theorem noteStable_viewNumber : r.noteStable.viewNumber = r.viewNumber := rfl
@[simp] theorem noteStable_lastNormalView : r.noteStable.lastNormalView = r.lastNormalView := rfl
@[simp] theorem noteStable_commitNumber : r.noteStable.commitNumber = r.commitNumber := rfl
@[simp] theorem noteStable_log : r.noteStable.log = r.log := rfl
@[simp] theorem noteStable_catchingUp : r.noteStable.catchingUp = r.catchingUp := rfl
@[simp] theorem noteStable_selfId : r.noteStable.selfId = r.selfId := rfl
@[simp] theorem noteStable_config : r.noteStable.config = r.config := rfl
@[simp] theorem noteStable_panicked : r.noteStable.panicked = r.panicked := rfl
@[simp] theorem noteStable_outbox : r.noteStable.outbox = r.outbox := rfl

@[simp] theorem waitTimedOut_status : r.waitTimedOut.1.status = r.status := rfl
@[simp] theorem waitTimedOut_viewNumber : r.waitTimedOut.1.viewNumber = r.viewNumber := rfl
@[simp] theorem waitTimedOut_lastNormalView : r.waitTimedOut.1.lastNormalView = r.lastNormalView := rfl
@[simp] theorem waitTimedOut_commitNumber : r.waitTimedOut.1.commitNumber = r.commitNumber := rfl
@[simp] theorem waitTimedOut_log : r.waitTimedOut.1.log = r.log := rfl
@[simp] theorem waitTimedOut_catchingUp : r.waitTimedOut.1.catchingUp = r.catchingUp := rfl
@[simp] theorem waitTimedOut_selfId : r.waitTimedOut.1.selfId = r.selfId := rfl
@[simp] theorem waitTimedOut_config : r.waitTimedOut.1.config = r.config := rfl
@[simp] theorem waitTimedOut_panicked : r.waitTimedOut.1.panicked = r.panicked := rfl

/-! ### The primary's re-sends -/

section Resend
variable (v : ViewNumber) (c : CommitNumber)

private theorem resendPrepares_proj {γ : Type} (p : Replica Op Output St → γ)
    (hpanic : ∀ r, p r.panic = p r) (hsend : ∀ r msg, p (r.sendToOthers msg) = p r) :
    p (r.resendPrepares v c) = p r := by
  unfold resendPrepares
  apply foldl_proj
  intro a i
  dsimp only
  split
  · exact hpanic a
  · exact hsend a _

@[simp] theorem resendPrepares_status : (r.resendPrepares v c).status = r.status :=
  resendPrepares_proj r v c Replica.status (fun _ => rfl) (fun _ _ => sendToOthers_status _ _)
@[simp] theorem resendPrepares_viewNumber : (r.resendPrepares v c).viewNumber = r.viewNumber :=
  resendPrepares_proj r v c Replica.viewNumber (fun _ => rfl) (fun _ _ => sendToOthers_viewNumber _ _)
@[simp] theorem resendPrepares_lastNormalView :
    (r.resendPrepares v c).lastNormalView = r.lastNormalView :=
  resendPrepares_proj r v c Replica.lastNormalView (fun _ => rfl)
    (fun _ _ => sendToOthers_lastNormalView _ _)
@[simp] theorem resendPrepares_commitNumber : (r.resendPrepares v c).commitNumber = r.commitNumber :=
  resendPrepares_proj r v c Replica.commitNumber (fun _ => rfl)
    (fun _ _ => sendToOthers_commitNumber _ _)
@[simp] theorem resendPrepares_log : (r.resendPrepares v c).log = r.log :=
  resendPrepares_proj r v c Replica.log (fun _ => rfl) (fun _ _ => sendToOthers_log _ _)
@[simp] theorem resendPrepares_catchingUp : (r.resendPrepares v c).catchingUp = r.catchingUp :=
  resendPrepares_proj r v c Replica.catchingUp (fun _ => rfl) (fun _ _ => sendToOthers_catchingUp _ _)

end Resend

/-! ### The outbox -/

section Outbox

@[simp] theorem send_outbox (to : ReplicaId) (msg : Message Op) :
    (r.send to msg).outbox = r.outbox ++ [(to, msg)] := rfl
@[simp] theorem panic_outbox : r.panic.outbox = r.outbox := rfl
@[simp] theorem appendToLog_outbox (entry : LogEntry Op) : (r.appendToLog entry).outbox = r.outbox := rfl
@[simp] theorem installLog_outbox (log : List (LogEntry Op)) : (r.installLog log).outbox = r.outbox := by
  unfold installLog; split <;> rfl
@[simp] theorem commitOp_outbox (entry : LogEntry Op) : (commitOp m r entry).1.outbox = r.outbox := rfl
@[simp] theorem withReplies_outbox (x : List (Reply Output)) :
    ({ r with replies := x } : Replica Op Output St).outbox = r.outbox := rfl
@[simp] theorem commitUpTo_outbox (n : Nat) (reply : Bool) :
    (commitUpTo m r n reply).outbox = r.outbox :=
  commitUpTo_go_proj m reply Replica.outbox (fun _ => rfl) (fun _ _ => rfl) (fun _ _ => rfl) _ _
@[simp] theorem clearViewChangeState_outbox : r.clearViewChangeState.outbox = r.outbox := rfl
@[simp] theorem enterNormal_outbox : r.enterNormal.outbox = r.outbox := rfl
@[simp] theorem addAcksForUncommitted_outbox : r.addAcksForUncommitted.outbox = r.outbox := rfl
@[simp] theorem waitTimedOut_outbox : r.waitTimedOut.1.outbox = r.outbox := rfl

/-- What `sendToOthers` puts in the outbox: what was there, and copies of
the message. -/
theorem mem_sendToOthers_outbox {msg : Message Op} {x : ReplicaId × Message Op}
    (h : x ∈ (r.sendToOthers msg).outbox) : x ∈ r.outbox ∨ x.2 = msg := by
  unfold sendToOthers at h
  generalize r.config.replicas.filter (· ≠ r.selfId) = l at h
  induction l generalizing r with
  | nil => exact Or.inl h
  | cons to l ih =>
    rw [List.foldl_cons] at h
    rcases ih _ h with h | h
    · simp only [send_outbox, List.mem_append, List.mem_singleton] at h
      rcases h with h | rfl
      · exact Or.inl h
      · exact Or.inr rfl
    · exact Or.inr h

end Outbox

/-! ### The fresh replicas -/

@[simp] theorem new_status (id : ReplicaId) (config : Config) (sm : St) :
    (new id config sm : Replica Op Output St).status = .normal := rfl
@[simp] theorem new_viewNumber (id : ReplicaId) (config : Config) (sm : St) :
    (new id config sm : Replica Op Output St).viewNumber = 0 := rfl
@[simp] theorem new_lastNormalView (id : ReplicaId) (config : Config) (sm : St) :
    (new id config sm : Replica Op Output St).lastNormalView = 0 := rfl
@[simp] theorem new_commitNumber (id : ReplicaId) (config : Config) (sm : St) :
    (new id config sm : Replica Op Output St).commitNumber = 0 := rfl
@[simp] theorem new_log (id : ReplicaId) (config : Config) (sm : St) :
    (new id config sm : Replica Op Output St).log = [] := rfl
@[simp] theorem new_catchingUp (id : ReplicaId) (config : Config) (sm : St) :
    (new id config sm : Replica Op Output St).catchingUp = false := rfl
@[simp] theorem new_panicked (id : ReplicaId) (config : Config) (sm : St) :
    (new id config sm : Replica Op Output St).panicked = false := rfl

@[simp] theorem recover_status (id : ReplicaId) (config : Config) (sm : St) (v : ViewNumber) (nonce : Nat) :
    (recover id config sm v nonce : Replica Op Output St).status = .recovering := by
  unfold recover; rw [sendRecovery_status]
@[simp] theorem recover_viewNumber (id : ReplicaId) (config : Config) (sm : St) (v : ViewNumber) (nonce : Nat) :
    (recover id config sm v nonce : Replica Op Output St).viewNumber = v := by
  unfold recover; rw [sendRecovery_viewNumber]
@[simp] theorem recover_lastNormalView (id : ReplicaId) (config : Config) (sm : St) (v : ViewNumber)
    (nonce : Nat) : (recover id config sm v nonce : Replica Op Output St).lastNormalView = v := by
  unfold recover; rw [sendRecovery_lastNormalView]
@[simp] theorem recover_commitNumber (id : ReplicaId) (config : Config) (sm : St) (v : ViewNumber)
    (nonce : Nat) : (recover id config sm v nonce : Replica Op Output St).commitNumber = 0 := by
  unfold recover; rw [sendRecovery_commitNumber]; rfl
@[simp] theorem recover_log (id : ReplicaId) (config : Config) (sm : St) (v : ViewNumber) (nonce : Nat) :
    (recover id config sm v nonce : Replica Op Output St).log = [] := by
  unfold recover; rw [sendRecovery_log]; rfl
@[simp] theorem recover_catchingUp (id : ReplicaId) (config : Config) (sm : St) (v : ViewNumber)
    (nonce : Nat) : (recover id config sm v nonce : Replica Op Output St).catchingUp = false := by
  unfold recover; rw [sendRecovery_catchingUp]; rfl
@[simp] theorem recover_panicked (id : ReplicaId) (config : Config) (sm : St) (v : ViewNumber)
    (nonce : Nat) : (recover id config sm v nonce : Replica Op Output St).panicked = false := by
  unfold recover; rw [sendRecovery_panicked]; rfl

end Replica

end Vsr
