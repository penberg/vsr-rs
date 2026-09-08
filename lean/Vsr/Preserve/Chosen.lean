import Vsr.Preserve.Shapes
import Vsr.Preserve.Best
import Vsr.Quorum

/-!
The chosen log survives: the best of a quorum of DoViewChanges for view `u`
holds whatever a quorum acknowledged in an earlier view. This is the
quorum-intersection argument of the paper, `Inv.bestHolds`, and from it,
by strong induction on the view, that a newly completed acknowledgement
quorum is held by everything of every later view, `Inv.viewHolds_of_newAck`.
Some small consequences of `Inv` used throughout come first.
-/

namespace Vsr

variable {Op Output St : Type}

/-! ### Small consequences of `Inv` -/

section Facts
variable {s : System Op Output St} (hinv : Inv s)
include hinv

/-- Two replicas with the same id are the same replica. -/
theorem Inv.eq_of_selfId {z r : Replica Op Output St} (hz : z ∈ s.replicas) (hr : r ∈ s.replicas)
    (h : z.selfId = r.selfId) : z = r := by
  obtain ⟨i, hi⟩ := List.mem_iff_getElem?.mp hz
  obtain ⟨j, hj⟩ := List.mem_iff_getElem?.mp hr
  have hzi := (hinv.ids i z hi).1
  have hrj := (hinv.ids j r hj).1
  have : i = j := by rw [← hzi, ← hrj]; exact h
  subst this
  rw [hi] at hj; exact Option.some.inj hj

theorem Inv.selfId_lt {r : Replica Op Output St} (hr : r ∈ s.replicas) : r.selfId < s.config.replicaCount := by
  obtain ⟨i, hi⟩ := List.mem_iff_getElem?.mp hr
  rw [(hinv.ids i r hi).1, ← hinv.count]
  exact (List.getElem?_eq_some_iff.mp hi).1

theorem Inv.replicaCount_pos : 0 < s.config.replicaCount := Nat.lt_of_lt_of_le (by decide) hinv.two

theorem Inv.primaryId_lt (v : ViewNumber) : s.config.primaryId v < s.config.replicaCount :=
  Nat.mod_lt _ hinv.replicaCount_pos

theorem Inv.config_eq {r : Replica Op Output St} (hr : r ∈ s.replicas) : r.config = s.config := by
  obtain ⟨i, hi⟩ := List.mem_iff_getElem?.mp hr
  exact (hinv.ids i r hi).2

/-- The replica with a given id. -/
theorem Inv.exists_replica {q : ReplicaId} (hq : q < s.config.replicaCount) :
    ∃ r ∈ s.replicas, r.selfId = q := by
  have hlt : q < s.replicas.length := hinv.count ▸ hq
  have hr : s.replicas[q]? = some s.replicas[q] := List.getElem?_eq_getElem hlt
  exact ⟨_, List.mem_of_getElem? hr, (hinv.ids q _ hr).1⟩

/-- A replica's log is within any bound on the fragments of its last
normal view, because every entry is in some fragment. -/
theorem Inv.log_le_of_frags {r : Replica Op Output St} (hr : r ∈ s.replicas) {m : Nat}
    (h : ∀ off log, Frag s r.lastNormalView off log → off + log.length ≤ m) : r.log.length ≤ m := by
  by_contra hlt
  obtain ⟨e, off, log, hf, hoff, hget⟩ := hinv.covered r hr m (Nat.lt_of_not_le hlt)
  have := h off log hf
  have hi : m - off < log.length := (List.getElem?_eq_some_iff.mp hget).1
  omega

/-- Two entries committed at the same index are the same entry. -/
theorem Inv.committed_unique {v1 v2 i : Nat} {e1 e2 : LogEntry Op} (h1 : Committed s v1 i e1)
    (h2 : Committed s v2 i e2) : e1 = e2 := by
  rcases Nat.lt_trichotomy v1 v2 with h | h | h
  · exact (hinv.survives_holds h1 h h2.1).symm
  · subst h; exact hinv.oneLog.1 v1 i e1 e2 h1.1 h2.1
  · exact hinv.survives_holds h2 h h1.1

theorem Inv.dvcOf_of_sent {dst u x l log o k} (h : Sent s dst (.doViewChange u x l log o k)) :
    DvcOf s u x ⟨l, log, k⟩ := by
  have hwf : log.length = o := (hinv.wf _ h).1
  subst hwf
  exact Or.inl ⟨dst, h⟩

/-- Every started view was started from a quorum, with a best. -/
theorem Inv.started_spec {v dvcs} (hv : (v, dvcs) ∈ s.started) :
    s.config.quorum ≤ dvcs.length ∧ (dvcs.map Prod.fst).Nodup ∧
      ∃ b, Replica.bestDoViewChange dvcs = some b := by
  obtain ⟨dst, log, o, k, hsv⟩ := hinv.startedViews.1 v dvcs hv
  obtain ⟨dvcs', best, hv', hq, hnd, hb, _⟩ := hinv.chosen dst v log o k hsv
  obtain rfl := hinv.startedOnce v dvcs dvcs' hv hv'
  exact ⟨hq, hnd, best, hb⟩

end Facts

theorem DvcOf.frag {s : System Op Output St} {u x d} (h : DvcOf s u x d) : Frag s d.lastNormalView 0 d.log := by
  rcases h with ⟨dst, h⟩ | ⟨dvcs, h1, h2⟩
  · exact .dvc h
  · exact .started h1 h2

theorem DvcOf.holds {s : System Op Output St} {u x d} (h : DvcOf s u x d) {i : Nat} {e : LogEntry Op}
    (hi : d.log[i]? = some e) : Holds s d.lastNormalView i e :=
  ⟨0, d.log, h.frag, Nat.zero_le _, by simpa using hi⟩

theorem List.IsPrefix.getElem?_of {α : Type} {l₁ l₂ : List α} (h : l₁ <+: l₂) {i : Nat} {a : α}
    (hi : l₁[i]? = some a) : l₂[i]? = some a := by
  obtain ⟨t, rfl⟩ := h
  rw [List.getElem?_append_left (List.getElem?_eq_some_iff.mp hi).1]; exact hi

/-- A log at least as long as another and agreeing with it wherever both
are defined extends it. -/
theorem List.prefix_of_agree {α : Type} {l₁ l₂ : List α} (hlen : l₁.length ≤ l₂.length)
    (h : ∀ (i : Nat) (a b : α), l₁[i]? = some a → l₂[i]? = some b → a = b) : l₁ <+: l₂ := by
  refine ⟨l₂.drop l₁.length, ?_⟩
  apply List.ext_getElem?
  intro i
  by_cases hi : i < l₁.length
  · rw [List.getElem?_append_left hi]
    have h1 : l₁[i]? = some l₁[i] := List.getElem?_eq_getElem hi
    have h2 : l₂[i]? = some l₂[i] := List.getElem?_eq_getElem (Nat.lt_of_lt_of_le hi hlen)
    rw [h1, h2, h i _ _ h1 h2]
  · rw [List.getElem?_append_right (Nat.le_of_not_lt hi), List.getElem?_drop,
      Nat.add_sub_cancel' (Nat.le_of_not_lt hi)]

/-! ### The chosen log survives -/

/-- What the intersection argument uses about a DoViewChange for `u`. -/
structure DvcFacts (s : System Op Output St) (u : ViewNumber) (x : ReplicaId) (d : DoViewChange Op) : Prop where
  afterAcks : ∀ dst v o, Sent s dst (.prepareOk v o x) → v < u → v ≤ d.lastNormalView
  afterOwn : ∀ v dvcs, (v, dvcs) ∈ s.started → x = s.config.primaryId v → v < u → v ≤ d.lastNormalView
  coversAcks : ∀ dst o, Sent s dst (.prepareOk d.lastNormalView o x) → o ≤ d.log.length
  primaryCovers : x = s.config.primaryId d.lastNormalView →
    ∀ off log, Frag s d.lastNormalView off log → off + log.length ≤ d.log.length
  holds : ∀ i e, d.log[i]? = some e → Holds s d.lastNormalView i e

theorem Inv.dvcFacts {s : System Op Output St} (hinv : Inv s) {u x d} (h : DvcOf s u x d) :
    DvcFacts s u x d where
  afterAcks := hinv.dvcAfterAcks u x d h
  afterOwn := hinv.dvcAfterOwn u x d h
  coversAcks := hinv.dvcCovers u x d h
  primaryCovers := hinv.dvcPrimary u x d h
  holds := fun _ _ hi => h.holds hi

/-- The best of a quorum of DoViewChanges for `u` holds, at `i`, an entry a
quorum acknowledged in an earlier view `v`, provided every DoViewChange of
the quorum from a view later than `v` holds it. The acknowledging quorum
may include one replica `q` that has no DoViewChange in the quorum, for the
acknowledgement being sent now. -/
theorem Inv.bestHolds {s : System Op Output St} (hinv : Inv s) {v i : Nat} {e : LogEntry Op}
    (he : Holds s v i e) {Q : List ReplicaId} (hnd : Q.Nodup) (hlen : s.config.quorum ≤ Q.length)
    (hQN : ∀ q ∈ Q, q < s.config.replicaCount)
    {u : ViewNumber} {V : List (ReplicaId × DoViewChange Op)} (hu : v < u)
    (hA : ∀ q ∈ Q, q = s.config.primaryId v ∨ (∃ dst o, Sent s dst (.prepareOk v o q) ∧ i < o) ∨
      ∀ d, (q, d) ∉ V)
    (hVq : s.config.quorum ≤ V.length) (hVnd : (V.map Prod.fst).Nodup)
    (hVN : ∀ x d, (x, d) ∈ V → x < s.config.replicaCount)
    (hVf : ∀ x d, (x, d) ∈ V → DvcFacts s u x d)
    (hih : ∀ x d, (x, d) ∈ V → v < d.lastNormalView → d.log[i]? = some e)
    {b : DoViewChange Op} (hb : Replica.bestDoViewChange V = some b) : b.log[i]? = some e := by
  have hVmapN : ∀ x ∈ V.map Prod.fst, x < s.config.replicaCount := by
    intro x hx; obtain ⟨⟨x', d⟩, hd, rfl⟩ := List.mem_map.mp hx; exact hVN x' d hd
  have hVlen : s.config.quorum ≤ (V.map Prod.fst).length := by rw [List.length_map]; exact hVq
  obtain ⟨x, hxQ, hxV⟩ := s.config.quorum_intersect hnd hVnd hQN hVmapN hlen hVlen
  obtain ⟨⟨x', d⟩, hd, hx'⟩ := List.mem_map.mp hxV
  simp only at hx'; subst hx'
  have hf := hVf x' d hd
  have hstarted : 0 < v → ∃ dvcs, (v, dvcs) ∈ s.started := by
    intro hpos; obtain ⟨off, log, hfr, _, _⟩ := he; exact hinv.startedViews.2.1 v off log hfr hpos
  have key : v ≤ d.lastNormalView ∧ (d.lastNormalView = v → d.log[i]? = some e) := by
    rcases hA x' hxQ with hp | ⟨dst, o, hs, hio⟩ | hno
    · refine ⟨?_, fun hl => ?_⟩
      · rcases Nat.eq_zero_or_pos v with hv0 | hpos
        · rw [hv0]; exact Nat.zero_le _
        · obtain ⟨dvcs, hv⟩ := hstarted hpos
          exact hf.afterOwn v dvcs hv hp hu
      · obtain ⟨off, log, hfr, hoff, hget⟩ := he
        have hcov := hf.primaryCovers (by rw [hl]; exact hp) off log (by rw [hl]; exact hfr)
        have hlt : i < d.log.length := by
          have := (List.getElem?_eq_some_iff.mp hget).1; omega
        have he' : d.log[i]? = some d.log[i] := List.getElem?_eq_getElem hlt
        rw [he']; congr 1
        exact hinv.oneLog.1 v i _ e (by rw [← hl]; exact hf.holds i _ he') ⟨off, log, hfr, hoff, hget⟩
    · refine ⟨hf.afterAcks dst v o hs hu, fun hl => ?_⟩
      have hlt : i < d.log.length := Nat.lt_of_lt_of_le hio (hf.coversAcks dst o (by rw [hl]; exact hs))
      have he' : d.log[i]? = some d.log[i] := List.getElem?_eq_getElem hlt
      rw [he']; congr 1
      exact hinv.oneLog.1 v i _ e (by rw [← hl]; exact hf.holds i _ he') he
    · exact absurd hd (hno d)
  have hdlog : d.log[i]? = some e := by
    rcases Nat.lt_or_eq_of_le key.1 with hlt | heq
    · exact hih x' d hd hlt
    · exact key.2 heq.symm
  obtain ⟨xb, hbV⟩ := bestDoViewChange_mem hb
  rcases Nat.lt_or_ge v b.lastNormalView with hlt | hge
  · exact hih xb b hbV hlt
  · rcases bestDoViewChange_ge' hb hd with h1 | ⟨h1, h2⟩
    · exact absurd (Nat.lt_of_le_of_lt key.1 h1) (Nat.not_lt.mpr hge)
    · have hbl : b.lastNormalView = v := Nat.le_antisymm hge (h1 ▸ key.1)
      have hlt : i < b.log.length := Nat.lt_of_lt_of_le (List.getElem?_eq_some_iff.mp hdlog).1 h2
      have he' : b.log[i]? = some b.log[i] := List.getElem?_eq_getElem hlt
      rw [he']; congr 1
      exact hinv.oneLog.1 v i _ e (by rw [← hbl]; exact (hVf xb b hbV).holds i _ he') he

/-! ### Everything of a later view -/

/-- Everything of view `u` holds `e` at `i`: the induction statement, and
the shape of the `Survives` clause. -/
def ViewHolds (s : System Op Output St) (u : ViewNumber) (i : Nat) (e : LogEntry Op) : Prop :=
  (∀ dst log o k, Sent s dst (.startView u log o k) → log[i]? = some e) ∧
  (∀ u' x d, DvcOf s u' x d → d.lastNormalView = u → d.log[i]? = some e) ∧
  (∀ dst n q st, Sent s dst (.recoveryResponse u n q (some st)) → st.log[i]? = some e) ∧
  (∀ dst log a b k, Sent s dst (.newState u log a b k) → a ≤ i → log[i - a]? = some e) ∧
  (∀ dst c n op k, Sent s dst (.prepare u (i + 1) c n op k) → (⟨c, n, op⟩ : LogEntry Op) = e) ∧
  (∀ z ∈ s.replicas, z.lastNormalView = u → z.status ≠ .recovering → z.log[i]? = some e)

/-- Once the log a view was started from holds `e` at `i`, everything of
the view does: every `StartView` extends that log, and everything else is
at least as long and agrees. -/
theorem Inv.viewHolds_of_best {s : System Op Output St} (hinv : Inv s) {u i : Nat} {e : LogEntry Op}
    (hpos : 0 < u)
    (hbest : ∀ dvcs b, (u, dvcs) ∈ s.started → Replica.bestDoViewChange dvcs = some b →
      b.log[i]? = some e) : ViewHolds s u i e := by
  have hsv : ∀ dst log o k, Sent s dst (.startView u log o k) → log[i]? = some e := by
    intro dst log o k hs
    obtain ⟨dvcs, best, hv, _, _, hb, hpre⟩ := hinv.chosen dst u log o k hs
    exact List.IsPrefix.getElem?_of hpre (hbest dvcs best hv hb)
  have hholds : ∀ dvcs, (u, dvcs) ∈ s.started → Holds s u i e := by
    intro dvcs hv
    obtain ⟨dst, log, o, k, hs⟩ := hinv.startedViews.1 u dvcs hv
    exact ⟨0, log, .startView hs, Nat.zero_le _, by simpa using hsv dst log o k hs⟩
  refine ⟨hsv, ?_, ?_, ?_, ?_, ?_⟩
  · intro u' x d hd hl
    obtain ⟨dvcs, hv⟩ := hinv.startedViews.2.1 u 0 d.log (by rw [← hl]; exact hd.frag) hpos
    obtain ⟨_, _, b, hb⟩ := hinv.started_spec hv
    have hlt : i < d.log.length := Nat.lt_of_lt_of_le
      (List.getElem?_eq_some_iff.mp (hbest dvcs b hv hb)).1 ((hinv.extendsBase u dvcs b hv hb).1 u' x d hd hl)
    have he' : d.log[i]? = some d.log[i] := List.getElem?_eq_getElem hlt
    rw [he']; congr 1
    exact hinv.oneLog.1 u i _ e (by rw [← hl]; exact hd.holds he') (hholds dvcs hv)
  · intro dst n q st hs
    obtain ⟨dvcs, hv⟩ := hinv.startedViews.2.1 u 0 st.log (.recovery hs) hpos
    obtain ⟨_, _, b, hb⟩ := hinv.started_spec hv
    have hlt : i < st.log.length := Nat.lt_of_lt_of_le
      (List.getElem?_eq_some_iff.mp (hbest dvcs b hv hb)).1 ((hinv.extendsBase u dvcs b hv hb).2.1 dst n q st hs)
    have he' : st.log[i]? = some st.log[i] := List.getElem?_eq_getElem hlt
    rw [he']; congr 1
    exact hinv.oneLog.1 u i _ e ⟨0, st.log, .recovery hs, Nat.zero_le _, by simpa using he'⟩ (hholds dvcs hv)
  · intro dst log a b' k hs ha
    obtain ⟨dvcs, hv⟩ := hinv.startedViews.2.1 u a log (.newState hs) hpos
    obtain ⟨_, _, b, hb⟩ := hinv.started_spec hv
    have hwf := hinv.wf _ hs
    have hlt : i - a < log.length := by
      have h1 : i < b.log.length := (List.getElem?_eq_some_iff.mp (hbest dvcs b hv hb)).1
      have h2 : b.log.length ≤ b' := (hinv.extendsBase u dvcs b hv hb).2.2.1 dst log a b' k hs
      have h3 : log.length = b' - a := hwf.1
      rw [h3]
      exact Nat.sub_lt_sub_right ha (Nat.lt_of_lt_of_le h1 h2)
    have he' : log[i - a]? = some log[i - a] := List.getElem?_eq_getElem hlt
    rw [he']; congr 1
    exact hinv.oneLog.1 u i _ e ⟨a, log, .newState hs, ha, he'⟩ (hholds dvcs hv)
  · intro dst c n op k hs
    obtain ⟨dvcs, hv⟩ := hinv.startedViews.2.1 u (i + 1 - 1) [⟨c, n, op⟩] (.prepare hs) hpos
    exact hinv.oneLog.1 u i _ e ⟨i + 1 - 1, [⟨c, n, op⟩], .prepare hs, by omega, by simp⟩ (hholds dvcs hv)
  · intro z hz hl hn
    obtain ⟨dvcs, hv⟩ := hinv.startedViews.2.2 z hz hn (by rw [hl]; exact hpos)
    have hv' : (u, dvcs) ∈ s.started := by rw [← hl]; exact hv
    obtain ⟨_, _, b, hb⟩ := hinv.started_spec hv'
    have hlt : i < z.log.length := Nat.lt_of_lt_of_le
      (List.getElem?_eq_some_iff.mp (hbest dvcs b hv' hb)).1 ((hinv.extendsBase u dvcs b hv' hb).2.2.2 z hz hl hn)
    have he' : z.log[i]? = some z.log[i] := List.getElem?_eq_getElem hlt
    rw [he']; congr 1
    exact hinv.oneLog.2 z hz i _ e he' (by rw [hl]; exact hholds dvcs hv')

/-- A `Committed` fact that is new with one `PrepareOk` is in that
acknowledgement's view, and its entry was already held. -/
theorem Committed.after_ok {s : System Op Output St} {id : ReplicaId} {r : Replica Op Output St}
    {dst : ReplicaId} {v o q} {v' i} {e : LogEntry Op}
    (hc : Committed (s.after id r [(dst, .prepareOk v o q)] []) v' i e) (hold : ¬ Committed s v' i e) :
    v' = v ∧ Holds s v' i e := by
  obtain ⟨hh, hq⟩ := hc
  have hh' : Holds s v' i e := by
    rcases Holds.after.mp hh with h | ⟨off, log, hf, _, _⟩
    · exact h
    · rcases hf with ⟨x, hx, hmf⟩ | ⟨_, _, _, _, hst, _⟩
      · rw [mem_singleton_eq hx] at hmf; cases hmf
      · simp at hst
  refine ⟨?_, hh'⟩
  by_contra hne
  apply hold
  refine ⟨hh', ?_⟩
  obtain ⟨Q, hnd, hlen, hQ⟩ := hq
  refine ⟨Q, hnd, hlen, fun q' hq' => ⟨(hQ q' hq').1, ?_⟩⟩
  rcases Acked.after.mp (hQ q' hq').2 with h | ⟨to', o', hnew, _⟩
  · exact h
  · have h := mem_singleton_eq hnew
    simp only [Prod.mk.injEq, Message.prepareOk.injEq] at h
    exact absurd h.2.1 hne

/-- A `PrepareOk` from `r`, normal in its view, completes a quorum for an
entry `e` at `i` that view `v` holds: every later view holds `e` at `i`. -/
theorem Inv.viewHolds_of_newAck {s : System Op Output St} (hinv : Inv s) {id : ReplicaId}
    {r : Replica Op Output St} (hr : s.replicas[id]? = some r) {dst : ReplicaId} {o : OpNumber}
    {i : Nat} {e : LogEntry Op} (he : Holds s r.viewNumber i e)
    (hq : QuorumAcked (s.after id r [(dst, .prepareOk r.viewNumber o r.selfId)] []) r.viewNumber i) :
    ∀ u, r.viewNumber < u → ViewHolds s u i e := by
  have hmem := List.mem_of_getElem? hr
  obtain ⟨Q, hnd, hlen, hQ⟩ := hq
  suffices ∀ n u, u < n → r.viewNumber < u → ViewHolds s u i e from
    fun u hu => this (u + 1) u (Nat.lt_succ_self u) hu
  intro n
  induction n with
  | zero => intro u hu; exact absurd hu (Nat.not_lt_zero _)
  | succ n ih =>
    intro u hun hvu
    apply hinv.viewHolds_of_best (Nat.lt_of_le_of_lt (Nat.zero_le _) hvu)
    intro dvcs b hst hb
    obtain ⟨hVq, hVnd, _⟩ := hinv.started_spec hst
    refine hinv.bestHolds he hnd hlen (fun q hq => (hQ q hq).1) hvu ?_ hVq hVnd
      (fun x d hd => hinv.startedIds u dvcs hst x d hd)
      (fun x d hd => hinv.dvcFacts (Or.inr ⟨dvcs, hst, hd⟩)) ?_ hb
    · intro q hq
      obtain ⟨_, hack⟩ := hQ q hq
      rcases Acked.after.mp hack with hack | ⟨to', o', hnew, hio⟩
      · rcases hack with h | ⟨to', o', hs, hio⟩
        · exact Or.inl h
        · exact Or.inr (Or.inl ⟨to', o', hs, hio⟩)
      · have h := mem_singleton_eq hnew
        simp only [Prod.mk.injEq, Message.prepareOk.injEq] at h
        obtain ⟨_, _, _, hqr⟩ := h
        refine Or.inr (Or.inr fun d hd => ?_)
        have := hinv.dvcBelow u q d (Or.inr ⟨dvcs, hst, hd⟩) r hmem hqr.symm
        exact absurd (Nat.lt_of_lt_of_le hvu this) (Nat.lt_irrefl _)
    · intro x d hd hlt
      have hdu := hinv.dvcBehind u x d (Or.inr ⟨dvcs, hst, hd⟩)
      exact (ih d.lastNormalView (Nat.lt_of_lt_of_le hdu (Nat.le_of_lt_succ hun)) hlt).2.1 u x d
        (Or.inr ⟨dvcs, hst, hd⟩) rfl

end Vsr
