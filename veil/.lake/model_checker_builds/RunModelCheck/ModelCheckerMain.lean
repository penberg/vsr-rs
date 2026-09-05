import Model

set_option maxHeartbeats 6400000
set_option synthInstance.maxHeartbeats 200000
set_option synthInstance.maxSize 10000

open RunModelCheck

def flushStdoutAndStderr : IO Unit := do
  let stdout ← IO.getStdout
  let stderr ← IO.getStderr
  stdout.flush
  stderr.flush

def exitWhenParentDies : IO Unit := do
  let stdin ← IO.getStdin
  let _ ← stdin.readToEnd
  flushStdoutAndStderr
  IO.Process.forceExit 2

def main (args : List String) : IO Unit := do
  let _ ← IO.asTask (prio := .dedicated) exitWhenParentDies
  -- Enable progress reporting to stderr for the IDE to read
  Veil.ModelChecker.Concrete.enableCompiledModeProgress
  let pcfg : Option Veil.ModelChecker.ParallelConfig :=
    match args with
    | a :: b :: args' =>
      let numSubSteps := args'.head?.bind String.toNat? |>.getD 1
      match a.toNat?, b.toNat? with
      | some numSubTasks, some thresholdToParallel => some { numSubTasks, thresholdToParallel, numSubSteps : Veil.ModelChecker.ParallelConfig }
      | _, _ => none
    | _ => none
  -- Instance ID is not used in compiled mode, pass 0
  -- Cancel token is created locally; cancellation is handled by killing the process from outside
  let cancelTk ← IO.CancelToken.new
  let res ← modelCheckerResult pcfg 0 cancelTk
  IO.println s!"{Lean.toJson res}"
  flushStdoutAndStderr
  IO.Process.forceExit 0
