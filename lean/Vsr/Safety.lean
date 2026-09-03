import Vsr.System

/-!
The safety properties, stated over reachable systems. They are the
simulator's, from `simulator/properties.rs`.

Proved so far: the lemmas about `commitUpTo`. The main theorem is stated
and left as `sorry`; see the note on it.
-/

namespace Vsr

variable {Op Output St : Type}

/-- The systems the cluster can get into from a fresh start. -/
inductive Reachable (m : Machine Op Output St) (sm : St) (config : Config) :
    System Op Output St → Prop
  | init : Reachable m sm config (System.init config sm)
  | step {s : System Op Output St} {st : Step Op} :
      Reachable m sm config s → Reachable m sm config (s.step m sm st)

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

/-- Every committed entry sits at its index in a quorum of logs. -/
def Durability [DecidableEq Op] (s : System Op Output St) : Prop :=
  ∀ r ∈ s.replicas, ∀ i, i < r.commitNumber →
    s.config.quorum ≤ (s.replicas.filter fun o => o.log[i]? = r.log[i]?).length

/-- The main theorem. Not proved: it needs an inductive invariant over the
whole system, in particular that every `sent` message is well formed and
that quorum intersection carries committed entries across view changes and
recovery. That is the work the model exists to make possible; it is not
done yet. -/
theorem safety [DecidableEq Op] (m : Machine Op Output St) (sm : St) (config : Config)
    (s : System Op Output St) (h : Reachable m sm config s) :
    NoPanic s ∧ CommitBounded s ∧ PrefixAgreement s ∧ Durability s := by
  sorry

/-! ### What is proved: commit numbers only move forward -/

namespace Replica

theorem commitOp_commitNumber (m : Machine Op Output St) (r : Replica Op Output St)
    (entry : LogEntry Op) : (commitOp m r entry).1.commitNumber = r.commitNumber + 1 := by
  simp [commitOp]

theorem commitUpTo_go_mono (m : Machine Op Output St) (reply : Bool) :
    ∀ (n : Nat) (r : Replica Op Output St),
      r.commitNumber ≤ (commitUpTo.go m reply n r).commitNumber := by
  intro n
  induction n with
  | zero => intro r; simp [commitUpTo.go]
  | succ n ih =>
    intro r
    simp only [commitUpTo.go]
    split
    · simp [panic]
    · rename_i entry _
      have h1 := commitOp_commitNumber m r entry
      generalize hc : commitOp m r entry = p at h1 ⊢
      obtain ⟨r', response⟩ := p
      simp only at h1 ⊢
      have h3 : (if reply = true then { r' with replies := r'.replies ++ [response] } else r').commitNumber
          = r'.commitNumber := by split <;> rfl
      have h2 := ih (if reply = true then { r' with replies := r'.replies ++ [response] } else r')
      rw [h3] at h2
      exact Nat.le_trans (by rw [h1]; exact Nat.le_succ _) h2

theorem commitUpTo_mono (m : Machine Op Output St) (r : Replica Op Output St)
    (commitNumber : CommitNumber) (reply : Bool) :
    r.commitNumber ≤ (commitUpTo m r commitNumber reply).commitNumber :=
  commitUpTo_go_mono m reply _ r

end Replica

end Vsr
