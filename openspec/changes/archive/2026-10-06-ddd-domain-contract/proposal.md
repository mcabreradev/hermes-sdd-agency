## Why

The agency already names Domain-Driven Design as a technique the architect "applies when the domain merits it", but nothing defines what merits it, nothing says what the model looks like, and nothing owns it after the architecture stage. Three failures follow:

- **The trigger is a judgment call.** Two runs over the same change can decide differently, and neither decision is recorded — so the choice cannot be contested, reproduced or reviewed.
- **The model has no home.** The `domain-modeling` skill produces a `CONTEXT.md` glossary, and the agency never mentions it: not in `templates/architecture.md`, not in the architecture stage's deliverables, not in any checklist. When a change resolves what a business term means, that resolution stays in a conversation instead of the repo.
- **Nothing fails when the model is ignored.** `rules/coding.md` requires the builder to follow the architect's model, but no review step checks that the terms are used as defined. The claim is prose, and prose goes stale without anything noticing — the exact defect the agency's own `context-architecture` skill names.

The result is a methodology that reads as adopted and behaves as optional: DDD is invoked when someone remembers it, in whatever shape that run invents.

## What Changes

- **The DDD trigger becomes explicit signals, not judgment.** The architect evaluates a fixed list of objective signals (invariants that must hold, an entity with identity and lifecycle, a new or redefined term in the project's vocabulary, a boundary between business capabilities, vocabulary drift already present) and models the domain when any of them fires. When none fires, it records which signals it checked — a falsifiable skip instead of an unstated one.
- **The ubiquitous language becomes a project artifact.** `CONTEXT.md` (the glossary format of the `domain-modeling` method: term, tight definition, `_Avoid_` synonyms) is updated by the same change that resolves a term, in the project, never in global memory.
- **The domain model becomes a required section of the change's design** when the trigger fires: vocabulary resolution, entities/aggregates with their invariants, and context boundaries. The architecture template gains the section and the filling rules that make it non-empty.
- **The reviewer verifies the domain contract.** Four checks enter the reviewer's checklist: the architect's trigger verdict against the real diff, the terms used in the diff against the glossary (one term, one meaning), the stated invariants against the tests that must fail when violated, and the code against the declared model. Each carries its severity.
- **The architecture stage loads its method.** The `/architecture` bundle loads `domain-modeling`, which the stage's own role file requires and today cannot resolve.
- **No new runtime, no bin, no dependency.** The verification mechanism is review — an agent reading the diff against a contract — which the repository's mechanism vocabulary already names as first class.

## Capabilities

### New Capabilities

- `methodology/ddd-domain-discipline`: the DDD trigger is decided by explicit signals the architect must evaluate and record; the ubiquitous language lives in the project's `CONTEXT.md`; the domain model is a required section of the change's design when the trigger fires; and the reviewer verifies the trigger, the vocabulary and the invariants against the real diff.

### Modified Capabilities

- `methodology/tdd-ddd-at-buildstage`: the "Domain-driven modeling when the domain merits it" requirement stops defining the trigger itself and defers to `methodology/ddd-domain-discipline`, so the two capabilities cannot contradict each other. TDD is untouched.

## Impact

- `agents/architect.md` — replace the "when the domain merits it" phrasing with the signal list; state the three artifacts it produces and the falsifiable skip.
- `agents/reviewer.md` — new checklist item for the domain contract; extend the Definition of Done.
- `workflows/openspec-to-architecture.md` — add the domain deliverables to stage 1 and the domain checks to the validation loop in step 2.
- `templates/architecture.md` — `## Domain` section (vocabulary, model, boundaries) with its filling rules.
- `rules/coding.md` — point the "Domain model" section at the design's `## Domain` section and `CONTEXT.md` as the vocabulary source of truth.
- `rules/quality.md` — the architect and reviewer rows of "Definition of Done by task type" carry the domain contract.
- `skill-bundles/architecture.yaml` — load `domain-modeling` (also the live copy under `~/.hermes/skill-bundles/`).
- `docs/sdd-feature-lifecycle.md` — stage 3 reflects the trigger, the artifacts and who verifies them.
- `README.md` — the complementary-skills/loop description states the contract instead of the intention.
- `CHANGELOG.md` — `[Unreleased]`.
- No runtime code, no dependency, no project data. Process-only change to the agency itself.
