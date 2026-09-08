import Mathlib
import Vsr.Types

/-!
The quorum-intersection lemma: in a cluster of `n` replicas, where a quorum
is `n / 2 + 1`, any two quorums of distinct replica ids share a member.
This is the pigeonhole that carries committed data across view changes and
gives durability.
-/

namespace Vsr

/-- Two lists of distinct replica ids, each drawn from `0..n` and each at
least a quorum long, share an element. -/
theorem quorum_intersect {n : Nat} {A B : List ReplicaId} (hA : A.Nodup) (hB : B.Nodup)
    (hAn : ∀ x ∈ A, x < n) (hBn : ∀ x ∈ B, x < n)
    (hAlen : n / 2 + 1 ≤ A.length) (hBlen : n / 2 + 1 ≤ B.length) :
    ∃ q, q ∈ A ∧ q ∈ B := by
  classical
  set sA := A.toFinset with hsA
  set sB := B.toFinset with hsB
  have hcardA : sA.card = A.length := List.toFinset_card_of_nodup hA
  have hcardB : sB.card = B.length := List.toFinset_card_of_nodup hB
  have hsub : sA ∪ sB ⊆ Finset.range n := by
    intro x hx
    rw [Finset.mem_union] at hx
    rw [Finset.mem_range]
    rcases hx with hx | hx
    · exact hAn x (List.mem_toFinset.mp hx)
    · exact hBn x (List.mem_toFinset.mp hx)
  have hunion : (sA ∪ sB).card ≤ n := by
    calc (sA ∪ sB).card ≤ (Finset.range n).card := Finset.card_le_card hsub
      _ = n := Finset.card_range n
  have hie : (sA ∪ sB).card + (sA ∩ sB).card = sA.card + sB.card :=
    Finset.card_union_add_card_inter sA sB
  have hpos : 0 < (sA ∩ sB).card := by
    have h1 : n / 2 + 1 + (n / 2 + 1) ≤ sA.card + sB.card := by
      rw [hcardA, hcardB]; omega
    have h2 : n < n / 2 + 1 + (n / 2 + 1) := by omega
    omega
  obtain ⟨q, hq⟩ := Finset.card_pos.mp hpos
  rw [Finset.mem_inter] at hq
  exact ⟨q, List.mem_toFinset.mp hq.1, List.mem_toFinset.mp hq.2⟩

/-- The same, phrased with `Config`: two quorums of a config's replicas
intersect. -/
theorem Config.quorum_intersect (c : Config) {A B : List ReplicaId} (hA : A.Nodup) (hB : B.Nodup)
    (hAn : ∀ x ∈ A, x < c.replicaCount) (hBn : ∀ x ∈ B, x < c.replicaCount)
    (hAlen : c.quorum ≤ A.length) (hBlen : c.quorum ≤ B.length) :
    ∃ q, q ∈ A ∧ q ∈ B :=
  Vsr.quorum_intersect hA hB hAn hBn hAlen hBlen

end Vsr
