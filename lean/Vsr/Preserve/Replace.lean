import Vsr.Preserve.Kinds

/-!
The replica-change shapes, and the links of a handler proof: one change,
one send, a fold of sends.
-/

namespace Vsr

variable {Op Output St : Type}

/-! ### Shapes of a change -/

section Shapes
variable {s : System Op Output St} (hinv : Inv s) {id : ReplicaId} {r r' : Replica Op Output St}
  (hr : s.replicas[id]? = some r)
include hinv hr

/-- A change that keeps the log and last normal view: a commit, a status
change, new bookkeeping. -/
theorem StepOK.keepLog (hlog : r'.log = r.log) (hlnv : r'.lastNormalView = r.lastNormalView)
    (hself : r'.selfId = r.selfId) (hconf : r'.config = r.config) (hnonce : r'.recoveryNonce = r.recoveryNonce)
    (hpanic : r'.panicked = false) (hout : r'.outbox = []) (hreplies : r'.replies = [])
    (hcv : r'.chosenDoViewChanges = none) (hview : r.viewNumber ≤ r'.viewNumber) (hloc : Replica.LocalInv r')
    (hnr : r.status ≠ .recovering) (hnr' : r'.status ≠ .recovering)
    (hbacked : Backed s r.lastNormalView r'.commitNumber)
    (hcatch : r'.catchingUp = true → r'.selfId ≠ r'.config.primaryId r'.viewNumber)
    (hacks : r'.status = .normal → r'.isPrimary = true → ∀ oa ∈ r'.acks, oa.1 ≤ r'.log.length ∧
      oa.2.Pairwise (· < ·) ∧ ∀ q ∈ oa.2, q < s.config.replicaCount ∧
        (q = r'.selfId ∨ ∃ dst, Sent s dst (.prepareOk r'.viewNumber oa.1 q)))
    (hvc : r'.status = .viewChange → r'.lastNormalView < r'.viewNumber)
    (htr : r'.status = .stateTransfer → r'.selfId ≠ s.config.primaryId r'.viewNumber)
    (hdvcs : r'.status = .viewChange →
      (r'.doViewChangeFrom.map Prod.fst).Pairwise (· < ·) ∧
      ∀ x d, (x, d) ∈ r'.doViewChangeFrom → x < s.config.replicaCount ∧
        ((∃ dst, Sent s dst (.doViewChange r'.viewNumber x d.lastNormalView d.log d.log.length d.commitNumber)) ∨
          (x = r'.selfId ∧ d = ⟨r'.lastNormalView, r'.log, r'.commitNumber⟩))) :
    StepOK s id r r' [] [] := by
  have hmem : r ∈ s.replicas := List.mem_of_getElem? hr
  refine StepOK.replace hinv hr hself hconf hpanic hout hreplies hcv hloc hview (hlnv ▸ Nat.le_refl _)
    ?_ ?_ ?_ hacks hcatch ?_ ?_ ?_ hvc ?_ ?_ ?_ ?_ ?_ htr ?_ hdvcs (fun h => absurd h hnr')
  · intro i e e' he hh; exact hinv.oneLog.2 r hmem i e e' (hlog ▸ he) (hlnv ▸ hh)
  · rw [hlnv]; exact hbacked
  · intro v' i e hc hlt _; rw [hlog]
    exact (hinv.survives v' i e hc _ (hlnv ▸ hlt)).2.2.2.2.2 r hmem rfl hnr
  · intro dst v o hs
    obtain ⟨ha, hb⟩ := hinv.acksHold dst v o r'.selfId hs r hmem hself.symm
    exact ⟨hlnv ▸ ha, fun he _ => by rw [hlog]; exact hb (hlnv ▸ he) hnr⟩
  · intro _ hp
    obtain ⟨f1, f2, f3⟩ := hinv.longest r hmem hnr (by rw [← hself, ← hlnv]; exact hp)
    refine ⟨fun off log hf => by rw [hlog]; exact f1 off log (hlnv ▸ hf),
      fun q hq _ hql hqn => by rw [hlog]; exact f2 q hq (hlnv ▸ hql) hqn,
      fun dst o q hs => by rw [hlog]; exact f3 dst o q (hlnv ▸ hs)⟩
  · intro p hp _ hpn hpp hl _
    rw [hlog]; exact (hinv.longest p hp hpn hpp).2.1 r hmem (hlnv ▸ hl) hnr
  · intro v dvcs b hv hb hl _; rw [hlog]
    exact (hinv.extendsBase v dvcs b hv hb).2.2.2 r hmem (hlnv ▸ hl) hnr
  · intro hrec; exact absurd hrec hnr'
  · intro i hi; rw [hlnv]; exact hinv.covered r hmem i (hlog ▸ hi)
  · intro z hz _ hl i e e' he he'; exact hinv.agree r hmem z hz (hlnv ▸ hl).symm i e e' (hlog ▸ he) he'
  · intro _ hpos; rw [hlnv] at hpos ⊢; exact hinv.startedViews.2.2 r hmem hnr hpos
  · intro hrec; exact absurd hrec hnr'

/-- Entering a view normal with a log taken from it: `onStartView`, a
catch-up's `onNewState`, `onRecoveryResponse`. The new log's entries are
held by the view, it holds every earlier commit, and the replica is not
the view's primary. -/
theorem StepOK.install {v : ViewNumber} {L : List (LogEntry Op)}
    (hstat : r'.status = .normal) (hview : r'.viewNumber = v) (hlnv : r'.lastNormalView = v)
    (hlog : r'.log = L) (hcatch : r'.catchingUp = false)
    (hself : r'.selfId = r.selfId) (hconf : r'.config = r.config) (hnonce : r'.recoveryNonce = r.recoveryNonce)
    (hpanic : r'.panicked = false) (hout : r'.outbox = []) (hreplies : r'.replies = [])
    (hcv : r'.chosenDoViewChanges = none) (hloc : Replica.LocalInv r')
    (hv : r.viewNumber ≤ v) (hlv : r.lastNormalView ≤ v)
    (hL : ∀ i e, L[i]? = some e → Holds s v i e)
    (hbacked : Backed s v r'.commitNumber)
    (hsurv : ∀ v' i e, Committed s v' i e → v' < v → L[i]? = some e)
    (hnp : r.selfId ≠ s.config.primaryId v)
    (hacksv : ∀ dst o, Sent s dst (.prepareOk v o r.selfId) → o ≤ L.length)
    (hlongOld : ∀ p ∈ s.replicas, p.selfId ≠ r.selfId → p.status ≠ .recovering →
      p.selfId = s.config.primaryId p.lastNormalView → p.lastNormalView = v → L.length ≤ p.log.length)
    (hext : ∀ dvcs b, (v, dvcs) ∈ s.started → Replica.bestDoViewChange dvcs = some b → b.log.length ≤ L.length)
    (hstarted : 0 < v → ∃ dvcs, (v, dvcs) ∈ s.started) :
    StepOK s id r r' [] [] := by
  have hmem : r ∈ s.replicas := List.mem_of_getElem? hr
  have hconf' : r'.config = s.config := hconf.trans (hinv.config_eq hmem)
  have hnr' : r'.status ≠ .recovering := by rw [hstat]; decide
  have hnp' : r'.selfId ≠ s.config.primaryId v := hself ▸ hnp
  refine StepOK.replace hinv hr hself hconf hpanic hout hreplies hcv hloc (hview ▸ hv) (hlnv ▸ hlv)
    ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_
    (fun hs => by rw [hstat] at hs; exact absurd hs (by decide))
    (fun hs => by rw [hstat] at hs; exact absurd hs (by decide))
  · intro i e e' he hh; rw [hlnv] at hh; exact hinv.oneLog.1 v i e e' (hL i e (hlog ▸ he)) hh
  · rw [hlnv]; exact hbacked
  · intro v' i e hc hlt _; rw [hlog]; exact hsurv v' i e hc (hlnv ▸ hlt)
  · intro _ hp
    exfalso; apply hnp'
    unfold Replica.isPrimary Replica.primaryId at hp
    rw [hconf', hview] at hp; exact of_decide_eq_true hp
  · intro hc; rw [hcatch] at hc; exact absurd hc (by decide)
  · intro dst v'' o hs
    rw [hlnv, hlog]
    rcases Nat.lt_or_eq_of_le ((hinv.acksHold dst v'' o r'.selfId hs r hmem hself.symm).1.trans hlv) with hlt | heq
    · exact ⟨Nat.le_of_lt hlt, fun he => absurd he (Nat.ne_of_gt hlt)⟩
    · exact ⟨Nat.le_of_eq heq, fun _ _ => hacksv dst o (heq ▸ (hself ▸ hs))⟩
  · intro _ hp; rw [hlnv] at hp; exact absurd hp hnp'
  · intro p hp hne hpn hpp hl _; rw [hlog]; exact hlongOld p hp hne hpn hpp (hlnv ▸ hl).symm
  · intro hs; rw [hstat] at hs; exact absurd hs (by decide)
  · intro v' dvcs b hv' hb hl _; rw [hlog]; rw [hlnv] at hl; subst hl; exact hext dvcs b hv' hb
  · intro hrec; exact absurd hrec hnr'
  · intro i hi; rw [hlnv]
    have hi' : i < L.length := hlog ▸ hi
    exact ⟨L[i], hL i _ (List.getElem?_eq_getElem hi')⟩
  · intro z hz _ hl i e e' he he'
    rw [hlnv] at hl
    exact (hinv.oneLog.2 z hz i e' e he' (hl ▸ hL i e (hlog ▸ he))).symm
  · intro _ hpos; rw [hlnv] at hpos ⊢; exact hstarted hpos
  · intro hs; rw [hstat] at hs; exact absurd hs (by decide)
  · intro hrec; exact absurd hrec hnr'

/-- A replica coming back with nothing but its view number and a fresh
nonce. -/
theorem StepOK.recover {n : Nat} (hstat : r'.status = .recovering) (hview : r'.viewNumber = r.viewNumber)
    (hlnv : r'.lastNormalView = r.viewNumber) (hlog : r'.log = []) (hcommit : r'.commitNumber = 0)
    (hcatch : r'.catchingUp = false) (hself : r'.selfId = r.selfId) (hconf : r'.config = r.config)
    (hnonce : r'.recoveryNonce = n) (hpanic : r'.panicked = false) (hout : r'.outbox = [])
    (hreplies : r'.replies = []) (hcv : r'.chosenDoViewChanges = none) (hloc : Replica.LocalInv r')
    (hresp : r'.recoveryResponses = [])
    (hfresh : ∀ dst i v, ¬ Sent s dst (.recovery i n v)) : StepOK s id r r' [] [] := by
  have hmem : r ∈ s.replicas := List.mem_of_getElem? hr
  have hnorr : ∀ dst v p st, ¬ Sent s dst (.recoveryResponse v n p st) := by
    intro dst v p st hs
    obtain ⟨dst', i, v', h'⟩ := hinv.rrNonce dst v n p st hs
    exact hfresh dst' i v' h'
  refine StepOK.replace hinv hr hself hconf hpanic hout hreplies hcv hloc (hview ▸ Nat.le_refl _)
    (hlnv ▸ (hinv.local_ r hmem).2.1) ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_
    (fun hs => by rw [hstat] at hs; exact absurd hs (by decide))
    (fun _ x resp hx => by rw [hresp] at hx; simp at hx)
  · intro i e e' he; rw [hlog] at he; simp at he
  · rw [hcommit]; intro i hi; simp at hi
  · intro _ _ _ _ _ hn; exact absurd hstat hn
  · intro hn; rw [hstat] at hn; exact absurd hn (by decide)
  · intro hc; rw [hcatch] at hc; exact absurd hc (by decide)
  · intro dst v o hs
    refine ⟨?_, fun _ hn => absurd hstat hn⟩
    rw [hlnv]
    exact ((hinv.acksHold dst v o r'.selfId hs r hmem hself.symm).1).trans (hinv.local_ r hmem).2.1
  · intro hn; exact absurd hstat hn
  · intro _ _ _ _ _ _ hn; exact absurd hstat hn
  · intro hs; rw [hstat] at hs; exact absurd hs (by decide)
  · intro _ _ _ _ _ _ hn; exact absurd hstat hn
  · intro _ dst v n' q stt hs hn; rw [hnonce] at hn; subst hn; exact absurd hs (hnorr dst v q _)
  · intro i hi; rw [hlog] at hi; simp at hi
  · intro z hz _ _ i e e' he; rw [hlog] at he; simp at he
  · intro hn; exact absurd hstat hn
  · intro hs; rw [hstat] at hs; exact absurd hs (by decide)
  · intro _ dst v n' p stt hs hn; rw [hnonce] at hn; subst hn; exact absurd hs (hnorr dst v p stt)

end Shapes

/-! ### The links of a handler proof -/

theorem Replica.send_clear (r : Replica Op Output St) (dst : ReplicaId) (msg : Message Op) :
    (r.send dst msg).clear = r.clear := rfl

theorem Replica.send_startedList (r : Replica Op Output St) (dst : ReplicaId) (msg : Message Op) :
    (r.send dst msg).startedList = r.startedList := rfl

theorem Replica.send_outbox' (r : Replica Op Output St) (dst : ReplicaId) (msg : Message Op) :
    (r.send dst msg).outbox = r.outbox ++ [(dst, msg)] := rfl

section Links
variable {s : System Op Output St} {id : ReplicaId} (hlt : id < s.replicas.length)
include hlt

/-- One send. -/
theorem Inv.drainSend {r1 : Replica Op Output St} (hinv : Inv (s.drainOf id r1)) {dst : ReplicaId}
    {msg : Message Op} (h : MsgOK (s.drainOf id r1) id r1.clear (dst, msg)) :
    Inv (s.drainOf id (r1.send dst msg)) := by
  refine hinv.drainStep hlt (Replica.send_outbox' r1 dst msg)
    (by rw [Replica.send_startedList, List.append_nil]) ?_
  rw [Replica.send_clear]
  exact StepOK.send hinv (s.drainOf_replicas_self r1 hlt) h

/-- One change with nothing sent. -/
theorem Inv.drainReplace {r1 r2 : Replica Op Output St} (hinv : Inv (s.drainOf id r1))
    (hout : r2.outbox = r1.outbox) (hst : r2.startedList = r1.startedList)
    (h : StepOK (s.drainOf id r1) id r1.clear r2.clear [] []) : Inv (s.drainOf id r2) :=
  hinv.drainStep hlt (by rw [hout, List.append_nil]) (by rw [hst, List.append_nil]) h

/-- A fold of sends of one message to a list of recipients, each of which
is fine from any state that satisfies the invariant with this replica in
it. -/
theorem Inv.drainSendFold {r1 : Replica Op Output St} (msg : Message Op) {l : List ReplicaId}
    (h : ∀ dst ∈ l, ∀ (s' : System Op Output St), Inv s' → s'.replicas[id]? = some r1.clear →
      MsgOK s' id r1.clear (dst, msg)) :
    ∀ (r : Replica Op Output St), r.clear = r1.clear → Inv (s.drainOf id r) →
      Inv (s.drainOf id (l.foldl (fun r dst => r.send dst msg) r)) := by
  induction l with
  | nil => intro r _ hr; exact hr
  | cons dst l ih =>
    intro r hcl hr
    rw [List.foldl_cons]
    refine ih (fun d hd => h d (List.mem_cons_of_mem _ hd)) (r.send dst msg) (by rw [Replica.send_clear, hcl]) ?_
    have hm := h dst (List.mem_cons_self ..) (s.drainOf id r) hr (by rw [s.drainOf_replicas_self r hlt, hcl])
    exact hr.drainSend hlt (hcl ▸ hm)

omit hlt in
theorem Replica.sendToOthers_eq (r : Replica Op Output St) (msg : Message Op) :
    r.sendToOthers msg = (r.config.replicas.filter (· ≠ r.selfId)).foldl (fun r dst => r.send dst msg) r := rfl

/-- `sendToOthers`. -/
theorem Inv.drainSendToOthers {r1 : Replica Op Output St} (hinv : Inv (s.drainOf id r1)) (msg : Message Op)
    (h : ∀ dst, dst ∈ r1.config.replicas → dst ≠ r1.selfId → ∀ (s' : System Op Output St), Inv s' →
      s'.replicas[id]? = some r1.clear → MsgOK s' id r1.clear (dst, msg)) :
    Inv (s.drainOf id (r1.sendToOthers msg)) := by
  rw [Replica.sendToOthers_eq]
  refine Inv.drainSendFold hlt msg (fun dst hd => ?_) r1 rfl hinv
  rw [List.mem_filter] at hd
  exact h dst hd.1 (by simpa using hd.2)

end Links

/-- The handler starts from a clean replica. -/
theorem Inv.drainOf_start {s : System Op Output St} (hinv : Inv s) {id : ReplicaId} {r : Replica Op Output St}
    (hr : s.replicas[id]? = some r) : Inv (s.drainOf id r) := by
  have hmem := List.mem_of_getElem? hr
  rw [s.drainOf_clean hr (hinv.drained r hmem) (hinv.clean r hmem).1 (hinv.clean r hmem).2]
  exact hinv

/-- Facts about the replica at `id` in its drained view: the same fields. -/
theorem drainOf_mem {s : System Op Output St} (id : ReplicaId) (r : Replica Op Output St)
    (hlt : id < s.replicas.length) : r.clear ∈ (s.drainOf id r).replicas :=
  List.mem_of_getElem? (s.drainOf_replicas_self r hlt)

end Vsr
