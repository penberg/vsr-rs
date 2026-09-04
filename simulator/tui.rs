//! A terminal viewer for the simulator: watch a cluster run, and inject
//! faults by hand.

use anyhow::Result;
use clap::Parser;
use rand::SeedableRng;
use rand_chacha::ChaCha8Rng;
use ratatui::crossterm::event::{self, Event, KeyCode, KeyEventKind};
use ratatui::layout::{Constraint, Layout, Rect};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::canvas::{Canvas, Context, Line as CanvasLine};
use ratatui::widgets::{Block, Cell, Paragraph, Row, Table, Wrap};
use ratatui::Frame;
use std::collections::VecDeque;
use std::time::{Duration, Instant};
use vsr_rs::Status;
use vsr_simulator::{
    message_kind, parse_script, Fault, FaultScript, Limits, NetworkOptions, Options, Origin, Phase,
    Simulator, Snapshot,
};

#[derive(Parser)]
#[command(name = "vsr-simulator-tui")]
#[command(about = "Watch the simulator run a cluster: replay a seed, or drive one yourself")]
#[command(
    after_help = "Give a seed to watch the run the headless simulator does for it, faults and \
all, without being able to change it. Give --interactive for a perfect cluster where nothing goes \
wrong until you inject a fault."
)]
struct Args {
    /// Replay this seed: a decimal integer, or a 40-character git commit
    /// hash. Everything the headless simulator would do for it happens
    /// here, and nothing can be injected.
    #[arg(
        conflicts_with = "interactive",
        required_unless_present = "interactive"
    )]
    seed: Option<String>,
    /// A perfect cluster, no seed: nothing goes wrong unless you make it,
    /// with the fault keys.
    #[arg(long)]
    interactive: bool,
    /// Replicas in the interactive cluster.
    #[arg(long, default_value_t = 3, requires = "interactive")]
    replicas: usize,
    /// Replay the seed's small-cluster configuration, as `--lite` does in
    /// the headless simulator.
    #[arg(long, conflicts_with = "interactive")]
    lite: bool,
    /// Start paused.
    #[arg(long)]
    paused: bool,
    /// Ticks per second to start with.
    #[arg(long, default_value_t = 1.0)]
    speed: f64,
    /// Run at full speed to this tick, then pause.
    #[arg(long)]
    until: Option<u64>,
    /// A fault script to replay in the interactive cluster: one `TICK
    /// FAULT` per line, as printed on quit.
    #[arg(long, requires = "interactive")]
    script: Option<std::path::PathBuf>,
    /// Ticks without a reply before the safety phase gives up.
    #[arg(long, default_value_t = Limits::default().ticks_max_requests)]
    ticks_max_requests: u64,
    /// Ticks the liveness phase may take to converge.
    #[arg(long, default_value_t = Limits::default().ticks_max_convergence)]
    ticks_max_convergence: u64,
}

const FRAME: Duration = Duration::from_millis(33);
const MAX_TICKS_PER_FRAME: u64 = 5_000;
const LOSS_LEVELS: [f64; 4] = [0.0, 0.05, 0.2, 0.5];

struct App {
    sim: Simulator,
    seed: u64,
    /// Whether faults may be injected; a seed replay is read-only.
    interactive: bool,
    limits: Limits,
    network: NetworkOptions,
    paused: bool,
    speed: f64,
    until: Option<u64>,
    /// Fraction of a tick carried over between frames.
    carry: f64,
    selected: usize,
    /// Faults still to come from the script given on the command line.
    scripted: FaultScript,
    /// Every fault injected, from the script or by hand.
    injected: FaultScript,
    events: VecDeque<String>,
    last: Snapshot,
    outcome: Option<Result<(), String>>,
}

impl App {
    fn log(&mut self, tick: u64, text: impl Into<String>) {
        self.events.push_back(format!("{tick:>8}  {}", text.into()));
        while self.events.len() > 500 {
            self.events.pop_front();
        }
    }

    fn inject(&mut self, fault: Fault) {
        let tick = self.sim.ticks;
        self.sim.apply(fault);
        self.injected.push((tick, fault));
        self.log(tick, format!("inject: {fault}"));
    }

    /// Advances the run by `ticks`, stopping early at a failure, the end,
    /// or the `--until` tick.
    fn advance(&mut self, ticks: u64) {
        for _ in 0..ticks {
            if self.outcome.is_some() {
                return;
            }
            while self
                .scripted
                .first()
                .is_some_and(|(at, _)| *at <= self.sim.ticks)
            {
                let (_, fault) = self.scripted.remove(0);
                self.inject(fault);
            }
            match self.sim.step_run(self.limits) {
                Ok(Phase::Done) => {
                    let tick = self.sim.ticks;
                    self.log(tick, "PASSED: the core converged");
                    self.outcome = Some(Ok(()));
                    self.paused = true;
                }
                Ok(_) => {}
                Err(err) => {
                    let tick = self.sim.ticks;
                    self.log(tick, format!("FAILED: {err:#}"));
                    self.outcome = Some(Err(format!("{err:#}")));
                    self.paused = true;
                }
            }
            if self.until.is_some_and(|until| self.sim.ticks >= until) {
                self.until = None;
                self.paused = true;
            }
        }
    }

    /// Notes what changed since the last frame.
    fn observe(&mut self) {
        let now = self.sim.snapshot();
        let tick = now.tick;
        if now.phase != self.last.phase {
            let core: Vec<usize> = now
                .replicas
                .iter()
                .filter(|r| r.in_core)
                .map(|r| r.id)
                .collect();
            self.log(tick, format!("{:?} phase, core {core:?}", now.phase));
        }
        let mut notes = Vec::new();
        for (before, after) in self.last.replicas.iter().zip(&now.replicas) {
            let id = after.id;
            if after.view_number != before.view_number {
                notes.push(format!(
                    "replica {id} moved to view {}{}",
                    after.view_number,
                    if after.is_primary { " as primary" } else { "" }
                ));
            }
            if after.status != before.status {
                notes.push(format!("replica {id} is {}", status_name(after.status)));
            }
            if after.up != before.up {
                notes.push(format!(
                    "replica {id} {}",
                    if after.up { "is back up" } else { "crashed" }
                ));
            }
            if after.partitioned != before.partitioned {
                notes.push(format!(
                    "replica {id} {}",
                    if after.partitioned {
                        "is cut off"
                    } else {
                        "is reconnected"
                    }
                ));
            }
        }
        for note in notes {
            self.log(tick, note);
        }
        self.last = now;
    }
}

fn status_name(status: Status) -> &'static str {
    match status {
        Status::Normal => "normal",
        Status::StateTransfer => "in state transfer",
        Status::ViewChange => "in view change",
        Status::Recovering => "recovering",
    }
}

fn parse_seed(s: &str) -> Result<u64> {
    if s.len() == 40 && s.chars().all(|c| c.is_ascii_hexdigit()) {
        return Ok(u64::from_str_radix(&s[24..], 16)?);
    }
    s.parse::<u64>()
        .map_err(|err| anyhow::anyhow!("invalid seed {s:?}: {err}"))
}

/// The interactive cluster: no random faults, every message takes exactly
/// one tick so it can be seen on its way but nothing is reordered, and a
/// short heartbeat and timeout so a crash is acted on within a few seconds
/// at viewing speed. Requests never run out.
fn interactive_options(replica_count: usize) -> Options {
    let mut prng = ChaCha8Rng::seed_from_u64(0);
    let mut options = Options::swarm(&mut prng);
    options.replica_count = replica_count;
    options.client_count = 2;
    options.network = NetworkOptions {
        one_way_delay_min: 1,
        one_way_delay_mean: 1,
        ..NetworkOptions::perfect()
    };
    options.requests_max = usize::MAX / 2;
    options.request_probability = 0.3;
    options.request_idle_on_probability = 0.0;
    options.heartbeat_interval = 5;
    options.primary_timeout = 3;
    options.replica_crash_probability = 0.0;
    options.replica_reboot_probability = 0.0;
    options.full_core = true;
    options
}

fn main() -> Result<()> {
    let args = Args::parse();
    let (seed, options) = if args.interactive {
        (0, interactive_options(args.replicas.max(1)))
    } else {
        let seed = parse_seed(args.seed.as_deref().unwrap_or_default())?;
        let mut prng = ChaCha8Rng::seed_from_u64(seed);
        let options = if args.lite {
            Options::lite(&mut prng)
        } else {
            Options::swarm(&mut prng)
        };
        (seed, options)
    };
    let scripted = match &args.script {
        Some(path) => parse_script(&std::fs::read_to_string(path)?)
            .map_err(|err| anyhow::anyhow!("{}: {err}", path.display()))?,
        None => Vec::new(),
    };
    let limits = Limits {
        ticks_max_requests: args.ticks_max_requests,
        ticks_max_convergence: args.ticks_max_convergence,
    };
    let network = options.network.clone();
    let sim = Simulator::init(seed, options)?;
    let last = sim.snapshot();
    let mut app = App {
        sim,
        seed,
        interactive: args.interactive,
        limits,
        network,
        paused: args.paused,
        speed: args.speed.max(0.1),
        until: args.until,
        carry: 0.0,
        selected: 0,
        scripted,
        injected: Vec::new(),
        events: VecDeque::new(),
        last,
        outcome: None,
    };
    if args.interactive {
        app.log(
            0,
            format!("interactive cluster of {} replicas", args.replicas),
        );
    } else {
        app.log(0, format!("replaying seed {seed}"));
    }

    // A panic inside the simulator must not leave the terminal raw.
    let hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |info| {
        ratatui::restore();
        hook(info);
    }));
    let mut terminal = ratatui::init();
    let result = run(&mut terminal, &mut app);
    ratatui::restore();
    result?;

    if app.interactive {
        println!("interactive cluster of {} replicas", args.replicas);
    } else {
        println!("seed = {}", app.seed);
    }
    if let Some(outcome) = &app.outcome {
        match outcome {
            Ok(()) => println!("passed at tick {}", app.sim.ticks),
            Err(err) => println!("failed at tick {}: {err}", app.sim.ticks),
        }
    } else {
        println!("stopped at tick {}", app.sim.ticks);
    }
    if !app.injected.is_empty() {
        println!("fault script:");
        for (tick, fault) in &app.injected {
            println!("{tick} {fault}");
        }
    }
    Ok(())
}

fn run(terminal: &mut ratatui::DefaultTerminal, app: &mut App) -> Result<()> {
    let mut last_frame = Instant::now();
    loop {
        app.observe();
        terminal.draw(|frame| draw(frame, app))?;

        let elapsed = last_frame.elapsed();
        last_frame = Instant::now();
        if !app.paused {
            let ticks = if app.until.is_some() {
                MAX_TICKS_PER_FRAME
            } else {
                app.carry += app.speed * elapsed.as_secs_f64();
                let whole = app.carry.floor();
                app.carry -= whole;
                (whole as u64).min(MAX_TICKS_PER_FRAME)
            };
            app.advance(ticks);
        }

        if event::poll(FRAME.saturating_sub(last_frame.elapsed()))? {
            if let Event::Key(key) = event::read()? {
                if key.kind != KeyEventKind::Press {
                    continue;
                }
                let replicas = app.last.replicas.len();
                match key.code {
                    KeyCode::Char('q') | KeyCode::Esc => return Ok(()),
                    KeyCode::Char(' ') => app.paused = !app.paused,
                    KeyCode::Char('.') => {
                        app.paused = true;
                        app.advance(1);
                    }
                    KeyCode::Char('+') | KeyCode::Char('=') => {
                        app.speed = (app.speed * 2.0).min(100_000.0)
                    }
                    KeyCode::Char('-') => app.speed = (app.speed / 2.0).max(0.25),
                    KeyCode::Char(c @ '0'..='9') => {
                        let id = c as usize - '0' as usize;
                        if id < replicas {
                            app.selected = id;
                        }
                    }
                    KeyCode::Up | KeyCode::Left | KeyCode::BackTab => {
                        app.selected = (app.selected + replicas - 1) % replicas
                    }
                    KeyCode::Down | KeyCode::Right | KeyCode::Tab => {
                        app.selected = (app.selected + 1) % replicas
                    }
                    _ if !app.interactive => {}
                    KeyCode::Char('c') => app.inject(Fault::Crash(app.selected)),
                    KeyCode::Char('r') => app.inject(Fault::Restart(app.selected)),
                    KeyCode::Char('R') => app.inject(Fault::Reboot(app.selected)),
                    KeyCode::Char('p') => {
                        let fault = if app.sim.is_partitioned(app.selected) {
                            Fault::Heal(app.selected)
                        } else {
                            Fault::Partition(app.selected)
                        };
                        app.inject(fault);
                    }
                    KeyCode::Char('h') => app.inject(Fault::HealAll),
                    KeyCode::Char('l') => {
                        let current = app.network.packet_loss_probability;
                        let next = LOSS_LEVELS
                            .iter()
                            .position(|level| *level > current + 1e-9)
                            .map(|i| LOSS_LEVELS[i])
                            .unwrap_or(LOSS_LEVELS[0]);
                        app.network.packet_loss_probability = next;
                        app.sim.set_network_options(app.network.clone());
                        let tick = app.sim.ticks;
                        app.log(tick, format!("packet loss set to {next}"));
                    }
                    _ => {}
                }
            }
        }
    }
}

fn draw(frame: &mut Frame, app: &App) {
    let snapshot = &app.last;
    let [header, body, keys] = Layout::vertical([
        Constraint::Length(4),
        Constraint::Min(8),
        Constraint::Length(2),
    ])
    .areas(frame.area());
    draw_header(frame, header, app, snapshot);
    let [cluster, side] =
        Layout::horizontal([Constraint::Percentage(55), Constraint::Percentage(45)]).areas(body);
    draw_cluster(frame, cluster, app, snapshot);
    let table_height = snapshot.replicas.len() as u16 + 4;
    let [replicas, messages, events] = Layout::vertical([
        Constraint::Length(table_height),
        Constraint::Min(5),
        Constraint::Length(9),
    ])
    .areas(side);
    draw_replicas(frame, replicas, app, snapshot);
    draw_messages(frame, messages, snapshot);
    draw_events(frame, events, app);
    let keys_line = if app.interactive {
        "q quit  space pause  . step  +/- speed  0-9 or arrows/tab select a replica  c crash  r restart  R reboot  p partition/heal  h heal all  l loss"
    } else {
        "q quit  space pause  . step  +/- speed  0-9 or arrows/tab select a replica     (replaying a seed: nothing can be injected)"
    };
    let legend = vec![
        Line::from(keys_line),
        Line::from("messages: r request  P prepare  k prepare-ok  c commit  g/N state transfer  v/V/S view change  ?/! recovery"),
    ];
    frame.render_widget(
        Paragraph::new(legend).style(Style::default().fg(Color::DarkGray)),
        keys,
    );
}

/// Where replica `id` of `count` sits on the ring, in canvas coordinates.
fn ring_position(id: usize, count: usize) -> (f64, f64) {
    // Replica 0 at the top, the rest clockwise.
    let angle = std::f64::consts::FRAC_PI_2 - std::f64::consts::TAU * id as f64 / count as f64;
    (0.72 * angle.cos(), 0.72 * angle.sin())
}

/// The glyph and color a message in flight is drawn with.
fn message_glyph(kind: &str) -> (&'static str, Color) {
    match kind {
        "Request" => ("r", Color::Blue),
        "Prepare" => ("P", Color::White),
        "PrepareOk" => ("k", Color::Green),
        "Commit" => ("c", Color::DarkGray),
        "GetState" => ("g", Color::Cyan),
        "NewState" => ("N", Color::Cyan),
        "StartViewChange" => ("v", Color::Magenta),
        "DoViewChange" => ("V", Color::Magenta),
        "StartView" => ("S", Color::Magenta),
        "Recovery" => ("?", Color::Yellow),
        "RecoveryResponse" => ("!", Color::Yellow),
        _ => ("*", Color::White),
    }
}

/// The cluster as a picture: replicas on a ring, clients in the middle,
/// and every message in flight as a letter moving from sender to
/// receiver, placed by how far it is between its send and due ticks.
fn draw_cluster(frame: &mut Frame, area: Rect, app: &App, snapshot: &Snapshot) {
    let count = snapshot.replicas.len();
    // Terminal cells are about twice as tall as wide; stretch x so the
    // ring looks round.
    let aspect = 2.0 * area.height as f64 / area.width.max(1) as f64;
    let half_width = 1.0 / aspect.min(1.0);
    let half_height = aspect.max(1.0);
    let x_bounds = [-half_width, half_width];
    let y_bounds = [-half_height, half_height];
    // Width of one character in canvas units, to center labels.
    let char_width = (x_bounds[1] - x_bounds[0]) / area.width.max(1) as f64;
    let line_height = (y_bounds[1] - y_bounds[0]) / area.height.max(1) as f64;
    // The snapshot's tick count is the number of ticks completed; the
    // frame shows the interval before the next one, `carry` of the way
    // through it. A message sent in the last completed tick is `carry` of
    // the way to its receiver.
    let now = snapshot.tick.saturating_sub(1) as f64 + app.carry;
    let canvas = Canvas::default()
        .block(Block::bordered().title(" cluster "))
        .x_bounds(x_bounds)
        .y_bounds(y_bounds)
        .paint(|ctx: &mut Context| {
            // Edges between replicas, and to the clients in the middle.
            for a in 0..count {
                let (x1, y1) = ring_position(a, count);
                for b in a + 1..count {
                    let (x2, y2) = ring_position(b, count);
                    ctx.draw(&CanvasLine {
                        x1,
                        y1,
                        x2,
                        y2,
                        color: Color::Rgb(50, 50, 50),
                    });
                }
            }
            ctx.layer();
            // Messages in flight.
            for m in &snapshot.messages {
                let (x1, y1) = match m.from {
                    Origin::Replica(id) => ring_position(id, count),
                    Origin::Client(_) => (0.0, 0.0),
                };
                let (x2, y2) = ring_position(m.to, count);
                let span = (m.due_at - m.sent_at).max(1) as f64;
                let t = ((now - m.sent_at as f64) / span).clamp(0.0, 1.0);
                let (x, y) = (x1 + (x2 - x1) * t, y1 + (y2 - y1) * t);
                let (glyph, color) = message_glyph(message_kind(&m.message));
                ctx.print(x, y, Span::styled(glyph, Style::default().fg(color)));
            }
            ctx.layer();
            // Clients in the middle.
            let waiting = snapshot
                .clients
                .iter()
                .filter(|c| c.inflight.is_some())
                .count();
            let label = format!("{} clients, {waiting} waiting", snapshot.clients.len());
            ctx.print(
                -(label.len() as f64) * char_width / 2.0,
                0.0,
                Span::styled(label, Style::default().fg(Color::Blue)),
            );
            // Replicas.
            for r in &snapshot.replicas {
                let (x, y) = ring_position(r.id, count);
                let color = if !r.up {
                    Color::DarkGray
                } else if r.partitioned {
                    Color::Magenta
                } else if r.status == Status::Recovering {
                    Color::Yellow
                } else if r.status != Status::Normal {
                    Color::Cyan
                } else if r.is_primary {
                    Color::Green
                } else {
                    Color::White
                };
                let mut style = Style::default().fg(color);
                if r.id == app.selected {
                    style = style.add_modifier(Modifier::BOLD | Modifier::REVERSED);
                }
                let name = if !r.up {
                    format!("[R{} down]", r.id)
                } else if r.partitioned {
                    format!("[R{} cut off]", r.id)
                } else if r.is_primary {
                    format!("[R{} primary]", r.id)
                } else {
                    format!("[R{}]", r.id)
                };
                let detail = if r.status == Status::Normal {
                    format!("v{} {}/{}", r.view_number, r.commit_number, r.op_number)
                } else {
                    format!("v{} {}", r.view_number, status_name(r.status))
                };
                // The name one row above the node, the detail one row
                // below, leaving the row the edges meet at clear.
                ctx.print(
                    x - name.len() as f64 * char_width / 2.0,
                    y + line_height,
                    Span::styled(name, style),
                );
                ctx.print(
                    x - detail.len() as f64 * char_width / 2.0,
                    y - line_height,
                    Span::styled(detail, Style::default().fg(color)),
                );
            }
        });
    frame.render_widget(canvas, area);
}

fn draw_header(frame: &mut Frame, area: Rect, app: &App, snapshot: &Snapshot) {
    let state = match &app.outcome {
        Some(Ok(())) => Span::styled(
            "PASSED",
            Style::default()
                .fg(Color::Green)
                .add_modifier(Modifier::BOLD),
        ),
        Some(Err(_)) => Span::styled(
            "FAILED",
            Style::default().fg(Color::Red).add_modifier(Modifier::BOLD),
        ),
        None if app.paused => Span::styled("paused", Style::default().fg(Color::Yellow)),
        None => Span::styled("running", Style::default().fg(Color::Green)),
    };
    let line1 = Line::from(vec![
        Span::raw(if app.interactive {
            format!("interactive   tick {}   ", snapshot.tick)
        } else {
            format!("replaying seed {}   tick {}   ", app.seed, snapshot.tick)
        }),
        Span::raw(format!("{:?} phase   ", snapshot.phase)),
        state,
        Span::raw(format!("   {} ticks/s", app.speed)),
        Span::raw(format!("   selected R{}", app.selected)),
    ]);
    let net = &snapshot.network;
    let line2 = Line::from(format!(
        "requests {}/{} replied of {}   crashes {} restarts {} reboots {}   messages sent {} lost {} replayed {} delayed {}   loss {} replay {} latency {} ticks, mean {}",
        snapshot.requests_replied,
        snapshot.requests_sent,
        snapshot.requests_max,
        snapshot.crashes,
        snapshot.restarts,
        snapshot.reboots,
        net.sent,
        net.lost,
        net.replayed,
        net.delayed,
        app.network.packet_loss_probability,
        app.network.packet_replay_probability,
        app.network.one_way_delay_min,
        app.network.one_way_delay_mean,
    ));
    frame.render_widget(
        Paragraph::new(vec![line1, line2]).block(Block::bordered().title(" vsr-simulator ")),
        area,
    );
}

fn draw_replicas(frame: &mut Frame, area: Rect, app: &App, snapshot: &Snapshot) {
    let longest = snapshot
        .replicas
        .iter()
        .map(|r| r.op_number)
        .max()
        .unwrap_or(0)
        .max(1);
    let bar_width = 10usize;
    let rows = snapshot.replicas.iter().map(|r| {
        let style = if !r.up {
            Style::default().fg(Color::DarkGray)
        } else if r.partitioned {
            Style::default().fg(Color::Magenta)
        } else if r.status == Status::Recovering {
            Style::default().fg(Color::Yellow)
        } else if r.status != Status::Normal {
            Style::default().fg(Color::Cyan)
        } else {
            Style::default()
        };
        let mark = if r.id == app.selected { "▶" } else { " " };
        let state = if !r.up {
            "down"
        } else if r.partitioned {
            "cut off"
        } else {
            "up"
        };
        let role = if !r.up {
            ""
        } else if r.is_primary {
            "primary"
        } else {
            "backup"
        };
        let committed = r.commit_number * bar_width / longest;
        let prepared = r.op_number * bar_width / longest;
        let bar: String = (0..bar_width)
            .map(|i| {
                if i < committed {
                    '█'
                } else if i < prepared {
                    '░'
                } else {
                    ' '
                }
            })
            .collect();
        Row::new(vec![
            Cell::from(format!("{mark}{}", r.id)),
            Cell::from(state),
            Cell::from(status_name(r.status)),
            Cell::from(format!("{}", r.view_number)),
            Cell::from(role),
            Cell::from(format!("{}", r.op_number)),
            Cell::from(format!("{}", r.commit_number)),
            Cell::from(bar),
            Cell::from(if r.in_core { "core" } else { "" }),
        ])
        .style(style)
    });
    let table = Table::new(
        rows,
        [
            Constraint::Length(3),
            Constraint::Length(7),
            Constraint::Length(17),
            Constraint::Length(4),
            Constraint::Length(7),
            Constraint::Length(6),
            Constraint::Length(6),
            Constraint::Length(bar_width as u16),
            Constraint::Length(4),
        ],
    )
    .header(
        Row::new(vec![
            "id", "state", "status", "view", "role", "op", "commit", "log", "",
        ])
        .style(Style::default().add_modifier(Modifier::BOLD)),
    )
    .block(Block::bordered().title(" replicas "));
    frame.render_widget(table, area);

    // Clients go under the table, in the same box's last lines.
    let clients: Vec<String> = snapshot
        .clients
        .iter()
        .map(|c| match c.inflight {
            Some(request) => format!("{}:#{request}", c.id),
            None => format!("{}:idle", c.id),
        })
        .collect();
    let text = format!(
        "clients (view they know: {}): {}",
        snapshot.clients.first().map(|c| c.view_number).unwrap_or(0),
        clients.join("  ")
    );
    let inner = Block::bordered().inner(area);
    if inner.height > snapshot.replicas.len() as u16 + 2 {
        let line = Rect {
            x: inner.x,
            y: inner.y + inner.height - 1,
            width: inner.width,
            height: 1,
        };
        frame.render_widget(
            Paragraph::new(text).style(Style::default().fg(Color::DarkGray)),
            line,
        );
    }
}

fn draw_messages(frame: &mut Frame, area: Rect, snapshot: &Snapshot) {
    let now = snapshot.tick;
    let rows = snapshot.messages.iter().map(|m| {
        let from = match m.from {
            Origin::Replica(id) => format!("R{id}"),
            Origin::Client(id) => format!("C{id}"),
        };
        let kind = message_kind(&m.message);
        let color = match kind {
            "Prepare" | "PrepareOk" | "Commit" => Color::White,
            "Request" => Color::Blue,
            "GetState" | "NewState" => Color::Cyan,
            "Recovery" | "RecoveryResponse" => Color::Yellow,
            _ => Color::Magenta,
        };
        Row::new(vec![
            Cell::from(format!("+{}", m.due_at.saturating_sub(now))),
            Cell::from(kind),
            Cell::from(format!("{from} → R{}", m.to)),
        ])
        .style(Style::default().fg(color))
    });
    let table = Table::new(
        rows,
        [
            Constraint::Length(6),
            Constraint::Length(17),
            Constraint::Min(9),
        ],
    )
    .header(
        Row::new(vec!["due", "kind", "path"]).style(Style::default().add_modifier(Modifier::BOLD)),
    )
    .block(Block::bordered().title(format!(" in flight: {} ", snapshot.messages.len())));
    frame.render_widget(table, area);
}

fn draw_events(frame: &mut Frame, area: Rect, app: &App) {
    let visible = area.height.saturating_sub(2) as usize;
    let lines: Vec<Line> = app
        .events
        .iter()
        .rev()
        .take(visible)
        .rev()
        .map(|e| {
            let style = if e.contains("FAILED") {
                Style::default().fg(Color::Red)
            } else if e.contains("PASSED") {
                Style::default().fg(Color::Green)
            } else if e.contains("inject") {
                Style::default().fg(Color::Yellow)
            } else {
                Style::default()
            };
            Line::styled(e.clone(), style)
        })
        .collect();
    frame.render_widget(
        Paragraph::new(lines)
            .wrap(Wrap { trim: false })
            .block(Block::bordered().title(" events ")),
        area,
    );
}
