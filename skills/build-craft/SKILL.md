---
name: build-craft
description: "Use when writing a failing test or judging one. Makes test-first produce tests worth keeping: seams agreed before the first test, the assertions that prove nothing, one vertical slice at a time."
---

# Build craft

`rules/testing.md` states the obligation: behavior-bearing work is built test-first, RED before GREEN.
This skill is the craft that makes the cycle produce a test worth keeping. It applies on **every**
cycle — read it before writing the test, not after it goes green.

The rule and this skill divide the work: the rule owns the *obligation and the prohibitions*; this
skill owns *what a test is*. Neither restates the other.

## The seam comes first

A **seam** is the boundary at which a test observes a behaviour without reaching inside it — the
location of a module's interface, not its implementation. Tests live at seams; they are never written
against internals.

Before writing the first test of a change, **state the seams under test and get them confirmed**. No
test is written at an unconfirmed seam. You cannot test everything, and agreeing the seams up front is
how the testing effort lands on the critical paths and the complex logic instead of on every edge case.

> **What's the public interface, and which seams should we test?**

The agreed seams go in the change's artifacts, so the reviewer can ask for the list instead of
reconstructing it from the diff. A test at a seam nobody agreed to may still be a good test — and the
artifact that records where testing happens is still missing.

When the *shape* of that interface is itself in question — how deep the module should be, where the
seam belongs, what the interface exposes — load `module-design`. It is a reference to consult, not a
session to run.

## A good test

A test verifies behavior through the public interface. Code can change entirely; tests shouldn't. A
good test reads like a specification — *"user can check out with a valid cart"* names the capability
that exists, and it survives a refactor because it does not care about internal structure.

The tell is the failure mode, not the assertion's style:

| If the code changes… | …and behaviour is unchanged | the test was written against |
|---|---|---|
| **fails** | — | the implementation (a finding) |
| passes | — | the interface (correct) |
| — | **fails** | the behaviour (correct) |

## The three anti-patterns

Each one passes a careless review, which is why they are named here rather than left to taste.

- **Implementation-coupled.** Mocks internal collaborators, tests private methods, or verifies
  through a side channel (querying the database instead of using the interface). The tell: the test
  breaks when you refactor but the behaviour has not changed.
- **Tautological.** The assertion recomputes the expected value the way the code does —
  `expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal
  to itself. It passes **by construction** and can never disagree with the code. Expected values must
  come from an independent source of truth: a known-good literal, a worked example, the spec's
  scenario.
- **Horizontal slicing.** Writing all the tests first, then all the implementation. Bulk tests verify
  *imagined* behaviour: you test the *shape* of things rather than user-facing behaviour, the tests go
  insensitive to real changes, and you commit to a test structure before understanding the
  implementation.

## The loop, one vertical slice at a time

- **One slice per cycle.** One seam, one test, one minimal implementation. Each test is a **tracer
  bullet** that responds to what the last cycle taught you.
- **Red before green.** Write the failing test first; watch it fail **for the expected reason** — a
  missing feature, not a typo. A green test before the code exists was aimed at the wrong thing.
- **Only enough code to pass.** No speculative features, no anticipating the next test.
- **Refactoring is not part of the loop.** It belongs to the review stage; the red→green cycle adds
  behaviour and nothing else.
- **Pin it against the real defect.** For a fix, the regression test must fail without the fix. A test
  that passes before and after proves nothing about the fix.

## Reporting

When the stage closes, say which seams were agreed, which spec scenarios the tests trace to, and which
behaviour is left uncovered with the reason. A green suite is a claim; the scenarios it covers are the
evidence.

The full vocabulary for a module's shape — depth, adapter, leverage, locality — is in `module-design`.
