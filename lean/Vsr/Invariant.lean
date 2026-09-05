import Vsr.Safety

/-!
Layers three to five of the safety invariant, stated. They are one
invariant, `Inv`, because they depend on each other: a replica catching up
keeps its committed prefix and takes the rest from the new view, and the
two agree only because committed entries survive view changes.

Every clause here has a `Bool` twin in `Vsr.Check` that the conformance
traces exercise; the statements were adjusted until those held.

The message fragments of a view's log are in `Frag`. They are persistent:
`sent` only grows, so a fact stated through them stays true, which is what
the consequents of the invariant need. Replica logs are not persistent, a
view change replaces them, so they appear only in antecedents and in
`OneLogPerView`, which relates them to the message fragments of their last
normal view.
-/

namespace Vsr

variable {Op Output St : Type}

/-- `msg` was sent to `to` at some point. -/
def Sent (s : System Op Output St) (to : ReplicaId) (msg : Message Op) : Prop := (to, msg) ∈ s.sent

/-- A piece of view `v`'s log, starting at index `off`, held by a message.
A `Prepare` is one entry at its op number; `NewState` a segment; `StartView`,
a `DoViewChange` dvc, and a primary's recovery state, whole logs, the dvc
belonging to the view its sender was last normal in. -/
inductive Frag (s : System Op Output St) : ViewNumber → Nat → List (LogEntry Op) → Prop
  | prepare {to v o c n op k} : Sent s to (.prepare v o c n op k) → Frag s v (o - 1) [⟨c, n, op⟩]
  | newState {to v log a b k} : Sent s to (.newState v log a b k) → Frag s v a log
  | startView {to v log o k} : Sent s to (.startView v log o k) → Frag s v 0 log
  | dvc {to v r l log o k} : Sent s to (.doViewChange v r l log o k) → Frag s l 0 log
  | recovery {to v n r st} : Sent s to (.recoveryResponse v n r (some st)) → Frag s v 0 st.log
  | started {v dvcs q dvc} : (v, dvcs) ∈ s.started → (q, dvc) ∈ dvcs →
      Frag s dvc.lastNormalView 0 dvc.log

/-- Some fragment of view `v` holds `e` at index `i`. -/
def Holds (s : System Op Output St) (v : ViewNumber) (i : Nat) (e : LogEntry Op) : Prop :=
  ∃ off log, Frag s v off log ∧ off ≤ i ∧ log[i - off]? = some e

/-- Layer three. The fragments of a view agree with one another, and every
replica's log agrees with the fragments of its last normal view. -/
def OneLogPerView (s : System Op Output St) : Prop :=
  (∀ v i e e', Holds s v i e → Holds s v i e' → e = e') ∧
  (∀ r ∈ s.replicas, ∀ i e e', r.log[i]? = some e → Holds s r.lastNormalView i e' → e = e')

/-- `q` acknowledged index `i` in view `v`: it is the primary, which
acknowledges its own ops without a message, or it sent a `PrepareOk` for
an op past `i`. -/
def Acked (s : System Op Output St) (v : ViewNumber) (i : Nat) (q : ReplicaId) : Prop :=
  q = s.config.primaryId v ∨ ∃ to o, Sent s to (.prepareOk v o q) ∧ i < o

def QuorumAcked (s : System Op Output St) (v : ViewNumber) (i : Nat) : Prop :=
  ∃ Q : List ReplicaId, Q.Nodup ∧ s.config.quorum ≤ Q.length ∧
    ∀ q ∈ Q, q < s.config.replicaCount ∧ Acked s v i q

/-- Entry `e` is committed at index `i` in view `v`. -/
def Committed (s : System Op Output St) (v : ViewNumber) (i : Nat) (e : LogEntry Op) : Prop :=
  Holds s v i e ∧ QuorumAcked s v i

/-- A commit number `k` in view `v` is backed: every index below it was
committed in a view no later than `v`, with the entry view `v` holds. -/
def Backed (s : System Op Output St) (v : ViewNumber) (k : Nat) : Prop :=
  ∀ i < k, ∃ e v', v' ≤ v ∧ Committed s v' i e ∧ Holds s v i e

/-- The commit number a message carries is backed. A `DoViewChange`
is judged by its last normal view. -/
def MsgBacked (s : System Op Output St) : Message Op → Prop
  | .prepare v _ _ _ _ k => Backed s v k
  | .commit v k => Backed s v k
  | .newState v _ _ _ k => Backed s v k
  | .startView v _ _ k => Backed s v k
  | .doViewChange _ _ l _ _ k => Backed s l k
  | .recoveryResponse v _ _ (some st) => Backed s v st.commitNumber
  | _ => True

/-- Layer four. Every replica's commit number, and every commit number a
message carries, is backed. -/
def CommitsBacked (s : System Op Output St) : Prop :=
  (∀ r ∈ s.replicas, Backed s r.lastNormalView r.commitNumber) ∧
  (∀ to (msg : Message Op), Sent s to msg → MsgBacked s msg)

/-- Layer five. Whatever was committed in view `v'` is held, at its index,
by every whole log of a later view, by every `NewState` segment of a later
view that reaches it, and by every replica whose last normal view is later
and that is not recovering. -/
def Survives (s : System Op Output St) : Prop :=
  ∀ v' i e, Committed s v' i e → ∀ v, v' < v →
    (∀ to log o k, Sent s to (.startView v log o k) → log[i]? = some e) ∧
    (∀ to v'' r log o k, Sent s to (.doViewChange v'' r v log o k) → log[i]? = some e) ∧
    (∀ to n r st, Sent s to (.recoveryResponse v n r (some st)) → st.log[i]? = some e) ∧
    (∀ to log a b k, Sent s to (.newState v log a b k) → a ≤ i → log[i - a]? = some e) ∧
    (∀ to c n op k, Sent s to (.prepare v (i + 1) c n op k) → (⟨c, n, op⟩ : LogEntry Op) = e) ∧
    (∀ v'' dvcs q dvc, (v'', dvcs) ∈ s.started → (q, dvc) ∈ dvcs → dvc.lastNormalView = v →
      dvc.log[i]? = some e) ∧
    (∀ r ∈ s.replicas, r.lastNormalView = v → r.status ≠ .recovering → r.log[i]? = some e)

/-! ### The helpers the induction needs -/

/-- Replica `i` of the list is the replica with id `i`. -/
def Ids (s : System Op Output St) : Prop :=
  ∀ i (r : Replica Op Output St), s.replicas[i]? = some r → r.selfId = i ∧ r.config = s.config

/-- A primary in normal status only records acknowledgements of its own
ops in its own view. -/
def AcksCurrent (s : System Op Output St) : Prop :=
  ∀ r ∈ s.replicas, r.status = .normal → r.isPrimary = true →
    ∀ oa ∈ r.acks, oa.1 ≤ r.log.length ∧
      ∀ q ∈ oa.2, q = r.selfId ∨ ∃ to, Sent s to (.prepareOk r.viewNumber oa.1 q)

/-- A replica catching up with a view is not its primary. -/
def CatchingUpNotPrimary (s : System Op Output St) : Prop :=
  ∀ r ∈ s.replicas, r.catchingUp = true → r.selfId ≠ r.config.primaryId r.viewNumber

/-- What an acknowledgement says stays true: the acknowledger's last
normal view is at least the view it acknowledged in, and while that is
still the view and it is not recovering, its log is still that long. -/
def AcksHold (s : System Op Output St) : Prop :=
  ∀ to v o q, Sent s to (.prepareOk v o q) → ∀ r ∈ s.replicas, r.selfId = q →
    v ≤ r.lastNormalView ∧ (r.lastNormalView = v → r.status ≠ .recovering → o ≤ r.log.length)

/-- `Prepare` and `Commit` never go to the primary of their view. -/
def PrimaryToOthers (s : System Op Output St) : Prop :=
  ∀ to (msg : Message Op), Sent s to msg →
    match msg with
    | .prepare v _ _ _ _ _ => to ≠ s.config.primaryId v
    | .commit v _ => to ≠ s.config.primaryId v
    | _ => True

/-- The primary of a view, while normal in it, holds the longest log of
the view: every fragment of the view, and every op acknowledged in it, is
within its log. -/
def PrimaryLongest (s : System Op Output St) : Prop :=
  ∀ p ∈ s.replicas, p.status = .normal → p.isPrimary = true →
    (∀ off log, Frag s p.viewNumber off log → off + log.length ≤ p.log.length) ∧
    (∀ q ∈ s.replicas, q.lastNormalView = p.viewNumber → q.status ≠ .recovering →
      q.log.length ≤ p.log.length) ∧
    (∀ to o q, Sent s to (.prepareOk p.viewNumber o q) → o ≤ p.log.length)

/-- Every entry a replica holds is covered by a message fragment of its
last normal view: nothing is in a log that was not sent. -/
def Covered (s : System Op Output St) : Prop :=
  ∀ r ∈ s.replicas, ∀ i, i < r.log.length → ∃ e, Holds s r.lastNormalView i e

/-- Two replicas with the same last normal view agree wherever their logs
overlap. -/
def ReplicasAgree (s : System Op Output St) : Prop :=
  ∀ r ∈ s.replicas, ∀ q ∈ s.replicas, r.lastNormalView = q.lastNormalView →
    ∀ (i : Nat) (e e' : LogEntry Op), r.log[i]? = some e → q.log[i]? = some e' → e = e'

/-- Every started view has a `StartView` message; every view above 0 that
a fragment belongs to, or that a replica not recovering was last normal
in, was started. -/
def StartedViews (s : System Op Output St) : Prop :=
  (∀ v dvcs, (v, dvcs) ∈ s.started → ∃ to log o k, Sent s to (.startView v log o k)) ∧
  (∀ v off log, Frag s v off log → 0 < v → ∃ dvcs, (v, dvcs) ∈ s.started) ∧
  (∀ r ∈ s.replicas, r.status ≠ .recovering → 0 < r.lastNormalView →
    ∃ dvcs, (r.lastNormalView, dvcs) ∈ s.started)

/-- Between steps a replica has handed over its replies and the view it
started, as it has its outbox (`Drained`). -/
def Clean (s : System Op Output St) : Prop :=
  ∀ r ∈ s.replicas, r.replies = [] ∧ r.chosenDoViewChanges = none

/-- A cluster of one replica never sends, so nothing about it can be said
through `sent`; the invariant is for clusters of at least two. -/
def TwoReplicas (s : System Op Output St) : Prop := 2 ≤ s.config.replicaCount

/-- The log a `StartView` carries extends the log its view was started
from: the best of a quorum of dvcs, by (last normal view, length). -/
def StartViewChosen (s : System Op Output St) : Prop :=
  ∀ to v log o k, Sent s to (.startView v log o k) →
    ∃ dvcs best, (v, dvcs) ∈ s.started ∧ s.config.quorum ≤ dvcs.length ∧
      (dvcs.map Prod.fst).Nodup ∧ Replica.bestDoViewChange dvcs = some best ∧ best.log <+: log

/-- Every DoViewChange a view was started from covers every op its sender
acknowledged in the view the dvc is from. -/
def StartedDoViewChangesCover (s : System Op Output St) : Prop :=
  ∀ v dvcs, (v, dvcs) ∈ s.started → ∀ q dvc, (q, dvc) ∈ dvcs →
    ∀ to o, Sent s to (.prepareOk dvc.lastNormalView o q) → o ≤ dvc.log.length

/-- The sender's view is written into the messages that name their
sender, and a replica's view only grows, so none of them is ahead of the
sender's current view. -/
def MessagesBelowView (s : System Op Output St) : Prop :=
  ∀ to (msg : Message Op), Sent s to msg → ∀ r ∈ s.replicas,
    match msg with
    | .prepareOk v _ q => r.selfId = q → v ≤ r.viewNumber
    | .getState q v _ => r.selfId = q → v ≤ r.viewNumber
    | .startViewChange v q => r.selfId = q → v ≤ r.viewNumber
    | .doViewChange v q _ _ _ _ => r.selfId = q → v ≤ r.viewNumber
    | .recovery q _ v => r.selfId = q → v ≤ r.viewNumber
    | .recoveryResponse v _ q _ => r.selfId = q → v ≤ r.viewNumber
    | _ => True

/-- A recovery state answering the recovery under way covers every op the
recovering replica acknowledged in that view before it crashed. -/
def RecoveryCoversAcks (s : System Op Output St) : Prop :=
  ∀ q ∈ s.replicas, q.status = .recovering →
    ∀ to v nonce r st, Sent s to (.recoveryResponse v nonce r (some st)) → nonce = q.recoveryNonce →
      ∀ to' o, Sent s to' (.prepareOk v o q.selfId) → o ≤ st.log.length

/-- Layers three to five together with what carries them, on top of the
proved layers one and two. -/
structure Inv (s : System Op Output St) : Prop where
  noPanic : NoPanic s
  ids : Ids s
  local_ : AllLocal s
  drained : Drained s
  wf : SentWF s
  oneLog : OneLogPerView s
  backed : CommitsBacked s
  survives : Survives s
  acks : AcksCurrent s
  catching : CatchingUpNotPrimary s
  acksHold : AcksHold s
  toOthers : PrimaryToOthers s
  longest : PrimaryLongest s
  chosen : StartViewChosen s
  doViewChangesCover : StartedDoViewChangesCover s
  belowView : MessagesBelowView s
  recoveryCovers : RecoveryCoversAcks s
  covered : Covered s
  agree : ReplicasAgree s
  startedViews : StartedViews s
  clean : Clean s
  two : TwoReplicas s

/-! ### Monotonicity: facts stated through `sent` never go away -/

section Mono
variable {s s' : System Op Output St} (hsent : ∀ x ∈ s.sent, x ∈ s'.sent)
  (hstarted : ∀ x ∈ s.started, x ∈ s'.started) (hconfig : s'.config = s.config)
include hsent

theorem Sent.mono {to : ReplicaId} {msg : Message Op} (h : Sent s to msg) : Sent s' to msg := hsent _ h

include hstarted

theorem Frag.mono {v off log} (h : Frag s v off log) : Frag s' v off log := by
  cases h with
  | prepare h => exact .prepare (Sent.mono hsent h)
  | newState h => exact .newState (Sent.mono hsent h)
  | startView h => exact .startView (Sent.mono hsent h)
  | dvc h => exact .dvc (Sent.mono hsent h)
  | recovery h => exact .recovery (Sent.mono hsent h)
  | started h hv => exact .started (hstarted _ h) hv

theorem Holds.mono {v i e} (h : Holds s v i e) : Holds s' v i e := by
  obtain ⟨off, log, hf, hle, hget⟩ := h
  exact ⟨off, log, Frag.mono hsent hstarted hf, hle, hget⟩

include hconfig

omit hstarted in
theorem Acked.mono {v i q} (h : Acked s v i q) : Acked s' v i q := by
  rcases h with h | ⟨to, o, hs, hlt⟩
  · left; rw [hconfig]; exact h
  · right; exact ⟨to, o, Sent.mono hsent hs, hlt⟩

omit hstarted in
theorem QuorumAcked.mono {v i} (h : QuorumAcked s v i) : QuorumAcked s' v i := by
  obtain ⟨Q, hnd, hlen, hq⟩ := h
  refine ⟨Q, hnd, by rw [hconfig]; exact hlen, fun q hq' => ?_⟩
  obtain ⟨hlt, hack⟩ := hq q hq'
  exact ⟨by rw [hconfig]; exact hlt, Acked.mono hsent hconfig hack⟩

theorem Committed.mono {v i e} (h : Committed s v i e) : Committed s' v i e :=
  ⟨Holds.mono hsent hstarted h.1, QuorumAcked.mono hsent hconfig h.2⟩

theorem Backed.mono {v k} (h : Backed s v k) : Backed s' v k := by
  intro i hi
  obtain ⟨e, v', hle, hc, hh⟩ := h i hi
  exact ⟨e, v', hle, Committed.mono hsent hstarted hconfig hc, Holds.mono hsent hstarted hh⟩

end Mono

/-! ### The initial state -/

theorem Sent.init {config : Config} {sm : St} {to : ReplicaId} {msg : Message Op}
    (h : Sent (System.init config sm : System Op Output St) to msg) : False := by
  simp [Sent, System.init] at h

theorem Frag.init {config : Config} {sm : St} {v off} {log : List (LogEntry Op)}
    (h : Frag (System.init config sm : System Op Output St) v off log) : False := by
  cases h with
  | prepare h => exact Sent.init h
  | newState h => exact Sent.init h
  | startView h => exact Sent.init h
  | dvc h => exact Sent.init h
  | recovery h => exact Sent.init h
  | started h _ => simp [System.init] at h

theorem Holds.init {config : Config} {sm : St} {v i} {e : LogEntry Op}
    (h : Holds (System.init config sm : System Op Output St) v i e) : False :=
  let ⟨_, _, hf, _, _⟩ := h
  Frag.init hf

theorem Inv.init (config : Config) (sm : St) (htwo : 2 ≤ config.replicaCount) :
    Inv (System.init config sm : System Op Output St) where
  noPanic := by
    intro r hr
    simp only [System.init, List.mem_map] at hr
    obtain ⟨id, _, rfl⟩ := hr
    rfl
  ids := by
    unfold Ids
    intro i r h
    simp only [System.init, List.getElem?_map, Config.replicas] at h
    rcases hi : (List.range config.replicaCount)[i]? with _ | id
    · rw [hi] at h; simp at h
    · rw [hi] at h
      simp only [Option.map_some, Option.some.injEq] at h
      obtain ⟨_, hget⟩ := List.getElem?_eq_some_iff.mp hi
      rw [List.getElem_range] at hget
      subst hget
      rw [← h]; exact ⟨rfl, rfl⟩
  local_ := AllLocal.init config sm
  drained := Drained.init config sm
  wf := SentWF.init config sm
  oneLog := by
    refine ⟨fun _ _ _ _ h _ => (Holds.init h).elim, fun r hr i e e' _ h => (Holds.init h).elim⟩
  backed := by
    refine ⟨fun r hr => ?_, fun to msg h => (Sent.init h).elim⟩
    simp only [System.init, List.mem_map] at hr
    obtain ⟨id, _, rfl⟩ := hr
    unfold Backed
    intro i hi
    simp at hi
  survives := fun _ _ _ hc => (Holds.init hc.1).elim
  acks := by
    unfold AcksCurrent
    intro r hr _ _ oa hoa
    simp only [System.init, List.mem_map] at hr
    obtain ⟨id, _, rfl⟩ := hr
    simp [Replica.new] at hoa
  catching := by
    unfold CatchingUpNotPrimary
    intro r hr hc
    simp only [System.init, List.mem_map] at hr
    obtain ⟨id, _, rfl⟩ := hr
    simp [Replica.new] at hc
  acksHold := fun _ _ _ _ h => (Sent.init h).elim
  toOthers := fun _ _ h => (Sent.init h).elim
  longest := by
    unfold PrimaryLongest
    intro p hp _ _
    refine ⟨fun _ _ hf => (Frag.init hf).elim, ?_, fun _ _ _ h => (Sent.init h).elim⟩
    intro q hq _ _
    simp only [System.init, List.mem_map] at hp hq
    obtain ⟨_, _, rfl⟩ := hp
    obtain ⟨_, _, rfl⟩ := hq
    exact Nat.le_refl _
  chosen := fun _ _ _ _ _ h => (Sent.init h).elim
  doViewChangesCover := by
    unfold StartedDoViewChangesCover
    intro v dvcs h
    simp [System.init] at h
  belowView := fun _ _ h => (Sent.init h).elim
  recoveryCovers := fun _ _ _ _ _ _ _ _ h => (Sent.init h).elim
  covered := by
    unfold Covered
    intro r hr i hi
    simp only [System.init, List.mem_map] at hr
    obtain ⟨_, _, rfl⟩ := hr
    simp at hi
  agree := by
    unfold ReplicasAgree
    intro r hr q hq _ i e e' he _
    simp only [System.init, List.mem_map] at hr
    obtain ⟨_, _, rfl⟩ := hr
    simp at he
  startedViews := by
    refine ⟨fun _ _ h => by simp [System.init] at h, fun _ _ _ hf => (Frag.init hf).elim, ?_⟩
    intro r hr _ hv
    simp only [System.init, List.mem_map] at hr
    obtain ⟨_, _, rfl⟩ := hr
    simp at hv
  clean := by
    unfold Clean
    intro r hr
    simp only [System.init, List.mem_map] at hr
    obtain ⟨_, _, rfl⟩ := hr
    exact ⟨rfl, rfl⟩
  two := htwo

/-! ### What the invariant gives -/

/-- A fragment of view `v` that covers index `i` agrees with what view `v`
holds there. -/
theorem Frag.holds_of_covers {s : System Op Output St} {v off i} {log : List (LogEntry Op)} {e : LogEntry Op}
    (hf : Frag s v off log) (hoff : off ≤ i) (hget : log[i - off]? = some e) : Holds s v i e :=
  ⟨off, log, hf, hoff, hget⟩

/-- A replica's committed entries are the entries its last normal view
holds: the commit is backed, and the log agrees with the view. -/
theorem Inv.committed_entry {s : System Op Output St} (hinv : Inv s) {r : Replica Op Output St}
    (hr : r ∈ s.replicas) {i : Nat} (hi : i < r.commitNumber) :
    ∃ e v', r.log[i]? = some e ∧ v' ≤ r.lastNormalView ∧ Committed s v' i e ∧
      Holds s r.lastNormalView i e := by
  obtain ⟨e, v', hle, hc, hh⟩ := hinv.backed.1 r hr i hi
  have hlen : i < r.log.length := Nat.lt_of_lt_of_le hi (hinv.local_ r hr).1
  have hx : r.log[i]? = some r.log[i] := List.getElem?_eq_getElem hlen
  have := hinv.oneLog.2 r hr i _ e hx hh
  rw [this] at hx
  exact ⟨e, v', hx, hle, hc, hh⟩

/-- Whatever was committed in an earlier view, a later view holds at the
same index, in every one of its fragments that covers it. -/
theorem Inv.survives_holds {s : System Op Output St} (hinv : Inv s) {v' v i} {e e' : LogEntry Op}
    (hc : Committed s v' i e) (hlt : v' < v) (hh : Holds s v i e') : e' = e := by
  obtain ⟨off, log, hf, hoff, hget⟩ := hh
  obtain ⟨hsv, hdvc, hrec, hnew, hprep, hstarted, _⟩ := hinv.survives v' i e hc v hlt
  cases hf with
  | prepare h =>
    rename_i o c n op k
    -- a single entry at index o - 1, so i = o - 1
    have : i - (o - 1) = 0 := by
      have : i - (o - 1) < [(⟨c, n, op⟩ : LogEntry Op)].length := (List.getElem?_eq_some_iff.mp hget).1
      simp at this; exact this
    have hi : i + 1 = o := by
      have hwf : 0 < o := hinv.wf _ h
      have h1 : i ≤ o - 1 := Nat.sub_eq_zero_iff_le.mp this
      have h2 : i = o - 1 := Nat.le_antisymm h1 hoff
      rw [h2]; exact Nat.sub_add_cancel hwf
    rw [this] at hget
    simp only [List.getElem?_cons_zero, Option.some.injEq] at hget
    subst hi
    rw [← hget]; exact hprep _ _ _ _ _ h
  | newState h => exact Option.some.inj (hget.symm.trans (hnew _ _ _ _ _ h hoff))
  | startView h =>
    simp only [Nat.sub_zero] at hget
    exact Option.some.inj (hget.symm.trans (hsv _ _ _ _ h))
  | dvc h =>
    simp only [Nat.sub_zero] at hget
    exact Option.some.inj (hget.symm.trans (hdvc _ _ _ _ _ _ h))
  | recovery h =>
    simp only [Nat.sub_zero] at hget
    exact Option.some.inj (hget.symm.trans (hrec _ _ _ _ h))
  | started h hv =>
    simp only [Nat.sub_zero] at hget
    exact Option.some.inj (hget.symm.trans (hstarted _ _ _ _ h hv rfl))

/-- The invariant gives prefix agreement: two replicas that have both
committed index `i` hold the same entry there. -/
theorem Inv.prefixAgreement {s : System Op Output St} (hinv : Inv s) : PrefixAgreement s := by
  intro a ha b hb i hia hib
  obtain ⟨ea, va, hga, _, hca, _⟩ := hinv.committed_entry ha hia
  obtain ⟨eb, vb, hgb, _, hcb, _⟩ := hinv.committed_entry hb hib
  rw [hga, hgb]
  congr 1
  rcases Nat.lt_trichotomy va vb with hlt | heq | hgt
  · exact (hinv.survives_holds hca hlt hcb.1).symm
  · subst heq
    exact hinv.oneLog.1 va i ea eb hca.1 hcb.1
  · exact hinv.survives_holds hcb hgt hca.1

end Vsr
