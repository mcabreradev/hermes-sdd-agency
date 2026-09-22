# Design — Run trace and park-and-resume

## Context

The agency produces prose reports but no structured memory of a run. Requirements that
shape the approach: evidence-first gate and reviewer/QA blocking authority are inviolable;
the trace is additive (mirrors what the envelope already carries, inventoried in
`rules/orchestration.md`, without inventing new data); autonomous mode parks at non-trivial
decisions and the park state must be auditable and resumable; no new runtime dependencies
beyond what the repo already has (bash + OpenSpec CLI).

## Goals / Non-Goals

**Goals:**
- A structured, machine-readable per-run log that is the source of truth for resume/audit.
- A read-only `bin/run-trace` that emits the audit summary from the log.
- Park-and-resume in autonomous mode: the parked decision is a trace entry, not just prose,
  and the resume workflow reads the log to pick up where it stopped.

**Non-Goals:**
- Waking the human (Discord/Telegram nudge) — a separate change, explicitly out of scope.
- Run-level **metrics** (cycle counts, per-cycle durations, gate outputs in full) — a later
  change. The trace has **no cycle field** and the summary does **not** report cycles;
  resumability and auditability do not need them. Removed from the spec to avoid a
  contradiction (see Decision: One schema).
- Changing the gate, the envelope, or who can block — untouched here. (The envelope gains a
  run id; its shape and authority are unchanged.)

## Decisions

### Decision: Trace lives in `reports/run-<run-id>.json` per run (NDJSON)

- **What:** each run gets a single file `reports/run-<run-id>.jsonl` in **NDJSON** — one
  JSON object per line, one append per stage closure (append-friendly).
- **Why:** `reports/` already exists in the project convention; NDJSON is machine-readable
  by `bin/run-trace` and humans, and append-safe (a plain `>>` is atomic enough under
  `set -o append`); per-run id keeps concurrent independent runs separate (the multi-project
  model in `rules/project-boundaries.md`). The project is the source of truth, per
  `rules/project-boundaries.md` (project-specific state lives in the project, never in
  `~/.hermes/**`).
- **Discarded alternatives:** a single global NDJSON — rejected: mixes projects and makes
  project boundaries messy. Writing the trace to `~/.hermes/` (e.g. Obsidian vault) —
  rejected: violates the "project state lives in the project" rule, would detach the trace
  from the change and the `no-smoke-worktree` evidence it must be bound to. An optional
  read-only mirror/summary to the Obsidian vault is a separate change, not the source of
  truth. Plain JSON array — rejected: not append-friendly; rewriting the whole file on each
  stage risks corruption and diff noise.
- **Consequences:** a run id is minted at preflight (below); the reader/`bin/run-trace`
  parses a stream of JSON lines. The run id is **mandatory** in the envelope for every
  stage brief/entry of a run — not optional — so the threading is enforceable.

### Decision: Run id is a short ISO timestamp, minted at preflight

- **What:** the run id is `run-<UTC ISO-8601 compact, e.g. 20260919T051200Z>`; Hermes mints
  it once at the workflow's preflight and threads it through every stage brief and every
  trace entry of that run.
- **Why:** unique per run for concurrency (the multi-project/per-project model); sortable
  and human-readable; needs no state beyond the clock. The id lives in the mandatory
  envelope as a new optional field so every stage's brief carries it (see Decision: Schema
  mirrors the envelope).
- **Discarded alternative:** a random UUID — rejected: not human-sortable for browsing
  history; the timestamp is enough for per-run uniqueness in practice.
- **Consequences:** the envelope gains a `runId` field; `rules/orchestration.md` is updated
  so the id is present on every brief/entry of a run. The workflow that mints it is the
  same preflight that resolves root, so every later stage inherits it from the brief.

### Decision: One trace schema, additive only, no cycle field

- **What:** the trace-entry field set maps 1:1 to what the envelope already carries —
  stage, status, filesCreated/filesModified, blockers, evidence, openQuestions/ASSUMED,
  nextRecommendedStep — plus `runId` and `timestamp`. No new data is invented; **notably
  there is no cycle/duration field**: the summary reports stages, blockers and ASSUMED
  only, not cycles.
- **Why:** the envelope is the existing single source of truth; the trace is its structured
  mirror, so no agent has to produce anything it does not already report. Cycle counts and
  durations are metrics, deliberately out of scope (Non-Goals).
- **Discarded alternative:** a richer schema (cycle counts, durations, full gate outputs) —
  rejected: not needed for resume/audit, grows the change, and creates the spec↔design
  contradiction that a reviewer flagged.
- **Consequences:** the trace is trivially derivable from data the loop already has; the
  only new work is the append step per stage, the run id in the envelope, and the reader.

### Decision: `bin/run-trace` is read-only, bash + jq

- **What:** a no-dependency reader (`bin/`) that parses the NDJSON log and prints the
  summary (stages, status, blockers, ASSUMED). Follows the repo's existing
  `bin/no-smoke-worktree` pattern.
- **Why:** the repo already ships bash tools in `bin/`; read-only tools can't corrupt
  state during a run. `jq` is the declared tool for NDJSON parsing in this change.
- **Discarded alternative:** a full telemetry service — rejected (overkill). bash `awk`
  only — rejected: `jq` is portable, already the JSON tooling norm, and far less error-prone
  for structured output.
- **Consequences:** the writer is the loop itself (Hermes appends entries); `run-trace`
  never writes the log.

### Decision: `reports/run-*.jsonl` is gitignored

- **What:** add `reports/run-*.jsonl` to the project's `.gitignore` so the trace (which
  grows as the run progresses) never enters the working tree included by
  `bin/no-smoke-worktree` (a `git add -A`-based content fingerprint).
- **Why:** `no-smoke-worktree` fingerprints the *working tree* including untracked files;
  `git add -A` honors `.gitignore`. If the trace were tracked/untracked-and-unignored, the
  fingerprint taken by reviewer (N entries) and by `release-change` (N+3 entries) would never
  match, and `rules/quality.md` treats that mismatch as a **blocker** — breaking every
  release. Gitignoring the run log stabilizes the fingerprint and keeps the diff clean.
- **Discarded alternative:** committing the trace — rejected: a mutating log in the diff
  makes every fingerprint and review non-reproducible. Leaving the decision to each project
  — rejected: that is exactly how the release-breaking mismatch slips in.
- **Consequences:** the trace is not versioned; the audit summary it powers is emitted on
  demand by `bin/run-trace`, and a run's trace can be captured/exported at close if a
  project wants it. This interaction is documented in Risks.

## Wiring and resume (per the reviewer findings)

- **Append trigger:** each stage workflow records its trace entry **at closure**, from the
  same data it already returns in the envelope; the run id comes from the brief.
- **Resume (continue mode):** `workflows/continue-change.md` currently detects the pending
  stage from `openspec list/status/apply` (`- [x]` checkboxes) and `git diff`. With the
  trace, it **additionally reads the run log's last parked/closed entry** (`bin/run-trace` or
  the raw NDJSON) to confirm/report the exact stage and decision to resume from. The
  checkbox state remains a cross-check; the trace is the authoritative record of where a
  run stopped.
- **Identifying the right log on resume:** when several `reports/run-*.jsonl` exist,
  `continue-change.md` resolves the correct one as the **most recent** run log whose last
  entry is a `parked` / closed entry for the active change being resumed. Each trace entry
  also carries the change name, so a log can be filtered to the active change deterministically.
  This is a stated rule (not left to the resume implementation to guess).
- **Parked entry:** `autonomous-change.md` writes a `"parked"` trace entry (status
  `needs-context`, decision in `blockers`/`openQuestions`, stage named) at a non-trivial
  decision; the resume path picks up from that entry.

## Risks / Trade-offs

- **Risk:** stages forget to append → the log is incomplete. **Mitigation:** the rule
  (`rules/observability.md`) and the resume path *read the log*, so a missing entry
  surfaces immediately on resume/audit; the reviewer's verifies exercise the append, not a
  prose mention.
- **Risk:** drift between envelope and trace schema. **Mitigation:** a single schema doc;
  the trace is derived from the envelope, not a parallel model. The run id is threaded, not
  re-invented per stage.
- **Risk:** a gitignored trace is invisible in CI/review. **Mitigation:** the summary is
  emitted on demand (`bin/run-trace`); nothing about the gate or review depends on the raw
  log being in the tree — the change keeps the fingerprint stable by design.
- **Trade-off accepted:** per-run NDJSON rather than a global log — cleaner project
  boundaries at the cost of one id per run. Trace not versioned — accepted because the audit
  summary it powers is reproducible on demand and the fingerprint stability is worth more
  than versioning a mutating log.

## Delivery strategy (recorded per rules/coding.md)

Measured `git diff --numstat main...HEAD`: **422 authored lines**, over the advisory
~400-line budget for one reviewable delivery. Strategy: **`single-pr`**.

- **Why `single-pr`:** the excess is mechanical — one short rule, one 77-line reader
  bin, one 97-line fixture suite, and 8 near-identical one-block workflow inserts
  (~15 added lines each). The diff is one behavior (the run trace); reviewers read it
  as a whole and the fixture suite pins its contract.
- **Why not `chained-pr`:** there are no independent slices — the bin is useless
  without the rule, the fixtures test the bin, and the workflows consume both. A chain
  would split one coherent change into reviewable stubs.
- **Why not `split-change`:** every piece is the same capability
  (`observability/run-trace` + `autonomy/park-and-resume`); nothing here is
  independent work that deserves its own OpenSpec change.
