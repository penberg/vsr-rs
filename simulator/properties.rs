//! Properties are invariants checked after every tick and at the
//! end of the run.

use crate::state_machine::{Accumulator, Op};
use anyhow::{ensure, Result};
use std::collections::{BTreeMap, BTreeSet};
use vsr_rs::{ClientID, LogEntry, Replica, Reply, RequestNumber};

/// Read-only view of the simulated system handed to properties.
pub struct SimContext<'a> {
    pub tick: u64,
    pub replicas: &'a [Replica<Accumulator>],
    /// Replies the clients have received, in order.
    pub replies: &'a [Reply<i64>],
    /// The replicas that must converge: all of them during the safety
    /// phase, the liveness core afterwards.
    pub core: &'a [usize],
}

pub trait Property {
    fn name(&self) -> &'static str;

    /// Called after every tick.
    fn check(&mut self, ctx: &SimContext) -> Result<()>;

    /// Called once at the end of the run, after the network has been drained
    /// with faults disabled.
    fn finalize(&mut self, _ctx: &SimContext) -> Result<()> {
        Ok(())
    }

    /// Called when a replica comes back from a crash with no memory: an
    /// empty log, view 0, a fresh state machine. Whatever the property
    /// tracked about that replica starts over.
    fn on_reboot(&mut self, _replica_id: usize) {}
}

/// The default property set.
pub fn default_properties() -> Vec<Box<dyn Property>> {
    vec![
        Box::new(CommitNumberMonotonic::default()),
        Box::new(StateMatchesCommittedLog::default()),
        Box::new(CommittedPrefixAgreement::default()),
        Box::new(NoDuplicateOps::default()),
        Box::new(RepliesMatchCommits::default()),
        Box::new(Durability::default()),
        Box::new(Convergence),
    ]
}

/// Every committed op is held by enough replicas to survive any view
/// change: every quorum the replicas that are not recovering could form
/// must include one that holds it. With nobody recovering that is a
/// majority. A recovering replica holds nothing and takes part in no quorum,
/// so it counts on neither side. A primary only commits on a quorum of
/// `PrepareOk` messages, and a backup only acknowledges an op once it is in
/// its log, so this must hold at the tick the commit happens, on whichever
/// replica committed it. Committed prefixes are never truncated, so each
/// committed index needs checking once per replica.
#[derive(Default)]
pub struct Durability {
    /// Per replica: number of committed entries already verified.
    verified: Vec<usize>,
}

impl Property for Durability {
    fn name(&self) -> &'static str {
        "durability"
    }

    fn on_reboot(&mut self, replica_id: usize) {
        if let Some(verified) = self.verified.get_mut(replica_id) {
            *verified = 0;
        }
    }

    fn check(&mut self, ctx: &SimContext) -> Result<()> {
        self.verified.resize(ctx.replicas.len(), 0);
        let quorum = ctx.replicas.len() / 2 + 1;
        let participants = ctx
            .replicas
            .iter()
            .filter(|replica| !replica.is_recovering())
            .count();
        let needed = (participants + 1).saturating_sub(quorum);
        for (id, replica) in ctx.replicas.iter().enumerate() {
            let commit = replica.commit_number();
            let log = replica.log();
            for (i, entry) in log.iter().enumerate().take(commit).skip(self.verified[id]) {
                let copies = ctx
                    .replicas
                    .iter()
                    .filter(|other| !other.is_recovering() && other.log().get(i) == Some(entry))
                    .count();
                ensure!(
                    copies >= needed,
                    "tick {}: replica {id} committed op at index {i} held by {copies} of {participants} replicas not recovering, {needed} needed to meet every quorum of {quorum}",
                    ctx.tick
                );
            }
            self.verified[id] = commit;
        }
        Ok(())
    }
}

/// A replica's commit number never decreases and never exceeds its op number,
/// and its op number always equals its log length.
#[derive(Default)]
pub struct CommitNumberMonotonic {
    last_commit: Vec<usize>,
}

impl Property for CommitNumberMonotonic {
    fn name(&self) -> &'static str {
        "commit-number-monotonic"
    }

    fn on_reboot(&mut self, replica_id: usize) {
        if let Some(last) = self.last_commit.get_mut(replica_id) {
            *last = 0;
        }
    }

    fn check(&mut self, ctx: &SimContext) -> Result<()> {
        self.last_commit.resize(ctx.replicas.len(), 0);
        for (id, replica) in ctx.replicas.iter().enumerate() {
            let commit = replica.commit_number();
            let op = replica.op_number();
            let len = replica.log().len();
            ensure!(
                op == len,
                "tick {}: replica {id} op_number {op} != log length {len}",
                ctx.tick
            );
            ensure!(
                commit <= op,
                "tick {}: replica {id} commit_number {commit} > op_number {op}",
                ctx.tick
            );
            ensure!(
                commit >= self.last_commit[id],
                "tick {}: replica {id} commit_number went backwards: {} -> {commit}",
                ctx.tick,
                self.last_commit[id]
            );
            self.last_commit[id] = commit;
        }
        Ok(())
    }
}

/// A replica's state machine has applied exactly the committed prefix of its
/// log, in order, and its value is the fold of those operations.
#[derive(Default)]
pub struct StateMatchesCommittedLog {
    /// Per replica: (number of committed entries already verified, expected value).
    verified: Vec<(usize, i64)>,
}

impl Property for StateMatchesCommittedLog {
    fn name(&self) -> &'static str {
        "state-matches-committed-log"
    }

    fn on_reboot(&mut self, replica_id: usize) {
        if let Some(verified) = self.verified.get_mut(replica_id) {
            *verified = (0, 0);
        }
    }

    fn check(&mut self, ctx: &SimContext) -> Result<()> {
        self.verified.resize(ctx.replicas.len(), (0, 0));
        for (id, replica) in ctx.replicas.iter().enumerate() {
            let commit = replica.commit_number();
            let log = replica.log();
            let state = replica.state_machine();
            let (verified, value) = &mut self.verified[id];
            ensure!(
                state.applied.len() == commit,
                "tick {}: replica {id} applied {} ops but commit_number is {commit}",
                ctx.tick,
                state.applied.len()
            );
            for (i, entry) in log.iter().enumerate().take(commit).skip(*verified) {
                ensure!(
                    state.applied[i] == entry.op,
                    "tick {}: replica {id} applied {:?} at index {i} but log has {:?}",
                    ctx.tick,
                    state.applied[i],
                    entry.op
                );
                *value = entry.op.kind.apply(*value);
            }
            *verified = commit;
            ensure!(
                state.value == *value,
                "tick {}: replica {id} value {} != expected {value}",
                ctx.tick,
                state.value
            );
        }
        Ok(())
    }
}

/// All replicas agree on the committed prefix of the log: if two replicas
/// have both committed index `i`, they hold the same operation there.
#[derive(Default)]
pub struct CommittedPrefixAgreement {
    /// The union of all committed prefixes seen so far.
    canonical: Vec<LogEntry<Op>>,
    /// Per replica: number of committed entries already verified.
    verified: Vec<usize>,
}

impl Property for CommittedPrefixAgreement {
    fn name(&self) -> &'static str {
        "committed-prefix-agreement"
    }

    fn on_reboot(&mut self, replica_id: usize) {
        if let Some(verified) = self.verified.get_mut(replica_id) {
            *verified = 0;
        }
    }

    fn check(&mut self, ctx: &SimContext) -> Result<()> {
        self.verified.resize(ctx.replicas.len(), 0);
        for (id, replica) in ctx.replicas.iter().enumerate() {
            let commit = replica.commit_number();
            let log = replica.log();
            for (i, entry) in log.iter().enumerate().take(commit).skip(self.verified[id]) {
                if let Some(canonical) = self.canonical.get(i) {
                    ensure!(
                        *canonical == *entry,
                        "tick {}: replica {id} committed {entry:?} at index {i} but another replica committed {canonical:?}",
                        ctx.tick
                    );
                } else {
                    self.canonical.push(entry.clone());
                }
            }
            self.verified[id] = commit;
        }
        Ok(())
    }
}

/// No operation appears twice in any replica's committed log. Entries
/// beyond the commit number can be replaced by a view change, so only the
/// committed prefix, which is append-only, is checked.
#[derive(Default)]
pub struct NoDuplicateOps {
    /// Per replica: (committed entries already verified, IDs seen).
    seen: Vec<(usize, BTreeSet<u64>)>,
}

impl Property for NoDuplicateOps {
    fn name(&self) -> &'static str {
        "no-duplicate-ops"
    }

    fn on_reboot(&mut self, replica_id: usize) {
        if let Some(seen) = self.seen.get_mut(replica_id) {
            *seen = (0, BTreeSet::new());
        }
    }

    fn check(&mut self, ctx: &SimContext) -> Result<()> {
        self.seen
            .resize_with(ctx.replicas.len(), || (0, BTreeSet::new()));
        for (id, replica) in ctx.replicas.iter().enumerate() {
            let commit = replica.commit_number();
            let log = replica.log();
            let (verified, seen) = &mut self.seen[id];
            for (i, entry) in log[..commit].iter().enumerate().skip(*verified) {
                ensure!(
                    seen.insert(entry.op.id),
                    "tick {}: replica {id} committed duplicate op {:?} at index {i}",
                    ctx.tick,
                    entry.op
                );
            }
            *verified = commit;
        }
        Ok(())
    }
}

/// Every reply is for a request that has committed, and carries the
/// accumulator value right after that request's op. Replies may be
/// duplicated, since the primary answers a re-sent request from its client
/// table, but every committed request gets at least one reply by the end.
///
/// Committed prefixes agree across replicas, so the expected results come
/// from whichever replica has committed furthest.
#[derive(Default)]
pub struct RepliesMatchCommits {
    /// Expected result per committed request.
    expected: BTreeMap<(ClientID, RequestNumber), i64>,
    /// Requests that have received a reply.
    replied: BTreeSet<(ClientID, RequestNumber)>,
    /// Committed entries and replies already processed.
    committed: usize,
    verified: usize,
    value: i64,
}

impl Property for RepliesMatchCommits {
    fn name(&self) -> &'static str {
        "replies-match-commits"
    }

    fn check(&mut self, ctx: &SimContext) -> Result<()> {
        let furthest = ctx
            .replicas
            .iter()
            .max_by_key(|replica| replica.commit_number())
            .unwrap();
        // Every replica that had committed further may have rebooted since,
        // in which case there is nothing new to learn until one catches up.
        let commit = furthest.commit_number();
        if commit > self.committed {
            let log = furthest.log();
            for entry in &log[self.committed..commit] {
                self.value = entry.op.kind.apply(self.value);
                self.expected
                    .insert((entry.client_id, entry.request_number), self.value);
            }
            self.committed = commit;
        }
        for reply in &ctx.replies[self.verified..] {
            let key = (reply.client_id, reply.request_number);
            let Some(expected) = self.expected.get(&key) else {
                anyhow::bail!(
                    "tick {}: reply {reply:?} for a request that has not committed",
                    ctx.tick
                );
            };
            ensure!(
                reply.result == *expected,
                "tick {}: reply {reply:?} but expected result {expected}",
                ctx.tick
            );
            self.replied.insert(key);
        }
        self.verified = ctx.replies.len();
        Ok(())
    }

    fn finalize(&mut self, _ctx: &SimContext) -> Result<()> {
        for key in self.expected.keys() {
            ensure!(
                self.replied.contains(key),
                "client {} got no reply for request {}",
                key.0,
                key.1
            );
        }
        Ok(())
    }
}

/// Once the network is drained, every core replica has the same log, has
/// committed all of it, and holds the same state machine value.
pub struct Convergence;

impl Property for Convergence {
    fn name(&self) -> &'static str {
        "convergence"
    }

    fn check(&mut self, _ctx: &SimContext) -> Result<()> {
        Ok(())
    }

    fn finalize(&mut self, ctx: &SimContext) -> Result<()> {
        let reference_id = ctx.core[0];
        let reference_log = ctx.replicas[reference_id].log();
        let reference_value = ctx.replicas[reference_id].state_machine().value;
        for &id in ctx.core {
            let replica = &ctx.replicas[id];
            let log = replica.log();
            ensure!(
                log.len() == reference_log.len(),
                "replica {id} log length {} != replica {reference_id} log length {}",
                log.len(),
                reference_log.len()
            );
            ensure!(
                *log == *reference_log,
                "replica {id} log differs from replica {reference_id} log"
            );
            ensure!(
                replica.commit_number() == log.len(),
                "replica {id} committed {} of {} log entries",
                replica.commit_number(),
                log.len()
            );
            let value = replica.state_machine().value;
            ensure!(
                value == reference_value,
                "replica {id} value {value} != replica {reference_id} value {reference_value}"
            );
        }
        Ok(())
    }
}
