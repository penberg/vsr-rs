//! Deterministic simulator for vsr-rs.
//!
//! The simulator runs a cluster of replicas and a set of clients in a single
//! thread. Every tick it lets clients submit requests, moves messages through
//! a simulated network that can lose, replay, and delay them, and checks a
//! set of properties. Given the same seed, a run is fully reproducible.
//!
//! The seed determines the entire configuration: cluster size, request rate,
//! idle periods, and network faults are all drawn from the seed's PRNG, so a
//! large number of seeds covers a large number of configurations.
//!
//! A run has two phases:
//!
//! 1. Safety: faults are active and clients submit `requests_max` requests.
//!    The phase ends when every request has been replied to, or when no reply
//!    arrives for `ticks_max_requests` ticks.
//! 2. Liveness: faults are disabled and the cluster must converge, i.e. every
//!    replica must end up with the same fully committed log, within
//!    `ticks_max_convergence` ticks.

pub mod network;
pub mod properties;
pub mod state_machine;
pub mod workload;

use anyhow::{bail, ensure, Context, Result};
use log::{debug, info, trace};
use rand::{Rng, SeedableRng};
use rand_chacha::ChaCha8Rng;
use std::fmt;
use vsr_rs::{Client, Config, Replica, Reply, RequestNumber};

use network::Network;
pub use network::{message_kind, Envelope, MessageSummary, NetworkOptions, Origin};
use std::collections::BTreeSet;
use std::str::FromStr;
use vsr_rs::{Status, ViewNumber};

/// A fault injected by hand, at a given tick, on top of the random ones.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Fault {
    /// Crash a replica; it keeps its state, as if paused.
    Crash(usize),
    /// Bring a crashed replica back with its state.
    Restart(usize),
    /// Bring a crashed replica back with no memory, through recovery.
    Reboot(usize),
    /// Cut a replica off from every other replica and client.
    Partition(usize),
    /// Reconnect a partitioned replica.
    Heal(usize),
    /// Reconnect every partitioned replica.
    HealAll,
}

impl fmt::Display for Fault {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Fault::Crash(id) => write!(f, "crash {id}"),
            Fault::Restart(id) => write!(f, "restart {id}"),
            Fault::Reboot(id) => write!(f, "reboot {id}"),
            Fault::Partition(id) => write!(f, "partition {id}"),
            Fault::Heal(id) => write!(f, "heal {id}"),
            Fault::HealAll => write!(f, "heal-all"),
        }
    }
}

impl FromStr for Fault {
    type Err = String;

    fn from_str(s: &str) -> std::result::Result<Fault, String> {
        let mut words = s.split_whitespace();
        let name = words.next().ok_or("empty fault")?;
        let id = |words: &mut std::str::SplitWhitespace| -> std::result::Result<usize, String> {
            words
                .next()
                .ok_or_else(|| format!("{name} needs a replica id"))?
                .parse()
                .map_err(|_| format!("{name}: bad replica id"))
        };
        match name {
            "crash" => Ok(Fault::Crash(id(&mut words)?)),
            "restart" => Ok(Fault::Restart(id(&mut words)?)),
            "reboot" => Ok(Fault::Reboot(id(&mut words)?)),
            "partition" => Ok(Fault::Partition(id(&mut words)?)),
            "heal" => Ok(Fault::Heal(id(&mut words)?)),
            "heal-all" => Ok(Fault::HealAll),
            _ => Err(format!("unknown fault {name:?}")),
        }
    }
}

/// A fault script: what to inject, and at which tick.
pub type FaultScript = Vec<(u64, Fault)>;

/// Parses a script with one `TICK FAULT` per line, `#` starting a comment.
pub fn parse_script(text: &str) -> std::result::Result<FaultScript, String> {
    let mut script = Vec::new();
    for (number, line) in text.lines().enumerate() {
        let line = line.split('#').next().unwrap().trim();
        if line.is_empty() {
            continue;
        }
        let (tick, fault) = line
            .split_once(char::is_whitespace)
            .ok_or_else(|| format!("line {}: expected TICK FAULT", number + 1))?;
        let tick = tick
            .parse()
            .map_err(|_| format!("line {}: bad tick {tick:?}", number + 1))?;
        script.push((tick, fault.trim().parse()?));
    }
    script.sort_by_key(|(tick, _)| *tick);
    Ok(script)
}

/// The phase a run is in. See [`Simulator::step_run`].
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Phase {
    /// Faults are active and the clients are working through their requests.
    Safety,
    /// Faults are off and the core has to converge.
    Liveness,
    /// The run passed.
    Done,
}

/// A replica as seen from outside, for display.
#[derive(Clone, Debug)]
pub struct ReplicaSnapshot {
    pub id: usize,
    pub up: bool,
    pub partitioned: bool,
    pub in_core: bool,
    pub status: Status,
    pub is_primary: bool,
    pub view_number: ViewNumber,
    pub op_number: usize,
    pub commit_number: usize,
    pub value: i64,
}

/// A client as seen from outside, for display.
#[derive(Clone, Debug)]
pub struct ClientSnapshot {
    pub id: usize,
    pub view_number: ViewNumber,
    pub inflight: Option<RequestNumber>,
}

/// The whole simulation as seen from outside, for display.
#[derive(Clone, Debug)]
pub struct Snapshot {
    pub tick: u64,
    pub phase: Phase,
    pub replicas: Vec<ReplicaSnapshot>,
    pub clients: Vec<ClientSnapshot>,
    pub messages: Vec<Envelope>,
    pub requests_sent: usize,
    pub requests_replied: usize,
    pub requests_max: usize,
    pub crashes: usize,
    pub restarts: usize,
    pub reboots: usize,
    pub network: MessageSummary,
}
use properties::{Property, SimContext};
use state_machine::{Accumulator, Op};
use workload::Workload;

/// Simulation options. Use [`Options::swarm`] to draw them from a PRNG.
#[derive(Clone, Debug)]
pub struct Options {
    pub replica_count: usize,
    /// Number of clients. Each client has at most one request in flight.
    pub client_count: usize,
    pub network: NetworkOptions,
    /// Total number of requests to send.
    pub requests_max: usize,
    /// Probability per tick that a client with no request in flight sends one.
    pub request_probability: f64,
    /// Probability per tick that clients go idle.
    pub request_idle_on_probability: f64,
    /// Probability per tick that idle clients resume.
    pub request_idle_off_probability: f64,
    /// Ticks between two runs of the replicas' idle logic, which is what makes
    /// the primary send `Commit` heartbeats.
    pub heartbeat_interval: u64,
    /// Probability per tick that a running replica crashes. A crashed
    /// replica neither receives nor sends messages and does not run its
    /// idle logic, but keeps its state.
    pub replica_crash_probability: f64,
    /// Ticks a crashed replica stays down before it may restart.
    pub replica_crash_stability: u64,
    /// Probability per tick that a crashed replica restarts.
    pub replica_restart_probability: f64,
    /// Ticks a restarted replica stays up before it may crash again.
    pub replica_restart_stability: u64,
    /// Probability per restart that the replica comes back with nothing:
    /// an empty log, view 0, no memory of what it acknowledged. Otherwise
    /// a restart resumes the replica with its state intact, as if it had
    /// only been paused.
    pub replica_reboot_probability: f64,
    /// Keep every replica in the liveness core instead of a random
    /// majority, so no replica is crashed for good at the transition.
    pub full_core: bool,
    /// Idle periods a backup waits without hearing from the primary before
    /// it starts a view change.
    pub primary_timeout: usize,
}

impl Options {
    /// Draws a random configuration from `prng`.
    pub fn swarm(prng: &mut ChaCha8Rng) -> Options {
        let one_way_delay_min = prng.gen_range(0..=2);
        let one_way_delay_mean: u64 = prng.gen_range(one_way_delay_min..=10);
        let heartbeat_interval: u64 = prng.gen_range(1..=50);
        // Heartbeats are delayed at random, so a timeout much shorter than
        // the typical delay makes every idle period look like a dead
        // primary. Allow a few times the mean delay before suspecting it,
        // which still leaves room for the occasional spurious view change.
        let primary_timeout = prng
            .gen_range(2..=10)
            .max((5 * one_way_delay_mean).div_ceil(heartbeat_interval) as usize);
        Options {
            replica_count: prng.gen_range(3..=7),
            client_count: prng.gen_range(1..=8),
            network: NetworkOptions {
                packet_loss_probability: f64::from(prng.gen_range(0..=30)) / 100.0,
                packet_replay_probability: f64::from(prng.gen_range(0..=50)) / 100.0,
                one_way_delay_min,
                one_way_delay_mean,
                fault_client_messages: prng.gen_bool(0.5),
            },
            requests_max: 10_000,
            request_probability: f64::from(prng.gen_range(1..=100)) / 100.0,
            request_idle_on_probability: f64::from(prng.gen_range(0..=20)) / 100.0,
            request_idle_off_probability: f64::from(prng.gen_range(10..=20)) / 100.0,
            heartbeat_interval,
            replica_crash_probability: f64::from(prng.gen_range(0..=20)) / 100_000.0,
            replica_crash_stability: prng.gen_range(0..=1_000),
            replica_restart_probability: f64::from(prng.gen_range(1..=10)) / 1_000.0,
            replica_restart_stability: prng.gen_range(0..=1_000),
            replica_reboot_probability: f64::from(prng.gen_range(0..=100)) / 100.0,
            full_core: false,
            primary_timeout,
        }
    }

    /// A small cluster, for quick runs.
    pub fn lite(prng: &mut ChaCha8Rng) -> Options {
        let mut options = Options::swarm(prng);
        options.replica_count = 3;
        options.requests_max = 1_000;
        options
    }

    pub fn validate(&self) -> Result<()> {
        ensure!(self.replica_count >= 1, "replica_count must be at least 1");
        ensure!(self.client_count >= 1, "client_count must be at least 1");
        ensure!(self.requests_max >= 1, "requests_max must be at least 1");
        ensure!(
            self.heartbeat_interval >= 1,
            "heartbeat_interval must be at least 1"
        );
        ensure!(
            self.primary_timeout >= 1,
            "primary_timeout must be at least 1"
        );
        for (name, p) in [
            ("request_probability", self.request_probability),
            (
                "request_idle_on_probability",
                self.request_idle_on_probability,
            ),
            (
                "request_idle_off_probability",
                self.request_idle_off_probability,
            ),
            ("replica_crash_probability", self.replica_crash_probability),
            (
                "replica_reboot_probability",
                self.replica_reboot_probability,
            ),
            (
                "replica_restart_probability",
                self.replica_restart_probability,
            ),
        ] {
            ensure!(
                (0.0..=1.0).contains(&p),
                "{name} must be in 0.0..=1.0, got {p}"
            );
        }
        ensure!(
            self.request_probability > 0.0,
            "request_probability must be positive"
        );
        ensure!(
            self.request_idle_off_probability > 0.0,
            "request_idle_off_probability must be positive"
        );
        ensure!(
            self.replica_crash_probability == 0.0 || self.replica_restart_probability > 0.0,
            "replica_restart_probability must be positive if replicas can crash"
        );
        self.network.validate()
    }
}

impl fmt::Display for Options {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        writeln!(f, "          replicas={}", self.replica_count)?;
        writeln!(f, "          clients={}", self.client_count)?;
        writeln!(f, "          requests_max={}", self.requests_max)?;
        writeln!(
            f,
            "          request_probability={}",
            self.request_probability
        )?;
        writeln!(
            f,
            "          idle_on_probability={}",
            self.request_idle_on_probability
        )?;
        writeln!(
            f,
            "          idle_off_probability={}",
            self.request_idle_off_probability
        )?;
        writeln!(
            f,
            "          heartbeat_interval={} ticks",
            self.heartbeat_interval
        )?;
        writeln!(
            f,
            "          one_way_delay_min={} ticks",
            self.network.one_way_delay_min
        )?;
        writeln!(
            f,
            "          one_way_delay_mean={} ticks",
            self.network.one_way_delay_mean
        )?;
        writeln!(
            f,
            "          packet_loss_probability={}",
            self.network.packet_loss_probability
        )?;
        writeln!(
            f,
            "          packet_replay_probability={}",
            self.network.packet_replay_probability
        )?;
        writeln!(
            f,
            "          fault_client_messages={}",
            self.network.fault_client_messages
        )?;
        writeln!(
            f,
            "          replica_crash_probability={}",
            self.replica_crash_probability
        )?;
        writeln!(
            f,
            "          replica_crash_stability={} ticks",
            self.replica_crash_stability
        )?;
        writeln!(
            f,
            "          replica_restart_probability={}",
            self.replica_restart_probability
        )?;
        writeln!(
            f,
            "          replica_restart_stability={} ticks",
            self.replica_restart_stability
        )?;
        writeln!(
            f,
            "          replica_reboot_probability={}",
            self.replica_reboot_probability
        )?;
        writeln!(f, "          full_core={}", self.full_core)?;
        write!(
            f,
            "          primary_timeout={} idle periods",
            self.primary_timeout
        )
    }
}

/// Tick budgets for the two phases of a run.
#[derive(Clone, Copy, Debug)]
pub struct Limits {
    /// Ticks without a reply before the safety phase gives up.
    pub ticks_max_requests: u64,
    /// Ticks the liveness phase may take to converge.
    pub ticks_max_convergence: u64,
}

impl Default for Limits {
    fn default() -> Limits {
        Limits {
            ticks_max_requests: 1_000_000,
            ticks_max_convergence: 1_000_000,
        }
    }
}

pub struct Simulator {
    pub seed: u64,
    pub options: Options,
    pub prng: ChaCha8Rng,
    /// Ticks elapsed.
    pub ticks: u64,
    pub requests_sent: usize,
    pub requests_replied: usize,
    requests_idle: bool,
    liveness_mode: bool,
    phase: Phase,
    /// Ticks since the last reply, in the safety phase.
    ticks_since_reply: u64,
    /// Ticks spent in the liveness phase.
    liveness_ticks: u64,
    /// Whether every request was replied to before the liveness phase.
    requests_done: bool,
    /// Replicas cut off from the network by an injected fault.
    partitioned: BTreeSet<usize>,
    /// Number of replica crashes and restarts so far.
    pub crashes: usize,
    pub restarts: usize,
    /// Number of restarts that lost the replica's memory.
    pub reboots: usize,
    config: Config,
    /// The view number each replica has persisted, which is the one thing
    /// that survives a reboot. Written before a replica's messages are
    /// sent, as the library requires.
    durable_view: Vec<vsr_rs::ViewNumber>,
    /// Whether each replica is up.
    replica_up: Vec<bool>,
    /// The tick before which each replica's health must not change again.
    replica_stable_until: Vec<u64>,
    /// The replicas that must converge: every replica during the safety
    /// phase, and a majority that is kept up during the liveness phase.
    core: Vec<usize>,
    replicas: Vec<Replica<Accumulator>>,
    clients: Vec<Client<Op>>,
    /// The request number each client is waiting for a reply to, if any.
    client_inflight: Vec<Option<RequestNumber>>,
    /// Replies received, in order.
    replies: Vec<Reply<i64>>,
    network: Network,
    workload: Workload,
    properties: Vec<Box<dyn Property>>,
    next_op_id: u64,
}

impl Simulator {
    pub fn init(seed: u64, options: Options) -> Result<Simulator> {
        options.validate()?;
        let prng = ChaCha8Rng::seed_from_u64(seed);

        let mut config = Config::new();
        for _ in 0..options.replica_count {
            config.add_replica();
        }
        config.set_primary_timeout(options.primary_timeout);
        let replicas = (0..options.replica_count)
            .map(|id| Replica::new(id, config.clone(), Accumulator::default()))
            .collect();
        let clients = (0..options.client_count)
            .map(|client_id| Client::new(client_id, config.clone()))
            .collect();

        let replica_count = options.replica_count;
        Ok(Simulator {
            seed,
            network: Network::new(options.network.clone()),
            client_inflight: vec![None; options.client_count],
            core: (0..replica_count).collect(),
            replica_up: vec![true; replica_count],
            replica_stable_until: vec![0; replica_count],
            options,
            prng,
            ticks: 0,
            requests_sent: 0,
            requests_replied: 0,
            requests_idle: false,
            liveness_mode: false,
            phase: Phase::Safety,
            ticks_since_reply: 0,
            liveness_ticks: 0,
            requests_done: false,
            partitioned: BTreeSet::new(),
            crashes: 0,
            restarts: 0,
            reboots: 0,
            config,
            durable_view: vec![0; replica_count],
            replicas,
            clients,
            replies: Vec::new(),
            workload: Workload,
            properties: properties::default_properties(),
            next_op_id: 0,
        })
    }

    /// Replaces the default property set.
    pub fn set_properties(&mut self, properties: Vec<Box<dyn Property>>) {
        self.properties = properties;
    }

    pub fn replicas(&self) -> &[Replica<Accumulator>] {
        &self.replicas
    }

    pub fn message_summary(&self) -> &MessageSummary {
        &self.network.summary
    }

    /// Whether replica `id` is up.
    pub fn is_up(&self, id: usize) -> bool {
        self.replica_up[id]
    }

    /// The replicas that must converge in the liveness phase.
    pub fn core(&self) -> &[usize] {
        &self.core
    }

    /// Runs both phases with the given tick budgets.
    pub fn run(&mut self, limits: Limits) -> Result<()> {
        self.run_script(&[], limits)
    }

    /// Runs both phases, injecting the script's faults at their ticks.
    pub fn run_script(&mut self, script: &[(u64, Fault)], limits: Limits) -> Result<()> {
        let mut next = 0;
        while self.phase != Phase::Done {
            while next < script.len() && script[next].0 <= self.ticks {
                self.apply(script[next].1);
                next += 1;
            }
            self.step_run(limits)?;
        }
        Ok(())
    }

    /// Runs one tick of the two-phase run: the safety phase until every
    /// request is replied to or none has been for `ticks_max_requests`
    /// ticks, then the liveness phase until the core converges. Returns the
    /// phase the run is in afterwards, and an error when it has failed.
    pub fn step_run(&mut self, limits: Limits) -> Result<Phase> {
        match self.phase {
            Phase::Safety => {
                let replied_before = self.requests_replied;
                self.tick()?;
                self.ticks_since_reply += 1;
                if self.requests_replied > replied_before {
                    self.ticks_since_reply = 0;
                }
                let done = self.requests_replied == self.options.requests_max;
                if done || self.ticks_since_reply >= limits.ticks_max_requests {
                    self.requests_done = done;
                    if !done {
                        info!(
                            "safety phase ran out of ticks: {} of {} requests replied",
                            self.requests_replied, self.options.requests_max
                        );
                    }
                    self.transition_to_liveness_mode();
                    self.phase = Phase::Liveness;
                }
            }
            Phase::Liveness => {
                if self.liveness_ticks >= limits.ticks_max_convergence {
                    let reason = self.pending()?.unwrap_or("nothing");
                    bail!("no state convergence: {reason}");
                }
                self.tick()?;
                self.liveness_ticks += 1;
                if self.pending()?.is_none() {
                    if !self.requests_done {
                        bail!(
                            "no liveness: only {} of {} requests were replied to",
                            self.requests_replied,
                            self.options.requests_max
                        );
                    }
                    self.phase = Phase::Done;
                }
            }
            Phase::Done => {}
        }
        Ok(self.phase)
    }

    pub fn phase(&self) -> Phase {
        self.phase
    }

    /// Injects a fault now.
    pub fn apply(&mut self, fault: Fault) {
        debug!("tick {}: inject {fault}", self.ticks);
        match fault {
            Fault::Crash(id) => {
                if self.replica_up[id] {
                    self.replica_up[id] = false;
                    self.crashes += 1;
                }
            }
            Fault::Restart(id) => {
                if !self.replica_up[id] {
                    self.replica_up[id] = true;
                    self.restarts += 1;
                }
            }
            Fault::Reboot(id) => {
                self.reboot_replica(id);
                self.replica_up[id] = true;
                self.restarts += 1;
            }
            Fault::Partition(id) => {
                self.partitioned.insert(id);
            }
            Fault::Heal(id) => {
                self.partitioned.remove(&id);
            }
            Fault::HealAll => self.partitioned.clear(),
        }
        // The replica's own crash timer starts over.
        if let Fault::Crash(id) | Fault::Restart(id) | Fault::Reboot(id) = fault {
            self.replica_stable_until[id] = self.ticks;
        }
    }

    /// Replaces the network fault options, for example to turn faults off.
    pub fn set_network_options(&mut self, options: NetworkOptions) {
        self.network.set_options(options);
    }

    /// Whether a replica is cut off by an injected partition.
    pub fn is_partitioned(&self, id: usize) -> bool {
        self.partitioned.contains(&id)
    }

    /// The state of everything, for display.
    pub fn snapshot(&self) -> Snapshot {
        Snapshot {
            tick: self.ticks,
            phase: self.phase,
            replicas: self
                .replicas
                .iter()
                .enumerate()
                .map(|(id, replica)| ReplicaSnapshot {
                    id,
                    up: self.replica_up[id],
                    partitioned: self.partitioned.contains(&id),
                    in_core: self.core.contains(&id),
                    status: replica.status(),
                    is_primary: replica.is_primary(),
                    view_number: replica.view_number(),
                    op_number: replica.op_number(),
                    commit_number: replica.commit_number(),
                    value: replica.state_machine().value,
                })
                .collect(),
            clients: self
                .clients
                .iter()
                .enumerate()
                .map(|(id, client)| ClientSnapshot {
                    id,
                    view_number: client.view_number(),
                    inflight: self.client_inflight[id],
                })
                .collect(),
            messages: self.network.in_flight().cloned().collect(),
            requests_sent: self.requests_sent,
            requests_replied: self.requests_replied,
            requests_max: self.options.requests_max,
            crashes: self.crashes,
            restarts: self.restarts,
            reboots: self.reboots,
            network: self.network.summary.clone(),
        }
    }

    /// Replaces a replica with one that lost its memory and is recovering.
    fn reboot_replica(&mut self, id: usize) {
        debug!("tick {}: replica {id} reboots with no memory", self.ticks);
        let nonce = self.prng.gen::<u64>();
        self.replicas[id] = Replica::recover(
            id,
            self.config.clone(),
            Accumulator::default(),
            self.durable_view[id],
            nonce,
        );
        for property in &mut self.properties {
            property.on_reboot(id);
        }
        self.reboots += 1;
    }

    /// Advances the simulation by one tick.
    pub fn tick(&mut self) -> Result<()> {
        trace!("tick={}", self.ticks);
        self.tick_requests();
        self.tick_crash();
        self.tick_heartbeat();
        self.tick_network();
        self.check_properties()?;
        self.ticks += 1;
        Ok(())
    }

    /// Disables network faults and picks a core, a random majority of the
    /// replicas, that is brought up and kept up so the cluster can
    /// converge. Replicas outside the core are crashed for good: the
    /// protocol promises liveness as long as a majority is up, so the core
    /// must get there on its own. Messages already in flight are still
    /// delivered at their scheduled tick.
    pub fn transition_to_liveness_mode(&mut self) {
        self.liveness_mode = true;
        self.network.set_options(NetworkOptions::perfect());
        self.partitioned.clear();
        let replica_count = self.options.replica_count;
        let quorum = replica_count / 2 + 1;
        let core_size = if self.options.full_core {
            replica_count
        } else {
            self.prng.gen_range(quorum..=replica_count)
        };
        // A recovering replica cannot answer anyone until it has recovered
        // itself, and it needs a quorum of answers for that. The protocol
        // tolerates f failures and a recovering replica is one, so the core
        // must hold a quorum of replicas that are not recovering: draw
        // those first, then fill up at random.
        let mut candidates: Vec<usize> = (0..replica_count).collect();
        for i in (1..replica_count).rev() {
            let j = self.prng.gen_range(0..=i);
            candidates.swap(i, j);
        }
        let (mut core, recovering): (Vec<usize>, Vec<usize>) = candidates
            .into_iter()
            .partition(|&id| !self.replicas[id].is_recovering());
        assert!(core.len() >= quorum);
        // The first quorum of healthy replicas is in. The remaining slots
        // are filled from the other healthy ones and the recovering ones
        // alike, in random order.
        let mut filler: Vec<usize> = core.split_off(quorum);
        filler.extend(recovering);
        for i in (1..filler.len()).rev() {
            let j = self.prng.gen_range(0..=i);
            filler.swap(i, j);
        }
        core.extend(filler);
        core.truncate(core_size);
        core.sort_unstable();
        for id in 0..replica_count {
            let in_core = core.contains(&id);
            if in_core && !self.replica_up[id] {
                self.replica_up[id] = true;
                self.restarts += 1;
            } else if !in_core && self.replica_up[id] {
                self.replica_up[id] = false;
                self.crashes += 1;
            }
        }
        debug!(
            "tick {}: transition to liveness mode, core={core:?}",
            self.ticks
        );
        self.core = core;
    }

    /// Returns why the cluster has not converged yet, or `None` once every
    /// replica holds the same fully committed log and all final property
    /// checks pass.
    pub fn pending(&mut self) -> Result<Option<&'static str>> {
        if self.requests_sent > self.requests_replied {
            return Ok(Some("pending request"));
        }
        if self.network.pending() > 0 {
            return Ok(Some("pending message"));
        }
        let reference_op_number = self.replicas[self.core[0]].op_number();
        for &id in &self.core {
            let replica = &self.replicas[id];
            if replica.op_number() != reference_op_number {
                return Ok(Some("pending replica convergence"));
            }
            if replica.commit_number() != replica.op_number() {
                return Ok(Some("pending commit"));
            }
        }
        let ctx = Self::context(self.ticks, &self.replicas, &self.replies, &self.core);
        for property in &mut self.properties {
            property
                .finalize(&ctx)
                .with_context(|| format!("property '{}' failed", property.name()))?;
        }
        Ok(None)
    }

    fn tick_requests(&mut self) {
        if self.requests_idle {
            if self
                .prng
                .gen_bool(self.options.request_idle_off_probability)
            {
                self.requests_idle = false;
            }
        } else if self.prng.gen_bool(self.options.request_idle_on_probability) {
            self.requests_idle = true;
        }
        if self.requests_idle || self.liveness_mode {
            return;
        }
        if self.requests_sent == self.options.requests_max {
            return;
        }
        if !self.prng.gen_bool(self.options.request_probability) {
            return;
        }
        let client_count = self.options.client_count;
        let base = self.prng.gen_range(0..client_count);
        let Some(client_index) = (0..client_count)
            .map(|offset| (base + offset) % client_count)
            .find(|index| self.client_inflight[*index].is_none())
        else {
            return; // Every client is waiting for a reply.
        };
        let op = Op {
            id: self.next_op_id,
            kind: self.workload.build_request(&mut self.prng),
        };
        self.next_op_id += 1;
        debug!("tick {}: client {client_index} sends {op:?}", self.ticks);
        let request_number = self.clients[client_index].on_request(op);
        self.client_inflight[client_index] = Some(request_number);
        self.requests_sent += 1;
    }

    /// Crashes and restarts replicas. In the liveness phase the core is
    /// kept up and the rest is left as it is.
    fn tick_crash(&mut self) {
        if self.liveness_mode {
            return;
        }
        for id in 0..self.replicas.len() {
            if self.ticks < self.replica_stable_until[id] {
                continue;
            }
            if self.replica_up[id] {
                if self.prng.gen_bool(self.options.replica_crash_probability) {
                    debug!("tick {}: replica {id} crashes", self.ticks);
                    self.replica_up[id] = false;
                    self.replica_stable_until[id] =
                        self.ticks + self.options.replica_crash_stability;
                    self.crashes += 1;
                }
            } else if self.prng.gen_bool(self.options.replica_restart_probability) {
                // The protocol tolerates f failed replicas, and one that lost
                // its memory counts as failed until it has recovered, so
                // reboot only while fewer than f are still recovering.
                let recovering = self
                    .replicas
                    .iter()
                    .filter(|replica| replica.is_recovering())
                    .count();
                let f = (self.replicas.len() - 1) / 2;
                if recovering < f && self.prng.gen_bool(self.options.replica_reboot_probability) {
                    self.reboot_replica(id);
                } else {
                    debug!("tick {}: replica {id} restarts", self.ticks);
                }
                self.replica_up[id] = true;
                self.replica_stable_until[id] = self.ticks + self.options.replica_restart_stability;
                self.restarts += 1;
            }
        }
    }

    fn tick_heartbeat(&mut self) {
        if self.ticks.is_multiple_of(self.options.heartbeat_interval) {
            for (id, replica) in self.replicas.iter_mut().enumerate() {
                if self.replica_up[id] {
                    replica.on_idle();
                }
            }
            for client in &mut self.clients {
                client.on_idle();
            }
        }
    }

    /// Hands everything the replicas and clients want sent to the network,
    /// delivers what is due this tick, and hands over what those deliveries
    /// produced, which the network delivers from the next tick on.
    fn tick_network(&mut self) {
        self.flush();
        for envelope in self.network.take_due(self.ticks) {
            let Envelope {
                from, to, message, ..
            } = envelope;
            if !self.replica_up[to] {
                debug!("tick {}: drop {message:?} to crashed {to}", self.ticks);
                continue;
            }
            let cut_off = self.partitioned.contains(&to)
                || matches!(from, Origin::Replica(id) if self.partitioned.contains(&id));
            if cut_off {
                debug!("tick {}: drop {message:?} to {to}: partitioned", self.ticks);
                continue;
            }
            debug!("tick {}: deliver {message:?} to {to}", self.ticks);
            self.replicas[to].on_message(message);
        }
        self.flush();
    }

    /// Moves the replicas' and clients' outgoing messages into the network
    /// and delivers the replicas' replies to the clients.
    fn flush(&mut self) {
        let Simulator {
            replicas,
            clients,
            client_inflight,
            replies,
            requests_replied,
            network,
            prng,
            ticks,
            durable_view,
            ..
        } = self;
        for (id, replica) in replicas.iter_mut().enumerate() {
            // Persist the view before anything sent in it goes out.
            durable_view[id] = replica.view_number();
            for (dst, msg) in replica.drain_messages() {
                network.send(*ticks, Origin::Replica(id), dst, msg, prng);
            }
            for reply in replica.drain_replies() {
                debug!("tick {ticks}: reply {reply:?}");
                // A reply completes the request its client is waiting for.
                // Any other reply is a duplicate, which the properties still
                // check.
                clients[reply.client_id].on_reply(reply.request_number, reply.view_number);
                let inflight = &mut client_inflight[reply.client_id];
                if *inflight == Some(reply.request_number) {
                    *inflight = None;
                    *requests_replied += 1;
                }
                replies.push(reply);
            }
        }
        for (id, client) in clients.iter_mut().enumerate() {
            for (dst, msg) in client.drain() {
                network.send(*ticks, Origin::Client(id), dst, msg, prng);
            }
        }
    }

    fn check_properties(&mut self) -> Result<()> {
        let ctx = Self::context(self.ticks, &self.replicas, &self.replies, &self.core);
        for property in &mut self.properties {
            property
                .check(&ctx)
                .with_context(|| format!("property '{}' failed", property.name()))?;
        }
        Ok(())
    }

    fn context<'a>(
        tick: u64,
        replicas: &'a [Replica<Accumulator>],
        replies: &'a [Reply<i64>],
        core: &'a [usize],
    ) -> SimContext<'a> {
        SimContext {
            tick,
            replicas,
            replies,
            core,
        }
    }
}
