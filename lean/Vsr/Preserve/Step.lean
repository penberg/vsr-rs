import Vsr.Preserve.Idle
import Vsr.Preserve.Durable

/-!
Every step of the cluster preserves `Inv`, so every reachable cluster
satisfies it, and the safety theorem follows.
-/

namespace Vsr

variable {Op Output St : Type}

/-- Delivering any message to any replica. -/
theorem Inv.onMessage {s : System Op Output St} (hinv : Inv s) {id : ReplicaId} {r : Replica Op Output St}
    (hr : s.replicas[id]? = some r) (m : Machine Op Output St) {msg : Message Op} {dst : ReplicaId}
    (hsent : Sent s dst (msg)) (hto : dst = id) :
    Inv (s.drainOf id (Replica.onMessage m r msg)) := by
  have h0 := hinv.drainOf_start hr
  have hself : r.selfId = id := (hinv.ids id r hr).1
  subst hto
  unfold Replica.onMessage
  split
  · exact h0
  · rename_i hc
    have hn : Replica.isRecoveryResponse msg = false → r.status ≠ .recovering := fun hm hs => hc ⟨hs, hm⟩
    split
    · exact hinv.onRequest hr _ _ _ (hn rfl)
    · rename_i v o c n op k
      have := hinv.toOthers dst _ hsent
      exact hinv.onPrepare hr m (hn rfl) this hsent
    · exact hinv.onPrepareOk hr m hsent
    · rename_i v k
      have := hinv.toOthers dst _ hsent
      exact hinv.onCommit hr m v k (hn rfl) this (hinv.backed.2 dst _ hsent)
    · exact hinv.onGetState hr _ _ _
    · exact hinv.onNewState hr m (hn rfl) hsent
    · exact hinv.onStartViewChange hr m (hn rfl) hsent
    · rename_i v x l log o k
      split
      · rename_i hlen; exact absurd (hinv.wf _ hsent).1 hlen
      · exact hinv.onDoViewChange hr m (hn rfl) hsent
    · rename_i v log o k
      split
      · rename_i hlen; exact absurd (hinv.wf _ hsent).1 hlen
      · exact hinv.onStartView hr m (hn rfl) hsent
    · exact hinv.onRecovery hr m (hn rfl) hsent
    · exact hinv.onRecoveryResponse hr m hsent

/-- A client request, arriving anywhere. -/
theorem Inv.onRequestMsg {s : System Op Output St} (hinv : Inv s) {id : ReplicaId} {r : Replica Op Output St}
    (hr : s.replicas[id]? = some r) (m : Machine Op Output St) (c : ClientId) (n : RequestNumber) (op : Op) :
    Inv (s.drainOf id (Replica.onMessage m r (.request c n op))) := by
  have h0 := hinv.drainOf_start hr
  unfold Replica.onMessage
  split
  · exact h0
  · rename_i hc
    exact hinv.onRequest hr c n op (fun hs => hc ⟨hs, rfl⟩)

theorem Inv.withReplica {s : System Op Output St} (hinv : Inv s) (id : ReplicaId)
    (f : Replica Op Output St → Replica Op Output St)
    (hf : ∀ r, s.replicas[id]? = some r → Inv (s.drainOf id (f r))) : Inv (s.withReplica id f) := by
  unfold System.withReplica
  split
  · exact hinv
  · rename_i r hr
    exact (hf r hr).ofDrainOf

/-- Every step keeps the invariant. -/
theorem Inv.step {s : System Op Output St} (hinv : Inv s) (m : Machine Op Output St) (sm : St) :
    ∀ st : Step Op, (∀ id n, st = .recover id n → NonceFresh s n) → Inv (s.step m sm st) := by
  intro st hfresh
  cases st with
  | deliver i =>
    simp only [System.step]
    split
    · exact hinv
    · rename_i dst msg h
      have hsent : Sent s dst msg := List.mem_of_getElem? h
      exact hinv.withReplica dst _ (fun r hr => hinv.onMessage hr m hsent rfl)
  | idle id =>
    simp only [System.step]
    exact hinv.withReplica id _ (fun r hr => hinv.onIdle hr m)
  | request dst c n op =>
    simp only [System.step]
    exact hinv.withReplica dst _ (fun r hr => hinv.onRequestMsg hr m c n op)
  | recover id n =>
    simp only [System.step]
    exact hinv.withReplica id _ (fun r hr => hinv.recover hr sm n (hfresh id n rfl))

/-- The invariant holds in every reachable cluster of at least two
replicas. -/
theorem inv_of_reachable {m : Machine Op Output St} {sm : St} {config : Config}
    (htwo : 2 ≤ config.replicaCount) {s : System Op Output St} (h : Reachable m sm config s) : Inv s := by
  induction h with
  | init => exact Inv.init config sm htwo
  | deliver i _ ih => exact ih.step m sm _ (fun _ _ h => by cases h)
  | idle id _ ih => exact ih.step m sm _ (fun _ _ h => by cases h)
  | request dst c n op _ ih => exact ih.step m sm _ (fun _ _ h => by cases h)
  | recover id n _ hfresh ih => exact ih.step m sm _ (fun id' n' h => by cases h; exact hfresh)

/-- The main theorem: no replica panics, committed prefixes agree, and
committed entries are durable, in every reachable cluster of at least two
replicas. -/
theorem safety [DecidableEq Op] (m : Machine Op Output St) (sm : St) (config : Config)
    (htwo : 2 ≤ config.replicaCount) (s : System Op Output St) (h : Reachable m sm config s) :
    NoPanic s ∧ PrefixAgreement s ∧ Durability s :=
  let hinv := inv_of_reachable htwo h
  ⟨hinv.noPanic, hinv.prefixAgreement, hinv.durability⟩

end Vsr
