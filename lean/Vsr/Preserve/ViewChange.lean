import Vsr.Preserve.Request

/-!
The view change: `startViewChange`, sending a `DoViewChange`, recording
one as the new primary and, on a quorum, starting the view, and the
handlers `onStartViewChange`, `onDoViewChange`, `onStartView`.
-/

namespace Vsr

variable {Op Output St : Type}

/-! ### Helpers -/

theorem Assoc.insert_keys_sorted {α : Type} : ∀ {l : List (Nat × α)} (k : Nat) (v : α),
    (l.map Prod.fst).Pairwise (· < ·) → ((Assoc.insert l k v).map Prod.fst).Pairwise (· < ·)
  | [], k, v, _ => by simp [Assoc.insert]
  | (k', v') :: rest, k, v, h => by
    unfold Assoc.insert
    simp only [List.map_cons] at h
    obtain ⟨hhead, hrest⟩ := List.pairwise_cons.mp h
    split
    · rename_i hlt
      simp only [List.map_cons]
      exact List.pairwise_cons.mpr ⟨fun q hq => by
        rw [List.mem_cons] at hq
        rcases hq with rfl | hq
        · exact hlt
        · exact Nat.lt_trans hlt (hhead q hq), h⟩
    · split
      · rename_i heq; subst heq; simpa using h
      · rename_i h1 h2
        simp only [List.map_cons]
        refine List.pairwise_cons.mpr ⟨fun q hq => ?_, insert_keys_sorted k v hrest⟩
        obtain ⟨⟨q', w⟩, hmem, rfl⟩ := List.mem_map.mp hq
        rcases Assoc.mem_insert hmem with h | h
        · obtain ⟨rfl, _⟩ := Prod.mk.inj h
          exact Nat.lt_of_le_of_ne (Nat.le_of_not_lt h1) (fun h => h2 h.symm)
        · exact hhead _ (List.mem_map.mpr ⟨_, h, rfl⟩)

/-- What the fold of maxima says. -/
theorem foldl_max_spec : ∀ (l : List (ReplicaId × DoViewChange Op)) (acc i : Nat),
    i < l.foldl (fun acc (p : ReplicaId × DoViewChange Op) => max acc p.2.commitNumber) acc →
    i < acc ∨ ∃ y d, (y, d) ∈ l ∧ i < d.commitNumber
  | [], acc, i, h => Or.inl h
  | (y, d) :: rest, acc, i, h => by
    rw [List.foldl_cons] at h
    rcases foldl_max_spec rest _ i h with h | ⟨y', d', hmem, hlt⟩
    · rcases Nat.le_total acc d.commitNumber with hle | hle
      · rw [Nat.max_eq_right hle] at h; exact Or.inr ⟨y, d, List.mem_cons_self .., h⟩
      · rw [Nat.max_eq_left hle] at h; exact Or.inl h
    · exact Or.inr ⟨y', d', List.mem_cons_of_mem _ hmem, hlt⟩

theorem foldl_max_ge : ∀ (l : List (ReplicaId × DoViewChange Op)) (acc : Nat) {y d}, (y, d) ∈ l →
    d.commitNumber ≤ l.foldl (fun acc (p : ReplicaId × DoViewChange Op) => max acc p.2.commitNumber) acc
  | [], _, _, _, h => by simp at h
  | (y', d') :: rest, acc, y, d, h => by
    rw [List.foldl_cons]
    rcases List.mem_cons.mp h with h | h
    · obtain ⟨rfl, rfl⟩ := Prod.mk.inj h
      exact Nat.le_trans (Nat.le_max_right _ _) (foldl_max_acc_le rest _)
    · exact foldl_max_ge rest _ h
where
  foldl_max_acc_le : ∀ (l : List (ReplicaId × DoViewChange Op)) (acc : Nat),
      acc ≤ l.foldl (fun acc (p : ReplicaId × DoViewChange Op) => max acc p.2.commitNumber) acc
    | [], _ => Nat.le_refl _
    | _ :: rest, acc => Nat.le_trans (Nat.le_max_left _ _) (foldl_max_acc_le rest _)

/-- A fold of `sendStartView` only fills the outbox. -/
theorem Replica.foldl_sendStartView_eq (r : Replica Op Output St) (l : List ReplicaId) :
    l.foldl (fun r dst => r.sendStartView dst) r = { r with outbox := r.outbox ++ l.map (fun dst => (dst, Message.startView r.viewNumber r.log r.opNumber r.commitNumber)) } := by
  induction l generalizing r with
  | nil => cases r; simp
  | cons dst l ih =>
    rw [List.foldl_cons, ih]
    cases r; simp [Replica.sendStartView, Replica.send, Replica.opNumber]

theorem Replica.addAcksForUncommitted_mem {r : Replica Op Output St} {oa : OpNumber × List ReplicaId}
    (h : oa ∈ r.addAcksForUncommitted.acks) : r.commitNumber < oa.1 ∧ oa.1 ≤ r.log.length ∧ oa.2 = [r.selfId] := by
  unfold Replica.addAcksForUncommitted at h
  simp only at h
  obtain ⟨i, hi, rfl⟩ := List.mem_map.mp h
  rw [List.mem_range] at hi
  refine ⟨Nat.lt_of_lt_of_le (Nat.lt_succ_self _) (Nat.le_add_right _ _), ?_, rfl⟩
  show r.commitNumber + 1 + i ≤ r.log.length
  unfold Replica.opNumber at hi
  have h2 : i + r.commitNumber < r.log.length := Nat.lt_sub_iff_add_lt.mp hi
  rw [Nat.add_assoc, Nat.add_comm 1 i, ← Nat.add_assoc, Nat.add_comm r.commitNumber i]
  exact Nat.succ_le_of_lt h2

/-! ### Starting the view -/

section Record
variable {s : System Op Output St} {id : ReplicaId} (hlt : id < s.replicas.length)
  {r1 : Replica Op Output St} (hinv : Inv (s.drainOf id r1))
include hlt hinv

/-- Recording a `DoViewChange` as the new primary, and starting the view
on a quorum. -/
theorem Inv.recordDoViewChange (m : Machine Op Output St) (x : ReplicaId) (dvc : DoViewChange Op)
    (hvc : r1.status = .viewChange) (hprim : r1.selfId = s.config.primaryId r1.viewNumber)
    (hcv : r1.chosenDoViewChanges = none) (hx : x < s.config.replicaCount)
    (hdvc : (∃ dst, Sent (s.drainOf id r1) dst
        (.doViewChange r1.viewNumber x dvc.lastNormalView dvc.log dvc.log.length dvc.commitNumber)) ∨
      (x = r1.selfId ∧ dvc = ⟨r1.lastNormalView, r1.log, r1.commitNumber⟩)) :
    Inv (s.drainOf id (Replica.recordDoViewChange m r1 x dvc)) := by
  have hloc := hinv.drainOf_local hlt
  have hconf := hinv.drainOf_config hlt
  have hnr : r1.status ≠ .recovering := by rw [hvc]; decide
  have hvcb : r1.lastNormalView < r1.viewNumber := hinv.drainOf_vcBehind hlt hvc
  have hrec := hinv.drainOf_dvcs hlt hvc
  unfold Replica.recordDoViewChange
  try simp only
  -- step one: the DoViewChange is recorded
  set V := Assoc.insert r1.doViewChangeFrom x dvc with hV
  set r2 : Replica Op Output St := { r1 with doViewChangeFrom := V } with hr2
  have hVspec : ∀ y d, (y, d) ∈ V → y < s.config.replicaCount ∧
      ((∃ dst, Sent (s.drainOf id r1) dst (.doViewChange r1.viewNumber y d.lastNormalView d.log d.log.length d.commitNumber)) ∨
        (y = r1.selfId ∧ d = ⟨r1.lastNormalView, r1.log, r1.commitNumber⟩)) := by
    intro y d hd
    rcases Assoc.mem_insert hd with h | h
    · obtain ⟨rfl, rfl⟩ := Prod.mk.inj h; exact ⟨hx, hdvc⟩
    · exact hrec.2 y d h
  have hVsorted : (V.map Prod.fst).Pairwise (· < ·) := Assoc.insert_keys_sorted x dvc hrec.1
  have h1 : Inv (s.drainOf id r2) := by
    refine hinv.drainKeepLog hlt rfl rfl rfl rfl rfl (hinv.drainOf_noPanic hlt) rfl rfl (Or.inr rfl) (Nat.le_refl _)
      (hloc.withDoViewChangeFrom V) hnr (by rw [hr2]; simpa using hnr) (hinv.drainOf_backed hlt)
      (hinv.drainOf_catching hlt)
      (fun hn => absurd (show r1.status = .normal by simpa [hr2] using hn) (by rw [hvc]; decide))
      (fun _ => hvcb)
      (fun h => absurd (show r1.status = .stateTransfer by simpa [hr2] using h) (by rw [hvc]; decide))
      (fun _ => ⟨hVsorted, hVspec⟩)
  split
  · exact h1
  · rename_i hq
    have hVq : s.config.quorum ≤ V.length := by rw [← hconf]; exact Nat.le_of_not_lt hq
    split
    · rename_i hnone
      exfalso
      have := bestDoViewChange_none hnone
      rw [this] at hVq; simp at hVq
      have := hinv.replicaCount_pos; unfold Config.quorum at hVq; omega
    · rename_i best hbest
      try simp only
      -- the state after the record, its facts
      have hmem2 : r2.clear ∈ (s.drainOf id r2).replicas := drainOf_mem id r2 hlt
      have hvpos : 0 < r1.viewNumber := Nat.lt_of_le_of_lt (Nat.zero_le _) hvcb
      have hprim2 : r2.clear.selfId = (s.drainOf id r2).config.primaryId r1.viewNumber := hprim
      -- nothing of view `r1.viewNumber` exists yet
      have hnotstarted : ∀ dvcs, (r1.viewNumber, dvcs) ∉ (s.drainOf id r2).started := by
        intro dvcs hst
        have := h1.primaryStarted r1.viewNumber dvcs hst r2.clear hmem2 hprim2
        exact absurd (Nat.lt_of_le_of_lt this hvcb) (Nat.lt_irrefl _)
      have hnofrag : ∀ off log, ¬ Frag (s.drainOf id r2) r1.viewNumber off log := fun off log hf =>
        (h1.startedViews.2.1 r1.viewNumber off log hf hvpos).elim fun dvcs h => hnotstarted dvcs h
      have hnoholds : ∀ i e, ¬ Holds (s.drainOf id r2) r1.viewNumber i e := fun i e ⟨off, log, hf, _, _⟩ => hnofrag off log hf
      have hnoack : ∀ dst o q, ¬ Sent (s.drainOf id r2) dst (.prepareOk r1.viewNumber o q) := fun dst o q hs =>
        (h1.acksStarted dst r1.viewNumber o q hs hvpos).elim fun dvcs h => hnotstarted dvcs h
      have hnoreplica : ∀ z ∈ (s.drainOf id r2).replicas, z.lastNormalView = r1.viewNumber → z.status ≠ .recovering → False :=
        fun z hz hl hn => (h1.startedViews.2.2 z hz hn (by rw [hl]; exact hvpos)).elim fun dvcs h => hnotstarted dvcs (by rw [← hl]; exact h)
      have hnodvc_v : ∀ u q d, DvcOf (s.drainOf id r2) u q d → d.lastNormalView ≠ r1.viewNumber := fun u q d hd hl =>
        hnofrag 0 d.log (by rw [← hl]; exact hd.frag)
      -- each recorded DoViewChange
      have hVdvc : ∀ y d, (y, d) ∈ V → DvcOf (s.drainOf id r2) r1.viewNumber y d ∨ (y = r1.selfId ∧ d = ⟨r1.lastNormalView, r1.log, r1.commitNumber⟩) := by
        intro y d hd
        rcases (hVspec y d hd).2 with ⟨dst, hs⟩ | h
        · exact Or.inl (Or.inl ⟨dst, by rw [hr2]; exact hs⟩)
        · exact Or.inr h
      have hVN : ∀ y d, (y, d) ∈ V → y < s.config.replicaCount := fun y d hd => (hVspec y d hd).1
      have hVnd : (V.map Prod.fst).Nodup := hVsorted.imp fun h => Nat.ne_of_lt h
      -- the facts the intersection argument needs, for each
      have hVfacts : ∀ y d, (y, d) ∈ V → DvcFacts (s.drainOf id r2) r1.viewNumber y d := by
        intro y d hd
        rcases hVdvc y d hd with hd' | ⟨rfl, rfl⟩
        · exact h1.dvcFacts hd'
        · refine ⟨fun dst v' o hs _ => (h1.acksHold dst v' o _ hs r2.clear hmem2 rfl).1,
            fun v' dvcs hv' hp _ => h1.primaryStarted v' dvcs hv' r2.clear hmem2 hp,
            fun dst o hs => (h1.acksHold dst _ o _ hs r2.clear hmem2 rfl).2 rfl hnr,
            fun hp off log hf => (h1.longest r2.clear hmem2 hnr hp).1 off log hf,
            fun i e hi => ?_⟩
          obtain ⟨e0, he0⟩ := h1.covered r2.clear hmem2 i (List.getElem?_eq_some_iff.mp hi).1
          rw [h1.oneLog.2 r2.clear hmem2 i e e0 hi he0]; exact he0
      -- the chosen log holds every earlier commit
      have hbestHolds : ∀ v'' i e, Committed (s.drainOf id r2) v'' i e → v'' < r1.viewNumber → best.log[i]? = some e := by
        intro v'' i e hc hlt'
        obtain ⟨Q, hnd, hlen, hQ⟩ := hc.2
        refine h1.bestHolds hc.1 hnd hlen (fun q hq => (hQ q hq).1) hlt' (fun q hq => ?_) hVq hVnd hVN hVfacts
          (fun y d hd hl => ?_) hbest
        · rcases (hQ q hq).2 with h | ⟨dst, o, hs, hio⟩
          · exact Or.inl h
          · exact Or.inr (Or.inl ⟨dst, o, hs, hio⟩)
        · rcases hVdvc y d hd with hd' | ⟨_, rfl⟩
          · exact (h1.survives v'' i e hc _ hl).2.1 r1.viewNumber y d hd' rfl
          · exact (h1.survives v'' i e hc _ hl).2.2.2.2.2 r2.clear hmem2 rfl hnr
      -- the primary's own commit is within the chosen log
      have hk1 : r1.commitNumber ≤ best.log.length := by
        by_contra hgt
        have hlt' : best.log.length < r1.commitNumber := Nat.lt_of_not_le hgt
        obtain ⟨e, v'', _, hle, hc, _⟩ := h1.committed_entry hmem2 (show best.log.length < r2.clear.commitNumber from hlt')
        have := hbestHolds v'' _ e hc (Nat.lt_of_le_of_lt hle hvcb)
        exact absurd (List.getElem?_eq_some_iff.mp this).1 (Nat.lt_irrefl _)
      -- the commit number chosen
      set kstar := V.foldl (fun acc (p : ReplicaId × DoViewChange Op) => max acc p.2.commitNumber) 0 with hkstar
      have hkstarBacked : ∀ i, i < kstar → ∃ e v'', v'' < r1.viewNumber ∧ Committed (s.drainOf id r2) v'' i e ∧ best.log[i]? = some e := by
        intro i hi
        rcases foldl_max_spec V 0 i hi with h | ⟨y, d, hd, hlt'⟩
        · exact absurd h (Nat.not_lt_zero _)
        · -- `d`'s commit is backed in `d`'s view, which is before `r1.viewNumber`
          have hbk : Backed (s.drainOf id r2) d.lastNormalView d.commitNumber ∧ d.lastNormalView < r1.viewNumber := by
            rcases hVdvc y d hd with hd' | ⟨_, rfl⟩
            · refine ⟨?_, h1.dvcBehind r1.viewNumber y d hd'⟩
              rcases hd' with ⟨dst, hs⟩ | ⟨dvcs, hst, _⟩
              · exact h1.backed.2 dst _ hs
              · exact absurd hst (hnotstarted dvcs)
            · exact ⟨h1.backed.1 r2.clear hmem2, hvcb⟩
          obtain ⟨e, v'', hle, hc, _⟩ := hbk.1 i hlt'
          exact ⟨e, v'', Nat.lt_of_le_of_lt hle hbk.2, hc, hbestHolds v'' i e hc (Nat.lt_of_le_of_lt hle hbk.2)⟩
      have hkstarLe : kstar ≤ best.log.length := by
        by_contra hgt
        obtain ⟨e, _, _, _, he⟩ := hkstarBacked best.log.length (Nat.lt_of_not_le hgt)
        exact absurd (List.getElem?_eq_some_iff.mp he).1 (Nat.lt_irrefl _)
      -- the replica that starts the view
      set r3 : Replica Op Output St := { r2 with chosenDoViewChanges := some V } with hr3
      have hinst : r3.installLog best.log = { r3 with
          clientTable := Replica.rebuildClientTable r3.commitNumber r3.clientTable 0 best.log [], log := best.log } := by
        unfold Replica.installLog; rw [if_neg (Nat.not_lt.mpr hk1)]
      rw [hinst]
      set r4 : Replica Op Output St := { r3 with
          clientTable := Replica.rebuildClientTable r3.commitNumber r3.clientTable 0 best.log [], log := best.log } with hr4
      set r5 : Replica Op Output St := Replica.commitUpTo m r4 kstar true with hr5
      set r6 : Replica Op Output St := { r5.enterNormal with acks := [] }.addAcksForUncommitted with hr6
      have hr6log : r6.log = best.log := (Replica.commitUpTo_log m r4 true kstar).trans rfl
      have hr6k : r6.commitNumber = r5.commitNumber := rfl
      have hr6v : r6.viewNumber = r1.viewNumber := (Replica.commitUpTo_viewNumber m r4 true kstar).trans rfl
      have hr6l : r6.lastNormalView = r1.viewNumber := (Replica.commitUpTo_viewNumber m r4 true kstar).trans rfl
      have hr6self : r6.selfId = r1.selfId := (Replica.commitUpTo_selfId m r4 true kstar).trans rfl
      have hr6conf : r6.config = r1.config := (Replica.commitUpTo_config m r4 true kstar).trans rfl
      have hr6stat : r6.status = .normal := rfl
      have hr6catch : r6.catchingUp = false := rfl
      have hr6nonce : r6.recoveryNonce = r1.recoveryNonce := (Replica.commitUpTo_recoveryNonce m r4 true kstar).trans rfl
      have hr6chosen : r6.chosenDoViewChanges = some V :=
        (Replica.commitUpTo_chosenDoViewChanges m r4 true kstar).trans rfl
      have hr6out : r6.outbox = r1.outbox := (Replica.commitUpTo_outbox m r4 kstar true).trans rfl
      have hr5k : r5.commitNumber ≤ max r1.commitNumber kstar := commitUpTo_le_max m r4 kstar true
      have hr6panic : r6.panicked = false :=
        (commitUpTo_panicked m r4 kstar true hk1 hkstarLe).trans (hinv.drainOf_noPanic hlt)
      have hloc4 : Replica.LocalInv r4 :=
        ⟨hk1, hloc.2.1, fun h => absurd (show r1.status = .normal ∨ r1.status = .stateTransfer from h) (by rw [hvc]; decide),
         fun _ => hvc, fun h => absurd (show r1.status = .recovering from h) (by rw [hvc]; decide)⟩
      have hloc6 : Replica.LocalInv r6 := ((hloc4.commitUpTo m kstar true).enterNormal.withAcks []).addAcksForUncommitted
      have hr6selfN : r6.selfId < s.config.replicaCount := by rw [hr6self]; exact hinv.drainOf_selfIdLt hlt
      set msg : Message Op := .startView r6.viewNumber r6.log r6.opNumber r6.commitNumber with hmsg
      set out := (r6.config.replicas.filter (· ≠ r6.selfId)).map (fun dst => (dst, msg)) with hout
      -- the drained result
      refine h1.drainStep hlt (r2 := (r6.config.replicas.filter (· ≠ r6.selfId)).foldl (fun r dst => r.sendStartView dst) r6)
        (out := out) (st := [(r1.viewNumber, V)]) ?_ ?_ ?_
      · rw [Replica.foldl_sendStartView_eq]
        show r6.outbox ++ _ = r2.outbox ++ out
        rw [hr6out]
      · rw [Replica.foldl_sendStartView_eq]
        unfold Replica.startedList
        simp only [hr6chosen, show r2.chosenDoViewChanges = none from hcv, List.nil_append]
        show [(r6.viewNumber, V)] = [(r1.viewNumber, V)]
        rw [hr6v]
      rw [Replica.foldl_sendStartView_eq]
      have hclear : ({ r6 with outbox := r6.outbox ++ out } : Replica Op Output St).clear = r6.clear := rfl
      rw [hclear]
      have hmsg_spec : ∀ x ∈ out, x.2 = msg ∧ x.1 ≠ r1.selfId ∧ x.1 < s.config.replicaCount := by
        intro x hx
        obtain ⟨h1', h2', h3'⟩ := mem_others hx
        exact ⟨h1', hr6self ▸ h2', by rw [← hconf, ← hr6conf]; exact h3'⟩
      have hex : ∃ x, x ∈ out := others_nonempty msg (by rw [hr6conf, hconf]; exact hinv.two) (by rw [hr6conf, hr6self, hconf]; exact hinv.drainOf_selfIdLt hlt)
      have hnew : ∀ v' off log, FragNew out [(r1.viewNumber, V)] v' off log →
          (v' = r1.viewNumber ∧ off = 0 ∧ log = best.log) ∨ (∃ y d, (y, d) ∈ V ∧ v' = d.lastNormalView ∧ off = 0 ∧ log = d.log) := by
        intro v' off log hf
        rcases hf with ⟨x, hx, hmf⟩ | ⟨u, dvcs, y, d, hst, hd, rfl, rfl, rfl⟩
        · have hx2 := (hmsg_spec x hx).1
          obtain ⟨dst, m'⟩ := x
          simp only at hx2; subst hx2
          obtain ⟨rfl, rfl, rfl⟩ := MsgFrag.startView_inv hmf
          exact Or.inl ⟨hr6v, rfl, hr6log⟩
        · rw [List.mem_singleton, Prod.mk.injEq] at hst
          obtain ⟨_, rfl⟩ := hst
          exact Or.inr ⟨y, d, hd, rfl, rfl, rfl⟩
      have hnewHolds : ∀ v' i e, HoldsNew out [(r1.viewNumber, V)] v' i e →
          (v' = r1.viewNumber ∧ best.log[i]? = some e) ∨ (∃ y d, (y, d) ∈ V ∧ v' = d.lastNormalView ∧ d.log[i]? = some e) := by
        intro v' i e ⟨off, log, hf, hle, hget⟩
        rcases hnew v' off log hf with ⟨rfl, rfl, rfl⟩ | ⟨y, d, hd, rfl, rfl, rfl⟩
        · exact Or.inl ⟨rfl, by simpa using hget⟩
        · exact Or.inr ⟨y, d, hd, rfl, by simpa using hget⟩
      have hnoOk : NoPrepareOk out := fun x hx v' o q h => by
        have := (hmsg_spec x hx).1; rw [this] at h; exact nomatch h
      have hsvNew : ∀ i e, best.log[i]? = some e → Holds ((s.drainOf id r2).after id r6.clear out [(r1.viewNumber, V)]) r1.viewNumber i e := by
        intro i e he
        obtain ⟨x, hx⟩ := hex
        have hx2 := (hmsg_spec x hx).1
        obtain ⟨dst, m'⟩ := x
        simp only at hx2; subst hx2
        exact ⟨0, best.log, Frag.after.mpr (Or.inr (FragNew.ofMsg hx (by rw [hmsg, hr6v, hr6log]; exact MsgFrag.startView))),
          Nat.zero_le _, by simpa using he⟩
      have hBacked6 : Backed ((s.drainOf id r2).after id r6.clear out [(r1.viewNumber, V)]) r1.viewNumber r6.commitNumber := by
        refine Backed.downward ?_ hr5k
        refine Backed.max ?_ ?_
        · intro i hi
          obtain ⟨e, v'', _, hle, hc, _⟩ := h1.committed_entry hmem2 (show i < r2.clear.commitNumber from hi)
          exact ⟨e, v'', Nat.le_of_lt (Nat.lt_of_le_of_lt hle hvcb), Committed.after_of hc,
            hsvNew i e (hbestHolds v'' i e hc (Nat.lt_of_le_of_lt hle hvcb))⟩
        · intro i hi
          obtain ⟨e, v'', hlt', hc, he⟩ := hkstarBacked i hi
          exact ⟨e, v'', Nat.le_of_lt hlt', Committed.after_of hc, hsvNew i e he⟩
      have hVholds : ∀ y d, (y, d) ∈ V → ∀ i e, d.log[i]? = some e → Holds (s.drainOf id r2) d.lastNormalView i e :=
        fun y d hd i e hi => (hVfacts y d hd).holds i e hi
      have hVbehind : ∀ y d, (y, d) ∈ V → d.lastNormalView < r1.viewNumber := by
        intro y d hd
        rcases hVdvc y d hd with hd' | ⟨_, rfl⟩
        · exact h1.dvcBehind _ y d hd'
        · exact hvcb
      have hdvcnew : ∀ u q d, DvcOfNew out [(r1.viewNumber, V)] u q d → u = r1.viewNumber ∧ (q, d) ∈ V := by
        intro u q d hd
        rcases hd with ⟨dst, hx⟩ | ⟨dvcs, hst, hd⟩
        · exact absurd (hmsg_spec _ hx).1 (by simp [hmsg])
        · rw [List.mem_singleton, Prod.mk.injEq] at hst
          obtain ⟨rfl, rfl⟩ := hst
          exact ⟨rfl, hd⟩
      -- a DoViewChange of the quorum is within a primary's DoViewChange of the same view
      have hVle : ∀ y' d', (y', d') ∈ V → ∀ u q d, DvcOf (s.drainOf id r2) u q d →
          q = s.config.primaryId d.lastNormalView → d'.lastNormalView = d.lastNormalView →
          d'.log.length ≤ d.log.length := by
        intro y' d' hd' u q d hd hq hl
        rcases hVdvc y' d' hd' with hd'' | ⟨_, rfl⟩
        · have := h1.dvcPrimary u q d hd hq 0 d'.log (by rw [← hl]; exact hd''.frag)
          simpa using this
        · exact h1.log_le_of_frags hmem2 (fun off' L hf' => h1.dvcPrimary u q d hd hq off' L (by rw [← hl]; exact hf'))
      have hrepl' : ∀ z ∈ ((s.drainOf id r2).after id r6.clear out [(r1.viewNumber, V)]).replicas,
          z = r6.clear ∨ (z ∈ (s.drainOf id r2).replicas ∧ z.selfId ≠ r1.selfId) :=
        fun z hz => mem_after_replicas h1.ids (s.drainOf_replicas_self r2 hlt) hz
      have hznone : ∀ z ∈ (s.drainOf id r2).replicas, z.status = .recovering → z.log = [] :=
        fun z hz hzr => ((h1.local_ z hz).2.2.2.2 hzr).1
      refine {
        self := by show r6.selfId = r2.selfId; exact hr6self,
        conf := by show r6.config = r2.config; exact hr6conf,
        panic := by show r6.panicked = false; exact hr6panic,
        outbox := rfl, replies := rfl, chosen := rfl,
        local_ := ?_,
        view := by show r2.viewNumber ≤ r6.viewNumber; exact Nat.le_of_eq hr6v.symm,
        lnv := by show r2.lastNormalView ≤ r6.lastNormalView; rw [hr6l]; exact Nat.le_of_lt hvcb,
        wf := fun x hx => by rw [(hmsg_spec x hx).1]; show r6.log.length = r6.opNumber ∧ r6.commitNumber ≤ r6.opNumber; exact ⟨rfl, hloc6.1⟩,
        okSelf := fun x hx v' o q h => by rw [(hmsg_spec x hx).1] at h; exact (nomatch h),
        oneLogNew := fun v' i e e' h h' => ?_,
        oneLogSelf := fun i e e' he hh => ?_,
        oneLogOld := fun z hz hne i e e' he h => ?_,
        backedSelf := by show Backed _ r6.lastNormalView r6.commitNumber; rw [hr6l]; exact hBacked6,
        backedOut := fun x hx => by
          rw [(hmsg_spec x hx).1]; show Backed _ r6.viewNumber r6.commitNumber; rw [hr6v]; exact hBacked6,
        survivesOld := fun v'' i e hc u hu => ?_,
        survivesNew := fun v'' i e hc hold => ?_,
        acksSelf := fun _ _ oa hoa => ?_,
        catchingSelf := fun hc => by rw [Replica.clear_catchingUp, hr6catch] at hc; exact absurd hc (by decide),
        acksHoldSelf := fun dst v' o hs => ?_,
        toOthers := fun x hx => by rw [(hmsg_spec x hx).1]; trivial,
        longestSelf := fun _ _ => ?_,
        longestOld := fun p hp hne hpn hpp => ?_,
        chosenNew := fun dst v' log o k hx => ?_,
        dvcCoversNew := fun u q d hd dst o hs => ?_,
        dvcCoversOk := fun u q d _ y hy o h => by rw [(hmsg_spec y hy).1] at h; exact (nomatch h),
        dvcBehindNew := fun u q d hd => ?_,
        dvcBelowNew := fun u q d hd z hz hq => ?_,
        dvcAfterAcksNew := fun u q d hd dst v' o hs hlt' => ?_,
        dvcAfterAcksOk := fun u q d _ y hy v' o h => by rw [(hmsg_spec y hy).1] at h; exact (nomatch h),
        dvcAfterOwnNew := fun u q d hd v' dvcs hv' hq hlt' => ?_,
        dvcAfterOwnSt := fun u q d hd v' dvcs hv' hq hlt' => ?_,
        dvcPrimaryNew := fun u q d hd hq off log hf => ?_,
        dvcPrimaryFrag := fun u q d hd hq off log hf => ?_,
        vcBehindSelf := fun h => by rw [Replica.clear_status, hr6stat] at h; exact absurd h (by decide),
        primaryStartedNew := fun v' dvcs hst p hp hpp => ?_,
        startedOnceNew := fun v' d1 h1' d2 h2' => ?_,
        extendsOld := fun v' dvcs b hv' hb => ?_,
        extendsNew := fun v' dvcs b hv' hb => ?_,
        rrNonceNew := fun dst v' n q stt hx => by have := (hmsg_spec _ hx).1; exact (nomatch this),
        belowNew := fun x hx z hz => by rw [(hmsg_spec x hx).1]; trivial,
        recoverySelf := fun h => by rw [Replica.clear_status, hr6stat] at h; exact absurd h (by decide),
        recoveryOk := fun _ _ _ _ _ _ _ _ _ _ _ y hy o h => by rw [(hmsg_spec y hy).1] at h; exact (nomatch h),
        recoveryRR := fun _ _ _ _ dst v' n p stt hx => by have := (hmsg_spec _ hx).1; exact (nomatch this),
        coveredSelf := fun i hi => ?_,
        agreeSelf := fun z hz hne hl i e e' he he' => ?_,
        startedViewsNew := fun v' dvcs hst => ?_,
        fragStartedNew := fun v' off log hf hpos => ?_,
        selfStarted := fun _ _ => ⟨V, by rw [Replica.clear_lastNormalView, hr6l]; exact List.mem_append_right _ (List.mem_singleton.mpr rfl)⟩,
        acksStartedNew := fun x hx u o q h => by rw [(hmsg_spec x hx).1] at h; exact (nomatch h),
        svcPosNew := fun x hx v' q h => by rw [(hmsg_spec x hx).1] at h; exact (nomatch h),
        transferSelf := fun h => by rw [Replica.clear_status, hr6stat] at h; exact absurd h (by decide),
        rrPrimaryNew := fun x hx v' n q stt h => by rw [(hmsg_spec x hx).1] at h; exact (nomatch h),
        rrNotSelfNew := fun x hx v' n p stt h => by rw [(hmsg_spec x hx).1] at h; exact (nomatch h),
        rrNotSelfSelf := fun h => by rw [Replica.clear_status, hr6stat] at h; exact absurd h (by decide),
        senderIdsNew := fun x hx => by rw [(hmsg_spec x hx).1]; trivial,
        startedIdsNew := fun v' dvcs hst y d hd => ?_,
        dvcsSelf := fun h => by rw [Replica.clear_status, hr6stat] at h; exact absurd h (by decide),
        rrsSelf := fun h => by rw [Replica.clear_status, hr6stat] at h; exact absurd h (by decide) }
      · -- local
        exact hloc6.clear
      · -- oneLogNew
        rcases hnewHolds _ i e h with ⟨rfl, he⟩ | ⟨y, d, hd, rfl, he⟩
        · rcases Holds.after.mp h' with h' | h'
          · exact absurd h' (hnoholds i e')
          · rcases hnewHolds _ i e' h' with ⟨_, he'⟩ | ⟨y, d, hd, hl, _⟩
            · rw [he] at he'; exact Option.some.inj he'
            · exact absurd (hVbehind y d hd) (by rw [hl]; exact Nat.lt_irrefl _)
        · rcases Holds.after.mp h' with h' | h'
          · exact h1.oneLog.1 _ i e e' (hVholds y d hd i e he) h'
          · rcases hnewHolds _ i e' h' with ⟨hl, _⟩ | ⟨y', d', hd', hl, he'⟩
            · exact absurd (hVbehind y d hd) (by rw [hl]; exact Nat.lt_irrefl _)
            · exact h1.oneLog.1 _ i e e' (hVholds y d hd i e he) (hl ▸ hVholds y' d' hd' i e' he')
      · -- oneLogSelf
        have he' : best.log[i]? = some e := by rw [Replica.clear_log, hr6log] at he; exact he
        have hh' : Holds ((s.drainOf id r2).after id r6.clear out [(r1.viewNumber, V)]) r1.viewNumber i e' := by
          rw [Replica.clear_lastNormalView, hr6l] at hh; exact hh
        rcases Holds.after.mp hh' with h | h
        · exact absurd h (hnoholds i e')
        · rcases hnewHolds _ i e' h with ⟨_, hb⟩ | ⟨y, d, hd, hl, _⟩
          · rw [he'] at hb; exact Option.some.inj hb
          · exact absurd (hVbehind y d hd) (by rw [hl]; exact Nat.lt_irrefl _)
      · -- oneLogOld
        rcases hnewHolds _ i e' h with ⟨hl, _⟩ | ⟨y, d, hd, hl, he'⟩
        · exfalso
          by_cases hzr : z.status = .recovering
          · rw [hznone z hz hzr] at he; simp at he
          · exact hnoreplica z hz hl hzr
        · exact h1.oneLog.2 z hz i e e' he (hl ▸ hVholds y d hd i e' he')
      · -- survivesOld
        refine ⟨fun dst log o k hx => ?_, fun u' q d hd hl => ?_,
          fun dst n q stt hx => absurd (hmsg_spec _ hx).1 (by simp [hmsg]),
          fun dst log a b k hx => absurd (hmsg_spec _ hx).1 (by simp [hmsg]),
          fun dst c n op k hx => absurd (hmsg_spec _ hx).1 (by simp [hmsg]), fun hl _ => ?_⟩
        · have hx2 := (hmsg_spec _ hx).1
          simp only [hmsg, Message.startView.injEq] at hx2
          obtain ⟨hu', rfl, _, _⟩ := hx2
          rw [hr6log]
          exact hbestHolds v'' i e hc (by rw [hu', hr6v] at hu; exact hu)
        · obtain ⟨rfl, hd'⟩ := hdvcnew u' q d hd
          rcases hVdvc q d hd' with hd'' | ⟨_, rfl⟩
          · exact (h1.survives v'' i e hc u hu).2.1 _ q d hd'' hl
          · exact (h1.survives v'' i e hc u hu).2.2.2.2.2 r2.clear hmem2 hl hnr
        · rw [Replica.clear_lastNormalView, hr6l] at hl
          rw [Replica.clear_log, hr6log]
          exact hbestHolds v'' i e hc (hl ▸ hu)
      · -- survivesNew: nothing new is committed
        exfalso; apply hold
        obtain ⟨hh, hq⟩ := hc
        have hq' := QuorumAcked.after_noOk hnoOk hq
        rcases Holds.after.mp hh with hh | hh
        · exact ⟨hh, hq'⟩
        · rcases hnewHolds _ i e hh with ⟨rfl, _⟩ | ⟨y, d, hd, rfl, he⟩
          · exfalso
            obtain ⟨Q, hnd, hlen, hQ⟩ := hq'
            have h2 : 2 ≤ Q.length := Nat.le_trans (by
              show 2 ≤ s.config.replicaCount / 2 + 1
              have h2 : 2 ≤ s.config.replicaCount := hinv.two; omega) hlen
            obtain ⟨q, hqQ, hqne⟩ := exists_ne_of_nodup hnd h2 (s.config.primaryId r1.viewNumber)
            rcases (hQ q hqQ).2 with h | ⟨dst, o, hs, _⟩
            · exact hqne h
            · exact hnoack dst o q hs
          · exact ⟨hVholds y d hd i e he, hq'⟩
      · -- acksSelf
        obtain ⟨_, hle, hq⟩ := Replica.addAcksForUncommitted_mem hoa
        refine ⟨hle, by rw [hq]; exact List.pairwise_singleton _ _, fun q hq' => ?_⟩
        rw [hq, List.mem_singleton] at hq'; subst hq'
        exact ⟨hr6selfN, Or.inl rfl⟩
      · -- acksHoldSelf
        rcases Sent.after.mp hs with hs | hs
        · have := (h1.acksHold dst v' o r6.clear.selfId hs r2.clear hmem2 hr6self.symm).1
          refine ⟨by rw [Replica.clear_lastNormalView, hr6l]; exact Nat.le_of_lt (Nat.lt_of_le_of_lt this hvcb), fun hl _ => ?_⟩
          rw [Replica.clear_lastNormalView, hr6l] at hl
          exact absurd (Nat.lt_of_le_of_lt this hvcb) (by rw [hl]; exact Nat.lt_irrefl _)
        · exact absurd (hmsg_spec _ hs).1 (by simp [hmsg])
      · -- longestSelf
        refine ⟨fun off log hf => ?_, fun q hq hql hqn => ?_, fun dst o q hs => ?_⟩
        · rw [Replica.clear_lastNormalView, hr6l] at hf
          rw [Replica.clear_log, hr6log]
          rcases Frag.after.mp hf with hf | hf
          · exact absurd hf (hnofrag off log)
          · rcases hnew _ off log hf with ⟨_, rfl, rfl⟩ | ⟨y, d, hd, hl, _, _⟩
            · simp
            · exact absurd (hVbehind y d hd) (by rw [hl]; exact Nat.lt_irrefl _)
        · rcases hrepl' q hq with rfl | ⟨hq, _⟩
          · exact Nat.le_refl _
          · rw [Replica.clear_lastNormalView, hr6l] at hql
            exact absurd hqn (fun h => hnoreplica q hq hql h)
        · rcases Sent.after.mp hs with hs | hs
          · rw [Replica.clear_lastNormalView, hr6l] at hs
            exact absurd hs (hnoack dst o q)
          · exact absurd (hmsg_spec _ hs).1 (by simp [hmsg])
      · -- longestOld
        refine ⟨fun off log hf => ?_, fun hl _ => ?_, fun x hx o q h => absurd ((hmsg_spec x hx).1.symm.trans h) (by simp [hmsg])⟩
        · rcases hnew _ off log hf with ⟨hl, rfl, rfl⟩ | ⟨y, d, hd, hl, rfl, rfl⟩
          · exfalso; apply hne
            show p.selfId = r1.selfId
            rw [hpp, hl]; exact hprim.symm
          · rcases hVdvc y d hd with hd' | ⟨_, rfl⟩
            · have := (h1.longest p hp hpn hpp).1 0 d.log (by rw [hl]; exact hd'.frag)
              simpa using this
            · simp only [Nat.zero_add]
              exact (h1.longest p hp hpn hpp).2.1 r2.clear hmem2 hl.symm hnr
        · exfalso; apply hne
          rw [Replica.clear_lastNormalView, hr6l] at hl
          show p.selfId = r1.selfId
          rw [hpp, ← hl]; exact hprim.symm
      · -- chosenNew
        have hx2 := (hmsg_spec _ hx).1
        simp only [hmsg, Message.startView.injEq] at hx2
        obtain ⟨rfl, rfl, _, _⟩ := hx2
        refine ⟨V, best, ?_, hVq, hVnd, hbest, ?_⟩
        · exact hr6v ▸ mem_started_after.mpr (Or.inr (List.mem_singleton.mpr rfl))
        · rw [hr6log]
      · -- dvcCoversNew
        obtain ⟨rfl, hd'⟩ := hdvcnew u q d hd
        rcases Sent.after.mp hs with hs | hs
        · rcases hVdvc q d hd' with hd'' | ⟨rfl, rfl⟩
          · exact h1.dvcCovers _ q d hd'' dst o hs
          · exact (h1.acksHold dst _ o _ hs r2.clear hmem2 rfl).2 rfl hnr
        · exact absurd (hmsg_spec _ hs).1 (by simp [hmsg])
      · -- dvcBehindNew
        obtain ⟨rfl, hd'⟩ := hdvcnew u q d hd
        exact hVbehind q d hd'
      · -- dvcBelowNew
        obtain ⟨rfl, hd'⟩ := hdvcnew u q d hd
        rcases hrepl' z hz with rfl | ⟨hz, hne⟩
        · rw [Replica.clear_viewNumber, hr6v]
        · rcases hVdvc q d hd' with hd'' | ⟨rfl, _⟩
          · exact h1.dvcBelow _ q d hd'' z hz hq
          · exact absurd hq hne
      · -- dvcAfterAcksNew
        obtain ⟨rfl, hd'⟩ := hdvcnew u q d hd
        rcases Sent.after.mp hs with hs | hs
        · rcases hVdvc q d hd' with hd'' | ⟨rfl, rfl⟩
          · exact h1.dvcAfterAcks _ q d hd'' dst v' o hs hlt'
          · exact (h1.acksHold dst v' o _ hs r2.clear hmem2 rfl).1
        · exact absurd (hmsg_spec _ hs).1 (by simp [hmsg])
      · -- dvcAfterOwnNew
        obtain ⟨rfl, hd'⟩ := hdvcnew u q d hd
        rcases mem_started_after.mp hv' with hv' | hv'
        · rcases hVdvc q d hd' with hd'' | ⟨rfl, rfl⟩
          · exact h1.dvcAfterOwn _ q d hd'' v' dvcs hv' hq hlt'
          · exact h1.primaryStarted v' dvcs hv' r2.clear hmem2 hq
        · rw [List.mem_singleton, Prod.mk.injEq] at hv'
          obtain ⟨rfl, _⟩ := hv'
          exact absurd hlt' (Nat.lt_irrefl _)
      · -- dvcAfterOwnSt
        rw [List.mem_singleton, Prod.mk.injEq] at hv'
        obtain ⟨rfl, _⟩ := hv'
        have := h1.dvcBelow u q d hd r2.clear hmem2 (by rw [hq]; exact hprim)
        exact absurd (Nat.lt_of_lt_of_le hlt' this) (Nat.lt_irrefl _)
      · -- dvcPrimaryNew
        obtain ⟨rfl, hd'⟩ := hdvcnew u q d hd
        rcases Frag.after.mp hf with hf | hf
        · rcases hVdvc q d hd' with hd'' | ⟨rfl, rfl⟩
          · exact h1.dvcPrimary _ q d hd'' hq off log hf
          · exact (h1.longest r2.clear hmem2 hnr hq).1 off log hf
        · rcases hnew _ off log hf with ⟨hl, _, _⟩ | ⟨y', d', hd'', hl, rfl, rfl⟩
          · exact absurd (hVbehind q d hd') (by rw [hl]; exact Nat.lt_irrefl _)
          · simp only [Nat.zero_add]
            rcases hVdvc q d hd' with hd3 | ⟨rfl, rfl⟩
            · exact hVle y' d' hd'' _ q d hd3 hq hl.symm
            · rcases hVdvc y' d' hd'' with hd4 | ⟨_, rfl⟩
              · have := (h1.longest r2.clear hmem2 hnr hq).1 0 d'.log (by have hl' : r1.lastNormalView = d'.lastNormalView := hl; show Frag _ r1.lastNormalView 0 d'.log; rw [hl']; exact hd4.frag)
                simpa using this
              · exact Nat.le_refl _
      · -- dvcPrimaryFrag
        rcases hnew _ off log hf with ⟨hl, _, _⟩ | ⟨y', d', hd', hl, rfl, rfl⟩
        · exact absurd hl (hnodvc_v u q d hd)
        · simp only [Nat.zero_add]
          exact hVle y' d' hd' u q d hd hq hl.symm
      · -- primaryStartedNew
        rw [List.mem_singleton, Prod.mk.injEq] at hst
        obtain ⟨rfl, _⟩ := hst
        rcases hrepl' p hp with rfl | ⟨_, hne⟩
        · rw [Replica.clear_lastNormalView, hr6l]
        · exact absurd (hpp.trans hprim.symm) hne
      · -- startedOnceNew
        rw [List.mem_singleton, Prod.mk.injEq] at h1'
        obtain ⟨rfl, rfl⟩ := h1'
        rcases mem_started_after.mp h2' with h2' | h2'
        · exact absurd h2' (hnotstarted d2)
        · rw [List.mem_singleton, Prod.mk.injEq] at h2'; exact h2'.2.symm
      · -- extendsOld
        refine ⟨fun u q d hd hl => ?_, fun dst n q stt hx => absurd (hmsg_spec _ hx).1 (by simp [hmsg]),
          fun dst log a e k hx => absurd (hmsg_spec _ hx).1 (by simp [hmsg]), fun hl _ => ?_⟩
        · obtain ⟨rfl, hd'⟩ := hdvcnew u q d hd
          rcases hVdvc q d hd' with hd'' | ⟨_, rfl⟩
          · exact (h1.extendsBase v' dvcs b hv' hb).1 _ q d hd'' hl
          · exact (h1.extendsBase v' dvcs b hv' hb).2.2.2 r2.clear hmem2 hl hnr
        · rw [Replica.clear_lastNormalView, hr6l] at hl
          exact absurd hv' (hl ▸ hnotstarted dvcs)
      · -- extendsNew
        rw [List.mem_singleton, Prod.mk.injEq] at hv'
        obtain ⟨rfl, rfl⟩ := hv'
        rw [hbest] at hb; obtain rfl := Option.some.inj hb
        refine ⟨fun u q d hd hl => ?_, fun dst n q stt hs => ?_, fun dst log a e k hs => ?_, fun z hz hl hn => ?_⟩
        · rcases DvcOf.after.mp hd with hd | hd
          · exact absurd hl (hnodvc_v u q d hd)
          · obtain ⟨_, hd'⟩ := hdvcnew u q d hd
            exact absurd hl (Nat.ne_of_lt (hVbehind q d hd'))
        · rcases Sent.after.mp hs with hs | hs
          · exact absurd (Frag.recovery hs) (hnofrag 0 stt.log)
          · exact absurd (hmsg_spec _ hs).1 (by simp [hmsg])
        · rcases Sent.after.mp hs with hs | hs
          · exact absurd (Frag.newState hs) (hnofrag a log)
          · exact absurd (hmsg_spec _ hs).1 (by simp [hmsg])
        · rcases hrepl' z hz with rfl | ⟨hz, _⟩
          · rw [Replica.clear_log, hr6log]
          · exact absurd hn (fun h => hnoreplica z hz hl h)
      · -- coveredSelf
        rw [Replica.clear_log, hr6log] at hi
        rw [Replica.clear_lastNormalView, hr6l]
        exact ⟨best.log[i], hsvNew i _ (List.getElem?_eq_getElem hi)⟩
      · -- agreeSelf
        exfalso
        rw [Replica.clear_lastNormalView, hr6l] at hl
        by_cases hzr : z.status = .recovering
        · rw [hznone z hz hzr] at he'; simp at he'
        · exact hnoreplica z hz hl hzr
      · -- startedViewsNew
        rw [List.mem_singleton, Prod.mk.injEq] at hst
        obtain ⟨rfl, _⟩ := hst
        obtain ⟨x, hx⟩ := hex
        have hx2 := (hmsg_spec x hx).1
        obtain ⟨dst, m'⟩ := x
        simp only at hx2; subst hx2
        refine ⟨dst, r6.log, r6.opNumber, r6.commitNumber, ?_⟩
        have := Sent.after_new (s := s.drainOf id r2) (id := id) (r' := r6.clear) (st := [(r1.viewNumber, V)]) hx
        rw [hmsg, hr6v] at this; exact this
      · -- fragStartedNew
        rcases hnew _ off log hf with ⟨rfl, _, _⟩ | ⟨y, d, hd, rfl, _, _⟩
        · exact ⟨V, mem_started_after.mpr (Or.inr (List.mem_singleton.mpr rfl))⟩
        · rcases hVdvc y d hd with hd' | ⟨_, rfl⟩
          · exact (h1.startedViews.2.1 _ 0 d.log hd'.frag hpos).imp fun dvcs h => started_after_of h
          · exact (h1.startedViews.2.2 r2.clear hmem2 hnr hpos).imp fun dvcs h => started_after_of h
      · -- startedIdsNew
        rw [List.mem_singleton, Prod.mk.injEq] at hst
        obtain ⟨_, rfl⟩ := hst
        exact hVN y d hd

end Record

/-! ### Starting a view change -/

/-- With no `StartViewChange` recorded and a threshold of at least one,
`maybeSendDoViewChange` does nothing. -/
theorem Replica.maybeSendDoViewChange_of_none (m : Machine Op Output St) (r : Replica Op Output St)
    (hsvc : r.startViewChangeFrom = []) (hf : 1 ≤ r.config.replicaCount / 2) :
    Replica.maybeSendDoViewChange m r = r := by
  unfold Replica.maybeSendDoViewChange
  split
  · rfl
  · try simp only
    rw [if_pos]
    rw [hsvc]; show 0 < r.config.replicaCount / 2; omega

/-- `startViewChange` for a later view. With at least two replicas the
DoViewChange threshold `f` is at least one, so the replica, having just
cleared its view-change state, sends none yet and ends in view-change
status. -/
theorem Replica.startViewChange_eq (m : Machine Op Output St) (r : Replica Op Output St) (v : ViewNumber)
    (hN : 2 ≤ r.config.replicaCount) :
    Replica.startViewChange m r v = ({ r.clearViewChangeState with
      viewChangeAttempts := (if r.status = .viewChange then r.viewChangeAttempts + 1 else r.viewChangeAttempts),
      viewNumber := v, status := .viewChange, catchingUp := false, idlePeriodsWaiting := 0 } :
      Replica Op Output St).sendToOthers (.startViewChange v r.selfId) := by
  unfold Replica.startViewChange
  simp only
  rw [Replica.maybeSendDoViewChange_of_none]
  · rfl
  · rw [Replica.sendToOthers_eq_withOutbox]; rfl
  · rw [Replica.sendToOthers_config]; show 1 ≤ r.config.replicaCount / 2; omega

section ViewChangeLinks
variable {s : System Op Output St} {id : ReplicaId} (hlt : id < s.replicas.length)
  {r1 : Replica Op Output St} (hinv : Inv (s.drainOf id r1))
include hlt hinv

theorem Inv.startViewChange (m : Machine Op Output St) (v : ViewNumber) (hv : r1.viewNumber < v)
    (hnr : r1.status ≠ .recovering) (hcv : r1.chosenDoViewChanges = none) :
    Inv (s.drainOf id (Replica.startViewChange m r1 v)) := by
  have hloc := hinv.drainOf_local hlt
  have hconf := hinv.drainOf_config hlt
  rw [Replica.startViewChange_eq m r1 v (hconf ▸ hinv.two)]
  have h1 : Inv (s.drainOf id ({ r1.clearViewChangeState with
      viewChangeAttempts := (if r1.status = .viewChange then r1.viewChangeAttempts + 1 else r1.viewChangeAttempts),
      viewNumber := v, status := .viewChange, catchingUp := false, idlePeriodsWaiting := 0 } : Replica Op Output St)) := by
    refine hinv.drainKeepLog hlt rfl rfl rfl rfl rfl (hinv.drainOf_noPanic hlt) rfl rfl (Or.inl hcv) (Nat.le_of_lt hv)
      ?_ hnr (fun h => by simp at h) (hinv.drainOf_backed hlt) (fun h => by simp at h) (fun h => by simp at h)
      (fun _ => Nat.lt_of_le_of_lt hloc.2.1 hv) (fun h => by simp at h)
      (fun _ => ⟨by simp [Replica.clearViewChangeState], fun x d hd => by simp [Replica.clearViewChangeState] at hd⟩)
    obtain ⟨h1, h2, _, _, _⟩ := hloc
    refine ⟨h1, Nat.le_trans h2 (Nat.le_of_lt hv), ?_, ?_, ?_⟩
    · rintro (h | h) <;> simp at h
    · intro h; simp at h
    · intro h; simp at h
  exact h1.drainSendToOthers hlt _ (fun dst _ _ s' h' hr' =>
    MsgOK.startViewChange h' hr' dst (Nat.lt_of_le_of_lt (Nat.zero_le _) hv))

theorem Inv.sendDoViewChange (m : Machine Op Output St) (hvc : r1.status = .viewChange)
    (hcv : r1.chosenDoViewChanges = none) : Inv (s.drainOf id (Replica.sendDoViewChange m r1)) := by
  have hconf := hinv.drainOf_config hlt
  unfold Replica.sendDoViewChange
  try simp only
  split
  · rename_i hp
    exact hinv.recordDoViewChange hlt m r1.selfId _ hvc (by rw [← hconf]; exact hp.symm) hcv
      (hinv.drainOf_selfIdLt hlt) (Or.inr ⟨rfl, rfl⟩)
  · exact hinv.drainSend hlt (MsgOK.doViewChange hinv (s.drainOf_replicas_self r1 hlt) _ hvc)

theorem Inv.maybeSendDoViewChange (m : Machine Op Output St) (hnr : r1.status ≠ .recovering)
    (hcv : r1.chosenDoViewChanges = none) : Inv (s.drainOf id (Replica.maybeSendDoViewChange m r1)) := by
  have hloc := hinv.drainOf_local hlt
  unfold Replica.maybeSendDoViewChange
  split
  · exact hinv
  · rename_i hg
    have hvc : r1.status = .viewChange := by
      rcases Decidable.em (r1.status = .viewChange) with h | h
      · exact h
      · exact absurd (Or.inl h) hg
    try simp only
    split
    · exact hinv
    · have h1 : Inv (s.drainOf id ({ r1 with doViewChangeSent := true } : Replica Op Output St)) := by
        refine hinv.drainKeepLog hlt rfl rfl rfl rfl rfl (hinv.drainOf_noPanic hlt) rfl rfl (Or.inr rfl) (Nat.le_refl _)
          (hloc.withDoViewChangeSent true) hnr hnr (hinv.drainOf_backed hlt) (hinv.drainOf_catching hlt)
          (fun hn hp oa hoa => hinv.drainOf_acks hlt hn hp oa hoa) (hinv.drainOf_vcBehind hlt)
          (hinv.drainOf_transfer hlt) (hinv.drainOf_dvcs hlt)
      exact h1.sendDoViewChange hlt m hvc hcv

theorem Inv.noteStartViewChange (m : Machine Op Output St) (q : ReplicaId) (hnr : r1.status ≠ .recovering)
    (hcv : r1.chosenDoViewChanges = none) : Inv (s.drainOf id (Replica.noteStartViewChange m r1 q)) := by
  have hloc := hinv.drainOf_local hlt
  unfold Replica.noteStartViewChange
  have h1 : Inv (s.drainOf id ({ r1 with startViewChangeFrom := (NatSet.insert r1.startViewChangeFrom q).1 } :
      Replica Op Output St)) := by
    refine hinv.drainKeepLog hlt rfl rfl rfl rfl rfl (hinv.drainOf_noPanic hlt) rfl rfl (Or.inr rfl) (Nat.le_refl _)
      (hloc.withStartViewChangeFrom _) hnr hnr (hinv.drainOf_backed hlt) (hinv.drainOf_catching hlt)
      (fun hn hp oa hoa => hinv.drainOf_acks hlt hn hp oa hoa) (hinv.drainOf_vcBehind hlt)
      (hinv.drainOf_transfer hlt) (hinv.drainOf_dvcs hlt)
  exact h1.maybeSendDoViewChange hlt m hnr hcv

end ViewChangeLinks

/-- After `startViewChange`, what the later steps need to know. -/
theorem Replica.startViewChange_facts (m : Machine Op Output St) (r : Replica Op Output St) (v : ViewNumber)
    (hN : 2 ≤ r.config.replicaCount) :
    (Replica.startViewChange m r v).status = .viewChange ∧
    (Replica.startViewChange m r v).chosenDoViewChanges = r.chosenDoViewChanges ∧
    (Replica.startViewChange m r v).viewNumber = v ∧
    (Replica.startViewChange m r v).selfId = r.selfId ∧
    (Replica.startViewChange m r v).config = r.config := by
  rw [Replica.startViewChange_eq m r v hN, Replica.sendToOthers_eq_withOutbox]
  exact ⟨rfl, rfl, rfl, rfl, rfl⟩

/-! ### The handlers -/

section Handlers
variable {s : System Op Output St} (hinv : Inv s) {id : ReplicaId} {r : Replica Op Output St}
  (hr : s.replicas[id]? = some r)
include hinv hr

theorem Inv.onStartViewChange (m : Machine Op Output St) {v : ViewNumber} {q dst : ReplicaId}
    (hnr : r.status ≠ .recovering) (hsent : Sent s dst (.startViewChange v q)) :
    Inv (s.drainOf id (Replica.onStartViewChange m r v q)) := by
  have hlt := hlt_of_getElem hr
  have h0 := hinv.drainOf_start hr
  have hmem := List.mem_of_getElem? hr
  have hconf := hinv.config_eq hmem
  have hclean := hinv.clean r hmem
  have hpos : 0 < v := hinv.svcPos dst v q hsent
  unfold Replica.onStartViewChange
  split
  · exact h0
  · rename_i hlt'
    split
    · rename_i hgt
      have h1 := h0.startViewChange hlt m v hgt hnr hclean.2
      obtain ⟨f1, f2, _, _, _⟩ := Replica.startViewChange_facts m r v (hconf ▸ hinv.two)
      exact h1.noteStartViewChange hlt m q (by rw [f1]; decide) (by rw [f2]; exact hclean.2)
    · split
      · split
        · rename_i hnp
          have hv : v = r.viewNumber := Nat.le_antisymm (Nat.le_of_not_lt (by assumption)) (Nat.le_of_not_lt hlt')
          exact h0.drainSend hlt (MsgOK.startView h0 (s.drainOf_replicas_self r hlt) q hnp.1 hnp.2 (hv ▸ hpos))
        · exact h0
      · exact h0.noteStartViewChange hlt m q hnr hclean.2

theorem Inv.onDoViewChange (m : Machine Op Output St) {v : ViewNumber} {x dst : ReplicaId} {l : ViewNumber}
    {log : List (LogEntry Op)} {o : OpNumber} {k : CommitNumber} (hnr : r.status ≠ .recovering)
    (hsent : Sent s dst (.doViewChange v x l log o k)) :
    Inv (s.drainOf id (Replica.onDoViewChange m r v x ⟨l, log, k⟩)) := by
  have hlt := hlt_of_getElem hr
  have h0 := hinv.drainOf_start hr
  have hmem := List.mem_of_getElem? hr
  have hconf := hinv.config_eq hmem
  have hclean := hinv.clean r hmem
  have hwf := hinv.wf _ hsent
  have hxN : x < s.config.replicaCount := hinv.senderIds dst _ hsent
  have hdvc : DvcOf s v x ⟨l, log, k⟩ := hinv.dvcOf_of_sent hsent
  have hbehind : l < v := hinv.dvcBehind v x _ hdvc
  have hsent' : Sent s dst (.doViewChange v x l log log.length k) := by rw [hwf.1]; exact hsent
  unfold Replica.onDoViewChange
  split
  · exact h0
  · rename_i hg
    have hv : r.viewNumber ≤ v := Nat.le_of_not_lt fun h => hg (Or.inl h)
    have hp : r.config.primaryId v = r.selfId := by
      rcases Decidable.em (r.config.primaryId v = r.selfId) with h | h
      · exact h
      · exact absurd (Or.inr h) hg
    have hp' : r.selfId = s.config.primaryId v := by rw [← hconf]; exact hp.symm
    split
    · rename_i hgt
      have h1 := h0.startViewChange hlt m v hgt hnr hclean.2
      obtain ⟨f1, f2, f3, f4, _⟩ := Replica.startViewChange_facts m r v (hconf ▸ hinv.two)
      refine h1.recordDoViewChange hlt m x ⟨l, log, k⟩ f1 (by rw [f4, f3]; exact hp') (by rw [f2]; exact hclean.2) hxN
        (Or.inl ⟨dst, ?_⟩)
      show Sent _ dst (.doViewChange (Replica.startViewChange m r v).viewNumber x l log log.length k)
      rw [f3]; exact Sent.after_of hsent'
    · rename_i hngt
      have hv' : v = r.viewNumber := Nat.le_antisymm (Nat.le_of_not_lt hngt) hv
      split
      · rename_i hn
        have hprim : r.isPrimary = true := by
          unfold Replica.isPrimary Replica.primaryId; rw [← hv']; exact decide_eq_true hp.symm
        exact h0.drainSend hlt (MsgOK.startView h0 (s.drainOf_replicas_self r hlt) x hn hprim
          (hv' ▸ Nat.lt_of_le_of_lt (Nat.zero_le _) hbehind))
      · rename_i hnn
        have hvc : r.status = .viewChange := by
          rcases hs : r.status with _ | _ | _ | _
          · exact absurd hs hnn
          · exact absurd (hv' ▸ hp') (hinv.transferNotPrimary r hmem hs)
          · exact absurd hs hnr
          · rfl
        exact h0.recordDoViewChange hlt m x ⟨l, log, k⟩ hvc (hv' ▸ hp') hclean.2 hxN
          (Or.inl ⟨dst, by rw [← hv']; exact Sent.after_of hsent'⟩)

theorem Inv.onStartView (m : Machine Op Output St) {v : ViewNumber} {log : List (LogEntry Op)} {o : OpNumber}
    {k : CommitNumber} {dst : ReplicaId} (hnr : r.status ≠ .recovering)
    (hsent : Sent s dst (.startView v log o k)) :
    Inv (s.drainOf id (Replica.onStartView m r v log k)) := by
  have hlt := hlt_of_getElem hr
  have h0 := hinv.drainOf_start hr
  have hmem := List.mem_of_getElem? hr
  have hconf := hinv.config_eq hmem
  have hclean := hinv.clean r hmem
  have hloc := hinv.local_ r hmem
  have hwf := hinv.wf _ hsent
  have hdrain : s.drainOf id r = s.after id r.clear [] [] := by
    simp only [System.drainOf, Replica.startedList, hinv.drained r hmem, hclean.2]
  unfold Replica.onStartView
  split
  · exact h0
  · rename_i hg
    try simp only
    have hv : r.viewNumber ≤ v := Nat.le_of_not_lt fun h => hg (Or.inl h)
    have hlv : r.lastNormalView < v := by
      rcases Nat.lt_or_eq_of_le hv with h | h
      · exact Nat.lt_of_le_of_lt hloc.2.1 h
      · have hvc : r.status = .viewChange := by
          by_contra hne; exact hg (Or.inr ⟨h.symm, hne⟩)
        exact h ▸ hinv.vcBehind r hmem hvc
    have hvpos : 0 < v := Nat.lt_of_le_of_lt (Nat.zero_le _) hlv
    obtain ⟨dvcs, hst⟩ := hinv.startedViews.2.1 v 0 log (.startView hsent) hvpos
    have hnp : r.selfId ≠ s.config.primaryId v := fun h =>
      absurd (hinv.primaryStarted v dvcs hst r hmem h) (Nat.not_le.mpr hlv)
    have hsurv : ∀ v' i e, Committed s v' i e → v' < v → log[i]? = some e :=
      fun v' i e hc hlt' => (hinv.survives v' i e hc v hlt').1 dst log o k hsent
    have hk : r.commitNumber ≤ log.length := by
      by_contra hgt
      obtain ⟨e, v'', _, hle, hc, _⟩ := hinv.committed_entry hmem (Nat.lt_of_not_le hgt)
      have := hsurv v'' _ e hc (Nat.lt_of_le_of_lt hle hlv)
      exact absurd (List.getElem?_eq_some_iff.mp this).1 (Nat.lt_irrefl _)
    set r2 : Replica Op Output St := ({ r with viewNumber := v } : Replica Op Output St).installLog log with hr2
    have hr2log : r2.log = log := by
      rw [hr2, Replica.installLog_log]; exact if_neg (Nat.not_lt.mpr hk)
    have hr2k : r2.commitNumber = r.commitNumber := by rw [hr2, Replica.installLog_commitNumber]
    have hr2v : r2.viewNumber = v := by rw [hr2, Replica.installLog_viewNumber]
    have hr2self : r2.selfId = r.selfId := by rw [hr2, Replica.installLog_selfId]
    have hr2conf : r2.config = r.config := by rw [hr2, Replica.installLog_config]
    have hr2out : r2.outbox = r.outbox := by rw [hr2, Replica.installLog_outbox]
    have hr2chosen : r2.chosenDoViewChanges = r.chosenDoViewChanges := by
      rw [hr2]; unfold Replica.installLog; split <;> rfl
    have hr2nonce : r2.recoveryNonce = r.recoveryNonce := by
      rw [hr2]; unfold Replica.installLog; split <;> rfl
    have hr2panic : r2.panicked = r.panicked := by
      rw [hr2]; unfold Replica.installLog; rw [if_neg (Nat.not_lt.mpr hk)]
    have hL : ∀ i e, log[i]? = some e → Holds s v i e :=
      fun i e hi => ⟨0, log, .startView hsent, Nat.zero_le _, by simpa using hi⟩
    have hbk : Backed s v r.commitNumber := by
      intro i hi
      obtain ⟨e, v'', hget, hle, hc, _⟩ := hinv.committed_entry hmem hi
      exact ⟨e, v'', Nat.le_of_lt (Nat.lt_of_le_of_lt hle hlv), hc, hL i e (hsurv v'' i e hc (Nat.lt_of_le_of_lt hle hlv))⟩
    have h4 : Inv (s.drainOf id ({ (Replica.commitUpTo m r2 k false).enterNormal with acks := [] } : Replica Op Output St)) := by
      refine h0.drainReplace hlt (by simp [hr2out]) (by simp [Replica.startedList, hr2chosen, hclean.2]) ?_
      refine StepOK.install h0 (s.drainOf_replicas_self r hlt) (v := v) (L := log) rfl (by simp [hr2v])
        (by simp [hr2v]) (by simp [hr2log]) rfl (by simp [hr2self]) (by simp [hr2conf]) (by simp [hr2nonce]) ?_ rfl rfl rfl
        ?_ hv (Nat.le_of_lt hlv) ?_ ?_ ?_ hnp ?_ ?_ ?_ ?_
      · show (Replica.commitUpTo m r2 k false).panicked = false
        rw [commitUpTo_panicked m r2 k false (by rw [hr2k, hr2log]; exact hk) (by rw [hr2log]; rw [hwf.1]; exact hwf.2), hr2panic]
        exact hinv.noPanic r hmem
      · exact ((Replica.LocalInv.install_then_normal m ({ r with viewNumber := v } : Replica Op Output St) hloc.1 log k false).withAcks []).clear
      · intro i e hi; exact Holds.after_of (hL i e hi)
      · simp only [Replica.clear_commitNumber]
        show Backed _ v (Replica.commitUpTo m r2 k false).commitNumber
        refine Backed.after_of (Backed.downward (Backed.max hbk (hinv.backed.2 dst _ hsent)) ?_)
        rw [← hr2k]; exact commitUpTo_le_max m r2 k false
      · intro v' i e hc hlt'
        rw [hdrain] at hc
        exact hsurv v' i e (Committed.after_nil.mp hc) hlt'
      · intro dst' o' hs
        have := (hinv.acksHold dst' v o' r.selfId (by rw [hdrain] at hs; exact Sent.after_nil.mp hs) r hmem rfl).1
        exact absurd (Nat.lt_of_lt_of_le hlv this) (Nat.lt_irrefl _)
      · intro p hp hne hpn hpp hl
        have hp' : p ∈ s.replicas := by
          rw [hdrain] at hp
          rcases mem_after_replicas hinv.ids hr hp with h | ⟨h, _⟩
          · subst h; exact absurd rfl hne
          · exact h
        have := (hinv.longest p hp' hpn hpp).1 0 log (by rw [hl]; exact .startView hsent)
        simpa using this
      · intro dvcs' b hst' hb
        have hst'' : (v, dvcs') ∈ s.started := by rw [hdrain] at hst'; exact started_after_nil.mp hst'
        obtain ⟨dvcs0, best, hst0, _, _, hb0, hpre⟩ := hinv.chosen dst v log o k hsent
        obtain rfl := hinv.startedOnce v dvcs' dvcs0 hst'' hst0
        rw [hb] at hb0; obtain rfl := Option.some.inj hb0
        exact hpre.length_le
      · intro _; exact ⟨dvcs, by rw [hdrain]; exact started_after_of hst⟩
    unfold Replica.sendPrepareOk Replica.sendToPrimary
    exact h4.drainSend hlt (MsgOK.prepareOk h4 (s.drainOf_replicas_self _ hlt) _ rfl)

end Handlers

end Vsr
