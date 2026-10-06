# Methodology — Build craft

## Purpose

State the craft that makes the test-first hard rule produce tests worth keeping, and the loop that
must precede a fix. The obligation lives in `rules/testing.md`; this capability owns what a seam is,
which assertions prove nothing, where a test belongs, how a bug whose cause is not visible is found,
and what makes a module's shape defensible — so the quality of the gate follows the process instead of
whoever is on shift. Verification is review: an agent reading the diff against this contract. No
executable tool is required for it and none replaces it.

## ADDED Requirements

### Requirement: The seams under test are agreed before the first test

The seams under test MUST be named and agreed before any test is written, and a test MUST NOT be
written at an unconfirmed seam. A seam is the boundary at which a test observes a behaviour without
reaching inside it — the location of a module's interface, not its implementation. The agreed list MUST
be **declared in the `seams:` field of the build stage's report**, together with the declaration of the
files to touch, since the builder never authors `design.md` and the list is the artifact the reviewer
asks for.

#### Scenario: The seams are declared before the first test

- **WHEN** the builder prepares to write the first test of a behavior-bearing change
- **THEN** the stage report already carries the `seams:` field, one seam per line with where each is, before any test is written

#### Scenario: A test is proposed at an unconfirmed seam

- **WHEN** a test would be written at a seam that was neither named nor declared
- **THEN** the test is not written; the seam is proposed and declared first

### Requirement: A test proves behaviour through the interface

A test MUST verify behaviour through the module's interface, not its internals. The tell is the
assertion's failure mode: a test that breaks when the code is refactored while the behaviour is
unchanged was written against the implementation.

#### Scenario: The behaviour changes and the test disagrees

- **WHEN** the code's observable behaviour changes without the test being edited
- **THEN** the test fails, naming the behaviour that broke

#### Scenario: The code is refactored and the behaviour does not change

- **WHEN** the implementation is restructured and the observable behaviour is identical
- **THEN** the test still passes — a test that breaks here was coupled to internals and is a finding

### Requirement: An assertion carries an independent source of truth

An assertion whose expected value is recomputed the way the code computes it passes by construction and
can never disagree with the code. Expected values MUST come from a source independent of the
implementation: a known-good literal, a worked example, or the spec's scenario.

#### Scenario: The expected value is recomputed the way the code computes it

- **WHEN** a test's expected value is derived by the same operation as the implementation under test
- **THEN** the assertion is a finding: it would pass even if the implementation were wrong

#### Scenario: The expected value comes from the spec

- **WHEN** a test asserts a value taken from the spec's scenario or a worked example
- **THEN** the assertion can disagree with the implementation, which is what makes it a test

#### Scenario: The implementation is broken deliberately

- **WHEN** the implementation is broken in the way the test is supposed to catch
- **THEN** the test fails — a test that stays green here is decoration

### Requirement: Work proceeds in vertical slices

Behavior-bearing work MUST be built one vertical slice at a time — one test, then the minimal
implementation that makes it pass, then the next — so each test responds to what the previous cycle
taught. Writing every test before any implementation is prohibited.

#### Scenario: A slice is completed

- **WHEN** the builder implements one behaviour of the change
- **THEN** it writes one test, watches it fail for the expected reason, writes the minimal implementation, watches it pass, and only then moves to the next behaviour

#### Scenario: All tests are written before any implementation

- **WHEN** a batch of tests is written before the implementation they exercise
- **THEN** it is a finding: those tests verify behaviour that was imagined rather than discovered, and they commit the test structure before the implementation is understood

### Requirement: A bug is diagnosed before it is fixed

A bug whose cause is not yet visible MUST be diagnosed before a hypothesis is committed to. The first
move is a command that goes red on **this** bug and green once it is fixed; the repro is then reduced
to the smallest scenario that still fails, and the fix lands only at a seam where the regression test
exercises the real pattern.

#### Scenario: A fix is proposed without a red-capable command

- **WHEN** a defect is under investigation and no command has yet been run that fails on it
- **THEN** the diagnosis does not proceed on a theory: the loop is built first, and its invocation and output are recorded

#### Scenario: The loop goes red and the repro is minimised

- **WHEN** a command reproduces the reported failure
- **THEN** the failing scenario is reduced until every remaining element is load-bearing (removing any one makes it pass), and the hypotheses considered are stated as falsifiable predictions before they are tested

#### Scenario: No seam reaches the bug

- **WHEN** the only seam available is too shallow to exercise the pattern that triggered the bug
- **THEN** that absence is reported as the finding — a regression test at the wrong seam gives false confidence — and the missing seam is a candidate for a design change

### Requirement: A module's interface is its depth, and the interface is the test surface

Where a change introduces or reshapes a module, the module's interface MUST be the surface both callers
and tests cross, and its shape MUST be defensible with the shared vocabulary: **module**, **interface**,
**implementation**, **depth**, **seam**, **adapter**, **leverage**, **locality**. A module whose
complexity vanishes when it is deleted was a pass-through, not a module.

#### Scenario: A module is defensible

- **WHEN** a change introduces a module and the deletion test is applied to it
- **THEN** the complexity it absorbs reappears across its callers when it is removed, which is what makes it earn its interface

#### Scenario: A module is a pass-through

- **WHEN** deleting a module makes the complexity vanish rather than reappear across its callers
- **THEN** it is a finding: it carries a large interface over little implementation, and the reviewer names it as shallow

#### Scenario: A seam is introduced with no variation across it

- **WHEN** a seam is introduced and nothing actually varies across it
- **THEN** it is a finding: one adapter is a hypothetical seam, two make it real

### Requirement: The builder loads the craft

The build stage MUST load the craft it exercises: `build-craft` for the test discipline and
`bug-diagnosis` for the loop that precedes a fix, alongside `test-driven-development` which carries the
red-green cycle itself. The hard rule of `rules/testing.md` is unchanged by this: a stuck task is
diagnosed, never theorised about, and the seam of a module the change introduces is recorded.

#### Scenario: The builder's method list resolves

- **WHEN** the build stage's brief is assembled and its methods are loaded
- **THEN** `build-craft` and `bug-diagnosis` are among the loaded methods, and a method that cannot be loaded is reported in `blockers` rather than improvised

#### Scenario: The stage resolves its methods from the shipped wiring

- **WHEN** the build stage's method list is read from `workflows/implement-change.md` and `agents/builder.md`
- **THEN** both files name `build-craft` and `bug-diagnosis`, and `workflows/review-change.md` and `agents/reviewer.md` name `module-design` for the review side

#### Scenario: A task gets stuck

- **WHEN** a task cannot be completed and the cause is not yet visible
- **THEN** the builder runs a command that fails on the defect before proposing a fix, and reports the command and its output as the evidence for the fix's cause

### Requirement: The reviewer checks the craft against the diff

The reviewer MUST report a `MAJOR` finding, with `path:line`, for each blocking craft violation it
reads in the real diff: an assertion whose expected value is recomputed the way the code computes it,
a test coupled to internals, a batch of tests written before the implementation they exercise, or a
bug fix whose regression test does not fail without the fix.

#### Scenario: A tautological assertion reaches the review

- **WHEN** the diff carries an assertion whose expected value is derived the way the implementation derives it
- **THEN** the reviewer reports a `MAJOR` finding with the assertion's `path:line` and the reason it can never disagree with the code

#### Scenario: A regression test does not fail without the fix

- **WHEN** a bug fix ships a regression test that passes on the pre-fix content
- **THEN** the reviewer reports a `MAJOR` finding naming the test — a test that passes before and after proves nothing about the fix

#### Scenario: The craft is respected and nothing is reported

- **WHEN** the diff's tests live at agreed seams, assert values independent of the implementation, and the fix's regression test fails without it
- **THEN** the reviewer reports no craft finding, and records the checks it ran as its evidence line

### Requirement: The reviewer flags the craft's softer defects

The reviewer MUST report a `MINOR` finding, with `path:line`, for the softer craft defects it reads in
the real diff — and each finding names the vocabulary term it disputes:

- tests written at a seam that was neither agreed nor declared;
- a module whose complexity vanishes when it is deleted (a pass-through), or a seam with nothing
  varying across it.

#### Scenario: A test lives at an undeclared seam

- **WHEN** the diff carries a test at a seam the change neither agreed nor declared
- **THEN** the reviewer reports a `MINOR` finding naming the seam and its path — the test may be right, and the artifact that records where testing happens is missing

#### Scenario: A pass-through module reaches the review

- **WHEN** the diff introduces a module and deleting it makes its complexity vanish rather than reappear across its callers
- **THEN** the reviewer reports a `MINOR` finding, naming it as shallow and citing the deletion test's result
