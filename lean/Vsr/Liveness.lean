import Vsr.Safety

/-!
Liveness. The safety theorems say nothing about whether the cluster gets
anywhere; a cluster that changes view forever satisfies all of them. To
say anything about progress the model needs time, so this file adds a
synchronous scheduler: rounds in which every replica gets an idle period
and every message in flight is delivered, with a one-round latency. It is
the simulator's order within a tick, and the order of `step` in
`tests/cluster.rs`.

The liveness property is that from any reachable state with a quorum of
replicas not recovering, the cluster settles on this scheduler: every
replica normal in the same view, and nothing in flight.

It is not proved in general. For one reachable state, the one the
regression test `test_view_change_does_not_start_the_next` builds, it is
proved by running the model in the kernel: see `storm`. Before the view
change backoff survived `enterNormal`, the same theorems refuted it: from
that state the model changed view every two rounds forever, in view 251
after 500 rounds, which is where the simulator and the Rust test found the
bug.
-/

namespace Vsr

/-- A cluster on a synchronous network: the replicas, and the messages in
flight, which arrive next round. -/
structure Sync (Op Output St : Type) where
  replicas : List (Replica Op Output St)
  queue : List (ReplicaId × Message Op)
deriving DecidableEq

namespace Sync

variable {Op Output St : Type} (m : Machine Op Output St)

def clear (r : Replica Op Output St) : Replica Op Output St := { r with outbox := [], replies := [] }

/-- Takes every outbox, in replica order, as the simulator's `flush` does. -/
def outboxes (replicas : List (Replica Op Output St)) : List (ReplicaId × Message Op) :=
  replicas.flatMap (·.outbox)

def deliver (replicas : List (Replica Op Output St)) (to : ReplicaId) (msg : Message Op) :
    List (Replica Op Output St) :=
  match replicas[to]? with
  | none => replicas
  | some r => replicas.set to (Replica.onMessage m r msg)

/-- One round: every replica gets an idle period, then everything in flight
and everything the idle periods sent is delivered, in that order, and what
those deliveries send is in flight for the next round. -/
def round (s : Sync Op Output St) : Sync Op Output St :=
  let idled := s.replicas.map (Replica.onIdle m)
  let due := s.queue ++ outboxes idled
  let replicas := due.foldl (fun rs (to, msg) => deliver m rs to msg) (idled.map clear)
  ⟨replicas.map clear, outboxes replicas⟩

def rounds : Nat → Sync Op Output St → Sync Op Output St
  | 0, s => s
  | n + 1, s => rounds n (round m s)

/-- Settled: every replica normal in the same view, nothing in flight. -/
def settled (s : Sync Op Output St) : Bool :=
  s.queue.isEmpty &&
  match s.replicas with
  | [] => true
  | r :: rest => rest.all fun o => o.status == .normal && o.viewNumber == r.viewNumber
      && r.status == .normal

/-- Whether some round among the next `n` is settled. -/
def settledWithin : Nat → Sync Op Output St → Bool
  | 0, _ => false
  | n + 1, s => settled s || settledWithin n (round m s)

/-- A cluster state as the synchronous network sees it: whatever was in
flight is lost, which the protocol must cope with. -/
def ofSystem (s : System Op Output St) : Sync Op Output St := ⟨s.replicas, []⟩

end Sync

/-- Liveness. On the synchronous network, from any reachable state in which
a quorum of the replicas is not recovering, the cluster settles.

Not proved. `Check.liveness` tests it, bounded, on every state the
conformance traces reach. `Storm.storm_settles` proves it for one state.
A proof needs the safety invariant, a ranking argument on the backoff,
and a bound on how long a view change takes on this scheduler. -/
theorem settles (m : Machine Op Output St) (sm : St) (config : Config) (s : System Op Output St)
    (h : Reachable m sm config s)
    (hquorum : config.quorum ≤ (s.replicas.filter fun r => r.status ≠ .recovering).length) :
    ∃ n, Sync.settled (Sync.rounds m n (Sync.ofSystem s)) = true := by
  sorry

/-! ### The storm, as the regression test builds it -/

namespace Storm

/-- The recorder state machine of the conformance test. -/
def recorder : Machine Nat Nat (List Nat) where
  apply s op := (s ++ [op], s.length + 1)

abbrev S := Sync Nat Nat (List Nat)

/-- Three replicas with a primary timeout of two idle periods, one request
committed everywhere. -/
def calm : S :=
  let s0 : S := Sync.ofSystem (System.init ⟨3, 2⟩ [])
  Sync.rounds recorder 4 { s0 with queue := [(0, .request 0 0 10)] }

/-- Replica 2 hears nothing from the primary for two idle periods and
starts a view change. -/
def storm : S :=
  match calm.replicas[2]? with
  | none => calm
  | some r =>
    let r := Replica.onIdle recorder (Replica.onIdle recorder (Replica.onIdle recorder r))
    { calm with replicas := calm.replicas.set 2 r }

/-- The set-up did what the test expects: one op committed on every
replica, all normal in view 0. -/
theorem calm_is_calm :
    calm.replicas.map (fun r => (r.status, r.viewNumber, r.commitNumber)) =
      [(.normal, 0, 1), (.normal, 0, 1), (.normal, 0, 1)] := by
  decide

theorem storm_started : (storm.replicas.map (·.status)) = [.normal, .normal, .viewChange] := by
  decide

/-- The cluster settles within eight rounds. -/
theorem storm_settles : Sync.settledWithin recorder 8 storm = true := by
  decide +kernel

/-- Where it settles: view 3, everyone normal, after two view changes
were cut short, and everyone's backoff has decayed again. -/
theorem storm_settled_in_view_3 :
    (Sync.rounds recorder 8 storm).replicas.map (fun r => (r.status, r.viewNumber, r.viewChangeAttempts)) =
      [(.normal, 3, 0), (.normal, 3, 0), (.normal, 3, 0)] := by
  decide +kernel

/-- And stays settled. -/
theorem storm_stays_settled : Sync.settled (Sync.rounds recorder 30 storm) = true := by
  decide +kernel

end Storm

end Vsr
