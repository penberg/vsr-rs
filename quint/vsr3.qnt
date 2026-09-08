// -*- mode: Bluespec; -*-
/// Three replicas, two clients, two requests each: the smallest cluster
/// with a quorum of two.
module vsr3 {
  import vsr(N = 3, CLIENTS = Set(1, 2), MAX_REQ = 2, OPS = Set(0, 1), MAX_VIEW = 3).* from "./vsr"
}
