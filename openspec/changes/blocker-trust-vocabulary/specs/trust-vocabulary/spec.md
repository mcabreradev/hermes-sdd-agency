# Blocker classification — Trust vocabulary

## Purpose

Classify every blocker as `retryable` | `technical` | `decision` so the workflow's
response to a blocked stage is selected by a declared rule instead of by re-reading the
situation, and record the trust depth of every validated outcome so no critical stage can
close on a self-reported claim.

## ADDED Requirements

### Requirement: Blocker classes select the response

The loop MUST carry, on every blocker, a `class` from `retryable` | `technical` |
`decision` that selects the allowed response: `retryable` → bounded retry (the retry
table in `rules/orchestration.md`); `technical` → no circular retry — another agent,
back-a-stage, or stop; `decision` → the human decides, with options + recommendation +
impact. An uncategorized blocker is treated as `class: decision`: the human is never
skipped by omission.

#### Scenario: A failed test blocks with class retryable

- **WHEN** a stage is blocked by a defect the retry rules allow retrying (e.g. a failed
  test from an implementation error)
- **THEN** the blocker is classified `retryable` and the bounded retry runs, and the
  retry consumes an iteration from the stage's limit

#### Scenario: A spec contradiction blocks with class technical

- **WHEN** a stage is blocked because the defect contradicts the spec or the design
- **THEN** the blocker is classified `technical` and the workflow goes back a stage or
  stops — never a circular retry of the same brief

#### Scenario: A public-contract change blocks with class decision

- **WHEN** a stage is blocked by a decision class: data-model change, public contract,
  architecture choice, cost, or business rule
- **THEN** the blocker is classified `decision` and raised to the human (options +
  recommendation + impact), and no work that depends on it advances while unanswered

#### Scenario: An unclassified blocker defaults to decision

- **WHEN** a blocker is recorded without a class
- **THEN** the workflow treats it as `class: decision` — reported to the human, never
  silently retried or skipped

### Requirement: Trust vocabulary on validated outcomes

The loop MUST assign, after Hermes validates an agent's reply in the repo, a trust level
from `verified` | `partially_verified` | `self_reported` | `blocked`, where `verified`
means Hermes re-ran the claim in the repo, `partially_verified` means only part of the
claim was re-verified (gap declared), `self_reported` means the outcome rests on the
agent's report alone, and `blocked` means a blocker is open. The assignment is made by
Hermes — an agent never self-declares its own trust level.

#### Scenario: Hermes re-runs the claimed gate and closes verified

- **WHEN** an agent returns `done` with evidence and Hermes re-runs the claimed command
  in the repo with the same result
- **THEN** the outcome is recorded as `verified`

#### Scenario: A reply without repo re-verification stays self_reported

- **WHEN** an agent returns `done` and Hermes has not re-run the claim in the repo (only
  the report exists)
- **THEN** the outcome is recorded as `self_reported`, and the critical-stage rule below
  applies

#### Scenario: A blocker open records blocked

- **WHEN** a stage ends with an open blocker
- **THEN** the outcome is recorded as `blocked` and no dependent stage advances

### Requirement: Critical stages never close on self_reported

The review, QA and release stages MUST NOT close on `self_reported` alone: a critical
stage closes only when Hermes has re-verified the decisive claim in the repo (`verified`,
or `partially_verified` with the unverified part declared). A `self_reported` claim is
never the last word for a critical gate.

#### Scenario: Release attempts to close on a self-reported gate

- **WHEN** the release stage would close with an outcome recorded `self_reported`
- **THEN** the workflow refuses the closure and requires Hermes to re-verify the
  decisive claim in the repo first (or to declare the part it cannot verify)
