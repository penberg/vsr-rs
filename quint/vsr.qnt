// -*- mode: Bluespec; -*-
/// The vsr-rs replica and cluster in Quint.
///
/// A twin of `lean/Vsr/Replica.lean` and `lean/Vsr/System.lean`, which are
/// themselves twins of `lib.rs`: one definition per Rust function, with the
/// same control flow. Where the Lean model is proved, this one is checked:
/// `quint run` explores random executions and `quint verify` (Apalache)
/// explores every execution up to a bounded length, both against the same
/// safety properties as the Lean theorem `Vsr.safety`.
///
/// Differences from the Lean model, all abstractions that only add behaviour:
///
/// - Timers are not modelled. Every idle period may or may not be the one
///   on which a wait runs out; the environment chooses (`onIdle`'s
///   `timeout`). Every schedule the Rust timers can produce is one of them.
/// - The state machine and replies are not modelled. An op is identified by
///   its client, request number, and an abstract op value; the client table
///   records whether a request has been executed instead of its reply.
/// - View numbers are bounded by `MAX_VIEW` so the state space is finite:
///   a replica whose view is `MAX_VIEW` no longer times out.
module vsr {
  // ---------------------------------------------------------------------
  // Parameters

  /// The number of replicas; ids are `0 .. N-1`.
  const N: int
  const CLIENTS: Set[int]
  /// Request numbers a client may use: `1 .. MAX_REQ`.
  const MAX_REQ: int
  /// The abstract op values a request may carry.
  const OPS: Set[int]
  /// No replica times out once it has reached this view.
  const MAX_VIEW: int

  type ReplicaId = int
  type ViewNumber = int
  type OpNumber = int
  type CommitNumber = int

  val REPLICAS: Set[ReplicaId] = 0.to(N - 1)
  val QUORUM: int = N / 2 + 1
  val F: int = N / 2

  pure def primaryOf(v: ViewNumber): ReplicaId = v % N
  pure def min(a: int, b: int): int = if (a < b) a else b
  pure def max(a: int, b: int): int = if (a > b) a else b

  // ---------------------------------------------------------------------
  // Types, as in `lib.rs`

  type Option[a] = Some(a) | None

  type Entry = { clientId: int, requestNumber: int, op: int }
  type Log = List[Entry]
  type RecoveryState = { log: Log, commitNumber: CommitNumber }

  /// `Message` in the Rust, variant for variant, field for field.
  type Message =
    | Request({ clientId: int, requestNumber: int, op: int })
    | Prepare({ viewNumber: ViewNumber, opNumber: OpNumber, entry: Entry, commitNumber: CommitNumber })
    | PrepareOk({ viewNumber: ViewNumber, opNumber: OpNumber, replicaId: ReplicaId })
    | Commit({ viewNumber: ViewNumber, commitNumber: CommitNumber })
    | GetState({ replicaId: ReplicaId, viewNumber: ViewNumber, opNumber: OpNumber })
    | NewState({ viewNumber: ViewNumber, log: Log, opNumberStart: OpNumber, opNumberEnd: OpNumber,
                 commitNumber: CommitNumber })
    | StartViewChange({ viewNumber: ViewNumber, replicaId: ReplicaId })
    | DoViewChange({ viewNumber: ViewNumber, replicaId: ReplicaId, lastNormalView: ViewNumber, log: Log,
                     opNumber: OpNumber, commitNumber: CommitNumber })
    | StartView({ viewNumber: ViewNumber, log: Log, opNumber: OpNumber, commitNumber: CommitNumber })
    | Recovery({ replicaId: ReplicaId, nonce: int, viewNumber: ViewNumber })
    | RecoveryResponse({ viewNumber: ViewNumber, nonce: int, replicaId: ReplicaId, state: Option[RecoveryState] })

  /// A message and the replica it is addressed to.
  type Envelope = { dst: ReplicaId, msg: Message }

  type Status = Normal | StateTransfer | Recovering | ViewChange

  type ClientEntry = { requestNumber: int, replied: bool }
  type Dvc = { lastNormalView: ViewNumber, log: Log, commitNumber: CommitNumber }
  type RecResp = { viewNumber: ViewNumber, state: Option[RecoveryState] }

  /// `Replica` in the Rust, without the timers and the state machine.
  type Replica = {
    id: ReplicaId,
    status: Status,
    viewNumber: ViewNumber,
    lastNormalView: ViewNumber,
    commitNumber: CommitNumber,
    log: Log,
    // For each uncommitted op number, the replicas that acknowledged it.
    acks: OpNumber -> Set[ReplicaId],
    clientTable: int -> ClientEntry,
    startViewChangeFrom: Set[ReplicaId],
    doViewChangeSent: bool,
    doViewChangeFrom: ReplicaId -> Dvc,
    catchingUp: bool,
    recoveryNonce: int,
    recoveryResponses: ReplicaId -> RecResp,
    // Sends go here; the cluster step moves them to `sent`.
    outbox: Set[Envelope],
    // Set where the Rust would have panicked.
    panicked: bool
  }

  pure def newReplica(id: ReplicaId): Replica = {
    id: id,
    status: Normal,
    viewNumber: 0,
    lastNormalView: 0,
    commitNumber: 0,
    log: [],
    acks: Map(),
    clientTable: Map(),
    startViewChangeFrom: Set(),
    doViewChangeSent: false,
    doViewChangeFrom: Map(),
    catchingUp: false,
    recoveryNonce: 0,
    recoveryResponses: Map(),
    outbox: Set(),
    panicked: false
  }

  // ---------------------------------------------------------------------
  // List helpers (total, like Lean's `take` and `drop`)

  pure def take(l: Log, n: int): Log = l.slice(0, min(max(n, 0), l.length()))
  pure def drop(l: Log, n: int): Log = l.slice(min(max(n, 0), l.length()), l.length())
  pure def entryAt(l: Log, i: int): Option[Entry] = if (i >= 0 and i < l.length()) Some(l[i]) else None

  // ---------------------------------------------------------------------
  // The replica

  pure def opNumber(r: Replica): OpNumber = r.log.length()
  pure def primaryId(r: Replica): ReplicaId = primaryOf(r.viewNumber)
  pure def isPrimary(r: Replica): bool = r.id == primaryId(r)
  pure def panic(r: Replica): Replica = { ...r, panicked: true }

  // --- Sending

  pure def send(r: Replica, dst: ReplicaId, m: Message): Replica =
    { ...r, outbox: r.outbox.union(Set({ dst: dst, msg: m })) }

  pure def sendToPrimary(r: Replica, m: Message): Replica = send(r, primaryId(r), m)

  pure def sendToOthers(r: Replica, m: Message): Replica =
    { ...r, outbox: r.outbox.union(REPLICAS.exclude(Set(r.id)).map(dst => { dst: dst, msg: m })) }

  pure def sendGetState(r: Replica, n: OpNumber): Replica =
    sendToPrimary(r, GetState({ replicaId: r.id, viewNumber: r.viewNumber, opNumber: n }))

  pure def sendPrepareOk(r: Replica): Replica =
    sendToPrimary(r, PrepareOk({ viewNumber: r.viewNumber, opNumber: opNumber(r), replicaId: r.id }))

  pure def startViewMessage(r: Replica): Message =
    StartView({ viewNumber: r.viewNumber, log: r.log, opNumber: opNumber(r), commitNumber: r.commitNumber })

  pure def sendStartView(r: Replica, dst: ReplicaId): Replica = send(r, dst, startViewMessage(r))

  pure def sendRecovery(r: Replica): Replica =
    sendToOthers(r, Recovery({ replicaId: r.id, nonce: r.recoveryNonce, viewNumber: r.viewNumber }))

  // --- The log and the client table

  pure def appendToLog(r: Replica, e: Entry): Replica = {
    ...r,
    clientTable: r.clientTable.put(e.clientId, { requestNumber: e.requestNumber, replied: false }),
    log: r.log.append(e)
  }

  /// Rebuilds the client table from `log`, keeping the replies of committed
  /// requests.
  pure def rebuildClientTable(commitNumber: CommitNumber, old: int -> ClientEntry, log: Log): int -> ClientEntry =
    log.foldl((Map(), 0), (acc, e) => {
      val i = acc._2
      val replied =
        i < commitNumber and old.keys().contains(e.clientId)
        and old.get(e.clientId).requestNumber == e.requestNumber and old.get(e.clientId).replied
      (acc._1.put(e.clientId, { requestNumber: e.requestNumber, replied: replied }), i + 1)
    })._1

  pure def installLog(r: Replica, log: Log): Replica =
    if (log.length() < r.commitNumber) panic(r)
    else { ...r, clientTable: rebuildClientTable(r.commitNumber, r.clientTable, log), log: log }

  // --- Committing

  pure def commitOne(r: Replica, e: Entry): Replica = {
    val table =
      if (r.clientTable.keys().contains(e.clientId) and r.clientTable.get(e.clientId).requestNumber == e.requestNumber)
        r.clientTable.set(e.clientId, { requestNumber: e.requestNumber, replied: true })
      else r.clientTable
    { ...r, commitNumber: r.commitNumber + 1, clientTable: table }
  }

  /// `commit_up_to`: commits every entry from the commit number up to `k`,
  /// in order. A missing entry is the Rust panic.
  pure def commitUpTo(r: Replica, k: CommitNumber): Replica = {
    val r1 = r.log.foldl((r, 0), (acc, e) => {
      val i = acc._2
      val r2 = if (i >= acc._1.commitNumber and i < k) commitOne(acc._1, e) else acc._1
      (r2, i + 1)
    })._1
    if (k > r1.log.length()) panic(r1) else r1
  }

  // --- View changes

  pure def clearViewChangeState(r: Replica): Replica =
    { ...r, startViewChangeFrom: Set(), doViewChangeSent: false, doViewChangeFrom: Map() }

  pure def enterNormal(r: Replica): Replica =
    { ...clearViewChangeState(r), status: Normal, lastNormalView: r.viewNumber, catchingUp: false }

  pure def stateTransfer(r: Replica): Replica = sendGetState({ ...r, status: StateTransfer }, opNumber(r))

  pure def catchUpWithView(r: Replica, v: ViewNumber): Replica =
    if (r.viewNumber == v and r.catchingUp) r
    else sendGetState({ ...clearViewChangeState(r), viewNumber: v, status: ViewChange, catchingUp: true }, r.commitNumber)

  /// The key `record_do_view_change` maximises: `(last_normal_view, log.len())`.
  pure def dvcKeyGe(a: Dvc, b: Dvc): bool =
    a.lastNormalView > b.lastNormalView
    or (a.lastNormalView == b.lastNormalView and a.log.length() >= b.log.length())

  /// `Iterator::max_by_key` returns the last of equal maxima, and the
  /// DoViewChange messages are iterated by replica id: so the one with
  /// the greatest key, and among those the one from the greatest id.
  pure def bestDoViewChange(dvcs: ReplicaId -> Dvc): Option[Dvc] = {
    val best = dvcs.keys().fold(None, (acc, i) =>
      match acc {
        | None => Some(i)
        | Some(b) =>
          if (dvcKeyGe(dvcs.get(i), dvcs.get(b)) and (not(dvcKeyGe(dvcs.get(b), dvcs.get(i))) or i > b)) Some(i)
          else Some(b)
      })
    match best {
      | None => None
      | Some(i) => Some(dvcs.get(i))
    }
  }

  pure def addAcksForUncommitted(r: Replica): Replica = {
    ...r,
    acks: r.log.indices().filter(i => i + 1 > r.commitNumber).map(i => i + 1).mapBy(n => Set(r.id))
  }

  pure def recordDoViewChange(r: Replica, sender: ReplicaId, dvc: Dvc): Replica = {
    val r1 = { ...r, doViewChangeFrom: r.doViewChangeFrom.put(sender, dvc) }
    if (r1.doViewChangeFrom.keys().size() < QUORUM) r1
    else match bestDoViewChange(r1.doViewChangeFrom) {
      | None => panic(r1)
      | Some(best) => {
        val k = r1.doViewChangeFrom.keys().fold(0, (acc, i) => max(acc, r1.doViewChangeFrom.get(i).commitNumber))
        val r2 = commitUpTo(installLog(r1, best.log), k)
        val r3 = addAcksForUncommitted({ ...enterNormal(r2), acks: Map() })
        sendToOthers(r3, startViewMessage(r3))
      }
    }
  }

  pure def sendDoViewChange(r: Replica): Replica = {
    val dvc = { lastNormalView: r.lastNormalView, log: r.log, commitNumber: r.commitNumber }
    val p = primaryOf(r.viewNumber)
    if (p == r.id) recordDoViewChange(r, r.id, dvc)
    else send(r, p, DoViewChange({ viewNumber: r.viewNumber, replicaId: r.id, lastNormalView: dvc.lastNormalView,
                                   log: dvc.log, opNumber: dvc.log.length(), commitNumber: dvc.commitNumber }))
  }

  pure def maybeSendDoViewChange(r: Replica): Replica =
    if (r.status != ViewChange or r.catchingUp or r.doViewChangeSent) r
    else if (r.startViewChangeFrom.size() < F) r
    else sendDoViewChange({ ...r, doViewChangeSent: true })

  pure def startViewChange(r: Replica, v: ViewNumber): Replica = {
    val r1 = { ...clearViewChangeState(r), viewNumber: v, status: ViewChange, catchingUp: false }
    maybeSendDoViewChange(sendToOthers(r1, StartViewChange({ viewNumber: v, replicaId: r1.id })))
  }

  // --- Normal operation

  /// `accept_from_primary`: the replica and whether to process the message
  /// as a normal-case message.
  pure def acceptFromPrimary(r: Replica, v: ViewNumber): (Replica, bool) =
    if (v < r.viewNumber) (r, false)
    else if (v > r.viewNumber) (catchUpWithView(r, v), false)
    else match r.status {
      | Normal => (r, not(isPrimary(r)))
      | StateTransfer => (r, false)
      | Recovering => (r, false)
      | ViewChange => (catchUpWithView(r, v), false)
    }

  pure def prepareRequest(r: Replica, c: int, n: int, op: int): Replica = {
    val e = { clientId: c, requestNumber: n, op: op }
    val r1 = appendToLog(r, e)
    val o = opNumber(r1)
    val r2 = { ...r1, acks: r1.acks.put(o, Set(r1.id)) }
    sendToOthers(r2, Prepare({ viewNumber: r2.viewNumber, opNumber: o, entry: e, commitNumber: r2.commitNumber }))
  }

  pure def onRequest(r: Replica, c: int, n: int, op: int): Replica =
    if (not(isPrimary(r)) or r.status != Normal) r
    else if (not(r.clientTable.keys().contains(c))) prepareRequest(r, c, n, op)
    else {
      val e = r.clientTable.get(c)
      if (n < e.requestNumber) r
      // The Rust re-sends the cached reply, if any. Replies are not modelled.
      else if (n == e.requestNumber) r
      else prepareRequest(r, c, n, op)
    }

  pure def onPrepare(r: Replica, v: ViewNumber, n: OpNumber, e: Entry, k: CommitNumber): Replica = {
    val a = acceptFromPrimary(r, v)
    val r1 = a._1
    if (not(a._2)) r1
    else if (n > opNumber(r1) + 1) stateTransfer(r1)
    else {
      val r2 = if (n == opNumber(r1) + 1) appendToLog(r1, e) else r1
      sendPrepareOk(commitUpTo(r2, min(k, opNumber(r2))))
    }
  }

  pure def onPrepareOk(r: Replica, v: ViewNumber, n: OpNumber, sender: ReplicaId): Replica =
    if (v != r.viewNumber or not(isPrimary(r)) or r.status != Normal) r
    else if (n <= r.commitNumber) r
    else if (not(r.acks.keys().contains(n))) r
    else {
      val ackedBy = r.acks.get(n)
      val fresh = not(ackedBy.contains(sender))
      val ackedBy1 = ackedBy.union(Set(sender))
      val r1 = { ...r, acks: r.acks.set(n, ackedBy1) }
      if (not(fresh) or ackedBy1.size() != QUORUM) r1
      else {
        val r2 = commitUpTo(r1, n)
        { ...r2, acks: r2.acks.keys().filter(o => o > n).mapBy(o => r2.acks.get(o)) }
      }
    }

  pure def onCommit(r: Replica, v: ViewNumber, k: CommitNumber): Replica = {
    val a = acceptFromPrimary(r, v)
    if (not(a._2)) a._1
    else if (k > opNumber(a._1)) stateTransfer(a._1)
    else commitUpTo(a._1, k)
  }

  // --- State transfer

  pure def onGetState(r: Replica, sender: ReplicaId, v: ViewNumber, n: OpNumber): Replica =
    if (r.status != Normal or v != r.viewNumber or n > opNumber(r)) r
    else send(r, sender, NewState({ viewNumber: v, log: drop(r.log, n), opNumberStart: n, opNumberEnd: opNumber(r),
                                    commitNumber: r.commitNumber }))

  pure def onNewState(r: Replica, v: ViewNumber, log: Log, s: OpNumber, e: OpNumber, k: CommitNumber): Replica =
    if (v != r.viewNumber) r
    else if (log.length() != e - s) panic(r)
    else match r.status {
      | StateTransfer => {
        val n = opNumber(r)
        if (s > n or e <= n) r
        else {
          val r1 = drop(log, n - s).foldl(r, (acc, entry) => appendToLog(acc, entry))
          if (opNumber(r1) != e) panic(r1)
          else sendPrepareOk({ ...commitUpTo(r1, k), status: Normal })
        }
      }
      | ViewChange =>
        if (not(r.catchingUp)) r
        else if (s != r.commitNumber) r
        else {
          val r1 = installLog(r, take(r.log, s).concat(log))
          if (opNumber(r1) != e) panic(r1)
          else sendPrepareOk(enterNormal(commitUpTo(r1, k)))
        }
      | _ => r
    }

  // --- View change messages

  /// Records that `sender` wants the current view, and sends `DoViewChange`
  /// if that makes `f` of them.
  pure def noteStartViewChange(r: Replica, sender: ReplicaId): Replica =
    maybeSendDoViewChange({ ...r, startViewChangeFrom: r.startViewChangeFrom.union(Set(sender)) })

  pure def onStartViewChange(r: Replica, v: ViewNumber, sender: ReplicaId): Replica =
    if (v < r.viewNumber) r
    else if (v > r.viewNumber) noteStartViewChange(startViewChange(r, v), sender)
    else if (r.status != ViewChange) (if (r.status == Normal and isPrimary(r)) sendStartView(r, sender) else r)
    else noteStartViewChange(r, sender)

  pure def onDoViewChange(r: Replica, v: ViewNumber, sender: ReplicaId, dvc: Dvc): Replica =
    if (v < r.viewNumber or primaryOf(v) != r.id) r
    else if (v > r.viewNumber) recordDoViewChange(startViewChange(r, v), sender, dvc)
    else if (r.status == Normal) sendStartView(r, sender)
    else recordDoViewChange(r, sender, dvc)

  pure def onStartView(r: Replica, v: ViewNumber, log: Log, k: CommitNumber): Replica =
    if (v < r.viewNumber or (v == r.viewNumber and r.status != ViewChange)) r
    else {
      val r1 = commitUpTo(installLog({ ...r, viewNumber: v }, log), k)
      sendPrepareOk({ ...enterNormal(r1), acks: Map() })
    }

  // --- Recovery

  pure def onRecovery(r: Replica, sender: ReplicaId, nonce: int, v: ViewNumber): Replica =
    if (v > r.viewNumber and r.status != Recovering) startViewChange(r, v)
    else if (r.status != Normal) r
    else {
      val st = if (isPrimary(r)) Some({ log: r.log, commitNumber: r.commitNumber }) else None
      send(r, sender, RecoveryResponse({ viewNumber: r.viewNumber, nonce: nonce, replicaId: r.id, state: st }))
    }

  pure def onRecoveryResponse(r: Replica, v: ViewNumber, nonce: int, sender: ReplicaId, st: Option[RecoveryState]): Replica =
    if (r.status != Recovering or nonce != r.recoveryNonce) r
    else {
      val r1 = { ...r, recoveryResponses: r.recoveryResponses.put(sender, { viewNumber: v, state: st }) }
      if (r1.recoveryResponses.keys().size() < QUORUM) r1
      else {
        val latest = r1.recoveryResponses.keys().fold(0, (acc, i) => max(acc, r1.recoveryResponses.get(i).viewNumber))
        if (latest < r1.viewNumber) r1
        else {
          val p = primaryOf(latest)
          if (not(r1.recoveryResponses.keys().contains(p))) r1
          else {
            val resp = r1.recoveryResponses.get(p)
            match resp.state {
              | None => r1
              | Some(s) =>
                if (resp.viewNumber != latest) r1
                else {
                  val r2 = installLog({ ...r1, recoveryResponses: Map(), viewNumber: latest }, s.log)
                  enterNormal(commitUpTo(r2, s.commitNumber))
                }
            }
          }
        }
      }
    }

  /// A replica coming back from a crash with no memory but its view number,
  /// which the owner persisted, and a fresh nonce.
  pure def recoverReplica(id: ReplicaId, v: ViewNumber, nonce: int): Replica =
    sendRecovery({ ...newReplica(id), status: Recovering, viewNumber: v, lastNormalView: v, recoveryNonce: nonce })

  // --- Entry points

  pure def isRecoveryResponse(m: Message): bool =
    match m { | RecoveryResponse(_) => true | _ => false }

  pure def onMessage(r: Replica, m: Message): Replica =
    if (r.status == Recovering and not(isRecoveryResponse(m))) r
    else match m {
      | Request(p) => onRequest(r, p.clientId, p.requestNumber, p.op)
      | Prepare(p) => onPrepare(r, p.viewNumber, p.opNumber, p.entry, p.commitNumber)
      | PrepareOk(p) => onPrepareOk(r, p.viewNumber, p.opNumber, p.replicaId)
      | Commit(p) => onCommit(r, p.viewNumber, p.commitNumber)
      | GetState(p) => onGetState(r, p.replicaId, p.viewNumber, p.opNumber)
      | NewState(p) => onNewState(r, p.viewNumber, p.log, p.opNumberStart, p.opNumberEnd, p.commitNumber)
      | StartViewChange(p) => onStartViewChange(r, p.viewNumber, p.replicaId)
      | DoViewChange(p) =>
        if (p.log.length() != p.opNumber) panic(r)
        else onDoViewChange(r, p.viewNumber, p.replicaId,
                            { lastNormalView: p.lastNormalView, log: p.log, commitNumber: p.commitNumber })
      | StartView(p) =>
        if (p.log.length() != p.opNumber) panic(r)
        else onStartView(r, p.viewNumber, p.log, p.commitNumber)
      | Recovery(p) => onRecovery(r, p.replicaId, p.nonce, p.viewNumber)
      | RecoveryResponse(p) => onRecoveryResponse(r, p.viewNumber, p.nonce, p.replicaId, p.state)
    }

  /// The primary's re-sends of every uncommitted `Prepare`.
  pure def resendPrepares(r: Replica, v: ViewNumber, k: CommitNumber): Replica =
    r.log.foldl((r, 0), (acc, e) => {
      val n = acc._2 + 1
      val r1 = if (n > k) sendToOthers(acc._1, Prepare({ viewNumber: v, opNumber: n, entry: e, commitNumber: k }))
               else acc._1
      (r1, n)
    })._1

  /// An idle period at the replica. `timeout` is the environment's choice
  /// of whether this is the period on which the replica's wait runs out;
  /// the Rust decides it with timers, which count idle periods, and every
  /// sequence of decisions they can make is one the environment can make.
  pure def onIdle(r: Replica, timeout: bool): Replica =
    match r.status {
      | Normal =>
        if (isPrimary(r))
          resendPrepares(sendToOthers(r, Commit({ viewNumber: r.viewNumber, commitNumber: r.commitNumber })),
                         r.viewNumber, r.commitNumber)
        else if (timeout) startViewChange(r, r.viewNumber + 1)
        else r
      | Recovering => sendRecovery(r)
      | StateTransfer => {
        val r1 = stateTransfer(r)
        if (timeout) startViewChange(r1, r1.viewNumber + 1) else r1
      }
      | ViewChange =>
        if (timeout) startViewChange(r, r.viewNumber + 1)
        else if (r.catchingUp) sendGetState(r, r.commitNumber)
        else {
          val r1 = sendToOthers(r, StartViewChange({ viewNumber: r.viewNumber, replicaId: r.id }))
          if (r1.doViewChangeSent) sendDoViewChange(r1) else r1
        }
    }

  // ---------------------------------------------------------------------
  // The cluster

  var replicas: ReplicaId -> Replica
  /// Every message ever sent. Delivery never removes one, so a message can
  /// arrive again, out of order, or never: loss, delay, duplication, and
  /// reordering in one rule.
  var sent: Set[Envelope]
  /// The next fresh recovery nonce.
  var nextNonce: int
  /// Ghost: the first entry ever committed at each index.
  var history: int -> Entry
  /// Ghost: each replica's commit number before its last step.
  var prevCommit: ReplicaId -> CommitNumber

  action init = all {
    replicas' = REPLICAS.mapBy(i => newReplica(i)),
    sent' = Set(),
    nextNonce' = 1,
    history' = Map(),
    prevCommit' = REPLICAS.mapBy(i => 0),
  }

  pure def recordCommits(h: int -> Entry, r: Replica): int -> Entry =
    r.log.foldl((h, 0), (acc, e) => {
      val i = acc._2
      val h1 = if (i < r.commitNumber and not(acc._1.keys().contains(i))) acc._1.put(i, e) else acc._1
      (h1, i + 1)
    })._1

  /// Puts replica `id` back after a step and takes what it wants sent.
  action apply(id: ReplicaId, r1: Replica, nonce: int, prev: CommitNumber): bool = all {
    replicas' = replicas.set(id, { ...r1, outbox: Set() }),
    sent' = sent.union(r1.outbox),
    nextNonce' = nonce,
    history' = recordCommits(history, r1),
    prevCommit' = prevCommit.set(id, prev),
  }

  /// Deliver any message ever sent to its destination.
  action deliver = all {
    sent.size() > 0,
    nondet env = sent.oneOf()
    apply(env.dst, onMessage(replicas.get(env.dst), env.msg), nextNonce, replicas.get(env.dst).commitNumber)
  }

  /// An idle period passes at a replica.
  action idle = {
    nondet id = REPLICAS.oneOf()
    nondet timeout = Set(true, false).oneOf()
    all {
      timeout implies replicas.get(id).viewNumber < MAX_VIEW,
      apply(id, onIdle(replicas.get(id), timeout), nextNonce, replicas.get(id).commitNumber),
    }
  }

  /// A client request arrives at a replica. Clients are not modelled: any
  /// request may arrive anywhere, which covers everything a client does.
  action request = {
    nondet dst = REPLICAS.oneOf()
    nondet c = CLIENTS.oneOf()
    nondet n = 1.to(MAX_REQ).oneOf()
    nondet op = OPS.oneOf()
    apply(dst, onMessage(replicas.get(dst), Request({ clientId: c, requestNumber: n, op: op })), nextNonce,
          replicas.get(dst).commitNumber)
  }

  /// A replica comes back from a crash with nothing but its view number.
  action recover = {
    nondet id = REPLICAS.oneOf()
    apply(id, recoverReplica(id, replicas.get(id).viewNumber, nextNonce), nextNonce + 1, 0)
  }

  action step = any { deliver, idle, request, recover }

  /// A replica crashes only while no other is recovering. A cluster with
  /// two of three replicas recovering never completes a recovery, so this
  /// is what a run has to assume to get anywhere; it is a restriction on
  /// the environment, not on the protocol, and `step` does without it.
  action recoverOne = all {
    REPLICAS.forall(i => replicas.get(i).status != Recovering),
    recover,
  }

  /// `step` weighted for random simulation: deliveries dominate, crashes
  /// are rare, and only one replica is down at a time. Every run of
  /// `stepFair` is a run of `step`.
  action stepFair = any {
    deliver, deliver, deliver, deliver, deliver, deliver,
    idle, idle, idle,
    request, request,
    recoverOne,
  }

  // ---------------------------------------------------------------------
  // Safety, as in `lean/Vsr/Safety.lean` and `simulator/properties.rs`

  def rep(i: ReplicaId): Replica = replicas.get(i)
  def committedPrefix(i: ReplicaId): Log = take(rep(i).log, rep(i).commitNumber)

  /// No Rust `assert!` fires.
  val noPanic = REPLICAS.forall(i => not(rep(i).panicked))

  /// A replica's commit number never exceeds its log length.
  val commitBounded = REPLICAS.forall(i => rep(i).commitNumber <= rep(i).log.length())

  /// A replica's commit number never goes down, except by a crash.
  val commitMonotonic = REPLICAS.forall(i => rep(i).commitNumber >= prevCommit.get(i))

  /// Two replicas that have both committed index `i` hold the same entry.
  val prefixAgreement = REPLICAS.forall(a => REPLICAS.forall(b => {
    val pa = committedPrefix(a)
    val pb = committedPrefix(b)
    pa.indices().forall(i => i < pb.length() implies pa[i] == pb[i])
  }))

  /// Every committed entry is the one first committed at its index: a
  /// committed prefix is never rewritten, even by the whole cluster at once.
  val historyAgreement = REPLICAS.forall(a => {
    val p = committedPrefix(a)
    p.indices().forall(i => history.keys().contains(i) and history.get(i) == p[i])
  })

  /// Every committed entry survives any view change: every quorum the
  /// replicas that are not recovering could form includes one that holds
  /// it at its index. A recovering replica holds nothing and takes part in
  /// no quorum, so it counts on neither side.
  val durability = {
    val participants = REPLICAS.filter(i => rep(i).status != Recovering)
    participants.forall(a => {
      val p = committedPrefix(a)
      p.indices().forall(i =>
        participants.size() + 1 - QUORUM
          <= participants.filter(o => entryAt(rep(o).log, i) == Some(p[i])).size())
    })
  }

  /// No request appears twice in a committed prefix.
  val noDuplicateOps = REPLICAS.forall(a => {
    val p = committedPrefix(a)
    p.indices().forall(i => p.indices().forall(j =>
      i != j implies (p[i].clientId != p[j].clientId or p[i].requestNumber != p[j].requestNumber)))
  })

  val safety = all {
    noPanic,
    commitBounded,
    commitMonotonic,
    prefixAgreement,
    historyAgreement,
    durability,
    noDuplicateOps,
  }

  // ---------------------------------------------------------------------
  // Witnesses: states worth reaching, to show the checks have something to
  // check. `quint run --witnesses=...` counts the runs that reach each.

  val wCommitted = REPLICAS.exists(i => rep(i).commitNumber >= 1)
  val wViewChanged = REPLICAS.exists(i => rep(i).status == Normal and rep(i).viewNumber >= 1)
  val wCommittedAfterViewChange = REPLICAS.exists(i => rep(i).status == Normal and rep(i).viewNumber >= 1
    and rep(i).commitNumber >= 1)
  val wStateTransferred = REPLICAS.exists(i => rep(i).status == StateTransfer)
  val wCaughtUp = REPLICAS.exists(i => rep(i).catchingUp)
  val wRecovered = nextNonce > 1 and REPLICAS.exists(i => rep(i).status == Normal and rep(i).commitNumber >= 1)
    and REPLICAS.forall(i => rep(i).status != Recovering)
}
