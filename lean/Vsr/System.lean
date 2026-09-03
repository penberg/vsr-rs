import Vsr.Replica

/-!
The cluster: replicas indexed by id, and every message ever sent. Delivery
never removes a message from `sent`, so a message can arrive again, out of
order, or never, and a replica that is not stepped is a crashed one. That
one rule covers loss, delay, replay, reordering, and pauses.
-/

namespace Vsr

structure System (Op Output St : Type) where
  config : Config
  replicas : List (Replica Op Output St)
  sent : List (ReplicaId × Message Op)
  replies : List (Reply Output)

/-- One step of the cluster, chosen by the environment. -/
inductive Step (Op : Type)
  /-- Deliver the message at index `i` of `sent` to its destination. -/
  | deliver (i : Nat)
  /-- An idle period passes at replica `r`. -/
  | idle (r : ReplicaId)
  /-- A client request arrives at replica `to`. Clients are not modelled:
  any request may arrive anywhere, which covers everything a client does. -/
  | request (to : ReplicaId) (clientId : ClientId) (requestNumber : RequestNumber) (op : Op)
  /-- Replica `r` comes back from a crash with no memory but its view
  number, which the owner persisted. -/
  | recover (r : ReplicaId) (nonce : Nat)

namespace System

variable {Op Output St : Type}

def init (config : Config) (sm : St) : System Op Output St where
  config := config
  replicas := config.replicas.map fun id => Replica.new id config sm
  sent := []
  replies := []

/-- Puts replica `id` back after a step and takes what it wants sent. -/
def drain (s : System Op Output St) (id : ReplicaId) (r : Replica Op Output St) :
    System Op Output St :=
  { s with
    replicas := s.replicas.set id { r with outbox := [], replies := [] }
    sent := s.sent ++ r.outbox
    replies := s.replies ++ r.replies }

def withReplica (s : System Op Output St) (id : ReplicaId)
    (f : Replica Op Output St → Replica Op Output St) : System Op Output St :=
  match s.replicas[id]? with
  | none => s
  | some r => s.drain id (f r)

/-- `sm` is the state a recovered replica's state machine starts from. -/
def step (m : Machine Op Output St) (sm : St) (s : System Op Output St) : Step Op → System Op Output St
  | .deliver i =>
    match s.sent[i]? with
    | none => s
    | some (to, msg) => s.withReplica to fun r => Replica.onMessage m r msg
  | .idle id => s.withReplica id (Replica.onIdle m)
  | .request to clientId requestNumber op =>
    s.withReplica to fun r => Replica.onMessage m r (.request clientId requestNumber op)
  | .recover id nonce =>
    s.withReplica id fun r => Replica.recover id s.config sm r.viewNumber nonce

end System

end Vsr
