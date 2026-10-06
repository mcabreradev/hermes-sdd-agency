# Design

## Context

The agency's build stage is governed by three rule files and one agent contract:

- `rules/testing.md` — TDD as a **hard rule** for behavior-bearing code, the origin of tests in the
  spec's scenarios, and a list of prohibitions (no weakened test, no faked environment, no green
  declared by omission).
- `agents/builder.md` — the method list (`test-driven-development`, `executing-plans`,
  `dispatching-parallel-agents`) and the persona list (`fullstack-developer`, `typescript-pro`,
  `debugger` / `error-detective` when a task gets stuck).
- `agents/reviewer.md` — a ten-item checklist over the real diff, plus the DDD domain contract.

What none of them carries is the craft: where a test belongs, what makes it worth keeping, how to
find a bug whose cause is not visible, or what makes a module's shape defensible. The gap is not
stylistic. `rules/testing.md` forbids weakening a test, and a tautological test is never weakened —
it is written that way and passes forever.

The constraint that shapes every decision below: this repository is a **process carrier**
(`openspec/project.md`, "Preferred Stack" — Bash and Markdown, no runtime dependency), and
`rules/project-boundaries.md` makes the process global and the product local. So the craft must enter
as **prose the stages load**, not as a tool, a linter or a dependency.

## Goals / Non-Goals

**Goals:**

- The obligation `rules/testing.md` already states becomes checkable against a real diff: an assertion
  that recomputes the expected value, a test coupled to internals, and a fix whose regression test does
  not fail without the fix are each named defects a reviewer can point at with `path:line`.
- A bug whose cause is not visible has a declared first move (build a loop that goes red on *this* bug)
  instead of a hypothesis.
- A module's shape has a vocabulary the reviewer can use when it disputes a structure, so a
  disagreement is settled against named terms instead of taste.
- Zero new runtime, zero dependencies, no third-party state machine ported (the repo's standing rule
  for adapting an external source, `CHANGELOG.md` adaptation notes).

**Non-Goals:**

- **No vendored copy of the upstream skills.** The upstream kit ships user-invoked routers
  (`ask-matt`), a host-specific setup command that writes a second source of truth for where decisions
  live, and slash commands that duplicate the agency's own entry points. None of them is ported; only
  the three host-agnostic disciplines are, rewritten for this repository's voice and vocabulary.
- **No parallel two-axis reviewer.** Splitting the reviewer into parallel Standards + Spec sub-agents
  is a real improvement and is deliberately **not** in this change: it changes the reviewer stage's
  shape and its cost profile, and it belongs in its own change with its own evidence. This change adds
  the craft the two axes would review against.
- **No new bin.** A detector for "tautological assertion" cannot read intent, and `rules/quality.md`
  already names the mechanism for meaning-bearing contracts: review. Adding a bin that guesses would
  violate the repo's own "a detector must cover every form of the defect it names, or flag what it
  cannot read".
- **No rewriting of `rules/testing.md`'s hard rule or prohibitions.** The rule's force is settled
  (see `sdd-agency-maintenance`: TDD is unconditional for behavior-bearing code, never a default with
  agent discretion). This change adds the craft beside it and changes none of its force: the
  obligation and the prohibitions are untouched, and the "Test craft" section added there is a short
  pointer chain — each rule stated once, in full, in the skill that owns it.

## Decisions

### D1 — Three skills, not one

The three disciplines address three different failure modes at three different moments: a test that
proves nothing (build time), a bug fixed by theory (stuck build time), and a structure that cannot be
defended (design and review time). Merging them into one skill would put the diagnosis loop in context
on every test-writing turn and the seam vocabulary in context on every bug hunt; splitting them lets
each stage load only what it needs, which is the same rule the bundles already follow ("the agent that
does not correspond to the stage is neither loaded nor invoked", `rules/orchestration.md`).

**Discarded alternative:** one `build-craft` skill with three sections, loaded by every build. Rejected
because it makes the diagnosis discipline — the one that must fire *before* a hypothesis, at the moment
a task is stuck — compete for attention with the routine test-writing rules on every ordinary turn.

### D2 — The craft enters as prose wired into the rules, not as a new bin

`rules/quality.md` and the repo's history both name the same distinction: a check that cannot fail on
the interesting input is decoration. No shell tool can detect a tautological assertion or decide
whether a test is coupled to internals; those are judgements about intent, read from a diff. The repo's
own vocabulary for that mechanism is review (`rules/quality.md`, "Definition of Done by task type" —
the reviewer "reviews the diff against a contract").

So the craft lands where it can actually fire: a section in `rules/testing.md` that states it, a method
list in `agents/builder.md` that loads it, and a checklist item in `agents/reviewer.md` that makes it
checkable.

**Discarded alternative:** a `bin/test-craft` that greps the diff for `expect(x).toBe(x)`-shaped
assertions. Rejected on the repo's own precedent: the `skill-registry` false positive (a legal `>-`
folded scalar flagged as a defect) showed that a line-wise parser that cannot read a shape faithfully
produces confident false findings, and `rules/quality.md` requires such a detector to flag what it
cannot read rather than guess. The value delivered would be one shape out of many, at the cost of a
false-positive surface the reviewer must then triage.

### D3 — The seam rule is stated as a *pre-agreed* seam, written down before the first test

The strongest available lever is not "test through public interfaces" (true but unguessable in a diff).
It is that the seams under test are **named and agreed before any test is written**, and a test at an
unconfirmed seam is not written. That converts a matter of taste into a missing artifact: the reviewer
can ask for the agreed seam list, exactly as it asks for the frozen snapshot and the declared diff.

### D4 — The diagnosis loop precedes the hypothesis, in the builder's own contract

`agents/builder.md` currently offers `debugger` / `error-detective` as personas "when a task gets stuck
and the cause has to be found". The change keeps the personas and adds the discipline: the first move
is a command that goes **red on this bug**, and a fix without one is a theory. The reason this belongs
in the builder's contract and not only in a skill is that a skill is reached by a pointer; a contract
clause is what the stage validates the output against.

### D5 — Attribution is recorded where the repo already records its other sources

`CHANGELOG.md` carries an adaptation note for each upstream source (`gstack`, `gentle-ai`) with a clause
stating what was **not** taken. The new source (`mattpocock/skills`, MIT) gets the same treatment: the
license, the three disciplines distilled, and the explicit clause — no router, no host setup command,
no slash commands, no runtime. A ported rule whose provenance is unrecorded reads as an original rule
and is quietly overwritten later.

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| The three skills re-state `rules/testing.md` and the two drift apart | The skills carry the **craft** (what a seam is, why an assertion passes by construction); `rules/testing.md` keeps the **obligation and the prohibitions**, and its two new sections are a **pointer chain** — each rule is stated in full once, in the skill that owns it, and the rule file names the skill and the section rather than restating the rule. The delta spec states that the hard rule's force is unchanged. |
| A reviewer treats the new checklist item as a new gate | `rules/quality.md` already fixes the severity vocabulary and states that findings need `path:line`; the new item's severities are declared (MAJOR for a tautological or implementation-coupled assertion, MINOR for an unagreed seam list). The item adds findings, not a new authority. |
| More prose in a rules file is more prose to keep relevant | The additions are two bounded pointer sections in `rules/testing.md` and one checklist item in `agents/reviewer.md`. Three existing surfaces were also **extended in place** and the design says so: the `builder` and `reviewer` rows of `rules/quality.md`'s "Definition of Done by task type", and the `testing.md` row of `README.md`'s operating-rules table. |
| The skill count in the public surfaces drifts from the tree | The counts are updated from a real run of `bin/skill-registry --root skills` (65 → 68), not from arithmetic on the added directories. |
| The change crosses the advisory 400-line budget | Measured, and the delivery strategy is **recorded** below, per `workflows/implement-change.md` step 4. |

## Delivery strategy

Measured before the commit with `git add -A && git diff --cached --numstat main | awk '{a+=$1; d+=$2} END
{print a+d}'`, generated files excluded. The change is one coherent behaviour — *the craft enters the
loop* — and the measurement below decides the shape:

```
total (authored, incl. this change's artifacts)         1107
total excluding openspec/changes/build-craft-discipline  535
```

Both figures are against the advisory ~400-line budget in `rules/coding.md`, so the strategy is
**recorded**:

| Strategy | When | Chosen? |
|---|---|---|
| `single-pr` | the excess is small and the reviewer accepts one larger diff | **yes** — 535 authored lines of prose across seven files, each with one concern, plus the change's own artifacts. The merged precedent is comparable or larger: the DDD contract change (`818bf4d`) measured 561, the phase gate (`ce96db9`) 1214, both delivered as a single PR. |
| `chained-pr` | the change is one behaviour delivered in slices | rejected — there is **no slice boundary** at which the gate passes and the behaviour is usable: a skill with no rule pointing at it is dead prose, and the reviewer item without the skill has nothing to name. Three slices would deliver three non-behaviours. |
| `split-change` | the excess is independent work | rejected — the excess is this change's own craft, not unrelated work. |

The budget is advisory by requirement: it justified no deletion of the explanations above, no
weakening of the task list, and no artificial split. The measured number and the two rejected
strategies are recorded here so the delivered shape is inspectable in review.

## Domain — trigger evaluation

**Signals evaluated (all five, per `agents/architect.md`):**

1. *An invariant that must hold across more than one operation, or on every write* — **fired**. `a
   test that passes before and after proves nothing` and `an assertion that recomputes the expected
   value passes by construction` are invariants over every assertion the change's rules describe, not
   over one operation.
2. *An entity with identity and a lifecycle* — fired, weakly: a **test** is an artifact with a lifecycle
   (red → green → kept or deleted), and this change is about what makes it worth keeping.
3. *A term the change defines or redefines in the project's vocabulary* — **fired**. `seam`, `depth`,
   `adapter`, `leverage`, `locality`, `tautological`, `vertical slice`. `rules/testing.md` today has no
   word for any of them.
4. *A boundary between two business capabilities* — fired: the build stage (which produces the test)
   and the review stage (which judges it) are the two capabilities whose contract changes.
5. *Vocabulary drift already present* — **fired**. "Test-first", "TDD", "regression test",
   "test-driven-development" (the external skill) and the spec scenario all name overlapping things
   with no stated relation.

**Verdict: the trigger fired (signals 1, 3, 4, 5, and 2 weakly). The domain is modeled.**

### Vocabulary resolution

The glossary belongs to each **project**, not to this repo (`rules/coding.md`, "Domain model": the
ubiquitous language is the project's `CONTEXT.md`). This repo ships no product vocabulary and carries
no `CONTEXT.md` — the process it ships defines the terms per project. So the resolution this change
owes is the one the reviewer must check: the terms are defined in one place each, and the new skill
names no concept the delta specs do not.

| Term | Is | `_Avoid_` |
|---|---|---|
| **Seam** | the boundary at which a test observes a behaviour without reaching inside — the *location* of a module's interface | boundary (overloaded with DDD's bounded context), surface, edge |
| **Tautological test** | an assertion whose expected value is recomputed the way the code computes it, so it passes by construction and can never disagree with the code | trivial test, weak test |
| **Vertical slice** | one test plus the minimal implementation that makes it pass, then the next — each test a tracer bullet that responds to what the last cycle taught | increment, iteration, unit of work |
| **Depth** | leverage at an interface: how much behaviour a caller or a test can exercise per unit of interface they must learn | — |
| **Diagnosis loop** | one command, already run at least once, that goes red on *this* bug and green once it is fixed | repro, reproduction case |

The terms the three skills introduce are exactly the five above plus `adapter`, `leverage`, `locality`
and `module/interface/implementation`, each defined once inside `module-design` and never redefined
thereafter. `rules/testing.md` names the craft and points at `build-craft` rather than restating it.

### Invariants and the tests that must fail when violated

This change ships prose, so its own verification is review against the diff — the mechanism
`rules/quality.md` names for meaning-bearing contracts. Each invariant below is bound to the check that
fails when it is violated:

| Invariant | Fails when violated |
|---|---|
| The hard rule's force is unchanged: no test-first exemption is introduced for behavior-bearing code | `grep -qiE 'default\|agent discretion\|at the agent'` over the new `rules/testing.md` sections finds no new discretion in the test-first cycle; the modified delta spec keeps the "no agent discretion" sentence |
| No ported skill names a host-specific mechanism (a slash command, a router, a setup command, a runtime) | `grep -qiE 'ask-matt\|/setup-matt\|/clear\|/compact\|npx skills\|claude plugins'` over the three new skills → empty; each is recorded as the deliverable of the review |
| Each new skill is registered and routable | `bin/skill-registry --root skills` prints 68 skills, 0 flagged, with the three new names present and `FLAG: ok` |
| The public counts match the tree | `grep -c` of the skill badges in `README.md` / `INSTALL.md` equals the count `bin/skill-registry --root skills` prints |
| The change validates and archives | `openspec validate build-craft-discipline --type change --json` → `summary.totals.failed == 0`, and no `Archive would refuse this delta` INFO |
