//! A replicated key-value store on top of vsr-rs.
//!
//! Every node runs one replica. Nodes exchange protocol messages over TCP
//! using a one-line-per-message text encoding, and every node also accepts
//! client connections speaking a Redis-like inline protocol, so `nc` works:
//!
//! ```text
//! SET foo bar
//! +OK
//! GET foo
//! $3
//! bar
//! ```
//!
//! Reads and writes both go through the replicated log, so a GET is
//! linearizable. See README.md next to this file.

use log::{debug, info, warn};
use std::collections::HashMap;
use std::io::{BufRead, BufReader, Write};
use std::net::{SocketAddr, TcpListener, TcpStream};
use std::sync::mpsc::{channel, Receiver, Sender};
use std::thread;
use std::time::{Duration, Instant};
use vsr_rs::{
    Client, ClientID, Config, LogEntry, Message, RecoveryState, Replica, ReplicaID, Reply,
    RequestNumber, StateMachine,
};

/// How often the replica and the clients run their idle logic.
const TICK: Duration = Duration::from_millis(100);
/// Ticks between two re-sends of a request that got no reply.
const CLIENT_RESEND_TICKS: u64 = 5;
/// Idle periods without hearing from the primary before a view change.
const PRIMARY_TIMEOUT: usize = 5;

// ---------------------------------------------------------------------------
// State machine

#[derive(Clone, Debug, PartialEq, Eq)]
enum Op {
    Put(String, String),
    Get(String),
}

/// The key-value store. The output of an op is the value read by a GET.
#[derive(Default)]
struct Store {
    map: HashMap<String, String>,
}

impl StateMachine for Store {
    type Input = Op;
    type Output = Option<String>;

    fn apply(&mut self, op: Op) -> Option<String> {
        match op {
            Op::Put(key, value) => {
                self.map.insert(key, value);
                None
            }
            Op::Get(key) => self.map.get(&key).cloned(),
        }
    }
}

// ---------------------------------------------------------------------------
// Wire encoding between nodes: one message per line, whitespace separated.

type KvReply = Reply<Option<String>>;

/// What travels between nodes: protocol messages, and replies routed back
/// to the node that owns the client connection.
enum Frame {
    Message(Message<Op>),
    Reply(KvReply),
}

fn encode_op(op: &Op) -> String {
    match op {
        Op::Put(key, value) => format!("PUT {key} {value}"),
        Op::Get(key) => format!("GET {key}"),
    }
}

fn encode_entries(log: &[LogEntry<Op>]) -> String {
    let mut out = log.len().to_string();
    for entry in log {
        out.push_str(&format!(
            " {} {} {}",
            entry.client_id,
            entry.request_number,
            encode_op(&entry.op)
        ));
    }
    out
}

fn encode(frame: &Frame) -> String {
    match frame {
        Frame::Message(message) => match message {
            Message::Request {
                client_id,
                request_number,
                op,
            } => format!("REQUEST {client_id} {request_number} {}", encode_op(op)),
            Message::Prepare {
                view_number,
                op_number,
                client_id,
                request_number,
                op,
                commit_number,
            } => format!(
                "PREPARE {view_number} {op_number} {commit_number} {client_id} {request_number} {}",
                encode_op(op)
            ),
            Message::PrepareOk {
                view_number,
                op_number,
                replica_id,
            } => format!("PREPAREOK {view_number} {op_number} {replica_id}"),
            Message::Commit {
                view_number,
                commit_number,
            } => format!("COMMIT {view_number} {commit_number}"),
            Message::GetState {
                replica_id,
                view_number,
                op_number,
            } => format!("GETSTATE {replica_id} {view_number} {op_number}"),
            Message::NewState {
                view_number,
                log,
                op_number_start,
                op_number_end,
                commit_number,
            } => format!(
                "NEWSTATE {view_number} {op_number_start} {op_number_end} {commit_number} {}",
                encode_entries(log)
            ),
            Message::StartViewChange {
                view_number,
                replica_id,
            } => format!("STARTVIEWCHANGE {view_number} {replica_id}"),
            Message::DoViewChange {
                view_number,
                replica_id,
                last_normal_view,
                log,
                op_number,
                commit_number,
            } => format!(
                "DOVIEWCHANGE {view_number} {replica_id} {last_normal_view} {op_number} {commit_number} {}",
                encode_entries(log)
            ),
            Message::StartView {
                view_number,
                log,
                op_number,
                commit_number,
            } => format!(
                "STARTVIEW {view_number} {op_number} {commit_number} {}",
                encode_entries(log)
            ),
            Message::Recovery {
                replica_id,
                nonce,
                view_number,
            } => format!("RECOVERY {replica_id} {nonce} {view_number}"),
            Message::RecoveryResponse {
                view_number,
                nonce,
                replica_id,
                state,
            } => match state {
                Some(state) => format!(
                    "RECOVERYRESPONSE {view_number} {nonce} {replica_id} + {} {}",
                    state.commit_number,
                    encode_entries(&state.log)
                ),
                None => format!("RECOVERYRESPONSE {view_number} {nonce} {replica_id} -"),
            },
        },
        Frame::Reply(reply) => format!(
            "REPLY {} {} {} {}",
            reply.view_number,
            reply.client_id,
            reply.request_number,
            match &reply.result {
                Some(value) => format!("+{value}"),
                None => "-".to_string(),
            }
        ),
    }
}

/// A cursor over the tokens of one encoded line.
struct Tokens<'a> {
    iter: std::str::SplitWhitespace<'a>,
}

impl<'a> Tokens<'a> {
    fn word(&mut self) -> Result<&'a str, String> {
        self.iter
            .next()
            .ok_or_else(|| "truncated message".to_string())
    }

    fn num(&mut self) -> Result<usize, String> {
        let word = self.word()?;
        word.parse().map_err(|_| format!("bad number {word:?}"))
    }

    fn op(&mut self) -> Result<Op, String> {
        match self.word()? {
            "PUT" => Ok(Op::Put(self.word()?.to_string(), self.word()?.to_string())),
            "GET" => Ok(Op::Get(self.word()?.to_string())),
            kind => Err(format!("bad op {kind:?}")),
        }
    }

    fn entries(&mut self) -> Result<Vec<LogEntry<Op>>, String> {
        let count = self.num()?;
        let mut log = Vec::with_capacity(count);
        for _ in 0..count {
            log.push(LogEntry {
                client_id: self.num()?,
                request_number: self.num()?,
                op: self.op()?,
            });
        }
        Ok(log)
    }
}

fn decode(line: &str) -> Result<Frame, String> {
    let mut t = Tokens {
        iter: line.split_whitespace(),
    };
    let message = match t.word()? {
        "REQUEST" => Message::Request {
            client_id: t.num()?,
            request_number: t.num()?,
            op: t.op()?,
        },
        "PREPARE" => Message::Prepare {
            view_number: t.num()?,
            op_number: t.num()?,
            commit_number: t.num()?,
            client_id: t.num()?,
            request_number: t.num()?,
            op: t.op()?,
        },
        "PREPAREOK" => Message::PrepareOk {
            view_number: t.num()?,
            op_number: t.num()?,
            replica_id: t.num()?,
        },
        "COMMIT" => Message::Commit {
            view_number: t.num()?,
            commit_number: t.num()?,
        },
        "GETSTATE" => Message::GetState {
            replica_id: t.num()?,
            view_number: t.num()?,
            op_number: t.num()?,
        },
        "NEWSTATE" => Message::NewState {
            view_number: t.num()?,
            op_number_start: t.num()?,
            op_number_end: t.num()?,
            commit_number: t.num()?,
            log: t.entries()?,
        },
        "STARTVIEWCHANGE" => Message::StartViewChange {
            view_number: t.num()?,
            replica_id: t.num()?,
        },
        "DOVIEWCHANGE" => Message::DoViewChange {
            view_number: t.num()?,
            replica_id: t.num()?,
            last_normal_view: t.num()?,
            op_number: t.num()?,
            commit_number: t.num()?,
            log: t.entries()?,
        },
        "STARTVIEW" => Message::StartView {
            view_number: t.num()?,
            op_number: t.num()?,
            commit_number: t.num()?,
            log: t.entries()?,
        },
        "RECOVERY" => Message::Recovery {
            replica_id: t.num()?,
            nonce: t.word()?.parse().map_err(|_| "bad nonce".to_string())?,
            view_number: t.num()?,
        },
        "RECOVERYRESPONSE" => {
            let view_number = t.num()?;
            let nonce = t.word()?.parse().map_err(|_| "bad nonce".to_string())?;
            let replica_id = t.num()?;
            let state = match t.word()? {
                "+" => Some(RecoveryState {
                    commit_number: t.num()?,
                    log: t.entries()?,
                }),
                _ => None,
            };
            Message::RecoveryResponse {
                view_number,
                nonce,
                replica_id,
                state,
            }
        }
        "REPLY" => {
            let view_number = t.num()?;
            let client_id = t.num()?;
            let request_number = t.num()?;
            let result = match t.word()? {
                "-" => None,
                value => Some(value[1..].to_string()),
            };
            return Ok(Frame::Reply(Reply {
                view_number,
                client_id,
                request_number,
                result,
            }));
        }
        kind => return Err(format!("unknown message {kind:?}")),
    };
    Ok(Frame::Message(message))
}

// ---------------------------------------------------------------------------
// Networking between nodes

/// Sends frames to other nodes, connecting on demand. A node that cannot be
/// reached just loses the message; the protocol re-sends what matters.
fn run_sender(
    self_id: ReplicaID,
    addresses: Vec<SocketAddr>,
    frames: Receiver<(ReplicaID, Frame)>,
    events: Sender<Event>,
) {
    let mut streams: HashMap<ReplicaID, TcpStream> = HashMap::new();
    let mut last_failure: HashMap<ReplicaID, Instant> = HashMap::new();
    for (dst, frame) in frames {
        if dst == self_id {
            // Our own messages, for example a client request when we are
            // the primary, go straight to our event loop.
            let event = match frame {
                Frame::Message(message) => Event::Message(message),
                Frame::Reply(reply) => Event::Reply(reply),
            };
            let _ = events.send(event);
            continue;
        }
        let stream = match streams.entry(dst) {
            std::collections::hash_map::Entry::Occupied(entry) => entry.into_mut(),
            std::collections::hash_map::Entry::Vacant(entry) => {
                if last_failure
                    .get(&dst)
                    .is_some_and(|at| at.elapsed() < Duration::from_millis(500))
                {
                    continue;
                }
                match TcpStream::connect_timeout(&addresses[dst], Duration::from_millis(200)) {
                    Ok(stream) => {
                        info!("connected to node {dst} at {}", addresses[dst]);
                        entry.insert(stream)
                    }
                    Err(err) => {
                        debug!("node {dst} unreachable: {err}");
                        last_failure.insert(dst, Instant::now());
                        continue;
                    }
                }
            }
        };
        let line = encode(&frame);
        if let Err(err) = stream
            .write_all(line.as_bytes())
            .and_then(|_| stream.write_all(b"\n"))
        {
            // Drop the stream but do not start the backoff: the peer was
            // reachable a moment ago, so the next frame retries the connect
            // right away. If that connect fails, the backoff starts then.
            warn!("lost connection to node {dst}: {err}");
            streams.remove(&dst);
        }
    }
}

/// Accepts connections from other nodes and feeds their frames to the event
/// loop.
fn run_peer_acceptor(listener: TcpListener, events: Sender<Event>) {
    for stream in listener.incoming().flatten() {
        let events = events.clone();
        thread::spawn(move || {
            for line in BufReader::new(stream).lines().map_while(Result::ok) {
                match decode(&line) {
                    Ok(Frame::Message(message)) => {
                        let _ = events.send(Event::Message(message));
                    }
                    Ok(Frame::Reply(reply)) => {
                        let _ = events.send(Event::Reply(reply));
                    }
                    Err(err) => warn!("bad message from peer: {err}"),
                }
            }
        });
    }
}

// ---------------------------------------------------------------------------
// Client connections

enum Command {
    Set(String, String),
    Get(String),
}

fn parse_command(line: &str) -> Result<Option<Command>, String> {
    let words: Vec<&str> = line.split_whitespace().collect();
    let Some(name) = words.first() else {
        return Ok(None);
    };
    match (name.to_ascii_uppercase().as_str(), words.len()) {
        ("PING", 1) => {
            Err("+PONG".to_string()) // not an error, just a canned response
        }
        ("SET", 3) => Ok(Some(Command::Set(
            words[1].to_string(),
            words[2].to_string(),
        ))),
        ("SET", _) => Err("-ERR usage: SET key value".to_string()),
        ("GET", 2) => Ok(Some(Command::Get(words[1].to_string()))),
        ("GET", _) => Err("-ERR usage: GET key".to_string()),
        _ => Err(format!("-ERR unknown command {name:?}")),
    }
}

/// Serves one client connection: one command at a time, each answered once
/// the replicated store has executed it.
fn run_client_connection(
    stream: TcpStream,
    connection: u64,
    events: Sender<Event>,
) -> std::io::Result<()> {
    let (respond_tx, respond_rx) = channel::<String>();
    let mut writer = stream.try_clone()?;
    let reader = BufReader::new(stream);
    for line in reader.lines() {
        let line = line?;
        let command = match parse_command(&line) {
            Ok(None) => continue,
            Ok(Some(command)) => command,
            Err(response) => {
                writer.write_all(format!("{response}\r\n").as_bytes())?;
                continue;
            }
        };
        let _ = events.send(Event::Command {
            connection,
            command,
            respond: respond_tx.clone(),
        });
        let Ok(response) = respond_rx.recv() else {
            break;
        };
        writer.write_all(response.as_bytes())?;
    }
    let _ = events.send(Event::Disconnect(connection));
    Ok(())
}

fn run_client_acceptor(listener: TcpListener, node_id: ReplicaID, events: Sender<Event>) {
    // Client ids must never repeat, or the primary's client table mistakes
    // a new connection's first request for a re-send of an old one and
    // answers it from the cache (section 4.5 of the paper). The node id in
    // the top byte tells the primary which node to route the reply to, the
    // start time below it separates restarts of the node, and the low bits
    // count connections.
    let started = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|since| since.as_secs())
        .unwrap_or(0)
        & 0xFF_FFFF;
    for (next, stream) in listener.incoming().flatten().enumerate() {
        let connection = ((node_id as u64) << 56) | (started << 32) | next as u64;
        let events = events.clone();
        thread::spawn(move || {
            if let Err(err) = run_client_connection(stream, connection, events) {
                debug!("client connection {connection} closed: {err}");
            }
        });
    }
}

fn node_of(client_id: ClientID) -> ReplicaID {
    (client_id >> 56) as ReplicaID
}

// ---------------------------------------------------------------------------
// The node: one thread owning the replica and the proxied clients

enum Event {
    Message(Message<Op>),
    Reply(KvReply),
    Command {
        connection: u64,
        command: Command,
        respond: Sender<String>,
    },
    Disconnect(u64),
    Tick,
}

/// A client connection's VSR client and the command it is waiting on.
struct Connection {
    client: Client<Op>,
    pending: Option<(RequestNumber, Command, Sender<String>)>,
}

/// Hands a reply to the connection waiting for it, if it is still there
/// and still waiting for that request.
fn deliver_reply(connections: &mut HashMap<u64, Connection>, reply: KvReply) {
    let Some(connection) = connections.get_mut(&(reply.client_id as u64)) else {
        return;
    };
    let answers_pending = connection
        .client
        .on_reply(reply.request_number, reply.view_number);
    if answers_pending {
        if let Some((_, command, respond)) = connection.pending.take() {
            let _ = respond.send(format_reply(&command, reply.result));
        }
    }
}

/// Sends out everything the replica and the clients produced: protocol
/// messages to the sender thread, and replies to the node that owns the
/// client connection, which may be this one.
fn flush(
    node_id: ReplicaID,
    replica: &mut Replica<Store>,
    connections: &mut HashMap<u64, Connection>,
    frames: &Sender<(ReplicaID, Frame)>,
) {
    for (dst, message) in replica.drain_messages() {
        let _ = frames.send((dst, Frame::Message(message)));
    }
    for reply in replica.drain_replies() {
        let owner = node_of(reply.client_id);
        if owner == node_id {
            deliver_reply(connections, reply);
        } else {
            let _ = frames.send((owner, Frame::Reply(reply)));
        }
    }
    for connection in connections.values_mut() {
        for (dst, message) in connection.client.drain() {
            let _ = frames.send((dst, Frame::Message(message)));
        }
    }
}

/// Writes `view` to `path` if it is not what is there already.
fn persist_view(path: &str, persisted: &mut Option<usize>, view: usize) {
    if *persisted == Some(view) {
        return;
    }
    let tmp = format!("{path}.tmp");
    let result = std::fs::write(&tmp, format!("{view}\n"))
        .and_then(|_| std::fs::File::open(&tmp).and_then(|f| f.sync_all()))
        .and_then(|_| std::fs::rename(&tmp, path));
    match result {
        Ok(()) => *persisted = Some(view),
        Err(err) => {
            eprintln!("cannot persist view to {path}: {err}");
            std::process::exit(1);
        }
    }
}

fn format_reply(command: &Command, result: Option<String>) -> String {
    match (command, result) {
        (Command::Set(..), _) => "+OK\r\n".to_string(),
        (Command::Get(_), Some(value)) => format!("${}\r\n{value}\r\n", value.len()),
        (Command::Get(_), None) => "$-1\r\n".to_string(),
    }
}

struct Args {
    id: ReplicaID,
    replicas: Vec<SocketAddr>,
    listen: SocketAddr,
}

fn parse_args() -> Result<Args, String> {
    let mut id = None;
    let mut replicas = None;
    let mut listen = None;
    let mut args = std::env::args().skip(1);
    while let Some(arg) = args.next() {
        let mut value = || args.next().ok_or_else(|| format!("{arg} needs a value"));
        match arg.as_str() {
            "--id" => id = Some(value()?.parse().map_err(|_| "bad --id")?),
            "--replicas" => {
                replicas = Some(
                    value()?
                        .split(',')
                        .map(|a| a.parse().map_err(|_| format!("bad address {a:?}")))
                        .collect::<Result<Vec<SocketAddr>, _>>()?,
                )
            }
            "--listen" => listen = Some(value()?.parse().map_err(|_| "bad --listen")?),
            _ => return Err(format!("unknown argument {arg}")),
        }
    }
    let usage = "usage: kvstore --id N --replicas ADDR,ADDR,... --listen ADDR";
    let args = Args {
        id: id.ok_or(usage)?,
        replicas: replicas.ok_or(usage)?,
        listen: listen.ok_or(usage)?,
    };
    if args.id >= args.replicas.len() {
        return Err("--id must index into --replicas".to_string());
    }
    Ok(args)
}

fn main() {
    env_logger::init();
    let args = match parse_args() {
        Ok(args) => args,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(2);
        }
    };

    let mut config = Config::new();
    for _ in &args.replicas {
        config.add_replica();
    }
    config.set_primary_timeout(PRIMARY_TIMEOUT);

    let (events_tx, events_rx) = channel::<Event>();
    let (frames_tx, frames_rx) = channel::<(ReplicaID, Frame)>();

    {
        let (self_id, addresses, events) = (args.id, args.replicas.clone(), events_tx.clone());
        thread::spawn(move || run_sender(self_id, addresses, frames_rx, events));
    }
    {
        let listener = TcpListener::bind(args.replicas[args.id]).unwrap_or_else(|err| {
            eprintln!("cannot listen on {}: {err}", args.replicas[args.id]);
            std::process::exit(1);
        });
        let events = events_tx.clone();
        thread::spawn(move || run_peer_acceptor(listener, events));
    }
    {
        let listener = TcpListener::bind(args.listen).unwrap_or_else(|err| {
            eprintln!("cannot listen on {}: {err}", args.listen);
            std::process::exit(1);
        });
        let (node_id, events) = (args.id, events_tx.clone());
        thread::spawn(move || run_client_acceptor(listener, node_id, events));
    }
    {
        let events = events_tx.clone();
        thread::spawn(move || loop {
            thread::sleep(TICK);
            if events.send(Event::Tick).is_err() {
                break;
            }
        });
    }

    // The view number is the one thing that must survive a crash. It lives
    // in a small file; if the file exists this node has run before, and it
    // comes back through recovery rather than as a brand new replica.
    let view_path = format!("kvstore-node-{}.view", args.id);
    let mut persisted_view = std::fs::read_to_string(&view_path)
        .ok()
        .and_then(|s| s.trim().parse::<usize>().ok());
    let mut replica = match persisted_view {
        Some(view) => {
            let nonce = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|since| since.as_nanos() as u64)
                .unwrap_or(0);
            println!("recovering from view {view}");
            Replica::recover(args.id, config.clone(), Store::default(), view, nonce)
        }
        None => Replica::new(args.id, config.clone(), Store::default()),
    };
    persist_view(&view_path, &mut persisted_view, replica.view_number());
    println!(
        "node {} of {}: replicas on {}, clients on {}, primary is node {}",
        args.id,
        args.replicas.len(),
        args.replicas[args.id],
        args.listen,
        replica.primary_id()
    );

    // This thread owns the replica and the clients. Every event steps them,
    // and whatever they produce is sent out afterwards.
    let mut connections: HashMap<u64, Connection> = HashMap::new();
    let mut ticks = 0u64;
    let mut view = replica.view_number();
    for event in events_rx {
        match event {
            Event::Message(message) => replica.on_message(message),
            Event::Reply(reply) => deliver_reply(&mut connections, reply),
            Event::Command {
                connection: id,
                command,
                respond,
            } => {
                let connection = connections.entry(id).or_insert_with(|| Connection {
                    client: Client::new(id as ClientID, config.clone()),
                    pending: None,
                });
                let op = match &command {
                    Command::Set(key, value) => Op::Put(key.clone(), value.clone()),
                    Command::Get(key) => Op::Get(key.clone()),
                };
                let request_number = connection.client.on_request(op);
                connection.pending = Some((request_number, command, respond));
            }
            Event::Disconnect(id) => {
                connections.remove(&id);
            }
            Event::Tick => {
                ticks += 1;
                replica.on_idle();
                if ticks.is_multiple_of(CLIENT_RESEND_TICKS) {
                    for connection in connections.values_mut() {
                        connection.client.on_idle();
                    }
                }
            }
        }
        persist_view(&view_path, &mut persisted_view, replica.view_number());
        flush(args.id, &mut replica, &mut connections, &frames_tx);
        if replica.view_number() != view {
            view = replica.view_number();
            println!(
                "view {view}: primary is node {}{}",
                replica.primary_id(),
                if replica.is_primary() {
                    " (this node)"
                } else {
                    ""
                }
            );
        }
    }
}
