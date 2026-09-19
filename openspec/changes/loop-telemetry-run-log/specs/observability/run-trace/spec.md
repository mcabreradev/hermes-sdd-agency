# Observability — Run trace

## Purpose

Give the agency a structured, machine-readable memory of each loop run: every stage's
outcome (status, files, evidence, blockers, decisions) recorded as a trace entry that is
the single source of truth for resuming a partial run and auditing what happened. The
existing evidence-first gate and reviewer/QA blocking authority are unchanged.

## ADDED Requirements

### Requirement: Structured per-run trace log

The loop MUST record each closed stage into a structured, machine-readable per-run log
(trace), capturing the stage, status, files created/modified, evidence, blockers, any
`ASSUMED`/decisions, and a timestamp, so a run can be resumed and audited without re-reading
prose reports.

#### Scenario: Stage closure records a trace entry

- **WHEN** a stage closes (done, blocked, failed or needs-context)
- **THEN** the loop appends a structured trace entry to the run log with the stage, status,
  files created/modified, evidence, blockers, decisions/ASSUMED and timestamp

#### Scenario: Partial run is resumable from the log

- **WHEN** a run is interrupted mid-loop and later resumed
- **THEN** the run log identifies the last closed stage and the pending stage, so Hermes
  resumes from the exact point instead of re-inferring state from prose

### Requirement: Run summary from the log

The loop MUST be able to emit a run audit summary mechanically from the log — stages
closed, status each, blockers, cycles consumed, ASSUMED decisions — without parsing
prose reports.

#### Scenario: Audit summary is generated from the log

- **WHEN** an operator requests a run summary
- **THEN** a `bin/run-trace` (or equivalent) reads the run log and reports the stage list
  with status, blockers, cycles and ASSUMED decisions, from the structured log alone

### Requirement: Park-and-resume in autonomous mode

In autonomous mode the loop MUST record, on a non-trivial decision that stops a stage, a
trace entry marking the run as "parked — decision needed" with the exact stage, and be
able to resume from that stage once the decision is made.

#### Scenario: Non-trivial decision parks the run auditably

- **WHEN** autonomous mode stops at a non-trivial decision (per `autonomous-change.md`)
- **THEN** the loop writes a "parked — decision needed" trace entry naming the stage and
  the decision, so the state is auditable and resumable

#### Scenario: Resume resumes from the parked stage

- **WHEN** the human resolves the decision and the run resumes
- **THEN** the run continues from the exact stage recorded as parked, using the trace as
  the source of truth for where to pick up
