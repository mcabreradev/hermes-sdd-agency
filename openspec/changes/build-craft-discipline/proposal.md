## Why

The agency enforces test-first as a **hard rule** (`rules/testing.md`) and names the personas a stage
should adopt — but it never says what makes a test worth keeping, where a test belongs, or how to find
a bug whose cause is not yet visible. Three failures follow, and all three are visible in this repo's
own history:

- **The rule forbids trial-and-error without teaching the craft.** `rules/testing.md` requires
  RED→GREEN→REFACTOR and forbids weakening a test. It never says that a test must assert through a
  **seam**, that a tautological assertion passes by construction, or that writing every test before any
  implementation produces tests for imagined behaviour. A builder can satisfy every sentence of the
  rule and still write a test that breaks on the next refactor.
- **A diagnosis starts from a hypothesis, not from a loop.** `agents/builder.md` offers `debugger` and
  `error-detective` as personas when a task gets stuck, and nothing else. The failure this produces is
  the one worth naming: reading code to build a theory before any command goes red on the bug —
  which is exactly how a wrong fix lands, and why a fix without a regression test proves nothing.
- **"Deep module" is not in the vocabulary.** `rules/coding.md` forbids speculative abstractions and
  flags without a consumer, which are *negative* rules. Nothing names what a good seam is, what
  leverage and locality buy, or how to tell a pass-through from a module earning its keep. The
  repo has discovered the concept one incident at a time — `bin/review-snapshot`'s `--compare` that
  checked one field and returned a confident `MATCH` is the deletion test found the hard way.

The result is a process that states the *obligation* (test-first) and leaves the *skill* to whoever is
on shift, so the quality of the gate follows the agent's background rather than the process.

## What Changes

- **The build stage gains its craft, as three method skills.** Three host-agnostic process skills enter
  `skills/`, English and in the agency's own voice, each one referenced by the stage that needs it:
  - `build-craft` — the discipline that makes the `rules/testing.md` hard rule produce tests worth
    keeping: seams and how to agree them before a test exists, the three anti-patterns
    (implementation-coupled, tautological, horizontal slicing), one vertical slice at a time.
  - `bug-diagnosis` — the loop that precedes a fix: build a feedback loop that goes **red on this bug**
    before any hypothesis, minimise the repro, rank falsifiable hypotheses, instrument one variable at
    a time, and fix only at a seam where the regression test exercises the real pattern.
  - `module-design` — the shared vocabulary for a module's *shape* (module, interface, implementation,
    depth, seam, adapter, leverage, locality), the deletion test, and the rule that the interface is the
    test surface.
- **`rules/testing.md` states the craft, not only the obligation.** A new "Test craft" section carries
  the seam rule (tests are written at pre-agreed seams, agreed and written down before the first test),
  the three anti-patterns with the reason each passes a careless review, and the vertical-slice rule.
  A new "Diagnosis before a fix" section makes the red-capable loop the precondition of a fix, not an
  option of it.
- **The builder loads the craft and the diagnosis loop.** `agents/builder.md` names `build-craft`
  alongside `test-driven-development`, states that a stuck task is diagnosed with `bug-diagnosis`
  before a hypothesis is committed to, and records where the module's seam is when the change
  introduces one.
- **The reviewer checks the craft against the diff.** `agents/reviewer.md` and `rules/quality.md` gain
  the checks that make the craft falsifiable: an assertion that recomputes the expected value the way
  the code does (tautological), a test coupled to internals, all-tests-then-all-implementation, and a
  bug fix whose regression test does not fail without the fix. `module-design` is named as the
  vocabulary the reviewer uses when it disputes a structure.
- **No new runtime, no bin, no dependency.** The three skills are prose; the checks they enable are
  **review** — an agent reading the diff against a contract — which the repository's mechanism
  vocabulary already names as first class.

## Capabilities

### New Capabilities

- `methodology/build-craft`: the craft the build and review stages must exercise — the seam a test is
  written at, the anti-patterns that make a test prove nothing, the feedback loop that must go red
  before a bug is diagnosed, and the vocabulary for a module's shape.

### Modified Capabilities

- `methodology/tdd-ddd-at-buildstage`: the "Test-driven build (hard rule)" requirement keeps its force
  and delegates the craft that makes the cycle produce a test worth keeping to
  `methodology/build-craft`, so the two capabilities cannot contradict each other. DDD is untouched.

## Impact

- `skills/build-craft/SKILL.md`, `skills/bug-diagnosis/SKILL.md`, `skills/module-design/SKILL.md` — new skill directories.
- `rules/testing.md` — new "Test craft" and "Diagnosis before a fix" sections; the hard rule and its
  prohibitions are unchanged.
- `agents/builder.md` — the method list gains `build-craft` and `bug-diagnosis`; the stuck-task path
  and the module-seam record.
- `agents/reviewer.md` — new checklist item for the craft, with severities; `module-design` named as
  the vocabulary for a structural dispute.
- `rules/quality.md` — the builder and reviewer rows of "Definition of Done by task type" carry the
  craft; the reviewer row carries the anti-pattern checks.
- `workflows/implement-change.md` — the build stage's method line names the two new methods.
- `workflows/review-change.md` — the review stage's method line names `module-design`.
- `README.md` — the skill counts (65 → 68), the catalog rows for the three skills (each cell generated
  as the skill's own frontmatter description, per the catalog's stated rule) and the operating-rules
  table.
- `INSTALL.md` — the skill count in the badges and the TL;DR row.
- `CHANGELOG.md` — `[Unreleased]`: the `### Added` entry for the three skills, the `### Fixed` count
  line (65 → 68), plus the adaptation note for the new upstream source.
- `docs/sdd-feature-lifecycle.md` — the build stage reflects the craft and the diagnosis loop.
- No runtime code, no dependency, no project data. Process-only change to the agency itself.
