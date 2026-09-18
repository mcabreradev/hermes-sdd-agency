---
name: developer-experience-review
description: "Audit a developer-facing surface: onboarding, docs, CLI; plan vs reality."
---
<!-- hermes-add-skill: concept adapted from gstack /devex-review (garrytan/gstack, MIT) —
     the "boomerang": measure the plan promise against real developer experience. -->

# Developer experience review

Actually test the developer experience of a developer-facing surface (onboarding, docs,
CLI, API, SDK) and report where the *plan promised* diverges from *how it actually is*.
The value is in the gap — the boomerang between the doc's "getting started in 3 minutes"
and the reality of 8.

Use when a developer-facing feature ships (API, CLI, SDK, library, onboarding, docs) or when
asked to audit developer experience.

## What to measure

- **Time to hello-world (TTHW)**: from a cold start to the first working example, timed for
  real, not estimated.
- **Onboarding flow**: do the docs get someone from zero to first success without dead ends?
- **Doc quality by task**: can a developer *do the thing* (a how-to), not just read concepts?
- **CLI/help text**: is the surface discoverable and does the help text resolve the
  next step?
- **Error messages**: when something breaks, does the error tell you what to do?

## Plan vs reality (the boomerang)

- Compare measured reality against what the plan or docs **promised**.
- A promised time/score that reality misses is a defect with `path:line` + the measured
  number, not a mood.
- Produce a **DX scorecard** with evidence (timing, screenshots, exact error text), and a
  before/after when a fixing pass runs.

## Rules

- Measure the real surface — don't re-read the design doc and declare DX good.
- A claim "onboarding is smooth" needs the timed run plus the friction points found.
- Fixing the DX is its own change; the review reports the scorecard, the fix goes back to
  the builder with evidence (per `rules/quality.md`).
