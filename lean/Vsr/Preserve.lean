import Vsr.Invariant

/-!
Preservation of `Inv` by the cluster steps, one handler at a time.

A step replaces one replica and appends what it sent to `sent`, and the
view it started, if any, to `started`. `Inv.drain_clean` and
`Inv.addMessage` are the two shapes that come up: a step that changes
nothing, and a step that only adds a message. The handlers are then
proved from those.
-/

namespace Vsr

variable {Op Output St : Type}

/-! ### What a message contributes to the fragments -/

/-- The fragment a message contributes, if any. -/
inductive MsgFrag : ReplicaId × Message Op → ViewNumber → Nat → List (LogEntry Op) → Prop
  | prepare {to v o c n op k} : MsgFrag (to, .prepare v o c n op k) v (o - 1) [⟨c, n, op⟩]
  | newState {to v log a b k} : MsgFrag (to, .newState v log a b k) v a log
  | startView {to v log o k} : MsgFrag (to, .startView v log o k) v 0 log
  | vote {to v r l log o k} : MsgFrag (to, .doViewChange v r l log o k) l 0 log
  | recovery {to v n r st} : MsgFrag (to, .recoveryResponse v n r (some st)) v 0 st.log

/-- A fragment of a state with one more message is an old fragment or the
new message's. -/
theorem Frag.addMessage {s : System Op Output St} {x : ReplicaId × Message Op} {v off log}
    (h : Frag { s with sent := s.sent ++ [x] } v off log) :
    Frag s v off log ∨ MsgFrag x v off log := by
  cases h with
  | prepare h =>
    simp only [Sent, List.mem_append, List.mem_singleton] at h
    rcases h with h | h
    · exact Or.inl (.prepare h)
    · subst h; exact Or.inr .prepare
  | newState h =>
    simp only [Sent, List.mem_append, List.mem_singleton] at h
    rcases h with h | h
    · exact Or.inl (.newState h)
    · subst h; exact Or.inr .newState
  | startView h =>
    simp only [Sent, List.mem_append, List.mem_singleton] at h
    rcases h with h | h
    · exact Or.inl (.startView h)
    · subst h; exact Or.inr .startView
  | vote h =>
    simp only [Sent, List.mem_append, List.mem_singleton] at h
    rcases h with h | h
    · exact Or.inl (.vote h)
    · subst h; exact Or.inr .vote
  | recovery h =>
    simp only [Sent, List.mem_append, List.mem_singleton] at h
    rcases h with h | h
    · exact Or.inl (.recovery h)
    · subst h; exact Or.inr .recovery
  | started h hv => exact Or.inl (.started h hv)

theorem Sent.addMessage {s : System Op Output St} {x : ReplicaId × Message Op} {to msg}
    (h : Sent { s with sent := s.sent ++ [x] } to msg) : Sent s to msg ∨ (to, msg) = x := by
  simpa [Sent, List.mem_append, List.mem_singleton] using h

theorem Sent.addMessage_of {s : System Op Output St} {x : ReplicaId × Message Op} {to msg}
    (h : Sent s to msg) : Sent { s with sent := s.sent ++ [x] } to msg := by
  simp only [Sent, List.mem_append, List.mem_singleton]; exact Or.inl h

theorem Sent.addMessage_self {s : System Op Output St} {x : ReplicaId × Message Op} :
    Sent { s with sent := s.sent ++ [x] } x.1 x.2 := by
  simp [Sent, List.mem_append]

/-- Adding a message that is not a `PrepareOk` changes no acknowledgement. -/
theorem QuorumAcked.addMessage {s : System Op Output St} {x : ReplicaId × Message Op}
    (hx : ∀ v o q, x.2 ≠ .prepareOk v o q) {v i}
    (h : QuorumAcked { s with sent := s.sent ++ [x] } v i) : QuorumAcked s v i := by
  obtain ⟨Q, hnd, hlen, hq⟩ := h
  refine ⟨Q, hnd, hlen, fun q hq' => ?_⟩
  obtain ⟨hlt, hack⟩ := hq q hq'
  refine ⟨hlt, ?_⟩
  rcases hack with hack | ⟨to, o, hs, hlt'⟩
  · exact Or.inl hack
  · rcases Sent.addMessage hs with hs | hs
    · exact Or.inr ⟨to, o, hs, hlt'⟩
    · exact absurd (congrArg Prod.snd hs).symm (hx v o q)

/-! ### A step that changes nothing -/

theorem List.set_getElem?_self {α : Type} : ∀ (l : List α) (i : Nat) (x : α), l[i]? = some x → l.set i x = l
  | [], _, _, h => by simp at h
  | a :: l, 0, x, h => by simp at h; rw [h]; rfl
  | a :: l, i + 1, x, h => by
    simp only [List.getElem?_cons_succ] at h
    simp [List.set_getElem?_self l i x h]

/-- A replica that changed nothing and sent nothing leaves the cluster as
it was. -/
theorem System.drain_clean {s : System Op Output St} {id : ReplicaId} {r : Replica Op Output St}
    (hr : s.replicas[id]? = some r) (ho : r.outbox = []) (hp : r.replies = [])
    (hc : r.chosenVotes = none) : s.drain id r = s := by
  unfold System.drain
  have : ({ r with outbox := [], replies := [], chosenVotes := none } : Replica Op Output St) = r := by
    rw [← ho, ← hp, ← hc]
  rw [this, List.set_getElem?_self _ _ _ hr, ho, hp, hc]
  simp

/-- A replica that changed nothing but sent one message. -/
theorem System.drain_send {s : System Op Output St} {id : ReplicaId} {r : Replica Op Output St}
    (hr : s.replicas[id]? = some r) (ho : r.outbox = []) (hp : r.replies = [])
    (hc : r.chosenVotes = none) (to : ReplicaId) (msg : Message Op) :
    s.drain id (r.send to msg) = { s with sent := s.sent ++ [(to, msg)] } := by
  unfold System.drain Replica.send
  have : ({ r with outbox := [], replies := [], chosenVotes := none } : Replica Op Output St) = r := by
    rw [← ho, ← hp, ← hc]
  simp only
  rw [this, List.set_getElem?_self _ _ _ hr, ho, hp, hc]
  simp

/-- The message clause of `CommitsBacked` is monotone. -/
theorem MsgBacked.mono {s s' : System Op Output St} (hsent : ∀ x ∈ s.sent, x ∈ s'.sent)
    (hstarted : ∀ x ∈ s.started, x ∈ s'.started) (hconfig : s'.config = s.config) {msg : Message Op}
    (h : MsgBacked s msg) : MsgBacked s' msg := by
  unfold MsgBacked at h ⊢
  cases msg with
  | prepare => exact Backed.mono hsent hstarted hconfig h
  | commit => exact Backed.mono hsent hstarted hconfig h
  | newState => exact Backed.mono hsent hstarted hconfig h
  | startView => exact Backed.mono hsent hstarted hconfig h
  | doViewChange => exact Backed.mono hsent hstarted hconfig h
  | recoveryResponse _ _ _ st =>
    cases st with
    | none => trivial
    | some => exact Backed.mono hsent hstarted hconfig h
  | _ => trivial

theorem MsgFrag.newState_inv {q : ReplicaId} {v : ViewNumber} {log : List (LogEntry Op)} {a b k v' off log'}
    (h : MsgFrag (q, .newState v log a b k) v' off log') : v' = v ∧ off = a ∧ log' = log := by
  cases h; exact ⟨rfl, rfl, rfl⟩

/-! ### One more `NewState` from a normal replica -/

/-- What `onGetState` sends: a suffix of a normal replica's log, which is
a fragment of its view, backed by its own commit number. -/
theorem Inv.addNewState {s : System Op Output St} (hinv : Inv s) {r : Replica Op Output St}
    (hr : r ∈ s.replicas) (hn : r.status = .normal) (q : ReplicaId) {o : Nat} (ho : o ≤ r.log.length) :
    Inv { s with sent := s.sent ++
      [(q, .newState r.viewNumber (r.log.drop o) o r.log.length r.commitNumber)] } := by
  generalize hx : ((q, .newState r.viewNumber (r.log.drop o) o r.log.length r.commitNumber) :
    ReplicaId × Message Op) = x
  have hlocal := hinv.local_ r hr
  have hlnv : r.lastNormalView = r.viewNumber := hlocal.2.2.1 (Or.inl hn)
  have hnr : r.status ≠ .recovering := by rw [hn]; decide
  have hsent : ∀ y ∈ s.sent, y ∈ ({ s with sent := s.sent ++ [x] } : System Op Output St).sent :=
    fun y hy => by simp [hy]
  have hstarted : ∀ y ∈ s.started, y ∈ ({ s with sent := s.sent ++ [x] } : System Op Output St).started :=
    fun y hy => hy
  have hconfig : ({ s with sent := s.sent ++ [x] } : System Op Output St).config = s.config := rfl
  -- the new fragment: a suffix of `r.log`, so it holds what `r.log` holds
  have hseg : ∀ (i : Nat) (e : LogEntry Op), o ≤ i →
      ((r.log.drop o)[i - o]? = some e ↔ r.log[i]? = some e) := by
    intro i e hoi
    rw [List.getElem?_drop, Nat.add_sub_cancel' hoi]
  have hholds : ∀ v i e, Holds ({ s with sent := s.sent ++ [x] } : System Op Output St) v i e →
      Holds s v i e ∨ (v = r.viewNumber ∧ r.log[i]? = some e) := by
    intro v i e ⟨off, log, hf, hoff, hget⟩
    rcases Frag.addMessage hf with hf | hf
    · exact Or.inl ⟨off, log, hf, hoff, hget⟩
    · rw [← hx] at hf
      obtain ⟨rfl, rfl, rfl⟩ := MsgFrag.newState_inv hf
      exact Or.inr ⟨rfl, (hseg i e hoff).mp hget⟩
  have hnotOk : ∀ v o' q', x.2 ≠ .prepareOk v o' q' := fun _ _ _ h => by rw [← hx] at h; simp at h
  -- an entry of `r.log` agrees with view `r.viewNumber`
  have hagree : ∀ i e e', r.log[i]? = some e → Holds s r.viewNumber i e' → e = e' :=
    fun i e e' he hh => hinv.oneLog.2 r hr i e e' he (hlnv ▸ hh)
  have hnewEq : ∀ {to : ReplicaId} {msg : Message Op}, (to, msg) = x →
      to = q ∧ msg = .newState r.viewNumber (r.log.drop o) o r.log.length r.commitNumber := by
    intro to msg h; rw [← hx] at h; simp only [Prod.mk.injEq] at h; exact h
  refine {
    noPanic := hinv.noPanic
    ids := hinv.ids
    local_ := hinv.local_
    drained := hinv.drained
    wf := ?_
    oneLog := ?_
    backed := ?_
    survives := ?_
    acks := ?_
    catching := hinv.catching
    acksHold := ?_
    toOthers := ?_
    longest := ?_
    chosen := ?_
    votesCover := ?_
    belowView := ?_
    recoveryCovers := ?_
    covered := ?_
    agree := hinv.agree
    startedViews := ?_
    clean := hinv.clean
    two := hinv.two }
  · -- wf
    intro y hy
    simp only [List.mem_append, List.mem_singleton] at hy
    rcases hy with hy | rfl
    · exact hinv.wf y hy
    · rw [← hx]; exact ⟨List.length_drop, ho, hlocal.1⟩
  · -- one log per view
    refine ⟨fun v i e e' h h' => ?_, fun z hz i e e' he hh => ?_⟩
    · rcases hholds v i e h with h1 | ⟨hv1, h1⟩
      · rcases hholds v i e' h' with h2 | ⟨hv2, h2⟩
        · exact hinv.oneLog.1 v i e e' h1 h2
        · subst hv2; exact (hagree i e' e h2 h1).symm
      · rcases hholds v i e' h' with h2 | ⟨hv2, h2⟩
        · subst hv1; exact hagree i e e' h1 h2
        · rw [h1] at h2; exact Option.some.inj h2
    · rcases hholds _ i e' hh with hh1 | ⟨hv, hh1⟩
      · exact hinv.oneLog.2 z hz i e e' he hh1
      · exact hinv.agree z hz r hr (hv.trans hlnv.symm) i e e' he hh1
  · -- commits backed
    refine ⟨fun z hz => Backed.mono hsent hstarted hconfig (hinv.backed.1 z hz), fun to msg hm => ?_⟩
    rcases Sent.addMessage hm with hold | hnew
    · exact MsgBacked.mono hsent hstarted hconfig (hinv.backed.2 to msg hold)
    · obtain ⟨rfl, rfl⟩ := hnewEq hnew
      show Backed _ r.viewNumber r.commitNumber
      exact Backed.mono hsent hstarted hconfig (hlnv ▸ hinv.backed.1 r hr)
  · -- survives
    intro v' i e hc v hlt
    have hc' : Committed s v' i e := by
      obtain ⟨hh, hq⟩ := hc
      have hq' := QuorumAcked.addMessage hnotOk hq
      rcases hholds v' i e hh with hh1 | ⟨hv, hlog⟩
      · exact ⟨hh1, hq'⟩
      · -- the entry is `r`'s, which some old fragment of the view covers
        subst hv
        obtain ⟨e0, he0⟩ := hinv.covered r hr i (List.getElem?_eq_some_iff.mp hlog).1
        rw [hlnv] at he0
        have := hagree i e e0 hlog he0
        subst this
        exact ⟨he0, hq'⟩
    obtain ⟨hsv, hvote, hrec, hnew', hprep, hst, hrep'⟩ := hinv.survives v' i e hc' v hlt
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · intro to log o' k h
      rcases Sent.addMessage h with hold | hnew
      · exact hsv to log o' k hold
      · exact absurd (hnewEq hnew).2 (by simp)
    · intro to v'' r' log o' k h
      rcases Sent.addMessage h with hold | hnew
      · exact hvote to v'' r' log o' k hold
      · exact absurd (hnewEq hnew).2 (by simp)
    · intro to n r' st h
      rcases Sent.addMessage h with hold | hnew
      · exact hrec to n r' st hold
      · exact absurd (hnewEq hnew).2 (by simp)
    · intro to log a b k h ha
      rcases Sent.addMessage h with hold | hnew
      · exact hnew' to log a b k hold ha
      · obtain ⟨_, hm⟩ := hnewEq hnew
        simp only [Message.newState.injEq] at hm
        obtain ⟨rfl, rfl, rfl, rfl, rfl⟩ := hm
        exact (hseg i e ha).mpr (hrep' r hr hlnv hnr)
    · intro to c n op k h
      rcases Sent.addMessage h with hold | hnew
      · exact hprep to c n op k hold
      · exact absurd (hnewEq hnew).2 (by simp)
    · exact hst
    · exact hrep'
  · -- acks current
    intro z hz hzn hzp oa hoa
    obtain ⟨hlen, hq⟩ := hinv.acks z hz hzn hzp oa hoa
    refine ⟨hlen, fun q' hq' => ?_⟩
    rcases hq q' hq' with h | ⟨to, h⟩
    · exact Or.inl h
    · exact Or.inr ⟨to, Sent.addMessage_of h⟩
  · -- acks hold
    intro to v o' q' h
    rcases Sent.addMessage h with hold | hnew
    · exact hinv.acksHold to v o' q' hold
    · exact absurd (hnewEq hnew).2 (by simp)
  · -- primary messages to others
    intro to msg hm
    rcases Sent.addMessage hm with hold | hnew
    · exact hinv.toOthers to msg hold
    · obtain ⟨rfl, rfl⟩ := hnewEq hnew
      trivial
  · -- primary longest
    intro p hp hpn hpp
    obtain ⟨hfrag, hreps, hacks⟩ := hinv.longest p hp hpn hpp
    refine ⟨fun off log hf => ?_, hreps, fun to o' q' h => ?_⟩
    · rcases Frag.addMessage hf with hf | hf
      · exact hfrag off log hf
      · rw [← hx] at hf
        obtain ⟨hv, rfl, rfl⟩ := MsgFrag.newState_inv hf
        rw [List.length_drop, Nat.add_sub_cancel' ho]
        exact hreps r hr (hlnv.trans hv.symm) hnr
    · rcases Sent.addMessage h with hold | hnew
      · exact hacks to o' q' hold
      · exact absurd (hnewEq hnew).2 (by simp)
  · -- start view chosen
    intro to v log o' k h
    rcases Sent.addMessage h with hold | hnew
    · exact hinv.chosen to v log o' k hold
    · exact absurd (hnewEq hnew).2 (by simp)
  · -- started votes cover
    intro v votes hv q' vote hvote to o' h
    rcases Sent.addMessage h with hold | hnew
    · exact hinv.votesCover v votes hv q' vote hvote to o' hold
    · exact absurd (hnewEq hnew).2 (by simp)
  · -- messages below view
    intro to msg hm z hz
    rcases Sent.addMessage hm with hold | hnew
    · exact hinv.belowView to msg hold z hz
    · obtain ⟨rfl, rfl⟩ := hnewEq hnew
      trivial
  · -- recovery covers acks
    intro z hz hzr to v nonce r' st h hnonce to' o' h'
    rcases Sent.addMessage h with hold | hnew
    · rcases Sent.addMessage h' with hold' | hnew'
      · exact hinv.recoveryCovers z hz hzr to v nonce r' st hold hnonce to' o' hold'
      · exact absurd (hnewEq hnew').2 (by simp)
    · exact absurd (hnewEq hnew).2 (by simp)
  · -- covered
    intro z hz i hi
    obtain ⟨e, he⟩ := hinv.covered z hz i hi
    exact ⟨e, Holds.mono hsent hstarted he⟩
  · -- started views
    obtain ⟨h1, h2, h3⟩ := hinv.startedViews
    refine ⟨fun v votes hv => ?_, fun v off log hf hpos => ?_, h3⟩
    · obtain ⟨to, log, o', k, h⟩ := h1 v votes hv
      exact ⟨to, log, o', k, Sent.addMessage_of h⟩
    · rcases Frag.addMessage hf with hf | hf
      · exact h2 v off log hf hpos
      · rw [← hx] at hf
        obtain ⟨rfl, rfl, rfl⟩ := MsgFrag.newState_inv hf
        have hpos' : 0 < r.lastNormalView := by rw [hlnv]; exact hpos
        obtain ⟨votes, hv⟩ := h3 r hr hnr hpos'
        exact ⟨votes, by rw [← hlnv]; exact hv⟩

/-! ### Commit steps: a replica raising its commit within a backed bound -/

/-- `commitUpTo.go` raises the commit number by at most the fuel. -/
theorem commitUpTo_go_add_le (m : Machine Op Output St) (reply : Bool) :
    ∀ (n : Nat) (r : Replica Op Output St),
      (Replica.commitUpTo.go m reply n r).commitNumber ≤ r.commitNumber + n := by
  intro n
  induction n with
  | zero => intro r; exact Nat.le_refl _
  | succ n ih =>
    intro r
    rw [Replica.commitUpTo_go_succ]
    split
    · show (r.panic).commitNumber ≤ r.commitNumber + (n + 1)
      exact Nat.le_add_right _ _
    · rename_i entry _
      have hxc : (if reply then { (Replica.commitOp m r entry).1 with
          replies := (Replica.commitOp m r entry).1.replies ++ [(Replica.commitOp m r entry).2] }
        else (Replica.commitOp m r entry).1).commitNumber = r.commitNumber + 1 := by
        split <;> rfl
      have hih := ih (if reply then { (Replica.commitOp m r entry).1 with
          replies := (Replica.commitOp m r entry).1.replies ++ [(Replica.commitOp m r entry).2] }
        else (Replica.commitOp m r entry).1)
      rw [hxc] at hih
      have heq : r.commitNumber + 1 + n = r.commitNumber + (n + 1) := by
        rw [Nat.add_assoc, Nat.add_comm 1 n]
      exact heq ▸ hih

theorem commitUpTo_le_max (m : Machine Op Output St) (r : Replica Op Output St) (k : Nat) (reply : Bool) :
    (Replica.commitUpTo m r k reply).commitNumber ≤ max r.commitNumber k := by
  unfold Replica.commitUpTo
  have hih := commitUpTo_go_add_le m reply (k - r.commitNumber) r
  have hmax : r.commitNumber + (k - r.commitNumber) = max r.commitNumber k := by
    rcases Nat.le_total r.commitNumber k with h | h
    · rw [Nat.add_sub_cancel' h, Nat.max_eq_right h]
    · rw [Nat.sub_eq_zero_of_le h, Nat.add_zero, Nat.max_eq_left h]
  exact hmax ▸ hih

theorem Backed.downward {s : System Op Output St} {v m n} (h : Backed s v n) (hle : m ≤ n) :
    Backed s v m := fun i hi => h i (Nat.lt_of_lt_of_le hi hle)

theorem Backed.max {s : System Op Output St} {v a b} (ha : Backed s v a) (hb : Backed s v b) :
    Backed s v (max a b) := by
  intro i hi
  have : i < a ∨ i < b := by omega
  rcases this with h | h
  · exact ha i h
  · exact hb i h

/-- Draining a replica that changed but sent nothing just replaces it. -/
theorem System.drain_replace {s : System Op Output St} {id : ReplicaId} {r' : Replica Op Output St}
    (ho : r'.outbox = []) (hp : r'.replies = []) (hc : r'.chosenVotes = none) :
    s.drain id r' = { s with replicas := s.replicas.set id r' } := by
  unfold System.drain
  have : ({ r' with outbox := [], replies := [], chosenVotes := none } : Replica Op Output St) = r' := by
    rw [← ho, ← hp, ← hc]
  rw [this, ho, hp, hc]; simp

/-! ### The handler -/

theorem Inv.onGetState {s : System Op Output St} (hinv : Inv s) (id q : ReplicaId) (v : ViewNumber)
    (o : OpNumber) : Inv (s.withReplica id fun r => r.onGetState q v o) := by
  unfold System.withReplica
  split
  · exact hinv
  · rename_i r hr
    have hmem : r ∈ s.replicas := List.mem_of_getElem? hr
    have hclean := hinv.clean r hmem
    have hdrained := hinv.drained r hmem
    show Inv (s.drain id (r.onGetState q v o))
    unfold Replica.onGetState
    split
    · rw [System.drain_clean hr hdrained hclean.1 hclean.2]; exact hinv
    · rename_i hg
      rw [System.drain_send hr hdrained hclean.1 hclean.2]
      have hn : r.status = .normal := by
        rcases Decidable.em (r.status = .normal) with h | h
        · exact h
        · exact absurd (Or.inl h) hg
      have hv : v = r.viewNumber := by
        rcases Decidable.em (v = r.viewNumber) with h | h
        · exact h
        · exact absurd (Or.inr (Or.inl h)) hg
      have ho : o ≤ r.opNumber := Nat.le_of_not_lt fun h => hg (Or.inr (Or.inr h))
      subst hv
      exact hinv.addNewState hmem hn q ho

end Vsr
