// -*- mode: Bluespec; -*-
/// Five replicas: a quorum of three, so one view change can lose two
/// replicas' worth of acknowledgements.
module vsr5 {
  import vsr(N = 5, CLIENTS = Set(1, 2), MAX_REQ = 2, OPS = Set(0, 1), MAX_VIEW = 4).* from "./vsr"
}
