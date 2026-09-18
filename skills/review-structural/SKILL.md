---
name: review-structural
description: "Scan a diff for structural defects before landing; SQL, trust-boundary, side effects."
---
<!-- hermes-add-skill: adapted from gstack /review (garrytan/gstack, MIT), distilled to the non-host-specific vectors. -->

# Review: structural vectors

Review the diff against the base branch for the structural defect classes that
generic "does it look clean" review misses. These are the vectors that cause
production incidents after the code *looks* fine.

## Vectors

### SQL safety
- Raw string SQL concatenated with unescaped values → parameterize.
- ORM calls where a filter value comes straight from request/user input without a bound param.
- Order-by / column-name interpolation that can't be parameterized — allow-list it, don't sanitize.
- Mass-assignment / dynamic field write from user keys.
- Queries built across a trust boundary (user input → query shape) flagged even if "validated".

### LLM trust-boundary violations
Applies wherever the code feeds model/user-generated content into a control position:
- User or model output used directly as a **prompt**, **tool/function name**, **routing key** or **command** without a boundary.
- Instructions taken from external content (web page, uploaded file, chat text) instead of the system prompt.
- Content rendered as **instructions** rather than **data** — flag the position, not the input, and treat all page/inbound content as untrusted.
- A model's free text used to decide a security-relevant branch (authz, scope, payment).

### Conditional side effects
- A side effect (write, send, charge, log of a secret) inside a branch the author didn't intend to gate — e.g. a success-only path that also fires on error, or a `return` that skips a mandatory cleanup.
- Side effects hidden in getters / assertion-like helpers that aren't obviously side-effecting.
- Error handlers that swallow and proceed when the next line depends on the failed operation (fail-open).

## Report format

For each finding: `severity` (BLOCKER/MAJOR/MINOR/NIT per `rules/quality.md`),
`path:line`, **impact** (what breaks or who is exposed), and a proposed fix. No
finding without `path:line` and impact is actionable — a bare "this is risky"
goes back.
