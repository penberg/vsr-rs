# `vsr-rs`

## Coding Style

- Code reads from top to bottom: a function comes before the helpers it
  calls. Put a new helper right after its caller, not above it.
- Keep comments to an absolute minimum. Say only what the code cannot, in
  one line if possible; never restate the code or narrate its history.
- Use the paper's vocabulary, not Raft's. Name things after the message
  they handle (`DoViewChange`, `do_view_change_from`), never "vote".

## Testing

- If you reproduce a bug with simulator, write an integration test case as
  regression test in `tests` directory. In the commit, record the seed and the
  git commit so we can go back in time to reproduce the issues.
- A regression test's doc comment names the issue it covers by full URL:
  `/// Regression test case for https://github.com/penberg/vsr-rs/issues/N`.
