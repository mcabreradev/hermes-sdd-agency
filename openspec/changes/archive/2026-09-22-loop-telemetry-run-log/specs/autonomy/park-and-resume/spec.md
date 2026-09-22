# Autonomy — Park and resume

## Purpose

In autonomous mode, when the loop stops at a non-trivial decision, record that pause as an
auditable, resumable trace state instead of a passive prose note — so the run's parked
position and the decision needed are machine-readable and the run can resume from the exact
stage once the decision is resolved.

## ADDED Requirements

### Requirement: Park the run auditably on a non-trivial decision

In autonomous mode the loop MUST record, on a non-trivial decision that stops a stage, a
trace entry marking the run as "parked — decision needed" with the exact stage, so the
state is auditable and resumable.

#### Scenario: Non-trivial decision parks the run auditably

- **WHEN** autonomous mode stops at a non-trivial decision (per `autonomous-change.md`)
- **THEN** the loop writes a "parked — decision needed" trace entry naming the stage and
  the decision, so the state is auditable and resumable

### Requirement: Resume from the parked stage using the trace

The resume workflow (continue mode) MUST detect where a run stopped by reading the run log's
last parked/closed entry, and continue from that exact stage once the decision is settled —
rather than re-inferring the point from prose or from task checkboxes alone.

#### Scenario: Resume resumes from the parked stage

- **WHEN** the human resolves the decision and the run resumes
- **THEN** the resume workflow reads the run log's last parked/closed entry, reports the
  exact stage and decision to resume from, and continues from that stage
