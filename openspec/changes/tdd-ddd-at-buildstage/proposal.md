## Why

The agency enforces spec-driven requirements but leaves the *implementation method* undirected: the builder writes code and tests in any order. That opens the door to trial-and-error loops — write code, discover a mismatch, patch, re-discover — instead of pinning behavior with a test first. It also has no guidance for modeling the domain when the business rules justify it, so entities and invariants tend to live implicitly in code instead of being shaped deliberately.

## What Changes

- The builder's default implementation method becomes **test-driven (TDD)** — a hard
  rule, not a judgment call: for every piece of code that carries business logic
  (backends, business logic, API endpoints, data transforms, bug fixes) the builder
  writes a failing test first, watches it fail for the right reason, writes the minimal
  code that makes it pass, then refactors.
- The rule is a **fixed rule, not a dogma**: the builder always applies test-first to
  behavior-bearing work; it declares `not applicable` only for code with no behavior to
  prove (configuration, generated code, boilerplate glue, wiring, throwaway prototypes)
  and records the reason in the report. There is no agent discretion to skip test-first
  for logic that changes behavior.
- **Domain-Driven Design (DDD)** is introduced as an available technique the **architect**
  applies when the change's domain merits it (entities, aggregates, ubiquitous language,
  bounded contexts), and the builder follows the resulting model.
- The decision of *when DDD fits* is made by the architect guided by explicit criteria;
  TDD, by contrast, does not depend on the agent's judgment.

## Capabilities

### New Capabilities

- `methodology/tdd-at-buildstage`: the builder implements behavior-bearing work test-first (RED→GREEN→REFACTOR) as a hard rule, with `not applicable` declared only for behavior-free code, so regressions are stopped before they ship.
- `methodology/ddd-when-appropriate`: the architect models the domain with DDD when it is appropriate, the builder follows that model, and only when the domain merits it.

## Impact

- `rules/testing.md` — add TDD as a hard rule and the RED→GREEN→REFACTOR cycle, plus the declared `not applicable` case.
- `agents/builder.md` — add TDD to the persona/method section and to the protocol.
- `workflows/implement-change.md` — state that the builder implements TDD-first by hard rule for behavior-bearing work.
- `rules/coding.md` — mention DDD model adherence once the architect chose it.
- `agents/architect.md` — add DDD as a model-shaping technique applied when appropriate.
- Documentation: `README.md` (complementary skills / loop description), `docs/sdd-feature-lifecycle.md`.
- No runtime code, no dependencies, no project data. This is a process-only change to the agency itself.
