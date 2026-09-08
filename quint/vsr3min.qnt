// -*- mode: Bluespec; -*-
/// The smallest instance: three replicas, one client with one request,
/// views up to 2. For Apalache, which pays for every value in the state.
module vsr3min {
  import vsr(N = 3, CLIENTS = Set(1), MAX_REQ = 1, OPS = Set(0), MAX_VIEW = 2).* from "./vsr"
}
