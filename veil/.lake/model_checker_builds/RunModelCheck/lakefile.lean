import Lake
open Lake DSL System

require Veil from "../../.."
require Cli from "../../../.lake/packages/Cli"
require cvc5 from "../../../.lake/packages/cvc5"
require smt from "../../../.lake/packages/smt"
require Loom from "../../../.lake/packages/Loom"
require mathlib from "../../../.lake/packages/mathlib"
require auto from "../../../.lake/packages/auto"
require plausible from "../../../.lake/packages/plausible"
require LeanSearchClient from "../../../.lake/packages/LeanSearchClient"
require importGraph from "../../../.lake/packages/importGraph"
require proofwidgets from "../../../.lake/packages/proofwidgets"
require aesop from "../../../.lake/packages/aesop"
require Qq from "../../../.lake/packages/Qq"
require batteries from "../../../.lake/packages/batteries"

package veilmodel

lean_lib Model where
  globs := #[Glob.one `Model]

lean_exe ModelCheckerMain where
  root := `ModelCheckerMain
  buildType := .relWithDebInfo
