## Context

`te-falta-uno-api` accumulated application code across five increments while its owner had
declared a documentation phase. Every increment carried a validated OpenSpec change, so the
system's hard rule — no implementation code without a validated change — was satisfied at each
step. The gate the agent could read was green; the instruction it was actually under lived only in
conversation. That repository has since been corrected by its own work (the code removed, the
correction recorded in its ADR 0011, and the requirement stated in its `platform` spec):
**the phase was never a fact the repository carried, and the rule it now states is prose.**

## Goals / Non-Goals

**Goals.** Make the phase a declared, human-owned fact in `openspec/project.md`; make "is
application code permitted here?" answerable from the tree by any session; give the answer a
mechanical form that a preflight and a project's CI both run; keep the refusal honest when the
declaration is missing.

**Non-Goals.** Not a general policy engine: this governs exactly one axis (is application code
permitted in this project at this phase). Not a substitute for the change gate — it is an
additional precondition, and a validated change is explicitly not an authorization. Not a way to
reclassify work to get past it: the refusal is the human's decision. No dependency, no schema,
no runtime surface.

## Decisions

### The gate reads the resulting tree, not the change's diff

The verdict is "does the tree this change produces carry application code under the declared
paths?" — not "does this change add such a file in `<base>...HEAD`". The diff shape is wrong twice
over: a **removal** must pass (the correction in `te-falta-uno-api` deletes `src/` and `test/`,
and a diff-based rule would refuse the very operation that fixes the problem), and a diff range is
a property of how the work happened to be committed rather than of the state being reviewed. The
tree form also makes the answer identical for two different readers, which is the whole point.

Consequence accepted: the gate is a fact about the current checkout, so a branch that already
carries the code is refused until the branch is corrected — which is exactly the desired behavior,
and it is also why the same command works unchanged in a project's CI.

### `bin/phase-gate` reads the declaration, and never invents one

Format in `openspec/project.md`:

```markdown
## Phase

phase: documentation
application-code: src/**, test/**, app/**, lib/**
```

Two keys only, parsed line-wise: `phase` and `application-code` (comma-separated glob list). The
parse is deliberately narrow rather than a YAML engine — the other bins in `bin/` are bash 3.2
with zero dependencies, and a general parser is a new failure surface for a two-key block.

An unrecognized `phase` value, an empty `application-code` list, a missing file or a missing block
all report **cannot assess** with a non-zero exit. That is the same rule the agency already holds
for `review-tier` and `agency-next`: an unmeasurable input never collapses into the cheapest
default. Here the cheap default would be "implementation is fine", which is the exact defect this
change exists to close.

### Exit codes are the contract

| Exit | Meaning |
|---|---|
| `0` | the phase was read and the tree respects it (including `implementation`) |
| `1` | the phase was read and the tree violates it — refusal, names the paths |
| `2` | the phase could not be assessed — never a pass |

Exit `1` is a *verdict*, exit `2` is *no verdict*. A consuming project's CI only needs the
non-zero pair to fail; an operator needs to tell "you are implementing too early" from "you have
not declared your phase".

### Where it binds

`rules/openspec.md` (Hard rule + preflight) and `rules/coding.md` (precondition) make it a
precondition of writing code; `workflows/implement-change.md` runs it in preflight;
`rules/orchestration.md` classifies a refusal as `decision` so the agent asks instead of looping;
`bin/agency-next` stops proposing `implement-change` in a documentation-phase project. The
project's CI is the backstop for work that reached a branch some other way.

### What the agency does not do

The agency ships the mechanism and the rule; **it does not flip a consuming project's phase.** The
phase is the human's, and an agent that changed it to unblock its own work would be defeating the
gate with the gate's own input — the `#2` prohibition in `rules/openspec.md`'s spirit. The repo
that motivated this change keeps its own phase declaration and its own CI wiring (including the
correction it already carries as ADR 0011), and is updated separately, not from here.

## Rejected alternatives

- **Diff-based rule (`<base>...HEAD` adds a source file ⇒ refuse).** Rejects the removal that
  fixes the tree, and makes the verdict depend on the commit range rather than on the state.
- **Infer the phase from the code present.** Self-defeating: the phase exists to say whether the
  code should be there, so the code cannot be its own evidence.
- **A prompt instruction / a skill paragraph only.** That is the status quo that failed:
  conversation-scoped, unreadable from a repo, and satisfied while the code was written anyway.
- **Block it in the builder persona.** A persona is a brief, not a gate; the preflight and CI are
  the two places with authority to stop work, and both are wired here.

## Risks

- **A project that declares no phase is now refused rather than assumed open.** Intended, and the
  cost is one two-line block per project. Declared as cannot-assess so no project is silently
  treated as unrestricted; the migration note goes in `INSTALL.md`.
- **Path globs that are too narrow leave a hole.** The declaration names the paths, so the hole is
  visible and reviewable in one line of `openspec/project.md` — which is the property a hardcoded
  default could not have.
- **The gate is a file check, so a determined agent could satisfy it by declaring a phase.** The
  declaration is human-owned by requirement and the gate never writes it; the residual risk is the
  same class as any agent editing `openspec/project.md`, which is already reviewable in the diff.
