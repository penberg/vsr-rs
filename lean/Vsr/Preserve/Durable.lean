import Vsr.Preserve.Chosen

/-!
Durability from the invariant: every committed entry is held, at its
index, by enough non-recovering replicas to meet every quorum they could
form. The acknowledging quorum meets the non-recovering replicas in at
least `|R| + Q - N` of them, and each of those holds the entry.
-/

namespace Vsr

variable {Op Output St : Type}

/-- Two lists of distinct ids below `n` share at least `|X| + |Y| - n`
members. -/
theorem filter_mem_length {n : Nat} {X Y : List ReplicaId} (hX : X.Nodup) (hY : Y.Nodup)
    (hXn : ∀ x ∈ X, x < n) (hYn : ∀ y ∈ Y, y < n) :
    X.length + Y.length ≤ (X.filter (· ∈ Y)).length + n := by
  classical
  have hfilt : (X.filter (· ∈ Y)).toFinset = X.toFinset ∩ Y.toFinset := by
    ext z; simp [List.mem_filter, List.mem_toFinset]
  have h1 : (X.filter (· ∈ Y)).length = (X.toFinset ∩ Y.toFinset).card := by
    rw [← hfilt, List.toFinset_card_of_nodup (hX.filter _)]
  have h2 : (X.toFinset ∪ Y.toFinset).card ≤ n := by
    calc (X.toFinset ∪ Y.toFinset).card ≤ (Finset.range n).card := by
          apply Finset.card_le_card
          intro z hz
          rw [Finset.mem_union] at hz
          rw [Finset.mem_range]
          rcases hz with hz | hz
          · exact hXn z (List.mem_toFinset.mp hz)
          · exact hYn z (List.mem_toFinset.mp hz)
      _ = n := Finset.card_range n
  have h3 := Finset.card_union_add_card_inter X.toFinset Y.toFinset
  rw [List.toFinset_card_of_nodup hX, List.toFinset_card_of_nodup hY] at h3
  rw [h1]; omega

/-- The ids of the replicas, in order. -/
theorem Inv.replicas_map_selfId {s : System Op Output St} (hinv : Inv s) :
    s.replicas.map Replica.selfId = List.range s.replicas.length := by
  apply List.ext_getElem?
  intro i
  rw [List.getElem?_map]
  rcases h : s.replicas[i]? with _ | r
  · simp only [Option.map_none]
    have : ¬ i < s.replicas.length := fun hlt => by rw [List.getElem?_eq_getElem hlt] at h; exact Option.some_ne_none _ h
    symm
    rw [List.getElem?_eq_none_iff, List.length_range]
    exact Nat.le_of_not_lt this
  · simp only [Option.map_some]
    have hlt : i < s.replicas.length := (List.getElem?_eq_some_iff.mp h).1
    rw [(hinv.ids i r h).1, List.getElem?_range hlt]

/-- A non-recovering replica that acknowledged a committed entry's index
in its view holds the entry. -/
theorem Inv.holds_of_acked {s : System Op Output St} (hinv : Inv s) {v i : Nat} {e : LogEntry Op}
    (hc : Committed s v i e) {z : Replica Op Output St} (hz : z ∈ s.replicas) (hzn : z.status ≠ .recovering)
    (hack : Acked s v i z.selfId) : z.log[i]? = some e := by
  have hvle : v ≤ z.lastNormalView := by
    rcases hack with hp | ⟨dst, o, hs, _⟩
    · rcases Nat.eq_zero_or_pos v with hv0 | hpos
      · rw [hv0]; exact Nat.zero_le _
      · obtain ⟨off, log, hf, _, _⟩ := hc.1
        obtain ⟨dvcs, hst⟩ := hinv.startedViews.2.1 v off log hf hpos
        exact hinv.primaryStarted v dvcs hst z hz hp
    · exact (hinv.acksHold dst v o z.selfId hs z hz rfl).1
  rcases Nat.lt_or_eq_of_le hvle with hlt | heq
  · exact (hinv.survives v i e hc _ hlt).2.2.2.2.2 z hz rfl hzn
  · -- last normal in `v`: the log reaches `i` and agrees with the view
    have hlen : i < z.log.length := by
      rcases hack with hp | ⟨dst, o, hs, hio⟩
      · obtain ⟨off, log, hf, hoff, hget⟩ := hc.1
        have := (hinv.longest z hz hzn (heq ▸ hp)).1 off log (heq ▸ hf)
        have := (List.getElem?_eq_some_iff.mp hget).1
        omega
      · exact Nat.lt_of_lt_of_le hio ((hinv.acksHold dst v o z.selfId hs z hz rfl).2 heq.symm hzn)
    have hz' : z.log[i]? = some z.log[i] := List.getElem?_eq_getElem hlen
    rw [hz']; congr 1
    exact hinv.oneLog.2 z hz i _ e hz' (heq ▸ hc.1)

theorem Inv.durability [DecidableEq Op] {s : System Op Output St} (hinv : Inv s) : Durability s := by
  intro r hr i hi
  have hrmem : r ∈ s.replicas := (List.mem_filter.mp hr).1
  have hrn : r.status ≠ .recovering := by simpa using (List.mem_filter.mp hr).2
  obtain ⟨e, v', hget, _, hc, _⟩ := hinv.committed_entry hrmem hi
  obtain ⟨Q, hnd, hlen, hQ⟩ := hc.2
  set P := s.replicas.filter (fun o => o.status ≠ .recovering) with hP
  -- the acknowledgers among the participants hold the entry
  have hholds : ∀ z ∈ P, z.selfId ∈ Q → z.log[i]? = r.log[i]? := by
    intro z hz hzq
    have hz' := List.mem_filter.mp hz
    rw [hget]
    exact hinv.holds_of_acked hc hz'.1 (by simpa using hz'.2) (hQ z.selfId hzq).2
  -- counting
  have hPnd : (P.map Replica.selfId).Nodup := by
    have := hinv.replicas_map_selfId
    have hsub : P.Sublist s.replicas := List.filter_sublist
    exact List.nodup_range.sublist (this ▸ hsub.map Replica.selfId)
  have hPn : ∀ x ∈ P.map Replica.selfId, x < s.config.replicaCount := by
    intro x hx
    obtain ⟨z, hz, rfl⟩ := List.mem_map.mp hx
    exact hinv.selfId_lt (List.mem_filter.mp hz).1
  have hcount := filter_mem_length hPnd hnd hPn (fun q hq => (hQ q hq).1)
  have hmap : ((P.map Replica.selfId).filter (· ∈ Q)).length = (P.filter (fun z => z.selfId ∈ Q)).length := by
    rw [List.filter_map, List.length_map]; rfl
  have hle : (P.filter (fun z => z.selfId ∈ Q)).length ≤ (P.filter (fun o => o.log[i]? = r.log[i]?)).length := by
    rw [← List.countP_eq_length_filter, ← List.countP_eq_length_filter]
    exact List.countP_mono_left fun z hz h => by
      simp only [decide_eq_true_eq] at h ⊢
      exact hholds z hz h
  rw [List.length_map] at hcount
  have hq : s.config.quorum = s.config.replicaCount / 2 + 1 := rfl
  show P.length + 1 - s.config.quorum ≤ (P.filter (fun o => o.log[i]? = r.log[i]?)).length
  rw [hq]
  omega

end Vsr
