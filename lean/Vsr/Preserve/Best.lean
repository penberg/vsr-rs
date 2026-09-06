import Vsr.Replica

/-!
What `bestDoViewChange` picks: one of the DoViewChanges, and one whose key,
`(last normal view, log length)`, is at least every other's.
-/

namespace Vsr

variable {Op : Type}

theorem keyGe_iff (a b : Nat × Nat) : Replica.keyGe a b = true ↔ b.1 < a.1 ∨ (a.1 = b.1 ∧ b.2 ≤ a.2) := by
  unfold Replica.keyGe
  simp only [Bool.or_eq_true, decide_eq_true_eq, Bool.and_eq_true, gt_iff_lt, ge_iff_le]

theorem keyGe_refl (a : Nat × Nat) : Replica.keyGe a a = true :=
  (keyGe_iff a a).mpr (Or.inr ⟨rfl, Nat.le_refl _⟩)

theorem keyGe_trans {a b c : Nat × Nat} (h1 : Replica.keyGe a b = true) (h2 : Replica.keyGe b c = true) :
    Replica.keyGe a c = true := by
  rw [keyGe_iff] at h1 h2 ⊢
  rcases h1 with h1 | ⟨h1, h1'⟩ <;> rcases h2 with h2 | ⟨h2, h2'⟩
  · exact Or.inl (Nat.lt_trans h2 h1)
  · exact Or.inl (h2 ▸ h1)
  · exact Or.inl (h1 ▸ h2)
  · exact Or.inr ⟨h1.trans h2, Nat.le_trans h2' h1'⟩

theorem keyGe_total (a b : Nat × Nat) : Replica.keyGe a b = true ∨ Replica.keyGe b a = true := by
  rw [keyGe_iff, keyGe_iff]
  rcases Nat.lt_trichotomy a.1 b.1 with h | h | h
  · exact Or.inr (Or.inl h)
  · rcases Nat.le_total b.2 a.2 with h' | h'
    · exact Or.inl (Or.inr ⟨h, h'⟩)
    · exact Or.inr (Or.inr ⟨h.symm, h'⟩)
  · exact Or.inl (Or.inl h)

/-- The fold of `bestDoViewChange` from an accumulator. -/
private def bestFrom (acc : Option (DoViewChange Op)) (dvcs : List (ReplicaId × DoViewChange Op)) :
    Option (DoViewChange Op) :=
  dvcs.foldl (fun best (_, v) =>
    match best with
    | none => some v
    | some b => if Replica.keyGe (Replica.doViewChangeKey v) (Replica.doViewChangeKey b) then some v else some b) acc

private theorem bestFrom_eq (dvcs : List (ReplicaId × DoViewChange Op)) :
    Replica.bestDoViewChange dvcs = bestFrom none dvcs := rfl

private theorem bestFrom_some : ∀ (dvcs : List (ReplicaId × DoViewChange Op)) (b0 : DoViewChange Op),
    ∃ b, bestFrom (some b0) dvcs = some b ∧
      (b = b0 ∨ ∃ x, (x, b) ∈ dvcs) ∧
      Replica.keyGe (Replica.doViewChangeKey b) (Replica.doViewChangeKey b0) = true ∧
      ∀ x d, (x, d) ∈ dvcs → Replica.keyGe (Replica.doViewChangeKey b) (Replica.doViewChangeKey d) = true
  | [], b0 => ⟨b0, rfl, Or.inl rfl, keyGe_refl _, fun _ _ h => by simp at h⟩
  | (x, d) :: rest, b0 => by
    simp only [bestFrom, List.foldl_cons]
    split
    · rename_i hge
      obtain ⟨b, hb, hmem, hkey, hall⟩ := bestFrom_some rest d
      refine ⟨b, hb, ?_, keyGe_trans hkey hge, fun y d' hy => ?_⟩
      · rcases hmem with rfl | ⟨y, hy⟩
        · exact Or.inr ⟨x, List.mem_cons_self ..⟩
        · exact Or.inr ⟨y, List.mem_cons_of_mem _ hy⟩
      · rcases List.mem_cons.mp hy with h | h
        · obtain ⟨rfl, rfl⟩ := Prod.mk.inj h
          exact hkey
        · exact hall y d' h
    · rename_i hnge
      obtain ⟨b, hb, hmem, hkey, hall⟩ := bestFrom_some rest b0
      refine ⟨b, hb, ?_, hkey, fun y d' hy => ?_⟩
      · rcases hmem with rfl | ⟨y, hy⟩
        · exact Or.inl rfl
        · exact Or.inr ⟨y, List.mem_cons_of_mem _ hy⟩
      · rcases List.mem_cons.mp hy with h | h
        · obtain ⟨rfl, rfl⟩ := Prod.mk.inj h
          have : Replica.keyGe (Replica.doViewChangeKey b0) (Replica.doViewChangeKey d') = true := by
            rcases keyGe_total (Replica.doViewChangeKey d') (Replica.doViewChangeKey b0) with h | h
            · exact absurd h hnge
            · exact h
          exact keyGe_trans hkey this
        · exact hall y d' h

/-- The best of a nonempty list exists, is one of them, and is at least
each of them by key. -/
theorem bestDoViewChange_spec {dvcs : List (ReplicaId × DoViewChange Op)} (hne : dvcs ≠ []) :
    ∃ b, Replica.bestDoViewChange dvcs = some b ∧ (∃ x, (x, b) ∈ dvcs) ∧
      ∀ x d, (x, d) ∈ dvcs → Replica.keyGe (Replica.doViewChangeKey b) (Replica.doViewChangeKey d) = true := by
  match dvcs, hne with
  | (x, d) :: rest, _ =>
    rw [bestFrom_eq]
    simp only [bestFrom, List.foldl_cons]
    obtain ⟨b, hb, hmem, hkey, hall⟩ := bestFrom_some rest d
    refine ⟨b, hb, ?_, fun y d' hy => ?_⟩
    · rcases hmem with rfl | ⟨y, hy⟩
      · exact ⟨x, List.mem_cons_self ..⟩
      · exact ⟨y, List.mem_cons_of_mem _ hy⟩
    · rcases List.mem_cons.mp hy with h | h
      · obtain ⟨rfl, rfl⟩ := Prod.mk.inj h
        exact hkey
      · exact hall y d' h

theorem bestDoViewChange_mem {dvcs : List (ReplicaId × DoViewChange Op)} {b : DoViewChange Op}
    (h : Replica.bestDoViewChange dvcs = some b) : ∃ x, (x, b) ∈ dvcs := by
  rcases dvcs with _ | ⟨y, rest⟩
  · simp [Replica.bestDoViewChange] at h
  · obtain ⟨b', hb', hmem, _⟩ := bestDoViewChange_spec (List.cons_ne_nil y rest)
    rw [h] at hb'; obtain rfl := Option.some.inj hb'
    exact hmem

theorem bestDoViewChange_ge {dvcs : List (ReplicaId × DoViewChange Op)} {b : DoViewChange Op}
    (h : Replica.bestDoViewChange dvcs = some b) {x : ReplicaId} {d : DoViewChange Op} (hd : (x, d) ∈ dvcs) :
    Replica.keyGe (Replica.doViewChangeKey b) (Replica.doViewChangeKey d) = true := by
  rcases dvcs with _ | ⟨y, rest⟩
  · simp at hd
  · obtain ⟨b', hb', _, hall⟩ := bestDoViewChange_spec (List.cons_ne_nil y rest)
    rw [h] at hb'; obtain rfl := Option.some.inj hb'
    exact hall x d hd

/-- What "at least by key" says: a later last normal view, or the same and
a log at least as long. -/
theorem bestDoViewChange_ge' {dvcs : List (ReplicaId × DoViewChange Op)} {b : DoViewChange Op}
    (h : Replica.bestDoViewChange dvcs = some b) {x : ReplicaId} {d : DoViewChange Op} (hd : (x, d) ∈ dvcs) :
    d.lastNormalView < b.lastNormalView ∨
      (b.lastNormalView = d.lastNormalView ∧ d.log.length ≤ b.log.length) :=
  (keyGe_iff _ _).mp (bestDoViewChange_ge h hd)

theorem bestDoViewChange_none {dvcs : List (ReplicaId × DoViewChange Op)}
    (h : Replica.bestDoViewChange dvcs = none) : dvcs = [] := by
  rcases dvcs with _ | ⟨y, rest⟩
  · rfl
  · obtain ⟨b', hb', _⟩ := bestDoViewChange_spec (List.cons_ne_nil y rest)
    rw [h] at hb'; exact absurd hb' (by simp)

end Vsr
