# Observability — Run trace

## Purpose

Give the agency a structured, machine-readable memory of each loop run: every stage's
outcome (status, files, evidence, blockers, decisions) recorded as a trace entry that is
the single source of truth for resuming a partial run and auditing what happened. The
existing evidence-first gate and reviewer/QA blocking authority are unchanged.

## ADDED Requirements

### Requirement: Structured per-run trace log

The loop MUST record each closed stage into a structured, machine-readable per-run log
(trace), capturing the stage, change, status, files created/modified, evidence, blockers,
any `ASSUMED`/decisions, a run id, the next recommended step and a timestamp, so a run can
be resumed and audited without re-reading prose reports.

#### Scenario: Stage closure records a trace entry

- **WHEN** a stage closes with any status in the envelope vocabulary — done, blocked,
  failed, needs-context; approved/changes-requested for reviewer; pass/fail for qa
- **THEN** the loop appends a structured trace entry to the run log with the stage,
  change, status, files created/modified, evidence, blockers, decisions/ASSUMED, run id,
  next recommended step and timestamp, and the entry identifies its run and change so a
  resume can deterministically resolve the correct log

#### Scenario: Partial run is resumable from the log

- **WHEN** a run is interrupted mid-loop and later resumed
- **THEN** the run log identifies the last closed stage and the pending stage, so Hermes
  resumes from the exact point instead of re-inferring state from prose

### Requirement: Run summary from the log

The loop MUST be able to emit a run audit summary mechanically from the log — stages
closed, status each, blockers, ASSUMED decisions — without parsing prose reports.

#### Scenario: Audit summary is generated from the log

- **WHEN** an operator requests a run summary
- **THEN** a `bin/run-trace` (or equivalent) reads the run log and reports the stage list
  with status, blockers and ASSUMED decisions, from the structured log alone
