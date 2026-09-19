# Design — Run trace and park-and-resume

## Context

The agency produces prose reports but no structured memory of a run. Requirements that
shape the approach: evidence-first gate and reviewer/QA blocking authority are inviolable
the trace is additive; autonomous mode parks at non-trivial decisions and the park state
must be auditable and resumable; no new runtime dependencies beyond what the repo already
has (bash + OpenSpec CLI).

## Goals / Non-Goals

**Goals:**
- A structured, machine-readable per-run log that is the source of truth for resume/audit.
- A read-only `bin/run-trace` that emits the audit summary from the log.
- Park-and-resume in autonomous mode: the parked decision is a trace entry, not just prose.

**Non-Goals:**
- Waking the human (Discord/Telegram nudge) — a separate change, explicitly out of scope.
- Metrics/telemetry beyond what the trace already holds (cycles, blockers) — a later change.
- Changing the gate, the envelope, or who can block — untouched here.

## Decisions

### Decision: Trace lives in `reports/run-<run-id>.json` per run

- **What:** each run gets a JSON lines (or JSON array) trace file under the project's
  `reports/` dir, one append per stage closure.
- **Why:** `reports/` already exists in the project convention; JSON is machine-readable
  by `bin/run-trace` and humans; per-run id keeps concurrent independent runs separate
  (the multi-project model in `rules/project-boundaries.md`). The project is the source
  of truth, per `rules/project-boundaries.md` (project-specific state lives in the
  project, never in `~/.hermes/**`).
- **Discarded alternatives:** a single global `runs.ndjson` — rejected: mixes projects and
  makes project boundaries messy. Writing the trace to `~/.hermes/` (e.g. Obsidian vault)
  — rejected: violates the "project state lives in the project" rule, would detach the
  trace from the change and the `no-smoke-worktree` evidence it must be bound to. An
  optional read-only mirror/summary to the Obsidian vault is a separate change, not the
  source of truth.
- **Consequences:** a run id must be minted at preflight and threaded through the stages;
  `reports/` stays git-ignored or committed per project taste (the reader works either way).

### Decision: One trace schema, additive only

- **What:** the trace-entry field set maps 1:1 to what the envelope already carries
  (stage, status, filesCreated/filesModified, blockers, evidence, openQuestions/ASSUMED,
  next step) plus a timestamp and run id. No new data is invented.
- **Why:** the envelope (rules/orchestration.md) is the existing single source of truth;
  the trace is its structured mirror, so no agent has to produce anything it does not
  already report.
- **Discarded alternative:** a richer schema (cycle counts, durations, gate outputs in
  full) — rejected: not needed for resume/audit and grows the change.
- **Consequences:** the trace is trivially derivable from data the loop already has; the
  only new work is the append step per stage and the reader.

### Decision: `bin/run-trace` is read-only, bash + jq/awk

- **What:** a no-dependency reader (`bin/`) that parses the JSON log and prints the
  summary. Follows the repo's existing `bin/no-smoke-worktree` pattern.
- **Why:** the repo already ships bash tools in `bin/`; read-only tools can't corrupt
  state during a run.
- **Discarded alternative:** a full telemetry service — rejected (overkill).
- **Consequences:** the writer is the loop itself (Hermes appends entries); `run-trace`
  never writes the log.

## Risks / Trade-offs

- **Risk:** stages forget to append → the log is incomplete. **Mitigation:** the rule
  (`rules/observability.md`) and the resume path *read the log*, so a missing entry
  surfaces immediately on resume/audit.
- **Risk:** drift between envelope and trace schema. **Mitigation:** a single schema doc;
  the trace is derived from the envelope, not a parallel model.
- **Trade-off accepted:** per-run JSON rather than global NDJSON — cleaner project
  boundaries at the cost of one id per run.
