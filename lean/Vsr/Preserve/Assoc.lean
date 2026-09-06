import Vsr.Types

/-!
Membership in the association lists and sorted sets that stand in for the
Rust maps and sets.
-/

namespace Vsr

namespace Assoc

variable {α : Type}

theorem mem_insert : ∀ {l : List (Nat × α)} {k : Nat} {v : α} {x : Nat × α},
    x ∈ insert l k v → x = (k, v) ∨ x ∈ l
  | [], k, v, x, h => by simp [insert] at h; exact Or.inl h
  | (k', v') :: rest, k, v, x, h => by
    unfold insert at h
    split at h
    · rcases List.mem_cons.mp h with h | h
      · exact Or.inl h
      · exact Or.inr h
    · split at h
      · rcases List.mem_cons.mp h with h | h
        · exact Or.inl h
        · exact Or.inr (List.mem_cons_of_mem _ h)
      · rcases List.mem_cons.mp h with h | h
        · exact Or.inr (h ▸ List.mem_cons_self ..)
        · rcases mem_insert h with h | h
          · exact Or.inl h
          · exact Or.inr (List.mem_cons_of_mem _ h)

theorem mem_insert_self : ∀ (l : List (Nat × α)) (k : Nat) (v : α), (k, v) ∈ insert l k v
  | [], k, v => List.mem_singleton.mpr rfl
  | (k', v') :: rest, k, v => by
    unfold insert
    split
    · exact List.mem_cons_self ..
    · split
      · exact List.mem_cons_self ..
      · exact List.mem_cons_of_mem _ (mem_insert_self rest k v)

theorem mem_insert_of_ne : ∀ {l : List (Nat × α)} {k : Nat} {v : α} {x : Nat × α},
    x ∈ l → x.1 ≠ k → x ∈ insert l k v
  | [], k, v, x, h, _ => by simp at h
  | (k', v') :: rest, k, v, x, h, hne => by
    unfold insert
    split
    · exact List.mem_cons_of_mem _ h
    · split
      · rename_i heq
        rcases List.mem_cons.mp h with h | h
        · subst h; exact absurd heq.symm hne
        · exact List.mem_cons_of_mem _ h
      · rcases List.mem_cons.mp h with h | h
        · exact h ▸ List.mem_cons_self ..
        · exact List.mem_cons_of_mem _ (mem_insert_of_ne h hne)

theorem lookup_some_mem : ∀ {l : List (Nat × α)} {k : Nat} {v : α}, lookup l k = some v → (k, v) ∈ l
  | [], k, v, h => by simp [lookup] at h
  | (k', v') :: rest, k, v, h => by
    unfold lookup at h
    split at h
    · rename_i heq; subst heq; exact (Option.some.inj h) ▸ List.mem_cons_self ..
    · exact List.mem_cons_of_mem _ (lookup_some_mem h)

theorem lookup_insert_self : ∀ (l : List (Nat × α)) (k : Nat) (v : α), lookup (insert l k v) k = some v
  | [], k, v => by simp [insert, lookup]
  | (k', v') :: rest, k, v => by
    unfold insert
    split
    · simp [lookup]
    · split
      · simp [lookup]
      · rename_i h1 h2
        unfold lookup
        rw [if_neg (Ne.symm (fun h => h2 h.symm)), lookup_insert_self rest k v]

theorem mem_update {l : List (Nat × α)} {k : Nat} {f : α → α} {x : Nat × α} (h : x ∈ update l k f) :
    ∃ v0, (x.1, v0) ∈ l ∧ (k = x.1 → x.2 = f v0) ∧ (k ≠ x.1 → x.2 = v0) := by
  unfold update at h
  obtain ⟨⟨k', v⟩, hmem, heq⟩ := List.mem_map.mp h
  simp only at heq
  split at heq
  · rename_i hk; subst heq; exact ⟨v, hmem, fun _ => rfl, fun hne => absurd hk hne⟩
  · rename_i hk; subst heq; exact ⟨v, hmem, fun h => absurd h hk, fun _ => rfl⟩

theorem length_insert_le : ∀ (l : List (Nat × α)) (k : Nat) (v : α), (insert l k v).length ≤ l.length + 1
  | [], k, v => by simp [insert]
  | (k', v') :: rest, k, v => by
    unfold insert
    split
    · simp
    · split
      · simp
      · simp only [List.length_cons]
        exact Nat.succ_le_succ (length_insert_le rest k v)

/-- The keys of an insert: the key inserted and the old ones. -/
theorem mem_insert_keys : ∀ {l : List (Nat × α)} {k : Nat} {v : α} {k' : Nat},
    (∃ w, (k', w) ∈ insert l k v) → k' = k ∨ ∃ w, (k', w) ∈ l
  | l, k, v, k', ⟨w, h⟩ => by
    rcases mem_insert h with h | h
    · exact Or.inl (Prod.mk.inj h).1
    · exact Or.inr ⟨w, h⟩

end Assoc

namespace NatSet

theorem mem_insert : ∀ {l : List Nat} {k q : Nat}, q ∈ (insert l k).1 → q ∈ l ∨ q = k
  | [], k, q, h => by simp [insert] at h; exact Or.inr h
  | k' :: rest, k, q, h => by
    unfold insert at h
    split at h
    · rcases List.mem_cons.mp h with h | h
      · exact Or.inr h
      · exact Or.inl h
    · split at h
      · exact Or.inl h
      · simp only at h
        rcases List.mem_cons.mp h with h | h
        · exact Or.inl (h ▸ List.mem_cons_self ..)
        · rcases mem_insert h with h | h
          · exact Or.inl (List.mem_cons_of_mem _ h)
          · exact Or.inr h

theorem mem_insert_of_mem : ∀ {l : List Nat} {k q : Nat}, q ∈ l → q ∈ (insert l k).1
  | [], k, q, h => by simp at h
  | k' :: rest, k, q, h => by
    unfold insert
    split
    · exact List.mem_cons_of_mem _ h
    · split
      · exact h
      · simp only
        rcases List.mem_cons.mp h with h | h
        · exact h ▸ List.mem_cons_self ..
        · exact List.mem_cons_of_mem _ (mem_insert_of_mem h)

theorem mem_insert_self : ∀ (l : List Nat) (k : Nat), k ∈ (insert l k).1
  | [], k => List.mem_singleton.mpr rfl
  | k' :: rest, k => by
    unfold insert
    split
    · exact List.mem_cons_self ..
    · split
      · rename_i h; exact h ▸ List.mem_cons_self ..
      · exact List.mem_cons_of_mem _ (mem_insert_self rest k)

/-- On a sorted list, the insert is sorted. -/
theorem insert_sorted : ∀ {l : List Nat} (k : Nat), l.Pairwise (· < ·) → (insert l k).1.Pairwise (· < ·)
  | [], k, _ => List.pairwise_singleton _ _
  | k' :: rest, k, h => by
    unfold insert
    obtain ⟨hhead, hrest⟩ := List.pairwise_cons.mp h
    split
    · rename_i hlt
      exact List.pairwise_cons.mpr ⟨fun q hq => by
        rcases List.mem_cons.mp hq with rfl | hq
        · exact hlt
        · exact Nat.lt_trans hlt (hhead q hq), h⟩
    · split
      · exact h
      · rename_i h1 h2
        simp only
        refine List.pairwise_cons.mpr ⟨fun q hq => ?_, insert_sorted k hrest⟩
        rcases mem_insert hq with hq | rfl
        · exact hhead q hq
        · exact Nat.lt_of_le_of_ne (Nat.le_of_not_lt h1) (fun h => h2 h.symm)

/-- On a sorted list, `fresh` says the element was absent. -/
theorem insert_fresh : ∀ {l : List Nat} (k : Nat), l.Pairwise (· < ·) → (insert l k).2 = true → k ∉ l
  | [], k, _, _ => by simp
  | k' :: rest, k, h, hf => by
    unfold insert at hf
    obtain ⟨hhead, hrest⟩ := List.pairwise_cons.mp h
    split at hf
    · rename_i hlt
      intro hk
      rcases List.mem_cons.mp hk with rfl | hk
      · exact Nat.lt_irrefl _ hlt
      · exact Nat.lt_irrefl _ (Nat.lt_trans hlt (hhead k hk))
    · split at hf
      · simp at hf
      · rename_i h1 h2
        simp only at hf
        intro hk
        rcases List.mem_cons.mp hk with rfl | hk
        · exact h2 rfl
        · exact insert_fresh k hrest hf hk

theorem insert_length_of_fresh : ∀ {l : List Nat} (k : Nat), (insert l k).2 = true →
    (insert l k).1.length = l.length + 1
  | [], k, _ => rfl
  | k' :: rest, k, hf => by
    unfold insert at hf ⊢
    by_cases h1 : k < k'
    · simp [h1]
    · by_cases h2 : k = k'
      · simp [h2] at hf
      · simp only [if_neg h1, if_neg h2] at hf ⊢
        rw [List.length_cons, insert_length_of_fresh k hf, List.length_cons]

end NatSet

end Vsr
