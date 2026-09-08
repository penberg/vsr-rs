/-!
The types of the protocol, as in `lib.rs`: identifiers, the configuration,
log entries, replies, and the messages.
-/

namespace Vsr

abbrev ClientId := Nat
abbrev ReplicaId := Nat
abbrev ViewNumber := Nat
abbrev OpNumber := Nat
abbrev CommitNumber := Nat
abbrev RequestNumber := Nat

/-- `Config` in the Rust. Replica ids are `0..replicaCount`, so the list of
replicas is implied by its length. -/
structure Config where
  replicaCount : Nat
  primaryTimeout : Nat
deriving Repr, DecidableEq

namespace Config

def primaryId (c : Config) (v : ViewNumber) : ReplicaId := v % c.replicaCount

def quorum (c : Config) : Nat := c.replicaCount / 2 + 1

def replicas (c : Config) : List ReplicaId := List.range c.replicaCount

end Config

structure LogEntry (Op : Type) where
  clientId : ClientId
  requestNumber : RequestNumber
  op : Op
deriving Repr, DecidableEq

structure Reply (Output : Type) where
  viewNumber : ViewNumber
  clientId : ClientId
  requestNumber : RequestNumber
  result : Output
deriving Repr, DecidableEq

structure RecoveryState (Op : Type) where
  log : List (LogEntry Op)
  commitNumber : CommitNumber
deriving Repr, DecidableEq

/-- `Message` in the Rust, variant for variant, field for field. -/
inductive Message (Op : Type)
  | request (clientId : ClientId) (requestNumber : RequestNumber) (op : Op)
  | prepare (viewNumber : ViewNumber) (opNumber : OpNumber) (clientId : ClientId)
      (requestNumber : RequestNumber) (op : Op) (commitNumber : CommitNumber)
  | prepareOk (viewNumber : ViewNumber) (opNumber : OpNumber) (replicaId : ReplicaId)
  | commit (viewNumber : ViewNumber) (commitNumber : CommitNumber)
  | getState (replicaId : ReplicaId) (viewNumber : ViewNumber) (opNumber : OpNumber)
  | newState (viewNumber : ViewNumber) (log : List (LogEntry Op)) (opNumberStart : OpNumber)
      (opNumberEnd : OpNumber) (commitNumber : CommitNumber)
  | startViewChange (viewNumber : ViewNumber) (replicaId : ReplicaId)
  | doViewChange (viewNumber : ViewNumber) (replicaId : ReplicaId) (lastNormalView : ViewNumber)
      (log : List (LogEntry Op)) (opNumber : OpNumber) (commitNumber : CommitNumber)
  | startView (viewNumber : ViewNumber) (log : List (LogEntry Op)) (opNumber : OpNumber)
      (commitNumber : CommitNumber)
  | recovery (replicaId : ReplicaId) (nonce : Nat) (viewNumber : ViewNumber)
  | recoveryResponse (viewNumber : ViewNumber) (nonce : Nat) (replicaId : ReplicaId)
      (state : Option (RecoveryState Op))
deriving Repr, DecidableEq

inductive Status
  | normal
  | stateTransfer
  | recovering
  | viewChange
deriving Repr, DecidableEq

/-- The replicated state machine: `StateMachine` in the Rust, as a pure
function on an explicit state. -/
structure Machine (Op Output St : Type) where
  apply : St → Op → St × Output

/-! Sorted association lists keyed by naturals stand in for the Rust
replica's `BTreeMap`s. Sorted so that iteration order matches the Rust,
which matters where the Rust picks the last of several equal maxima. -/
namespace Assoc

def insert {α : Type} : List (Nat × α) → Nat → α → List (Nat × α)
  | [], k, v => [(k, v)]
  | (k', v') :: rest, k, v =>
    if k < k' then (k, v) :: (k', v') :: rest
    else if k = k' then (k, v) :: rest
    else (k', v') :: insert rest k v

def lookup {α : Type} : List (Nat × α) → Nat → Option α
  | [], _ => none
  | (k', v') :: rest, k => if k = k' then some v' else lookup rest k

def update {α : Type} (l : List (Nat × α)) (k : Nat) (f : α → α) : List (Nat × α) :=
  l.map fun (k', v) => if k = k' then (k', f v) else (k', v)

end Assoc

/-! Sorted lists of naturals stand in for the `BTreeSet`s. -/
namespace NatSet

/-- Inserts `k`, and says whether it was new, like `BTreeSet::insert`. -/
def insert : List Nat → Nat → List Nat × Bool
  | [], k => ([k], true)
  | k' :: rest, k =>
    if k < k' then (k :: k' :: rest, true)
    else if k = k' then (k' :: rest, false)
    else
      let (rest', fresh) := insert rest k
      (k' :: rest', fresh)

end NatSet

end Vsr
