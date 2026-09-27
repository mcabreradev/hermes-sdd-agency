# The phase gate — no code before the project says so

The agency's hard rule is *no implementation code without a validated OpenSpec change*. That rule
was honoured **literally** while code was still written when it should not have been: a project in
a declared documentation phase accumulated 23 TypeScript files and 3 e2e specs across five
increments, each one carrying a validated change, a green gate and a merged PR. Every step complied
and the outcome was still the failure the rule exists to prevent.

The gap was not the change requirement. It was that **the project's phase was not a fact in the
repository** — the instruction not to code lived in a conversation, and an agent reading the repo
cannot see a conversation. The phase gate closes that half of the rule.

## Declaring the phase

The declaration goes in `openspec/project.md`, the file Hermes already treats as the marker that a
project entered the loop. Two keys:

```markdown
## Phase

phase: documentation
application-code: src/**, test/**, app/**, lib/**
```

| Key | Values | Meaning |
|---|---|---|
| `phase` | `documentation` \| `implementation` | Whether application code is permitted in this tree |
| `application-code` | comma-separated globs | The paths that count as application code for this project |

`*` matches within a path segment and `**` crosses segments (`src/**` covers `src/a/b.ts`; `src/*`
covers only `src/a.ts`). A bare directory name — `src` or `src/` — is read as everything under it.

**The declaration is the human's.** An agent that flips the phase to unblock its own work defeats
the gate with the gate's own input. The gate only ever reads it.

## Running it

```bash
$ bin/phase-gate                     # from a project root (git toplevel, else cwd)
$ bin/phase-gate --root /path/to/project
```

The verdict is derived from **the resulting tree**, not from a diff range. Two consequences that
are load-bearing:

- A change that **removes** the code is the correction, and it passes. A diff-based rule would
  refuse the very operation that fixes the project.
- The answer is identical for any two readers of the same checkout, and it works unchanged in a
  project's CI.

## The three verdicts, and the exit codes that carry them

```
$ bin/phase-gate --root fixtures/phase-gate/roots/docs-clean
phase: documentation
application-code: src/**,test/**,app/**
verdict: pass
```

```
$ bin/phase-gate --root fixtures/phase-gate/roots/docs-violating
phase: documentation
application-code: src/**,test/**,app/**
verdict: refuse
violating:
  src/main.ts
  test/app.e2e-spec.ts
phase-gate: 2 file(s) under the declared application-code paths while the phase is documentation
phase-gate: opening the phase is the human's decision (blocker class: decision) — this is not
retried or worked around
```

```
$ bin/phase-gate --root fixtures/phase-gate/roots/no-declaration
phase: cannot assess
reason: no 'phase:' key inside the '## Phase' block of openspec/project.md
verdict: cannot assess
phase-gate: could not assess the phase (...) — this is NOT a pass
```

| Exit | Verdict | Meaning |
|---|---|---|
| `0` | pass | The phase was read and the tree respects it (including an `implementation` phase) |
| `1` | refuse | The phase was read and the tree violates it — the offending paths are named |
| `2` | cannot assess | No declaration, an unrecognized phase, or no declared paths — **never a pass** |

Exit `1` is a *verdict*; exit `2` is *no verdict*. A CI gate only needs the non-zero pair to fail,
but an operator needs to tell "you are implementing too early" from "you have not declared your
phase" — those have different fixes.

**An undeclared phase is not an open one.** The same honesty rule the agency holds for `review-tier`
and `agency-next` applies here: an unmeasurable input never collapses into the cheapest default, and
here the cheap default would be *implementation is fine* — the exact defect this exists to close.

## Where it binds

| Layer | What it does |
|---|---|
| `rules/openspec.md` | The Hard rule and the implementation preflight both require it; the fast path (`cosmetic` / `minimal`) does not bypass it |
| `rules/coding.md` | A precondition of any implementation work |
| `agents/builder.md` | The builder's hard precondition — a second gate, not a substitute for the change gate |
| `workflows/implement-change.md` | Runs it in the blocking preflight |
| `rules/orchestration.md` | A refusal is blocker class `decision`; the precise state `PHASE_GATED` |
| `bin/agency-next` | Stops proposing `implement-change` in a documentation-phase project, and reports an undeclared phase as undetermined |
| The project's CI | The backstop for work that reached a branch some other way |

**A validated change is necessary, never sufficient.** That sentence is the whole point: a change
that is complete, `apply-ready` and validated is *not* authorization to write code. It is
authorization to write code **once the project's phase permits it**.

## Adding it to a project

```bash
# 1. declare the phase (the human writes this, not an agent)
cat >> openspec/project.md <<'EOF'

## Phase

phase: documentation
application-code: src/**, test/**
EOF

# 2. wire it into the project's gate (before the build/test steps)
bin/phase-gate
```

For a project that carries no declaration, the gate reports `cannot assess` (exit 2) rather than
passing — that is deliberate: a silent pass would leave every existing project silently treated as
open for implementation. Declare the phase, then the gate has something to read.

## What it is not

- **Not a general policy engine.** It governs exactly one axis: whether application code is
  permitted in this project at this phase.
- **Not a substitute for the change gate.** It is an additional precondition; both must be green.
- **Not a way to reclassify work.** The refusal is the human's to close. Narrowing the change,
  retrying, or recategorizing the work to fit under the gate is the failure mode, not a workaround.

## The suite that pins it

`fixtures/phase-gate/check.sh` — 12 cases, one per row of the exit-code table plus the near-misses:

```bash
$ bash fixtures/phase-gate/check.sh
checked=12 failed=0
```

Covered: both phases, a bare-directory glob, a worktree whose copies are ignored (the project's own
tree answers, not its worktrees'), behavior-bearing files **outside** the declared globs staying
clean (the near-miss that catches a pattern widened for recall), all three cannot-assess shapes, and
determinism across two runs.

The suite fails **closed**: if the bin under test is missing or not executable it exits `3` with a
distinct message instead of reporting the green that "no case failed" would produce.
