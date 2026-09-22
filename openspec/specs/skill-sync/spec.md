# Orchestration skill — public mirror parity

## Purpose

The public `hermes-sdd-orchestration` skill MUST mirror the live `~/.hermes` skill
exactly, so the skill a reader loads teaches the same process the machine runs — and
the v2 process rules (derived collision verdict, blocker classes, trust vocabulary) have
a home that is versioned with the rules they describe.

## Requirements

### Requirement: The mirror equals the live skill

The repo copy of `hermes-sdd-orchestration` MUST contain the full live content — the
SKILL.md body including every pitfall, and every `references/*.md` — with no content
unique to the repo left behind.

#### Scenario: Mirror carries the live pitfalls

- **WHEN** the repo SKILL.md is compared against the live `~/.hermes` copy after sync
- **THEN** no live line is absent from the repo copy

#### Scenario: Missing references are restored

- **WHEN** the references available in live (incl. live-only `postgres-migration-pitfalls`
  and `repo-gate-flake`) are listed against the repo skill dir
- **THEN** every live reference exists in the repo copy

### Requirement: The skill teaches the derived collision verdict

The skill's parallelization section MUST teach `bin/change-collision` as the decision
mechanism: `parallelizable` / `collision` / `cannot assess`, the high-risk families,
and that `cannot assess` never reads as `parallelizable`.

#### Scenario: Old union-of-paths method is gone

- **WHEN** a fresh orchestrator reads the skill's parallelization section
- **THEN** it finds the three verdicts and the bin, not the union-of-paths rule

### Requirement: The skill teaches blocker classes and trust vocabulary

The skill MUST teach the three blocker classes (`retryable` / `technical` / `decision`
and their responses) and the four trust levels (`verified` / `partially_verified` /
`self_reported` / `blocked`), including the hard gate: review/QA/release never close on
`self_reported`.

#### Scenario: Classes and levels are in the skill

- **WHEN** the skill body is searched for the classes and the levels
- **THEN** all are present with their response rules
