---
name: bug-diagnosis
description: "Use when something is broken, failing or intermittent. Diagnose before fixing: a command that goes red on this bug first, then falsifiable hypotheses."
---

# Bug diagnosis

A discipline for hard bugs: the one that resists a first glance, the intermittent flake, the
regression that crept in between two known-known-good states. Skip a phase only when it is explicitly
justified in the report.

The failure this skill exists to prevent: **reading code to build a theory before any command has gone
red on the bug.** A fix built that way is a guess, and its regression test — if it exists — passes
before and after.

## Redact first

You will show commands, outputs and captured artifacts. **Redact every secret** before it reaches a
report: write `<REDACTED>` in its place. Build loops against environment variables, so the credential
stays in the environment rather than in what you show. Captured artifacts carry auth headers; quote
only the lines that carry the signal. If the redacted output is not enough to diagnose the bug, say so
and ask — do not unredact.

## Phase 1 — Build a feedback loop

**This is the skill.** Everything else is mechanical. With a **tight** pass/fail signal for the bug —
one that goes red on *this* bug — you will find the cause; bisection, hypothesis-testing and
instrumentation all just consume it. Without one, no amount of staring at code will save you.

Spend disproportionate effort here. Be aggressive; be creative; refuse to give up.

Ways to construct one, roughly in order:

1. **Failing test** at whatever seam reaches the bug: unit, integration, e2e.
2. **curl / HTTP script** against a running dev server.
3. **CLI invocation** with a fixture input, diffing stdout against a known-good snapshot.
4. **Headless browser script** that drives the UI and asserts on DOM/console/network.
5. **Replay a captured trace** — save a real request, payload or event log to disk and replay it
   through the code path in isolation.
6. **Throwaway harness** — a minimal subset of the system that exercises the bug's code path with one
   call.
7. **Property / fuzz loop** — for "sometimes wrong output", run a thousand random inputs and look for
   the failure mode.
8. **Bisection harness** — automate "boot at state X, check, repeat" so a `git bisect run` can drive
   it.
9. **Differential loop** — the same input through old vs new (or two configs), diffing the outputs.
10. **HITL script** — last resort. If a human must click, drive *them* with a script so the loop stays
    structured and their output feeds back to you.

### Tighten the loop

Treat the loop as a product. Once you have *a* loop, tighten it:

- **Faster?** Cache the setup, skip unrelated init, narrow the test scope.
- **Sharper?** Assert the specific symptom, not "didn't crash".
- **More deterministic?** Pin time, seed the RNG, isolate the filesystem, freeze the network.

A 30-second flaky loop is barely better than none; a 2-second deterministic one is a debugging
superpower.

For non-deterministic bugs the goal is not a clean repro but a **higher reproduction rate**: loop the
trigger a hundred times, parallelise, add stress, narrow timing windows. A 50%-flake bug is debuggable;
1% is not, so keep raising the rate until it is.

### When you genuinely cannot build one

Stop and say so explicitly. List what you tried and ask for: access to whatever environment reproduces
it, a redacted captured artifact, or permission to add temporary instrumentation. **Do not proceed to
a hypothesis without a loop.**

**Phase 1 is done** when you can name **one command** — a script path, a test invocation, a curl — that
you have **already run at least once** (show the invocation and its output, redacted), and that is:

- [ ] **Red-capable** — it drives the bug's code path and asserts the user's exact symptom, so it can
      go red on this bug and green once fixed.
- [ ] **Deterministic** — the same verdict every run (for a flake: a pinned, high reproduction rate).
- [ ] **Fast** — seconds, not minutes.
- [ ] **Agent-runnable** — you can run it unattended.

## Phase 2 — Reproduce and minimise

Run the loop; watch it go red as the bug appears. Confirm the failure mode is the one the **user**
described, not a nearby different failure — wrong bug, wrong fix. Capture the exact symptom so a later
phase can verify the fix actually addresses it.

Then **minimise**: shrink the repro to the smallest scenario that still goes red. Cut inputs, callers,
config, data and steps **one at a time**, re-running after each cut, keeping only what is load-bearing
for the failure. A minimal repro shrinks the hypothesis space in Phase 3 and becomes the clean
regression test in Phase 5.

Done when **every remaining element is load-bearing**: removing any one of them makes the loop go
green. Do not proceed until you have reproduced **and** minimised.

## Phase 3 — Hypothesise

Generate **3–5 ranked hypotheses** before testing any of them; single-hypothesis generation anchors on
the first plausible idea. Each must be **falsifiable** — state the prediction it makes:

> **If** `<X>` **is the cause, then** changing `<Y>` will make the bug disappear / changing `<Z>` will
> make it worse.

If you cannot state the prediction, it is a vibe: discard it or sharpen it. **Show the ranked list to
the user before testing it.** They often have domain knowledge that re-ranks instantly ("we just
deployed a change to #3"), or know hypotheses already ruled out. Cheap checkpoint, big time saver —
don't block on it if they are away.

## Phase 4 — Instrument

Each probe must map to one specific prediction. **Change one variable at a time.**

Preference order: **debugger / REPL inspection** if the environment supports it (one breakpoint beats
ten logs); then **targeted logs** at the boundaries that distinguish hypotheses. Never "log everything
and grep".

**Tag every debug log** with a unique prefix (e.g. `[DEBUG-a4f2]`); cleanup then becomes a single grep.
Untagged logs survive and become sediment.

For a **performance regression**, logs are usually the wrong instrument: establish a baseline
measurement (timing harness, profiler, query plan), then bisect. Measure first, fix second.

## Phase 5 — Fix, with a regression test at a seam

Write the regression test **before** the fix — but only if there is a **correct seam**: one where the
test exercises the real bug pattern as it occurs at the call site. A test at a seam too shallow (a
single-caller test when the bug needed several, a unit test that cannot replicate the chain that
triggered it) gives false confidence.

**If no correct seam exists, that is itself the finding.** Note it, and flag it as a candidate for a
design change — the architecture is preventing the bug from being locked down. Consult `module-design`
for where a better seam would go.

Where a correct seam exists:

1. Turn the minimised repro into a failing test at that seam.
2. Watch it fail — for the reason the bug fails.
3. Apply the fix.
4. Watch it pass.
5. Re-run the Phase 1 loop against the **original, un-minimised** scenario.

## Phase 6 — Cleanup

Required before declaring done:

- [ ] The original repro no longer reproduces (re-run the Phase 1 loop).
- [ ] The regression test passes — or the absence of a seam is documented as the finding.
- [ ] All `[DEBUG-...]` instrumentation removed (grep the prefix).
- [ ] Throwaway prototypes deleted or moved to a clearly marked debug location.
- [ ] The hypothesis that turned out correct **stated in the commit or PR message**, so the next
      debugger learns.

## Reporting

The stage's evidence is the loop's invocation and its output, redacted — not a description of the bug.
A fix reported without the command that went red before it is a theory, and `rules/testing.md` treats it
as one.
