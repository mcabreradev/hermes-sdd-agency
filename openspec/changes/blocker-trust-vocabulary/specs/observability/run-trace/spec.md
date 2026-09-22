# Blocker classification — Trust vocabulary

## Purpose

Classify blockers and record trust depth on every trace entry, so the run log can be an
honest audit surface: it tells whether a pass was re-verified (`verified`), only partly
verified (`partially_verified`, gap declared), self-reported, or blocked.

## ADDED Requirements

### Requirement: Trace entries carry class and trust

The trace-entry schema MUST record, on every entry, the blocker `class` and the trust
level of the outcome, so a run can be audited and resumed with the same depth of
validation Hermes actually performed.

#### Scenario: A traced closure records its blocker class

- **WHEN** a stage closes blocked and the run is traced
- **THEN** the trace entry records the blocker `class` (`retryable` | `technical` |
  `decision`) next to the blocker itself

#### Scenario: A traced closure records its trust level

- **WHEN** a stage closes and the run is traced
- **THEN** the trace entry records the trust level (`verified` |
  `partially_verified` | `self_reported` | `blocked`) of the validated outcome

#### Scenario: The audit summary surfaces class and trust

- **WHEN** an operator requests a run summary
- **THEN** `bin/run-trace` reports the blocker class and the trust level of each entry
  from the structured log alone
