## Why

The agency orchestrates the SDD loop and returns autonomous results, but it has **no
structured, machine-readable memory of a run**. Every stage's outcome lives as prose in
proposal/design/final reports, not as a structured record. Consequences today:

- A run that dies mid-loop (crash, timeout, session lost) leaves no exact trace of which
  stage closed, with what evidence, and what was pending — so resuming means re-reading
  prose reports and re-inferring state.
- There is no way to audit a run mechanically: which stage ran, what blocked, what was
  `ASSUMED`, which gates were green.
- `autonomous-change.md` parks at a non-trivial decision and waits passively — but the
  human is not woken, so autonomy degrades into a stall the user only notices on return.

The ask: the loop should **orchestrate and return results autonomously and auditably** —
easy to do, well done. Add a lightweight structured run log the stages write into, that
is the single source of truth for resuming and auditing a run.

## What Changes

- Each stage of the loop records a **structured trace entry** (stage, status, files
  created/modified, evidence, blockers, decisions/ASSUMED, run id, next recommended step,
  timestamp) appended to a per-run log file, instead of only writing prose reports.
- The run log is the **single source of truth** for resuming a partial run and for
  auditing what happened: a `bin/run-trace` command reads the log and emits a summary
  (stages closed, status, blockers, ASSUMED decisions) without parsing prose. Run-level
  metrics such as per-cycle counts are out of scope and not part of the summary.
- On a non-trivial decision in autonomous mode, the loop writes the decision into the run
  log **and emits an explicit "run parked, decision needed" record** so the state is
  auditable and resumable (the mechanism that *wakes the human* remains a separate
  channel decision, out of scope here).
- Nothing about the existing envelope, gate, evidence-before-advance, or reviewer/QA
  blocking authority changes: the run log is additive, a trace of the same events the
  loop already produces.

## Capabilities

### New Capabilities

- `observability/run-trace`: the loop records each stage's outcome into a structured
  per-run log that is machine-readable, resumable and auditable, without changing the
  evidence-first gate or the blocking authority.
- `autonomy/park-and-resume`: autonomous mode records a "parked — decision needed"
  trace entry at a non-trivial decision and can resume from the exact stage, instead of
  waiting passively with only a prose note.

## Impact

- `workflows/` — each stage workflow (`idea-to-openspec` … `release-change`) records its
  trace entry on closure and on blocked/parked.
- `workflows/autonomous-change.md` — records the "parked" entry at a non-trivial decision.
- `workflows/continue-change.md` — the resume path reads the run log's last parked/closed
  entry to determine the exact stage to resume from (trace as source of truth, checkboxes as
  cross-check).
- New `rules/observability.md` — the trace schema and the "log is source of truth for
  resume/audit" rule.
- `rules/orchestration.md` — the mandatory envelope gains a `runId` field threaded through
  every stage brief/entry of a run.
- `.gitignore` — add `reports/run-*.jsonl` so the growing trace never breaks the
  `no-smoke-worktree` release fingerprint (`rules/quality.md`).
- New `bin/run-trace` — reads the log and emits the run summary.
- `templates/final-report.md` — the final report cites/logs the run trace.
- Documentation: `README.md`, `docs/sdd-feature-lifecycle.md`, `docs/FAQ.md`.
- No runtime code beyond a small read-only `bin/run-trace`; no new dependencies.
- **Scope boundary:** the mechanism that *wakes the human* (Discord/Telegram nudge) is
  explicitly out of scope — it is a separate change. This change only makes the parked
  state auditable and resumable.
- **Scope boundary:** the **Obsidian vault mirror** — an optional read-only summary of a
  run's trace emitted into the Obsidian vault for cross-project browsing — is also out of
  scope. It is a separate change. The project is the single source of truth
  (`rules/project-boundaries.md`); the vault mirror, when it lands, reads it, never writes
  it back.
