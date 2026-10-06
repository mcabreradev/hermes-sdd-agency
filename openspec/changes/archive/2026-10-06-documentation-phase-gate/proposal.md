## Why

The system's hard rule is "no implementation code without a validated OpenSpec change" — and
that rule was honoured *literally* while code was still written when it should not have been.
A real project (`te-falta-uno-api`) accumulated 23 TypeScript files under `src/` and 3 e2e specs
across five increments. Every one of those increments had a validated change, a passing gate and
a merged PR. The rule was satisfied at every step, and the outcome was still the exact failure
the rule exists to prevent.

The gap is not the change requirement — it is that **the project's phase is not a fact in the
repository**. The standing instruction was *"aun no haremos codigo hasta tener completa la
documentacion y requisitos"*: the product owner had declared a documentation phase and closed
implementation. That declaration existed only in conversation. An agent that reads the repo
cannot see it, so the only gate it can satisfy is the change gate — and it complies, correctly,
against the wrong contract. The mistake is therefore not a rule violation an agent chose; it is
a rule the system never encoded in a place the agent could read.

The cost is concrete and not merely procedural: five increments of application code had to be
removed afterwards, the gate had to be rewritten to verify what actually exists, and six claims
in the project documentation had to be withdrawn as history. Writing code a phase early is
cheaper to prevent than to un-write.

That repository has since corrected itself — the code is gone and its `platform` spec now carries
the prose requirement *"The repository holds no implementation before its phase is opened"*. The
correction is real and it is the reason this change is shaped the way it is: **the requirement
there is prose, and prose is what failed.** Nothing in that repository stops the next increment
from being added the same way the first five were. This change supplies the missing half — the
phase as a declared fact and a mechanical gate that reads it — so the rule stops depending on an
agent having read the right conversation.

## What Changes

A project **declares its phase** in `openspec/project.md` — the file Hermes already treats as the
marker that a project entered the loop — and the declaration is the human's, never an agent's.
In the **documentation** phase, application code paths must be absent from the tree; the phase
gate refuses to let a change add them, and passes when a change removes them. In the
**implementation** phase the gate adds no constraint beyond the existing change gate.

Observable behavior:

- An agent (or a person) can ask a project what phase it is in and get a file answer, not a
  remembered one — `bin/phase-gate` prints the phase and the verdict.
- Implementing in a documentation-phase project **fails the preflight** and, in the project's CI,
  fails the gate — including when a perfectly valid change is the thing proposing the code.
- A project that declares no phase is not silently treated as open for implementation: the gate
  reports that it cannot assess and exits non-zero.

## Capabilities

### New Capabilities

- `project-phase`: the declared phase of a project, the rule that binds implementation to it,
  and `bin/phase-gate` — the read-only command that derives the verdict from the repository.

### Modified Capabilities

- `agency-state`: the state the agency derives may be *phase-gated* — a change that is complete
  and apply-ready is not implementable when the project's phase forbids application code, and the
  derived transition has to say so rather than propose `implement-change`.

## Impact

- `bin/phase-gate` (new) and `fixtures/phase-gate/check.sh` (new suite).
- `rules/openspec.md` — the "Hard rule" gains the phase gate as a precondition.
- `rules/coding.md` — the precondition of any implementation work.
- `agents/builder.md`, `workflows/implement-change.md` — the preflight and the builder brief.
- `rules/orchestration.md` — the phase-gated state and the blocker class it produces.
- `docs/phase-gate.md` (new), `docs/evidence-bins.md`, `README.md`, `INSTALL.md`, `CHANGELOG.md`.
- Each consuming project: a `## Phase` block in its `openspec/project.md` and the gate wired into
  its CI. The agency ships the mechanism; the project declares the phase.
- No dependency, no schema, no runtime change: the gate is bash 3.2 + git, like the other bins.
