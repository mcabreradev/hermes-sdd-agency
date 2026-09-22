# Rule: Observability — per-run trace log

The loop records a structured, machine-readable trace of every run: one NDJSON file
per run (`reports/<runId>.jsonl`), one JSON line appended at each stage closure and
at a parked stop in autonomous mode. The trace is the **single source of truth** for
resuming a partial run and for auditing what happened. Reports stay human artifacts;
the trace is the machine record.

## Trace entry schema

Each entry maps 1:1 to the mandatory envelope (`rules/orchestration.md`,
"Mandatory output contract") plus `runId` and `timestamp`. No field invents data the
envelope does not carry.

| Field | Content |
|---|---|
| `timestamp` | ISO-8601 UTC of the append |
| `runId` | the run id threaded through every brief of the run (`run-<UTC ISO-8601 compact>`, e.g. `run-20260919T051200Z`), minted once at the workflow's preflight |
| `change` | the OpenSpec change name this entry belongs to |
| `stage` | the closing stage (`idea-to-openspec` … `release-change`, or `autonomous-change` for a parked stop) |
| `kind` | `closed` for a stage closure · `parked` for a non-trivial autonomous stop |
| `status` | the envelope status vocabulary: `done` `blocked` `failed` `needs-context`; `approved` `changes-requested` (reviewer); `pass` `fail` (qa) |
| `filesCreated` / `filesModified` | absolute paths (or `[]`) |
| `evidence` | command + output, or `path:line` |
| `blockers` | what stops the run and the exact decision needed (or `[]`) |
| `decisions` | recorded decisions and `ASSUMED` items (or `[]`) |
| `nextRecommendedStep` | a proposal only; Hermes decides the transition |

## Properties of the log

- **Additive.** The trace only mirrors events the loop already produces. It never
  changes the evidence-first gate, the reviewer/QA blocking authority, or the
  envelope's shape — the envelope merely gains `runId`.
- **Append-only, per run, per project.** One file per run keeps concurrent runs
  separate and project state in the project (`rules/project-boundaries.md`). A plain
  append (`>>`, `set -o append`) is the write path.
- **Not versioned.** `reports/run-*.jsonl` is gitignored — a growing trace must never
  break the `no-smoke-worktree` content fingerprint (`rules/quality.md`). The audit
  summary it powers is emitted on demand by `bin/run-trace`; a run's trace is
  captured/exported at close only if the project wants it.
- **Resume source of truth.** `workflows/continue-change.md` resolves the run's last
  `parked`/`closed` entry for the change being resumed; task checkboxes are a
  cross-check, never the authoritative stop point.
- **Parked stops are trace entries.** In autonomous mode a non-trivial decision
  writes a `parked` entry (`kind: parked`, `status: needs-context`, the decision in
  `blockers`/`decisions`) so the paused state is auditable and resumable.

## Reading the log

`bin/run-trace` parses the NDJSON and emits the audit summary (stages, status,
blockers, ASSUMED), from the structured log alone — never from prose. Summary
metrics beyond stage/status/blockers/decisions (cycle counts, durations, full gate
outputs) are out of scope here; they are a later change.
