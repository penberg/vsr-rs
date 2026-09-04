import Vsr.Types

/-!
The replica, as a pure function of its state: a twin of `Replica` in
`lib.rs`, one definition per Rust function, with the same control flow.

Sends go to `outbox` and replies to `replies`; the owner drains them. A
Rust `assert!` becomes `panicked := true`, so every handler is total and the
safety theorems say the flag is never set in a reachable state.
-/

namespace Vsr

structure ClientEntry (Output : Type) where
  requestNumber : RequestNumber
  reply : Option Output
deriving Repr, DecidableEq

structure Vote (Op : Type) where
  lastNormalView : ViewNumber
  log : List (LogEntry Op)
  commitNumber : CommitNumber
deriving Repr, DecidableEq

structure RecoveryResponse (Op : Type) where
  viewNumber : ViewNumber
  state : Option (RecoveryState Op)
deriving Repr, DecidableEq

structure Replica (Op Output St : Type) where
  config : Config
  selfId : ReplicaId
  sm : St
  status : Status
  viewNumber : ViewNumber
  lastNormalView : ViewNumber
  commitNumber : CommitNumber
  log : List (LogEntry Op)
  /-- For each uncommitted op number, the replicas that acknowledged it. -/
  acks : List (OpNumber × List ReplicaId)
  clientTable : List (ClientId × ClientEntry Output)
  heardFromPrimary : Bool
  idlePeriodsWaiting : Nat
  viewChangeAttempts : Nat
  idlePeriodsStable : Nat
  startViewChangeFrom : List ReplicaId
  doViewChangeSent : Bool
  doViewChangeVotes : List (ReplicaId × Vote Op)
  catchingUp : Bool
  recoveryNonce : Nat
  recoveryResponses : List (ReplicaId × RecoveryResponse Op)
  outbox : List (ReplicaId × Message Op)
  replies : List (Reply Output)
  /-- Set where the Rust would have panicked. -/
  panicked : Bool
  /-- Ghost, for the proofs: the votes this replica just started a view
  from, taken by the system step into its history like the outbox. Not in
  the Rust, and not observable. -/
  chosenVotes : Option (List (ReplicaId × Vote Op))
deriving DecidableEq

namespace Replica

variable {Op Output St : Type}

def new (selfId : ReplicaId) (config : Config) (sm : St) : Replica Op Output St where
  config := config
  selfId := selfId
  sm := sm
  status := .normal
  viewNumber := 0
  lastNormalView := 0
  commitNumber := 0
  log := []
  acks := []
  clientTable := []
  heardFromPrimary := true
  idlePeriodsWaiting := 0
  viewChangeAttempts := 0
  idlePeriodsStable := 0
  startViewChangeFrom := []
  doViewChangeSent := false
  doViewChangeVotes := []
  catchingUp := false
  recoveryNonce := 0
  recoveryResponses := []
  outbox := []
  replies := []
  panicked := false
  chosenVotes := none

def opNumber (r : Replica Op Output St) : OpNumber := r.log.length

def primaryId (r : Replica Op Output St) : ReplicaId := r.config.primaryId r.viewNumber

def isPrimary (r : Replica Op Output St) : Bool := r.selfId = r.primaryId

def panic (r : Replica Op Output St) : Replica Op Output St := { r with panicked := true }

/-! ### Sending -/

def send (r : Replica Op Output St) (to : ReplicaId) (m : Message Op) : Replica Op Output St :=
  { r with outbox := r.outbox ++ [(to, m)] }

def sendToPrimary (r : Replica Op Output St) (m : Message Op) : Replica Op Output St :=
  r.send r.primaryId m

def sendToOthers (r : Replica Op Output St) (m : Message Op) : Replica Op Output St :=
  (r.config.replicas.filter (· ≠ r.selfId)).foldl (fun r to => r.send to m) r

def sendGetState (r : Replica Op Output St) (opNumber : OpNumber) : Replica Op Output St :=
  r.sendToPrimary (.getState r.selfId r.viewNumber opNumber)

def sendPrepareOk (r : Replica Op Output St) : Replica Op Output St :=
  r.sendToPrimary (.prepareOk r.viewNumber r.opNumber r.selfId)

def sendStartView (r : Replica Op Output St) (to : ReplicaId) : Replica Op Output St :=
  r.send to (.startView r.viewNumber r.log r.opNumber r.commitNumber)

def sendRecovery (r : Replica Op Output St) : Replica Op Output St :=
  r.sendToOthers (.recovery r.selfId r.recoveryNonce r.viewNumber)

/-! ### The log and the client table -/

def appendToLog (r : Replica Op Output St) (entry : LogEntry Op) : Replica Op Output St :=
  { r with
    clientTable := Assoc.insert r.clientTable entry.clientId ⟨entry.requestNumber, none⟩
    log := r.log ++ [entry] }

/-- Rebuilds the client table from `log`, keeping the replies of committed
requests. `i` is the index of the first entry of `log` in the full log. -/
def rebuildClientTable (commitNumber : CommitNumber)
    (old : List (ClientId × ClientEntry Output)) :
    Nat → List (LogEntry Op) → List (ClientId × ClientEntry Output) → List (ClientId × ClientEntry Output)
  | _, [], table => table
  | i, entry :: rest, table =>
    let reply :=
      if i < commitNumber then
        ((Assoc.lookup old entry.clientId).filter (·.requestNumber = entry.requestNumber)).bind (·.reply)
      else none
    rebuildClientTable commitNumber old (i + 1) rest
      (Assoc.insert table entry.clientId ⟨entry.requestNumber, reply⟩)

def installLog (r : Replica Op Output St) (log : List (LogEntry Op)) : Replica Op Output St :=
  if log.length < r.commitNumber then r.panic
  else
    { r with
      clientTable := rebuildClientTable r.commitNumber r.clientTable 0 log []
      log := log }

/-! ### Committing -/

def commitOp (m : Machine Op Output St) (r : Replica Op Output St) (entry : LogEntry Op) :
    Replica Op Output St × Reply Output :=
  let (sm, result) := m.apply r.sm entry.op
  let clientTable := Assoc.update r.clientTable entry.clientId fun c =>
    if c.requestNumber = entry.requestNumber then { c with reply := some result } else c
  ({ r with sm := sm, commitNumber := r.commitNumber + 1, clientTable := clientTable },
   ⟨r.viewNumber, entry.clientId, entry.requestNumber, result⟩)

/-- `commit_up_to`: the Rust loops while `commit_number < commit_number'`,
indexing the log, so the fuel is the distance and a missing entry is the
panic. -/
def commitUpTo.go (m : Machine Op Output St) (reply : Bool) :
    Nat → Replica Op Output St → Replica Op Output St
  | 0, r => r
  | n + 1, r =>
    match r.log[r.commitNumber]? with
    | none => r.panic
    | some entry =>
      let (r, response) := commitOp m r entry
      let r := if reply then { r with replies := r.replies ++ [response] } else r
      commitUpTo.go m reply n r

def commitUpTo (m : Machine Op Output St) (r : Replica Op Output St) (commitNumber : CommitNumber)
    (reply : Bool) : Replica Op Output St :=
  commitUpTo.go m reply (commitNumber - r.commitNumber) r

/-! ### View changes -/

def clearViewChangeState (r : Replica Op Output St) : Replica Op Output St :=
  { r with startViewChangeFrom := [], doViewChangeSent := false, doViewChangeVotes := [] }

def enterNormal (r : Replica Op Output St) : Replica Op Output St :=
  { r.clearViewChangeState with
    status := .normal
    lastNormalView := r.viewNumber
    catchingUp := false
    heardFromPrimary := true
    idlePeriodsWaiting := 0
    idlePeriodsStable := 0 }

def stateTransfer (r : Replica Op Output St) : Replica Op Output St :=
  { r with status := .stateTransfer }.sendGetState r.opNumber

def catchUpWithView (r : Replica Op Output St) (viewNumber : ViewNumber) : Replica Op Output St :=
  if r.viewNumber = viewNumber ∧ r.catchingUp then r
  else
    { r.clearViewChangeState with
      viewNumber := viewNumber
      status := .viewChange
      catchingUp := true
      idlePeriodsWaiting := 0 }.sendGetState r.commitNumber

/-- The key `record_do_view_change` maximises: `(last_normal_view, log.len())`. -/
def voteKey (v : Vote Op) : Nat × Nat := (v.lastNormalView, v.log.length)

def keyGe (a b : Nat × Nat) : Bool := a.1 > b.1 || (a.1 = b.1 && a.2 ≥ b.2)

/-- `Iterator::max_by_key` returns the last of equal maxima, and the votes
are iterated by replica id. -/
def bestVote (votes : List (ReplicaId × Vote Op)) : Option (Vote Op) :=
  votes.foldl (fun best (_, v) =>
    match best with
    | none => some v
    | some b => if keyGe (voteKey v) (voteKey b) then some v else some b) none

def addAcksForUncommitted (r : Replica Op Output St) : Replica Op Output St :=
  let acks := (List.range (r.opNumber - r.commitNumber)).map fun i => (r.commitNumber + 1 + i, [r.selfId])
  { r with acks := acks }

def recordDoViewChange (m : Machine Op Output St) (r : Replica Op Output St) (replicaId : ReplicaId)
    (vote : Vote Op) : Replica Op Output St :=
  let r := { r with doViewChangeVotes := Assoc.insert r.doViewChangeVotes replicaId vote }
  if r.doViewChangeVotes.length < r.config.quorum then r
  else
    match bestVote r.doViewChangeVotes with
    | none => r.panic
    | some best =>
      let commitNumber := r.doViewChangeVotes.foldl (fun acc (_, v) => max acc v.commitNumber) 0
      let r := { r with chosenVotes := some r.doViewChangeVotes }
      let r := r.installLog best.log
      let r := commitUpTo m r commitNumber true
      let r := { r.enterNormal with acks := [] }.addAcksForUncommitted
      (r.config.replicas.filter (· ≠ r.selfId)).foldl (fun r to => r.sendStartView to) r

def sendDoViewChange (m : Machine Op Output St) (r : Replica Op Output St) : Replica Op Output St :=
  let vote : Vote Op := ⟨r.lastNormalView, r.log, r.commitNumber⟩
  let primaryId := r.config.primaryId r.viewNumber
  if primaryId = r.selfId then recordDoViewChange m r r.selfId vote
  else r.send primaryId
    (.doViewChange r.viewNumber r.selfId vote.lastNormalView vote.log vote.log.length vote.commitNumber)

def maybeSendDoViewChange (m : Machine Op Output St) (r : Replica Op Output St) : Replica Op Output St :=
  if r.status ≠ .viewChange ∨ r.catchingUp ∨ r.doViewChangeSent then r
  else
    let f := r.config.replicaCount / 2
    if r.startViewChangeFrom.length < f then r
    else sendDoViewChange m { r with doViewChangeSent := true }

def startViewChange (m : Machine Op Output St) (r : Replica Op Output St) (viewNumber : ViewNumber) :
    Replica Op Output St :=
  let attempts := if r.status = .viewChange then r.viewChangeAttempts + 1 else r.viewChangeAttempts
  let r :=
    { r.clearViewChangeState with
      viewChangeAttempts := attempts
      viewNumber := viewNumber
      status := .viewChange
      catchingUp := false
      idlePeriodsWaiting := 0 }
  let r := r.sendToOthers (.startViewChange viewNumber r.selfId)
  maybeSendDoViewChange m r

/-- `note_stable`: an idle period of stable normal operation; after
`primaryTimeout` of them the backoff is forgotten. -/
def noteStable (r : Replica Op Output St) : Replica Op Output St :=
  let stable := r.idlePeriodsStable + 1
  { r with
    idlePeriodsStable := stable
    viewChangeAttempts := if stable ≥ r.config.primaryTimeout then 0 else r.viewChangeAttempts }

/-- `wait_timed_out`: counts the idle period and says whether the wait is
over. -/
def waitTimedOut (r : Replica Op Output St) : Replica Op Output St × Bool :=
  let r := { r with idlePeriodsWaiting := r.idlePeriodsWaiting + 1 }
  let backoff := min r.viewChangeAttempts 10
  (r, decide (r.idlePeriodsWaiting ≥ r.config.primaryTimeout <<< backoff))

/-! ### Normal operation -/

/-- `accept_from_primary`: returns the replica and whether to process the
message as a normal-case message. -/
def acceptFromPrimary (r : Replica Op Output St) (viewNumber : ViewNumber) :
    Replica Op Output St × Bool :=
  if viewNumber < r.viewNumber then (r, false)
  else if viewNumber > r.viewNumber then (r.catchUpWithView viewNumber, false)
  else
    let r := { r with heardFromPrimary := true }
    match r.status with
    | .normal => (r, !r.isPrimary)
    | .stateTransfer | .recovering => (r, false)
    | .viewChange => (r.catchUpWithView viewNumber, false)

/-- Appends a new request to the log, records our own acknowledgement,
and replicates it. -/
def prepareRequest (r : Replica Op Output St) (clientId : ClientId) (requestNumber : RequestNumber)
    (op : Op) : Replica Op Output St :=
  let r := r.appendToLog ⟨clientId, requestNumber, op⟩
  let opNumber := r.opNumber
  let r := { r with acks := Assoc.insert r.acks opNumber [r.selfId] }
  r.sendToOthers (.prepare r.viewNumber opNumber clientId requestNumber op r.commitNumber)

def onRequest (r : Replica Op Output St) (clientId : ClientId) (requestNumber : RequestNumber)
    (op : Op) : Replica Op Output St :=
  if !r.isPrimary ∨ r.status ≠ .normal then r
  else
    match Assoc.lookup r.clientTable clientId with
    | none => r.prepareRequest clientId requestNumber op
    | some entry =>
      if requestNumber < entry.requestNumber then r
      else if requestNumber = entry.requestNumber then
        match entry.reply with
        | some result =>
          { r with replies := r.replies ++ [⟨r.viewNumber, clientId, requestNumber, result⟩] }
        | none => r
      else r.prepareRequest clientId requestNumber op

def onPrepare (m : Machine Op Output St) (r : Replica Op Output St) (viewNumber : ViewNumber)
    (opNumber : OpNumber) (entry : LogEntry Op) (commitNumber : CommitNumber) :
    Replica Op Output St :=
  let (r, accept) := r.acceptFromPrimary viewNumber
  if !accept then r
  else if opNumber > r.opNumber + 1 then r.stateTransfer
  else
    let r := if opNumber = r.opNumber + 1 then r.appendToLog entry else r
    let r := commitUpTo m r (min commitNumber r.opNumber) false
    r.sendPrepareOk

def onPrepareOk (m : Machine Op Output St) (r : Replica Op Output St) (viewNumber : ViewNumber)
    (opNumber : OpNumber) (replicaId : ReplicaId) : Replica Op Output St :=
  if viewNumber ≠ r.viewNumber ∨ !r.isPrimary ∨ r.status ≠ .normal then r
  else if opNumber ≤ r.commitNumber then r
  else
    match Assoc.lookup r.acks opNumber with
    | none => r
    | some ackedBy =>
      let (ackedBy, fresh) := NatSet.insert ackedBy replicaId
      let r := { r with acks := Assoc.update r.acks opNumber fun _ => ackedBy }
      if !fresh ∨ ackedBy.length ≠ r.config.quorum then r
      else
        let r := commitUpTo m r opNumber true
        { r with acks := r.acks.filter fun (k, _) => k > opNumber }

def onCommit (m : Machine Op Output St) (r : Replica Op Output St) (viewNumber : ViewNumber)
    (commitNumber : CommitNumber) : Replica Op Output St :=
  let (r, accept) := r.acceptFromPrimary viewNumber
  if !accept then r
  else if commitNumber > r.opNumber then r.stateTransfer
  else commitUpTo m r commitNumber false

/-! ### State transfer -/

def onGetState (r : Replica Op Output St) (replicaId : ReplicaId) (viewNumber : ViewNumber)
    (opNumber : OpNumber) : Replica Op Output St :=
  if r.status ≠ .normal ∨ viewNumber ≠ r.viewNumber ∨ opNumber > r.opNumber then r
  else r.send replicaId (.newState viewNumber (r.log.drop opNumber) opNumber r.opNumber r.commitNumber)

def onNewState (m : Machine Op Output St) (r : Replica Op Output St) (viewNumber : ViewNumber)
    (log : List (LogEntry Op)) (opNumberStart opNumberEnd : OpNumber) (commitNumber : CommitNumber) :
    Replica Op Output St :=
  if viewNumber ≠ r.viewNumber then r
  else if log.length ≠ opNumberEnd - opNumberStart then r.panic
  else
    let r := { r with heardFromPrimary := true }
    match r.status with
    | .stateTransfer =>
      let opNumber := r.opNumber
      if opNumberStart > opNumber ∨ opNumberEnd ≤ opNumber then r
      else
        let r := (log.drop (opNumber - opNumberStart)).foldl appendToLog r
        if r.opNumber ≠ opNumberEnd then r.panic
        else
          let r := commitUpTo m r commitNumber false
          { r with status := .normal }.sendPrepareOk
    | .viewChange =>
      if !r.catchingUp then r
      else if opNumberStart ≠ r.commitNumber then r
      else
        let r := r.installLog (r.log.take opNumberStart ++ log)
        if r.opNumber ≠ opNumberEnd then r.panic
        else
          let r := commitUpTo m r commitNumber false
          r.enterNormal.sendPrepareOk
    | _ => r

/-! ### View change messages -/

/-- Records that `replicaId` wants the current view, and sends
`DoViewChange` if that makes `f` of them. -/
def noteStartViewChange (m : Machine Op Output St) (r : Replica Op Output St) (replicaId : ReplicaId) :
    Replica Op Output St :=
  maybeSendDoViewChange m
    { r with startViewChangeFrom := (NatSet.insert r.startViewChangeFrom replicaId).1 }

def onStartViewChange (m : Machine Op Output St) (r : Replica Op Output St) (viewNumber : ViewNumber)
    (replicaId : ReplicaId) : Replica Op Output St :=
  if viewNumber < r.viewNumber then r
  else if viewNumber > r.viewNumber then noteStartViewChange m (startViewChange m r viewNumber) replicaId
  else if r.status ≠ .viewChange then
    if r.status = .normal ∧ r.isPrimary then r.sendStartView replicaId else r
  else noteStartViewChange m r replicaId

def onDoViewChange (m : Machine Op Output St) (r : Replica Op Output St) (viewNumber : ViewNumber)
    (replicaId : ReplicaId) (vote : Vote Op) : Replica Op Output St :=
  if viewNumber < r.viewNumber ∨ r.config.primaryId viewNumber ≠ r.selfId then r
  else if viewNumber > r.viewNumber then
    recordDoViewChange m (startViewChange m r viewNumber) replicaId vote
  else if r.status = .normal then r.sendStartView replicaId
  else recordDoViewChange m r replicaId vote

def onStartView (m : Machine Op Output St) (r : Replica Op Output St) (viewNumber : ViewNumber)
    (log : List (LogEntry Op)) (commitNumber : CommitNumber) : Replica Op Output St :=
  if viewNumber < r.viewNumber ∨ (viewNumber = r.viewNumber ∧ r.status ≠ .viewChange) then r
  else
    let r := { r with viewNumber := viewNumber }.installLog log
    let r := commitUpTo m r commitNumber false
    { r.enterNormal with acks := [] }.sendPrepareOk

/-! ### Recovery -/

def onRecovery (m : Machine Op Output St) (r : Replica Op Output St) (replicaId : ReplicaId)
    (nonce : Nat) (viewNumber : ViewNumber) : Replica Op Output St :=
  if viewNumber > r.viewNumber ∧ r.status ≠ .recovering then startViewChange m r viewNumber
  else if r.status ≠ .normal then r
  else
    let state := if r.isPrimary then some (RecoveryState.mk r.log r.commitNumber) else none
    r.send replicaId (.recoveryResponse r.viewNumber nonce r.selfId state)

def onRecoveryResponse (m : Machine Op Output St) (r : Replica Op Output St) (viewNumber : ViewNumber)
    (nonce : Nat) (replicaId : ReplicaId) (state : Option (RecoveryState Op)) :
    Replica Op Output St :=
  if r.status ≠ .recovering ∨ nonce ≠ r.recoveryNonce then r
  else
    let r := { r with recoveryResponses := Assoc.insert r.recoveryResponses replicaId ⟨viewNumber, state⟩ }
    if r.recoveryResponses.length < r.config.quorum then r
    else
      let latestView := r.recoveryResponses.foldl (fun acc (_, resp) => max acc resp.viewNumber) 0
      if latestView < r.viewNumber then r
      else
        let primaryId := r.config.primaryId latestView
        match Assoc.lookup r.recoveryResponses primaryId with
        | some ⟨primaryView, some state⟩ =>
          if primaryView ≠ latestView then r
          else
            let r := { r with recoveryResponses := [], viewNumber := latestView }.installLog state.log
            let r := commitUpTo m r state.commitNumber false
            r.enterNormal
        | _ => r

def recover (selfId : ReplicaId) (config : Config) (sm : St) (viewNumber : ViewNumber) (nonce : Nat) :
    Replica Op Output St :=
  ({ new selfId config sm with
    status := .recovering
    viewNumber := viewNumber
    lastNormalView := viewNumber
    recoveryNonce := nonce } : Replica Op Output St).sendRecovery

/-! ### Entry points -/

def isRecoveryResponse : Message Op → Bool
  | .recoveryResponse .. => true
  | _ => false

def onMessage (m : Machine Op Output St) (r : Replica Op Output St) (msg : Message Op) :
    Replica Op Output St :=
  if r.status = .recovering ∧ isRecoveryResponse msg = false then r
  else
    match msg with
    | .request clientId requestNumber op => r.onRequest clientId requestNumber op
    | .prepare viewNumber opNumber clientId requestNumber op commitNumber =>
      onPrepare m r viewNumber opNumber ⟨clientId, requestNumber, op⟩ commitNumber
    | .prepareOk viewNumber opNumber replicaId => onPrepareOk m r viewNumber opNumber replicaId
    | .commit viewNumber commitNumber => onCommit m r viewNumber commitNumber
    | .getState replicaId viewNumber opNumber => r.onGetState replicaId viewNumber opNumber
    | .newState viewNumber log opNumberStart opNumberEnd commitNumber =>
      onNewState m r viewNumber log opNumberStart opNumberEnd commitNumber
    | .startViewChange viewNumber replicaId => onStartViewChange m r viewNumber replicaId
    | .doViewChange viewNumber replicaId lastNormalView log opNumber commitNumber =>
      if log.length ≠ opNumber then r.panic
      else onDoViewChange m r viewNumber replicaId ⟨lastNormalView, log, commitNumber⟩
    | .startView viewNumber log opNumber commitNumber =>
      if log.length ≠ opNumber then r.panic
      else onStartView m r viewNumber log commitNumber
    | .recovery replicaId nonce viewNumber => onRecovery m r replicaId nonce viewNumber
    | .recoveryResponse viewNumber nonce replicaId state =>
      onRecoveryResponse m r viewNumber nonce replicaId state

/-- The primary's re-sends of every uncommitted `Prepare`. -/
def resendPrepares (r : Replica Op Output St) (viewNumber : ViewNumber) (commitNumber : CommitNumber) :
    Replica Op Output St :=
  (List.range (r.opNumber - commitNumber)).foldl (fun r i =>
    let opNumber := commitNumber + 1 + i
    match r.log[opNumber - 1]? with
    | none => r.panic
    | some entry =>
      r.sendToOthers (.prepare viewNumber opNumber entry.clientId entry.requestNumber entry.op commitNumber)) r

def onIdle (m : Machine Op Output St) (r : Replica Op Output St) : Replica Op Output St :=
  match r.status with
  | .normal =>
    if r.isPrimary then
      let r := r.noteStable
      let r := r.sendToOthers (.commit r.viewNumber r.commitNumber)
      r.resendPrepares r.viewNumber r.commitNumber
    else backupIdle r
  | .recovering => r.sendRecovery
  | .stateTransfer => backupIdle r.stateTransfer
  | .viewChange =>
    let (r, timedOut) := r.waitTimedOut
    if timedOut then startViewChange m r (r.viewNumber + 1)
    else if r.catchingUp then r.sendGetState r.commitNumber
    else
      let r := r.sendToOthers (.startViewChange r.viewNumber r.selfId)
      if r.doViewChangeSent then sendDoViewChange m r else r
where
  backupIdle (r : Replica Op Output St) : Replica Op Output St :=
    if r.heardFromPrimary then
      ({ r with heardFromPrimary := false, idlePeriodsWaiting := 0 } : Replica Op Output St).noteStable
    else
      let r : Replica Op Output St := { r with idlePeriodsStable := 0 }
      let (r, timedOut) := r.waitTimedOut
      if timedOut then startViewChange m r (r.viewNumber + 1) else r

end Replica

end Vsr
