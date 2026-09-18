---
name: code-health
description: "Score repo quality 0-10 from real tool output, with before/after and trends."
---
<!-- hermes-add-skill: concept adapted from gstack /health (garrytan/gstack, MIT); implementation is host-agnostic. -->

# Code health score

Quantify repo quality from the project's own tools — a composite, weighted score
with before/after and trend tracking. It turns "it looks clean" into a number you
can audit and compare between stages.

## How

Run the project's real tooling (read the repo's declared commands, never invent):

- type checker
- linter (with the repo's configured rules)
- test runner
- dead-code / unused-import detector, if the project has one
- shell linter for any shell files

Compute a composite **0-10** score with explicit weights you state up front
(defaults: tests 40%, type-check 25%, lint 20%, dead-code 10%, shell 5% — adjust to the
project and declare the weights in the report). Each failing check subtracts proportionally.

## What must be in the report

- The **commands run** and their real output (evidence, per `rules/quality.md`).
- The **score breakdown** and the weights used.
- Any check that could not run, and why (`blocked`, not silently zero-rated).
- A **before/after** when used across stages (e.g. a fix's effect on the score) or the
  **trend** against previously stored scores, when a history exists.

## Persistence (optional, per-project)

If the project keeps a health history, store scores in the repo's own data file
(e.g. `.context/health.jsonl`) so trends and before/after survive across sessions. Do not
store scores in global memory — project data lives in the project.
