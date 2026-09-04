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

theorem commitUpTo_go_false_panicked (m : Machine Op Output St) :
    ∀ (n : Nat) (r : Replica Op Output St),
      r.commitNumber + n ≤ r.log.length →
      (Replica.commitUpTo.go m false n r).panicked = r.panicked := by
  intro n
  induction n with
  | zero => intro r _; rfl
  | succ n ih =>
    intro r hle
    rw [Replica.commitUpTo_go_succ]
    have hlt : r.commitNumber < r.log.length :=
      Nat.lt_of_lt_of_le (Nat.lt_add_of_pos_right (Nat.succ_pos n)) hle
    split
    · rename_i heq
      rw [List.getElem?_eq_getElem hlt] at heq
      exact absurd heq (Option.some_ne_none _)
    · rename_i entry _
      show (Replica.commitUpTo.go m false n (Replica.commitOp m r entry).1).panicked = r.panicked
      rw [ih (Replica.commitOp m r entry).1 ?_, Replica.commitOp_panicked]
      rw [Replica.commitOp_commitNumber, Replica.commitOp_log]
      have heq2 : r.commitNumber + 1 + n = r.commitNumber + (n + 1) := by
        rw [Nat.add_assoc, Nat.add_comm 1 n]
      rw [heq2]; exact hle

theorem commitUpTo_false_panicked (m : Machine Op Output St) (r : Replica Op Output St) (k : Nat)
    (hc : r.commitNumber ≤ r.log.length) (hk : k ≤ r.log.length) :
    (Replica.commitUpTo m r k false).panicked = r.panicked := by
  unfold Replica.commitUpTo
  apply commitUpTo_go_false_panicked
  have hmax : r.commitNumber + (k - r.commitNumber) = max r.commitNumber k := by
    rcases Nat.le_total r.commitNumber k with h | h
    · rw [Nat.add_sub_cancel' h, Nat.max_eq_right h]
    · rw [Nat.sub_eq_zero_of_le h, Nat.add_zero, Nat.max_eq_left h]
  rw [hmax]; exact Nat.max_le.mpr ⟨hc, hk⟩

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

/-- A replica changed to `r'` that sends nothing (empty outbox, replies,
chosen votes) and agrees with the old `r` on every field the invariant
reads except the commit number, which is backed, preserves `Inv`. Nothing
is sent, so `sent` and `started` are unchanged; only the replaced replica
is re-checked. -/
theorem Inv.replace {s : System Op Output St} (hinv : Inv s) {id : ReplicaId}
    {r r' : Replica Op Output St} (hr : s.replicas[id]? = some r)
    (hlog : r'.log = r.log) (hstat : r'.status = r.status) (hview : r'.viewNumber = r.viewNumber)
    (hlnv : r'.lastNormalView = r.lastNormalView) (hcatch : r'.catchingUp = r.catchingUp)
    (hself : r'.selfId = r.selfId) (hconf : r'.config = r.config) (hacks : r'.acks = r.acks)
    (hnonce : r'.recoveryNonce = r.recoveryNonce) (hpanic : r'.panicked = false)
    (hout : r'.outbox = []) (hreplies : r'.replies = []) (hcv : r'.chosenVotes = none)
    (hbacked : Backed s r.lastNormalView r'.commitNumber) (hloc : Replica.LocalInv r') :
    Inv (s.drain id r') := by
  have hmem : r ∈ s.replicas := List.mem_of_getElem? hr
  rw [System.drain_replace hout hreplies hcv]
  generalize hs' : ({ s with replicas := s.replicas.set id r' } : System Op Output St) = s'
  have hse : s'.sent = s.sent := by rw [← hs']
  have hste : s'.started = s.started := by rw [← hs']
  have hce : s'.config = s.config := by rw [← hs']
  have hre : s'.replicas = s.replicas.set id r' := by rw [← hs']
  have fS : ∀ x ∈ s.sent, x ∈ s'.sent := fun x h => by rw [hse]; exact h
  have fS' : ∀ x ∈ s'.sent, x ∈ s.sent := fun x h => by rw [← hse]; exact h
  have fT : ∀ x ∈ s.started, x ∈ s'.started := fun x h => by rw [hste]; exact h
  have fT' : ∀ x ∈ s'.started, x ∈ s.started := fun x h => by rw [← hste]; exact h
  have hSent : ∀ to msg, Sent s' to msg ↔ Sent s to msg := fun to msg => by
    simp only [Sent, hse]
  have hFrag : ∀ v off log, Frag s' v off log ↔ Frag s v off log := fun v off log =>
    ⟨Frag.mono fS' fT', Frag.mono fS fT⟩
  have hHolds : ∀ v i e, Holds s' v i e ↔ Holds s v i e := fun v i e =>
    ⟨Holds.mono fS' fT', Holds.mono fS fT⟩
  have hBacked : ∀ v k, Backed s' v k ↔ Backed s v k := fun v k =>
    ⟨Backed.mono fS' fT' hce.symm, Backed.mono fS fT hce⟩
  have hComm : ∀ v i e, Committed s' v i e ↔ Committed s v i e := fun v i e =>
    ⟨Committed.mono fS' fT' hce.symm, Committed.mono fS fT hce⟩
  have hprim : r'.isPrimary = r.isPrimary := by
    unfold Replica.isPrimary Replica.primaryId; rw [hself, hconf, hview]
  have hrepl : ∀ x ∈ s'.replicas, x ∈ s.replicas ∨ r' = x := fun x hx => by
    rw [hre] at hx; exact (mem_set_or hx).imp (fun h => h) Eq.symm
  -- primaryId of s' equals that of s
  have hpid : ∀ v, s'.config.primaryId v = s.config.primaryId v :=
    fun v => congrArg (fun c => Config.primaryId c v) hce
  refine {
    noPanic := ?_, ids := ?_, local_ := ?_, drained := ?_, wf := ?_, oneLog := ?_,
    backed := ?_, survives := ?_, acks := ?_, catching := ?_, acksHold := ?_, toOthers := ?_,
    longest := ?_, chosen := ?_, votesCover := ?_, belowView := ?_,
    recoveryCovers := ?_, covered := ?_, agree := ?_, startedViews := ?_, clean := ?_, two := ?_ }
  · intro x hx; rcases hrepl x hx with h | rfl
    · exact hinv.noPanic x h
    · exact hpanic
  · intro i x hx
    rw [hre] at hx
    have hlt : id < s.replicas.length := (List.getElem?_eq_some_iff.mp hr).1
    by_cases hi : i = id
    · subst hi
      rw [List.getElem?_set_self hlt] at hx
      simp only [Option.some.injEq] at hx; subst hx
      obtain ⟨hid, hcfg⟩ := hinv.ids i r hr
      exact ⟨hself.trans hid, hconf.trans (hce ▸ hcfg)⟩
    · rw [List.getElem?_set_ne (Ne.symm hi)] at hx
      obtain ⟨hid, hcfg⟩ := hinv.ids i x hx
      exact ⟨hid, hce ▸ hcfg⟩
  · intro x hx; rcases hrepl x hx with h | rfl
    · exact hinv.local_ x h
    · exact hloc
  · intro x hx; rcases hrepl x hx with h | rfl
    · exact hinv.drained x h
    · exact hout
  · intro x hx; exact hinv.wf x ((hSent x.1 x.2).mp hx)
  · refine ⟨fun v i e e' h h' => hinv.oneLog.1 v i e e' ((hHolds ..).mp h) ((hHolds ..).mp h'),
      fun z hz i e e' he hh => ?_⟩
    rcases hrepl z hz with h | rfl
    · exact hinv.oneLog.2 z h i e e' he ((hHolds ..).mp hh)
    · exact hinv.oneLog.2 r hmem i e e' (hlog ▸ he) (hlnv ▸ (hHolds ..).mp hh)
  · refine ⟨fun z hz => ?_, fun to msg hm => ?_⟩
    · rcases hrepl z hz with h | rfl
      · exact (hBacked ..).mpr (hinv.backed.1 z h)
      · rw [hlnv]; exact (hBacked ..).mpr hbacked
    · exact MsgBacked.mono fS fT hce (hinv.backed.2 to msg ((hSent ..).mp hm))
  · intro v' i e hc v hlt
    obtain ⟨h1, h2, h3, h4, h5, h6, h7⟩ := hinv.survives v' i e ((hComm ..).mp hc) v hlt
    refine ⟨fun to log o k hs => h1 to log o k ((hSent ..).mp hs),
      fun to v'' r0 log o k hs => h2 to v'' r0 log o k ((hSent ..).mp hs),
      fun to n r0 st hs => h3 to n r0 st ((hSent ..).mp hs),
      fun to log a b k hs ha => h4 to log a b k ((hSent ..).mp hs) ha,
      fun to c n op k hs => h5 to c n op k ((hSent ..).mp hs),
      fun v'' votes q vote hstd hin hlv => h6 v'' votes q vote (fT' _ hstd) hin hlv,
      fun z hz hzv hzr => ?_⟩
    rcases hrepl z hz with h | rfl
    · exact h7 z h hzv hzr
    · rw [hlog]; exact h7 r hmem (hlnv ▸ hzv) (hstat ▸ hzr)
  · intro z hz hzn hzp oa hoa
    rcases hrepl z hz with h | rfl
    · obtain ⟨c1, c2⟩ := hinv.acks z h hzn hzp oa hoa
      exact ⟨c1, fun q hq => (c2 q hq).imp (fun h => h) (fun ⟨to, ht⟩ => ⟨to, (hSent ..).mpr ht⟩)⟩
    · have := hinv.acks r hmem (hstat ▸ hzn) (hprim ▸ hzp) oa (by rw [hacks] at hoa; exact hoa)
      exact ⟨by rw [hlog]; exact this.1,
        fun q hq => (this.2 q hq).imp (fun h => hself.symm ▸ h) (fun ⟨to, ht⟩ => ⟨to, (hSent ..).mpr (hview ▸ ht)⟩)⟩
  · intro z hz hzc
    rcases hrepl z hz with h | rfl
    · exact hinv.catching z h hzc
    · rw [hself, hconf, hview]; exact hinv.catching r hmem (hcatch ▸ hzc)
  · intro to v o q hs z hz
    rcases hrepl z hz with h | rfl
    · exact hinv.acksHold to v o q ((hSent ..).mp hs) z h
    · intro hq
      obtain ⟨ha, hb⟩ := hinv.acksHold to v o q ((hSent ..).mp hs) r hmem (hself ▸ hq)
      exact ⟨hlnv ▸ ha, fun he hnr => by rw [hlog]; exact hb (hlnv ▸ he) (hstat ▸ hnr)⟩
  · intro to msg hs
    have := hinv.toOthers to msg ((hSent ..).mp hs)
    revert this; cases msg <;> simp_all
  · intro p hp hpn hpp
    rcases hrepl p hp with h | rfl
    · obtain ⟨f1, f2, f3⟩ := hinv.longest p h hpn hpp
      refine ⟨fun off log hf => f1 off log ((hFrag ..).mp hf), fun z hz hzv hzr => ?_,
        fun to o q hs => f3 to o q ((hSent ..).mp hs)⟩
      rcases hrepl z hz with h2 | rfl
      · exact f2 z h2 hzv hzr
      · rw [hlog]; exact f2 r hmem (hlnv ▸ hzv) (hstat ▸ hzr)
    · obtain ⟨f1, f2, f3⟩ := hinv.longest r hmem (hstat ▸ hpn) (hprim ▸ hpp)
      refine ⟨fun off log hf => by rw [hlog]; exact f1 off log (hview ▸ (hFrag ..).mp hf),
        fun z hz hzv hzr => ?_, fun to o q hs => by rw [hlog]; exact f3 to o q (hview ▸ (hSent ..).mp hs)⟩
      rcases hrepl z hz with h2 | rfl
      · rw [hlog]; exact f2 z h2 (hview ▸ hzv) hzr
      · exact Nat.le_refl _
  · intro to v log o k hs
    obtain ⟨votes, best, hv, hq, hnd, hb, hpre⟩ := hinv.chosen to v log o k ((hSent ..).mp hs)
    exact ⟨votes, best, fT _ hv, by rw [hce]; exact hq, hnd, hb, hpre⟩
  · intro v votes hv q vote hin to o hs
    exact hinv.votesCover v votes (fT' _ hv) q vote hin to o ((hSent ..).mp hs)
  · intro to msg hs z hz
    rcases hrepl z hz with h | rfl
    · exact hinv.belowView to msg ((hSent ..).mp hs) z h
    · simpa only [hview, hself] using hinv.belowView to msg ((hSent ..).mp hs) r hmem
  · intro z hz hzr to v nonce r0 st hs hnhyp to' o' hs'
    rcases hrepl z hz with h | rfl
    · exact hinv.recoveryCovers z h hzr to v nonce r0 st ((hSent ..).mp hs) hnhyp to' o' ((hSent ..).mp hs')
    · exact hinv.recoveryCovers r hmem (hstat ▸ hzr) to v nonce r0 st ((hSent ..).mp hs)
        (hnonce ▸ hnhyp) to' o' ((hSent ..).mp (hself ▸ hs'))
  · intro z hz i hi
    rcases hrepl z hz with h | rfl
    · obtain ⟨e, he⟩ := hinv.covered z h i hi
      exact ⟨e, (hHolds ..).mpr he⟩
    · obtain ⟨e, he⟩ := hinv.covered r hmem i (hlog ▸ hi)
      exact ⟨e, hlnv ▸ (hHolds ..).mpr he⟩
  · intro z hz w hw hlnvzw i e e' he he'
    have get : ∀ {x : Replica Op Output St}, x ∈ s.replicas ∨ r' = x →
        ∃ y ∈ s.replicas, y.log = x.log ∧ y.lastNormalView = x.lastNormalView := by
      intro x hx; rcases hx with h | rfl
      · exact ⟨x, h, rfl, rfl⟩
      · exact ⟨r, hmem, hlog.symm, hlnv.symm⟩
    obtain ⟨z0, hz0, hz0log, hz0lnv⟩ := get (hrepl z hz)
    obtain ⟨w0, hw0, hw0log, hw0lnv⟩ := get (hrepl w hw)
    exact hinv.agree z0 hz0 w0 hw0 (by rw [hz0lnv, hw0lnv]; exact hlnvzw) i e e'
      (by rw [hz0log]; exact he) (by rw [hw0log]; exact he')
  · obtain ⟨g1, g2, g3⟩ := hinv.startedViews
    refine ⟨fun v votes hv => ?_,
      fun v off log hf hpos => (g2 v off log ((hFrag ..).mp hf) hpos).imp (fun votes hh => fT _ hh),
      fun z hz hzr hzv => ?_⟩
    · obtain ⟨to, log, o, k, h⟩ := g1 v votes (fT' _ hv)
      exact ⟨to, log, o, k, (hSent ..).mpr h⟩
    · rcases hrepl z hz with h | rfl
      · exact (g3 z h hzr hzv).imp (fun votes hh => fT _ hh)
      · rw [hlnv]
        exact (g3 r hmem (hstat ▸ hzr) (by rw [hlnv] at hzv; exact hzv)).imp (fun votes hh => fT _ hh)
  · intro z hz; rcases hrepl z hz with h | rfl
    · exact hinv.clean z h
    · exact ⟨hreplies, hcv⟩
  · show 2 ≤ s'.config.replicaCount
    rw [hce]; exact hinv.two

/-- A normal backup raising its commit number to a backed bound within its
log keeps `Inv`. The receiving-side core of `onCommit`, `onPrepare`, and
`onNewState`. -/
theorem Inv.commitStep {s : System Op Output St} (hinv : Inv s) {id : ReplicaId}
    {r : Replica Op Output St} (hr : s.replicas[id]? = some r) (m : Machine Op Output St) (k : Nat)
    (hkle : k ≤ r.log.length) (hk : Backed s r.lastNormalView k) :
    Inv (s.drain id (Replica.commitUpTo m r k false)) := by
  have hmem : r ∈ s.replicas := List.mem_of_getElem? hr
  have hlocal := hinv.local_ r hmem
  have hclean := hinv.clean r hmem
  have hbackedNew : Backed s r.lastNormalView (Replica.commitUpTo m r k false).commitNumber :=
    (Backed.max (hinv.backed.1 r hmem) hk).downward (commitUpTo_le_max m r k false)
  exact hinv.replace hr (by simp) (by simp) (by simp) (by simp) (by simp) (by simp) (by simp) (by simp)
    (by simp) (by rw [commitUpTo_false_panicked m r k hlocal.1 hkle]; exact hinv.noPanic r hmem)
    (by rw [Replica.commitUpTo_outbox]; exact hinv.drained r hmem)
    (by rw [Replica.commitUpTo_replies_false]; exact hclean.1)
    (by rw [Replica.commitUpTo_chosenVotes]; exact hclean.2)
    hbackedNew (hlocal.commitUpTo m k false)

/-- Adding a `GetState` message keeps `Inv`. It carries no log and is not
a fragment, an acknowledgement, or any constructor a clause tracks, so it
is inert everywhere except `MessagesBelowView`, which the sender's view
being at least the message's discharges. -/
theorem Inv.addGetState {s : System Op Output St} (hinv : Inv s) (to q : ReplicaId)
    (v : ViewNumber) (o : OpNumber)
    (hbelow : ∀ q0 ∈ s.replicas, q0.selfId = q → v ≤ q0.viewNumber) :
    Inv { s with sent := s.sent ++ [(to, .getState q v o)] } := by
  generalize hs' : ({ s with sent := s.sent ++ [(to, (.getState q v o : Message Op))] } :
    System Op Output St) = s'
  have hse : s'.sent = s.sent ++ [(to, (.getState q v o : Message Op))] := by rw [← hs']
  have hre : s'.replicas = s.replicas := by rw [← hs']
  have hste : s'.started = s.started := by rw [← hs']
  have hce : s'.config = s.config := by rw [← hs']
  have fS : ∀ x ∈ s.sent, x ∈ s'.sent := fun x h => by rw [hse]; exact List.mem_append_left _ h
  have fT : ∀ x ∈ s.started, x ∈ s'.started := fun x h => by rw [hste]; exact h
  have fT' : ∀ x ∈ s'.started, x ∈ s.started := fun x h => by rw [← hste]; exact h
  -- a fragment of s' is a fragment of s: GetState contributes none
  have hFrag : ∀ w off log, Frag s' w off log ↔ Frag s w off log := by
    intro w off log
    constructor
    · intro h
      have : Frag { s with sent := s.sent ++ [(to, (.getState q v o : Message Op))] } w off log := by
        rw [hs']; exact h
      rcases Frag.addMessage this with h' | h'
      · exact h'
      · nomatch h'
    · exact Frag.mono fS fT
  have hHolds : ∀ w i e, Holds s' w i e ↔ Holds s w i e := by
    intro w i e; constructor
    · rintro ⟨off, log, hf, hle, hget⟩; exact ⟨off, log, (hFrag ..).mp hf, hle, hget⟩
    · rintro ⟨off, log, hf, hle, hget⟩; exact ⟨off, log, (hFrag ..).mpr hf, hle, hget⟩
  have hSentSplit : ∀ {t : ReplicaId} {msg : Message Op}, Sent s' t msg →
      Sent s t msg ∨ (t, msg) = (to, (.getState q v o : Message Op)) := by
    intro t msg h
    have : Sent { s with sent := s.sent ++ [(to, (.getState q v o : Message Op))] } t msg := by
      rw [hs']; exact h
    exact Sent.addMessage this
  have hSentOf : ∀ {t : ReplicaId} {msg : Message Op}, Sent s t msg → Sent s' t msg := by
    intro t msg h; rw [Sent, hse]; exact List.mem_append_left _ h
  have hAcked : ∀ w i qq, Acked s' w i qq → Acked s w i qq := by
    intro w i qq h
    rcases h with h | ⟨t0, o0, hs0, hlt0⟩
    · left; rw [hce] at h; exact h
    · rcases hSentSplit hs0 with h' | h'
      · exact Or.inr ⟨t0, o0, h', hlt0⟩
      · simp at h'
  have hQuorum : ∀ w i, QuorumAcked s' w i → QuorumAcked s w i := by
    intro w i ⟨Q, hnd, hlen, hq⟩
    refine ⟨Q, hnd, by rw [hce] at hlen; exact hlen, fun qq hqq => ?_⟩
    obtain ⟨hlt, ha⟩ := hq qq hqq
    exact ⟨by rw [← hce]; exact hlt, hAcked w i qq ha⟩
  have hComm : ∀ w i e, Committed s' w i e → Committed s w i e :=
    fun w i e ⟨hh, hqa⟩ => ⟨(hHolds ..).mp hh, hQuorum w i hqa⟩
  have hBackedFwd : ∀ w k, Backed s w k → Backed s' w k := fun w k => Backed.mono fS fT hce
  refine {
    noPanic := fun r hr => hinv.noPanic r (hre ▸ hr)
    ids := fun i x hx => ⟨(hinv.ids i x (hre ▸ hx)).1, hce ▸ (hinv.ids i x (hre ▸ hx)).2⟩
    local_ := fun x hx => hinv.local_ x (hre ▸ hx)
    drained := fun x hx => hinv.drained x (hre ▸ hx)
    wf := ?_, oneLog := ?_, backed := ?_, survives := ?_, acks := ?_
    catching := fun x hx hc => hinv.catching x (hre ▸ hx) hc
    acksHold := ?_, toOthers := ?_, longest := ?_, chosen := ?_, votesCover := ?_,
    belowView := ?_, recoveryCovers := ?_, covered := ?_
    agree := fun z hz w hw h i e e' he he' => hinv.agree z (hre ▸ hz) w (hre ▸ hw) h i e e' he he'
    startedViews := ?_
    clean := fun x hx => hinv.clean x (hre ▸ hx)
    two := by show 2 ≤ s'.config.replicaCount; rw [hce]; exact hinv.two }
  · intro x hx
    rcases hSentSplit hx with h | h
    · exact hinv.wf x h
    · injection h with _ h2; rw [h2]; trivial
  · exact ⟨fun w i e e' h h' => hinv.oneLog.1 w i e e' ((hHolds ..).mp h) ((hHolds ..).mp h'),
      fun z hz i e e' he hh => hinv.oneLog.2 z (hre ▸ hz) i e e' he ((hHolds ..).mp hh)⟩
  · refine ⟨fun z hz => hBackedFwd _ _ (hinv.backed.1 z (hre ▸ hz)), fun t msg hm => ?_⟩
    rcases hSentSplit hm with h | h
    · exact MsgBacked.mono fS fT hce (hinv.backed.2 t msg h)
    · injection h with _ h2; rw [h2]; trivial
  · intro v' i e hc w hlt
    obtain ⟨h1, h2, h3, h4, h5, h6, h7⟩ := hinv.survives v' i e (hComm _ _ _ hc) w hlt
    refine ⟨fun t log o0 k hs => ?_, fun t v'' r0 log o0 k hs => ?_, fun t n r0 st hs => ?_,
      fun t log a b k hs ha => ?_, fun t c n op k hs => ?_,
      fun v'' votes qq vote hstd hin hlv => h6 v'' votes qq vote (fT' _ hstd) hin hlv,
      fun z hz => h7 z (hre ▸ hz)⟩
    · rcases hSentSplit hs with h | h; exact h1 t log o0 k h; simp at h
    · rcases hSentSplit hs with h | h; exact h2 t v'' r0 log o0 k h; simp at h
    · rcases hSentSplit hs with h | h; exact h3 t n r0 st h; simp at h
    · rcases hSentSplit hs with h | h; exact h4 t log a b k h ha; simp at h
    · rcases hSentSplit hs with h | h; exact h5 t c n op k h; simp at h
  · intro z hz hzn hzp oa hoa
    obtain ⟨c1, c2⟩ := hinv.acks z (hre ▸ hz) hzn hzp oa hoa
    exact ⟨c1, fun qq hq => (c2 qq hq).imp (fun h => h) (fun ⟨t, ht⟩ => ⟨t, hSentOf ht⟩)⟩
  · intro t v0 o0 qq hs z hz
    rcases hSentSplit hs with h | h
    · exact hinv.acksHold t v0 o0 qq h z (hre ▸ hz)
    · simp at h
  · intro t msg hs
    rcases hSentSplit hs with h | h
    · have := hinv.toOthers t msg h; revert this; cases msg <;> simp_all
    · injection h with _ h2; rw [h2]; trivial
  · intro p hp hpn hpp
    obtain ⟨f1, f2, f3⟩ := hinv.longest p (hre ▸ hp) hpn hpp
    exact ⟨fun off log hf => f1 off log ((hFrag ..).mp hf), fun z hz hzv hzr => f2 z (hre ▸ hz) hzv hzr,
      fun t o0 qq hs => by rcases hSentSplit hs with h | h; exact f3 t o0 qq h; simp at h⟩
  · intro t v0 log o0 k hs
    rcases hSentSplit hs with h | h
    · obtain ⟨votes, best, hv, hq, hnd, hb, hpre⟩ := hinv.chosen t v0 log o0 k h
      exact ⟨votes, best, fT _ hv, by rw [hce]; exact hq, hnd, hb, hpre⟩
    · simp at h
  · intro v0 votes hv qq vote hin t o0 hs
    rcases hSentSplit hs with h | h
    · exact hinv.votesCover v0 votes (fT' _ hv) qq vote hin t o0 h
    · simp at h
  · intro t msg hs z hz
    rcases hSentSplit hs with h | h
    · exact hinv.belowView t msg h z (hre ▸ hz)
    · injection h with h1 h2; subst h1; subst h2
      intro hq; exact hbelow z (hre ▸ hz) hq
  · intro z hz hzr t v0 nonce r0 st hs hnhyp t' o0 hs'2
    rcases hSentSplit hs with h | h
    · rcases hSentSplit hs'2 with h' | h'
      · exact hinv.recoveryCovers z (hre ▸ hz) hzr t v0 nonce r0 st h hnhyp t' o0 h'
      · simp at h'
    · simp at h
  · intro z hz i hi
    obtain ⟨e, he⟩ := hinv.covered z (hre ▸ hz) i hi
    exact ⟨e, (hHolds ..).mpr he⟩
  · obtain ⟨g1, g2, g3⟩ := hinv.startedViews
    refine ⟨fun w votes hv => ?_,
      fun w off log hf hpos => (g2 w off log ((hFrag ..).mp hf) hpos).imp (fun votes hh => fT _ hh),
      fun z hz hzr hzv => (g3 z (hre ▸ hz) hzr hzv).imp (fun votes hh => fT _ hh)⟩
    obtain ⟨t, log, o0, k, h⟩ := g1 w votes (fT' _ hv)
    exact ⟨t, log, o0, k, hSentOf h⟩


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
