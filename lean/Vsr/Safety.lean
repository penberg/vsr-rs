import Vsr.System
import Vsr.Local
import Vsr.WellFormed

/-!
The safety properties, stated over reachable systems. They are the
simulator's, from `simulator/properties.rs`.

This file proves `CommitBounded` and the well-formedness of every sent
message from the per-replica invariant in `Vsr.Local`. The main theorem,
`Vsr.safety` (no panic, prefix agreement, durability), is proved in
`Vsr.Preserve.Step` from the inductive invariant `Vsr.Inv`.
-/

namespace Vsr

variable {Op Output St : Type}

/-- A nonce no `Recovery` has carried yet. The owner of a replica picks
the nonce when it restarts the replica, and the protocol needs it fresh:
this is the paper's "fresh nonce", an assumption on the environment, like
the persisted view number. -/
def NonceFresh (s : System Op Output St) (nonce : Nat) : Prop :=
  ∀ to i v, (to, Message.recovery i nonce v) ∉ s.sent

/-- The systems the cluster can get into from a fresh start. A recover
step must use a fresh nonce. -/
inductive Reachable (m : Machine Op Output St) (sm : St) (config : Config) :
    System Op Output St → Prop
  | init : Reachable m sm config (System.init config sm)
  | deliver {s : System Op Output St} (i : Nat) :
      Reachable m sm config s → Reachable m sm config (s.step m sm (.deliver i))
  | idle {s : System Op Output St} (id : ReplicaId) :
      Reachable m sm config s → Reachable m sm config (s.step m sm (.idle id))
  | request {s : System Op Output St} (to : ReplicaId) (c : ClientId) (n : RequestNumber) (op : Op) :
      Reachable m sm config s → Reachable m sm config (s.step m sm (.request to c n op))
  | recover {s : System Op Output St} (id : ReplicaId) (nonce : Nat) :
      Reachable m sm config s → NonceFresh s nonce →
      Reachable m sm config (s.step m sm (.recover id nonce))

/-- No Rust `assert!` fires: every handler's precondition holds. -/
def NoPanic (s : System Op Output St) : Prop :=
  ∀ r ∈ s.replicas, r.panicked = false

/-- A replica's commit number never exceeds its log length. -/
def CommitBounded (s : System Op Output St) : Prop :=
  ∀ r ∈ s.replicas, r.commitNumber ≤ r.log.length

/-- Two replicas that have both committed index `i` hold the same entry. -/
def PrefixAgreement (s : System Op Output St) : Prop :=
  ∀ a ∈ s.replicas, ∀ b ∈ s.replicas, ∀ i,
    i < a.commitNumber → i < b.commitNumber → a.log[i]? = b.log[i]?

/-- Every committed entry survives any view change: every quorum the
replicas that are not recovering could form includes one that holds it at
its index. A recovering replica holds nothing and takes part in no quorum, so it
counts on neither side. With nobody recovering this is a majority. This is
`Durability` in `simulator/properties.rs`. -/
def Durability [DecidableEq Op] (s : System Op Output St) : Prop :=
  let participants := s.replicas.filter fun o => o.status ≠ .recovering
  ∀ r ∈ participants, ∀ i, i < r.commitNumber →
    participants.length + 1 - s.config.quorum ≤ (participants.filter fun o => o.log[i]? = r.log[i]?).length

/-! ### The local invariant lifted to the system -/

/-- Every replica satisfies the per-replica invariant. -/
def AllLocal (s : System Op Output St) : Prop :=
  ∀ r ∈ s.replicas, Replica.LocalInv r

theorem mem_set_or {α : Type} : ∀ {l : List α} {i : Nat} {y x : α}, x ∈ l.set i y → x ∈ l ∨ x = y
  | [], _, _, _, h => by simp at h
  | a :: l, 0, y, x, h => by
    simp only [List.set_cons_zero, List.mem_cons] at h
    rcases h with h | h
    · exact Or.inr h
    · exact Or.inl (List.mem_cons_of_mem a h)
  | a :: l, i + 1, y, x, h => by
    simp only [List.set_cons_succ, List.mem_cons] at h
    rcases h with h | h
    · exact Or.inl (by simp [h])
    · rcases mem_set_or h with h | h
      · exact Or.inl (List.mem_cons_of_mem a h)
      · exact Or.inr h

theorem AllLocal.init (config : Config) (sm : St) :
    AllLocal (System.init config sm : System Op Output St) := by
  intro r hr
  simp only [System.init, List.mem_map] at hr
  obtain ⟨id, _, rfl⟩ := hr
  exact Replica.LocalInv.new id config sm

theorem AllLocal.drain {s : System Op Output St} (hs : AllLocal s) (id : ReplicaId)
    {r' : Replica Op Output St} (hr' : Replica.LocalInv r') : AllLocal (s.drain id r') := by
  intro r hr
  simp only [System.drain] at hr
  rcases mem_set_or hr with hr | rfl
  · exact hs r hr
  · simpa [Replica.LocalInv] using hr'

theorem AllLocal.withReplica {s : System Op Output St} (hs : AllLocal s) (id : ReplicaId)
    (f : Replica Op Output St → Replica Op Output St)
    (hf : ∀ r, Replica.LocalInv r → Replica.LocalInv (f r)) : AllLocal (s.withReplica id f) := by
  unfold System.withReplica
  split
  · exact hs
  · rename_i r hr
    exact hs.drain id (hf r (hs r (List.mem_of_getElem? hr)))

theorem AllLocal.step (m : Machine Op Output St) (sm : St) {s : System Op Output St}
    (hs : AllLocal s) (st : Step Op) : AllLocal (s.step m sm st) := by
  cases st with
  | deliver i =>
    simp only [System.step]
    split
    · exact hs
    · exact hs.withReplica _ _ (fun _ h => Replica.LocalInv.onMessage m h _)
  | idle id =>
    simp only [System.step]
    exact hs.withReplica _ _ (fun _ h => Replica.LocalInv.onIdle m h)
  | request to c n op =>
    simp only [System.step]
    exact hs.withReplica _ _ (fun _ h => Replica.LocalInv.onMessage m h _)
  | recover id nonce =>
    simp only [System.step]
    exact hs.withReplica _ _ (fun _ _ => Replica.LocalInv.recover _ _ _ _ _)

theorem allLocal_of_reachable {m : Machine Op Output St} {sm : St} {config : Config}
    {s : System Op Output St} (h : Reachable m sm config s) : AllLocal s := by
  induction h with
  | init => exact AllLocal.init _ _
  | deliver _ _ ih => exact ih.step _ _ _
  | idle _ _ ih => exact ih.step _ _ _
  | request _ _ _ _ _ ih => exact ih.step _ _ _
  | recover _ _ _ _ ih => exact ih.step _ _ _

/-! ### Well-formed messages lifted to the system -/

/-- Every message ever sent is well formed. -/
def SentWF (s : System Op Output St) : Prop := ∀ x ∈ s.sent, WF x.2

/-- Between steps every outbox is empty: `drain` took it. -/
def Drained (s : System Op Output St) : Prop := ∀ r ∈ s.replicas, r.outbox = []

theorem SentWF.init (config : Config) (sm : St) : SentWF (System.init config sm : System Op Output St) := by
  intro x hx; simp [System.init] at hx

theorem Drained.init (config : Config) (sm : St) : Drained (System.init config sm : System Op Output St) := by
  intro r hr
  simp only [System.init, List.mem_map] at hr
  obtain ⟨id, _, rfl⟩ := hr
  rfl

theorem Drained.drain {s : System Op Output St} (hd : Drained s) (id : ReplicaId)
    (r' : Replica Op Output St) : Drained (s.drain id r') := by
  intro r hr
  simp only [System.drain] at hr
  rcases mem_set_or hr with hr | rfl
  · exact hd r hr
  · rfl

theorem SentWF.drain {s : System Op Output St} (hw : SentWF s) (id : ReplicaId)
    {r' : Replica Op Output St} (ho : Replica.OutboxWF r') : SentWF (s.drain id r') := by
  intro x hx
  simp only [System.drain, List.mem_append] at hx
  rcases hx with hx | hx
  · exact hw x hx
  · exact ho x hx

theorem SentWF.withReplica {s : System Op Output St} (hl : AllLocal s) (hd : Drained s) (hw : SentWF s)
    (id : ReplicaId) (f : Replica Op Output St → Replica Op Output St)
    (hf : ∀ r, Replica.LocalInv r → Replica.OutboxWF r → Replica.OutboxWF (f r)) :
    SentWF (s.withReplica id f) ∧ Drained (s.withReplica id f) := by
  unfold System.withReplica
  split
  · exact ⟨hw, hd⟩
  · rename_i r hr
    have hmem := List.mem_of_getElem? hr
    have ho : Replica.OutboxWF r := by
      intro x hx; rw [hd r hmem] at hx; simp at hx
    exact ⟨hw.drain id (hf r (hl r hmem) ho), hd.drain id _⟩

theorem SentWF.step (m : Machine Op Output St) (sm : St) {s : System Op Output St}
    (hl : AllLocal s) (hd : Drained s) (hw : SentWF s) (st : Step Op) :
    SentWF (s.step m sm st) ∧ Drained (s.step m sm st) := by
  cases st with
  | deliver i =>
    simp only [System.step]
    split
    · exact ⟨hw, hd⟩
    · exact SentWF.withReplica hl hd hw _ _ (fun _ h ho => Replica.OutboxWF.onMessage m h ho _)
  | idle id =>
    simp only [System.step]
    exact SentWF.withReplica hl hd hw _ _ (fun _ h ho => Replica.OutboxWF.onIdle m h ho)
  | request to c n op =>
    simp only [System.step]
    exact SentWF.withReplica hl hd hw _ _ (fun _ h ho => Replica.OutboxWF.onMessage m h ho _)
  | recover id nonce =>
    simp only [System.step]
    exact SentWF.withReplica hl hd hw _ _ (fun _ _ _ => Replica.OutboxWF.recover _ _ _ _ _)

/-- Proved: in every reachable state, every message ever sent is well
formed. -/
theorem sentWF_of_reachable {m : Machine Op Output St} {sm : St} {config : Config}
    {s : System Op Output St} (h : Reachable m sm config s) : SentWF s := by
  suffices SentWF s ∧ Drained s from this.1
  induction h with
  | init => exact ⟨SentWF.init _ _, Drained.init _ _⟩
  | deliver _ hr ih => exact SentWF.step _ _ (allLocal_of_reachable hr) ih.2 ih.1 _
  | idle _ hr ih => exact SentWF.step _ _ (allLocal_of_reachable hr) ih.2 ih.1 _
  | request _ _ _ _ hr ih => exact SentWF.step _ _ (allLocal_of_reachable hr) ih.2 ih.1 _
  | recover _ _ hr _ ih => exact SentWF.step _ _ (allLocal_of_reachable hr) ih.2 ih.1 _

/-- Proved: in every reachable state, every replica's commit number is
within its log. -/
theorem commitBounded_of_reachable {m : Machine Op Output St} {sm : St} {config : Config}
    {s : System Op Output St} (h : Reachable m sm config s) : CommitBounded s :=
  fun r hr => ((allLocal_of_reachable h) r hr).1

end Vsr
