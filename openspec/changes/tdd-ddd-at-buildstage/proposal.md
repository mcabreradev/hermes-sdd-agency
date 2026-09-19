## Why

The agency enforces spec-driven requirements but leaves the *implementation method* undirected: the builder writes code and tests in any order. That opens the door to trial-and-error loops — write code, discover a mismatch, patch, re-discover — instead of pinning behavior with a test first. It also has no guidance for modeling the domain when the business rules justify it, so entities and invariants tend to live implicitly in code instead of being shaped deliberately.

## What Changes

- The builder's default implementation method becomes **test-driven (TDD)**: for every behavior-bearing change it writes a failing test first, watches it fail for the right reason, writes the minimal code that makes it pass, then refactors. Skipping TDD is an explicit, documented exception, never a silent default.
- The method is a **default, not a dogma**: the builder applies TDD by default but deliberately omits it for UI glue, generated code, config/transpilation or throwaway prototypes — and records each omission with its reason in the report.
- **Domain-Driven Design (DDD)** is introduced as an available technique the **architect** applies when the change's domain merits it (entities, aggregates, ubiquitous language, bounded contexts), and the builder follows the resulting model.
- The decision of *when TDD fits and when to avoid it* is made by the agent at build time, guided by explicit criteria — not left undefined, not made always-on without judgment.

## Capabilities

### New Capabilities

- `methodology/tdd-at-buildstage`: the builder implements behavior-bearing work test-first (RED→GREEN→REFACTOR) by default, with explicit documented exceptions, so the loop avoids trial-and-error.
- `methodology/ddd-when-appropriate`: the architect models the domain with DDD when it is appropriate, the builder follows that model, and only when the domain merits it.

## Impact

- `rules/testing.md` — add TDD as the default origin and the RED→GREEN→REFACTOR cycle, plus the explicit-omission rule.
- `agents/builder.md` — add TDD to the persona/method section and to the protocol.
- `workflows/implement-change.md` — state that the builder implements TDD-first by default.
- `rules/coding.md` — mention DDD model adherence once the architect chose it.
- `agents/architect.md` — add DDD as a model-shaping technique applied when appropriate.
- Documentation: `README.md` (complementary skills / loop description), `docs/sdd-feature-lifecycle.md`.
- No runtime code, no dependencies, no project data. This is a process-only change to the agency itself.
