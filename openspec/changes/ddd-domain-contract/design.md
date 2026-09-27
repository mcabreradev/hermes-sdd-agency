## Context

The agency states DDD as a technique applied "when the domain merits it" (`agents/architect.md`) and requires the builder to follow the model (`rules/coding.md`), with a delta requirement in `openspec/specs/methodology/tdd-ddd-at-buildstage/spec.md`. What is missing is not the intention but the three things that make an intention a contract: a criterion the architect cannot dodge, an artifact in the repository the model lives in, and a step that fails when the model is violated.

Constraints that shape the approach:

- The repository has no CI workflow; the gate for its own changes is local (`bin/` fixtures + `openspec validate` + `bash -n`).
- This repository's own doctrine (`skills/context-architecture`, quoted in `docs/`: "every claim a repository makes about itself must be bound to a mechanism that fails when that claim stops being true") applies to the agency's process rules too.
- The agency's mechanism vocabulary names four kinds: compiler, linter, automated tests, and **review by a person or an agent**. Review is a first-class mechanism, and the only one that can read *meaning* — whether a business term is used as the glossary defines it.
- The `domain-modeling` method's own artifact conventions are fixed: glossary in `CONTEXT.md` with `_Avoid_` synonyms, ADRs in `docs/adr/`. The agency already writes ADRs to `docs/decisions/`.

## Goals / Non-Goals

**Goals:**

- The DDD trigger is decidable and recorded: any reader can tell, from the change's design, whether DDD was applied and on which signal.
- The ubiquitous language of a change lands in the project (`CONTEXT.md`) instead of a conversation.
- The domain model is a required, non-hollow part of the change's design.
- A concrete, graded review step fails when the model is violated (MAJOR for the content violations, BLOCKER when the artifact that anchors the contract is missing).

**Non-Goals:**

- An executable `bin/` that reads prose and judges it. Explicitly out of scope (see Decision 2).
- Naming a project's folders after domain concepts (`Structure Screams Intent`). That is `context-architecture`'s discipline, a per-project restructuring with its own cost, and it is not part of this change.
- Forcing DDD onto thin behavior. The signal list exists as much to legitimise a recorded skip as to fire.

## Decisions

### Decision: The trigger is a fixed signal list, not a judgment call

- **What:** `agents/architect.md` carries five objective signals (invariant across operations; entity with identity and lifecycle; a term defined or redefined; a boundary between business capabilities; vocabulary drift already present). Any one fires the trigger. The architect records the evaluation in the design whether or not it fires.
- **Why:** "when the domain merits it" is unfalsifiable: two runs decide differently and neither decision is reviewable. A signal list makes the decision reproducible and, more importantly, makes the *skip* reviewable.
- **Discarded alternative:** keep the judgment call and add examples — it reduces variance without making the skip falsifiable, and a reviewer still has nothing to check the architect against.
- **Discarded alternative:** always apply DDD — the previous change's own requirement forbids forcing it on thin behavior, and it would make every bounded fix carry a glossary edit.
- **Consequences:** the architect must justify DDD by naming a signal; a change with real domain structure and no recorded evaluation is a defect the reviewer reports as a BLOCKER.

### Decision: The verification mechanism is review, not a bin

- **What:** the contract is verified by the reviewer's checklist against the real diff (glossary conformance, invariants covered by a failing test, faithfulness to the declared model, recorded trigger verdict). No new executable.
- **Why:** the violations that matter are semantic — whether `Customer` in the diff means what the glossary says, whether an invariant is really covered by a test that fails without it. A bin that greps for a term's presence cannot tell a compliant use from a contradictory one, so it would report a confident green on exactly the input the rule exists for.
- **Discarded alternative:** a `bin/domain-check` that fails when glossary terms are absent or duplicated. Discarded because it can only produce false positives (a term mentioned in a comment) and false confidence (a term used in the wrong sense passes), and the repository's own doctrine is that the review mechanism exists for meaning.
- **Discarded alternative:** a `review-tier` class that forces DDD review depth. Discarded because `review-tier` derives depth from the *diff shape* (paths, size), and a domain trigger is a property of the change's *subject matter* — wiring it there would make a rule depend on a signal the tool cannot see.
- **Consequences:** the honest limit — this contract depends on the reviewer actually running the checklist. `rules/quality.md` grades the reviewer's own Definition of Done, and the reviewer's findings carry `path:line`, so a hollow review is itself a defect the orchestrator can catch. If the agency ever gains a project with many concurrent domain changes, the bin can be revisited with real material to design it against.

### Decision: The model lives in a `## Domain` section of the change's design

- **What:** `templates/architecture.md` gains `## Domain` (vocabulary resolution, entities/aggregates with invariants, boundaries between business capabilities), populated only when the trigger fires, with filling rules that make a hollow section a defect.
- **Why:** `design.md` is already the artifact the architect owns, the planner reads and the reviewer checks against the code. A separate `domain.md` would be a fourth artifact with no owner in the loop and no stage that reads it.
- **Discarded alternative:** a dedicated `openspec/changes/<name>/domain.md`. Discarded: the loop has no stage that consumes it, so it would rot as prose the reviewer never opens.
- **Consequences:** the architecture stage's validation gains three checks; the planner inherits a model it does not decide.

### Decision: The glossary is the project's `CONTEXT.md`

- **What:** when the trigger fires, the vocabulary resolution is written to the project's `CONTEXT.md` in the `domain-modeling` glossary format (term, tight definition, `_Avoid_` synonyms), never to global memory.
- **Why:** `CONTEXT.md` is the format the loaded method already produces and consumes, and it is the only artifact with an explicit anti-ambiguity convention (`_Avoid_`), which is what makes "one term, one meaning" reviewable.
- **Discarded alternative:** record the terms inside the change's spec. Discarded: the glossary is project-wide language, not a requirement of one change — a term resolved in change A must be available to change B, and delta specs go to the archive.
- **Consequences:** the architect may touch one project file outside `openspec/` (`CONTEXT.md`); that file is declared in the brief, and a contradiction between the change and the existing glossary is a blocker, never a silent redefinition.

### Decision: The old requirement defers instead of duplicating

- **What:** `methodology/tdd-ddd-at-buildstage`'s "Domain-driven modeling when the domain merits it" is MODIFIED to cite `methodology/ddd-domain-discipline` for the trigger and the artifacts, keeping its own builder-follows-the-model duty.
- **Why:** `rules/openspec.md` treats a statement appearing twice as a drift surface. Leaving the old trigger text in place would ship two sources for the same decision, and the second would silently win in whichever file an agent read first.
- **Discarded alternative:** add the signal list to the existing requirement instead of creating a capability. Discarded: the new contract spans the architect, the design artifact, the glossary and the reviewer's checklist — a capability with its own purpose, not a patch to a TDD-and-DDD build-stage requirement.
- **Consequences:** the delta must be `## MODIFIED Requirements` (the requirement exists in the main spec), and the archive's inline sync updates the main spec in place.

### Delivery strategy

Measured before the final commit — `git add -A && git diff --cached --numstat main`:

- **224 authored lines** across the process files (`agents/`, `templates/`, `rules/`, `workflows/`, `skill-bundles/`, `install.sh`, docs) — well inside the ~400-line advisory of `rules/coding.md`.
- **547 lines** including the change's own planning artifacts (`proposal.md`, the two delta specs, `design.md`, `tasks.md` = 321 of them, which the gate requires and are not authored code).

Strategy: **`single-pr`**. The change is one coherent rule — the agency's domain contract — expressed across five process files, and it has no natural split: shipping the spec without the architect's trigger leaves a requirement nothing satisfies, and shipping the trigger without the reviewer's checklist leaves a claim with no mechanism behind it, which is the exact defect this change removes. Splitting would also hand the second half a reviewer with no contract to check against. No chained PR, no split change.

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| The reviewer skips the domain checks and the contract becomes prose again | The four checks are graded with explicit severities; `rules/quality.md` grades the reviewer's DoD; a `BLOCKER`-class violation is defined (missing trigger evaluation) so the review cannot close on a diff with unexplained domain structure |
| The signal list is read as "always apply DDD" and thin fixes start carrying glossaries | The skip is a first-class outcome with its own scenario, and the record requirement is what makes it legitimate: signals evaluated and absent |
| A project's `CONTEXT.md` contradicts the change | The contradiction is a blocker, settled in the spec before the design continues; never a silent redefinition |
| The `## Domain` section is filled to satisfy structure | `templates/architecture.md` filling rules and the reviewer's MAJOR finding for a structure that contradicts the model; the validation step carries the "present but hollow" check |
| A project on a stack where DDD has no idiomatic shape gets a model it cannot express | The contract requires vocabulary, invariants and boundaries — not a prescribed code structure; `rules/coding.md` says the model lands as the design declares it, and the project's own conventions win (`rules/coding.md`, "Conventions: local first") |
