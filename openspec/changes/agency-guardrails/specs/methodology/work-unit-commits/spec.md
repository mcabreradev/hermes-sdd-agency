## Purpose

Direct how the build stage closes work: each coherent unit of it lands as its own commit with
its tests and docs, and a change whose authored size outgrows a single reviewable diff is
delivered as chained/stacked pull requests instead of one unreviewable one. Pure process
guidance that applies to any project the agency runs.

## ADDED Requirements

### Requirement: One commit per coherent work unit

The `builder` MUST close each coherent work unit of a change with its own commit, carrying the
unit's behavior together with its tests and documentation, using a Conventional Commit message.
A work unit is the smallest coherent behavior plus the tests and docs that make it verifiable —
not a checkpoint, not every edited file, not one commit for the whole change unless the change
is itself a single unit.

#### Scenario: A multi-unit change is committed unit by unit

- **WHEN** the builder implements a change that comprises more than one coherent behavior
- **THEN** each unit lands as its own commit with its tests and documentation, and the commit
  identity of each unit is recorded in the change's progress evidence

#### Scenario: The work is a single coherent unit

- **WHEN** the change implements one indivisible behavior with no meaningful internal boundary
- **THEN** the builder commits once for that unit, with its tests and docs, and does not split
  it artificially to satisfy a granularity ritual

### Requirement: Authored-lines budget is an advisory heuristic

The agency MUST declare an **advisory** planning heuristic of about 400 authored changed lines
(additions plus deletions, generated files excluded) per reviewable delivery, and MUST NOT
present it as a hard cap, an automatic stop, a trigger for mandatory rework, or an acceptance
criterion. The heuristic MUST NOT justify deleting spaces, blank lines or comments for cosmetic
savings, omitting or weakening tests, minifying, adding gratuitous abstractions, or splitting a
unit artificially.

#### Scenario: A unit naturally exceeds the heuristic

- **WHEN** the correct, clear implementation of a work unit exceeds about 400 authored changed
  lines without an artificial way to reduce it
- **THEN** the builder states briefly why it exceeds the heuristic and continues, and no
  size-only rework loop is required

#### Scenario: A change is forecast to exceed the heuristic

- **WHEN** the task list indicates a change will exceed about 400 authored changed lines before
  delivery
- **THEN** the agency applies a delivery strategy — chained/stacked pull requests — so each
  delivered increment stays reviewable, and records the slice boundaries (which commits each
  pull request holds) in the change's artifacts

### Requirement: Delivery strategy is chosen from the budget, not from momentum

For a change exceeding the advisory budget, the agency MUST choose one delivery strategy
**before** opening the next pull request, and MUST record it: `single-pr` (one pull request,
explicitly accepted as large), `chained-pr` (stacked commits delivered as a chain of pull
requests, each based on the previous slice), or `split-change` (the excess is cut into a
separate OpenSpec change). The strategy MUST be recorded in the change's design or tasks so the
delivery shape is a decision on record rather than an accident of how many commits accumulated.

#### Scenario: A growing change crosses the budget

- **WHEN** the running count of authored changed lines for a multi-unit change crosses the
  advisory budget before the whole change is delivered
- **THEN** the agency records the chosen delivery strategy in the change's artifacts and, when
  it is `chained-pr`, delivers each slice as its own pull request based on the previous slice

#### Scenario: The change is cut instead of chained

- **WHEN** the excess scope turns out to be independent work rather than a slice of the same
  behavior
- **THEN** the agency stops, records it as `split-change`, and proposes a separate OpenSpec
  change per `rules/openspec.md` — the excess is never absorbed silently into the current one
