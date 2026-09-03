import Vsr
import Vsr.Check

/-!
Replays a trace of cluster steps on the Lean model and prints what it sees
after each one, in the format the Rust conformance test prints for the real
replicas. The test diffs the two.

After each step the invariants and the candidate invariants in
`Vsr.Check` are evaluated, and any that fail are reported on stderr as
`violation step N name`. The conformance test fails on any such line.

The trace is one step per line:

    config replicas=N timeout=T
    deliver I
    idle R
    request to=R client=C request=N op=OP
    recover R nonce=X
-/

open Vsr

/-- The state machine the conformance test uses on both sides: it records
every op and answers with how many it has applied. -/
def recorder : Machine Nat Nat (List Nat) where
  apply s op := (s ++ [op], s.length + 1)

def fmtEntry (e : LogEntry Nat) : String := s!"{e.clientId}:{e.requestNumber}:{e.op}"

def fmtLog (log : List (LogEntry Nat)) : String := "[" ++ ",".intercalate (log.map fmtEntry) ++ "]"

def fmtMessage : Message Nat → String
  | .request c n op => s!"Request client={c} request={n} op={op}"
  | .prepare v o c n op k => s!"Prepare view={v} op={o} client={c} request={n} input={op} commit={k}"
  | .prepareOk v o r => s!"PrepareOk view={v} op={o} replica={r}"
  | .commit v k => s!"Commit view={v} commit={k}"
  | .getState r v o => s!"GetState replica={r} view={v} op={o}"
  | .newState v log a b k => s!"NewState view={v} log={fmtLog log} start={a} end={b} commit={k}"
  | .startViewChange v r => s!"StartViewChange view={v} replica={r}"
  | .doViewChange v r l log o k =>
    s!"DoViewChange view={v} replica={r} last_normal={l} log={fmtLog log} op={o} commit={k}"
  | .startView v log o k => s!"StartView view={v} log={fmtLog log} op={o} commit={k}"
  | .recovery r n v => s!"Recovery replica={r} nonce={n} view={v}"
  | .recoveryResponse v n r state =>
    let st := match state with
      | none => "none"
      | some s => s!"{fmtLog s.log}/{s.commitNumber}"
    s!"RecoveryResponse view={v} nonce={n} replica={r} state={st}"

def fmtReply (r : Reply Nat) : String :=
  s!"Reply view={r.viewNumber} client={r.clientId} request={r.requestNumber} result={r.result}"

def fmtStatus : Status → String
  | .normal => "Normal"
  | .stateTransfer => "StateTransfer"
  | .recovering => "Recovering"
  | .viewChange => "ViewChange"

def fmtReplica (id : Nat) (r : Replica Nat Nat (List Nat)) : String :=
  let applied := "[" ++ ",".intercalate (r.sm.map toString) ++ "]"
  let base := s!"replica {id} status={fmtStatus r.status} view={r.viewNumber} commit={r.commitNumber} log={fmtLog r.log} applied={applied}"
  if r.panicked then base ++ " panicked" else base

/-- `key=value` fields of a line. -/
def field (tokens : List String) (key : String) : Option Nat :=
  tokens.findSome? fun t =>
    match t.splitOn "=" with
    | [k, v] => if k = key then v.toNat? else none
    | _ => none

def parseStep (tokens : List String) : Option (Step Nat) :=
  match tokens with
  | ["deliver", i] => i.toNat?.map .deliver
  | ["idle", r] => r.toNat?.map .idle
  | "request" :: rest => do
    let to ← field rest "to"
    let c ← field rest "client"
    let n ← field rest "request"
    let op ← field rest "op"
    pure (.request to c n op)
  | "recover" :: r :: rest => do
    let r ← r.toNat?
    let nonce ← field rest "nonce"
    pure (.recover r nonce)
  | _ => none

def main (args : List String) : IO UInt32 := do
  let [path] := args | IO.eprintln "usage: vsr-replay TRACE"; return 2
  let lines ← IO.FS.lines path
  let mut system : Option (System Nat Nat (List Nat)) := none
  let mut stepNumber := 0
  for line in lines do
    let tokens := (line.splitOn " ").filter (· ≠ "")
    if tokens.isEmpty then continue
    match tokens with
    | "config" :: rest =>
      let some replicas := field rest "replicas" | IO.eprintln s!"bad config: {line}"; return 2
      let some timeout := field rest "timeout" | IO.eprintln s!"bad config: {line}"; return 2
      system := some (System.init ⟨replicas, timeout⟩ [])
    | _ =>
      let some s := system | IO.eprintln "config line must come first"; return 2
      let some step := parseStep tokens | IO.eprintln s!"bad step: {line}"; return 2
      let s' := s.step recorder [] step
      IO.println s!"step {stepNumber} {line}"
      let mut i := s.sent.length
      for (to, msg) in s'.sent.drop s.sent.length do
        IO.println s!"send {i} to={to} {fmtMessage msg}"
        i := i + 1
      for reply in s'.replies.drop s.replies.length do
        IO.println (fmtReply reply)
      let mut id := 0
      for r in s'.replicas do
        IO.println (fmtReplica id r)
        id := id + 1
      for name in Check.violations recorder s' do
        IO.eprintln s!"violation step {stepNumber} {name}"
      system := some s'
      stepNumber := stepNumber + 1
  return 0
