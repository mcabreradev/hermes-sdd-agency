## Why

The agency already treats blockers and evidence with discipline, but the **classes** and
**trust levels are implicit.** Today: a blocker can be `retryable`, `technical` or a human
decision without the workflow naming which — so the same "blocked" status can start a
bounded retry, a back-a-stage, or a waiting state, depending on the model's reading of the
situation. And Hermes verifies agent claims in the repo, but the *verification depth* is
not recorded: a `done` that Hermes re-checked and a `done` that rests only on the agent's
word both read the same in the trace and in the final report.

The ask: make both **explicit, auditable and resumable**. Every blocker carries a class
that selects the allowed response (retry / technical stop / human decision), and every
validated outcome carries a trust level (`verified` / `partially_verified` /
`self_reported` / `blocked`) — assigned by Hermes, never self-declared by the agent. The
rule that closes the loop's critical stages: **no critical stage (review / QA / release)
closes on `self_reported` alone** — Hermes must re-verify in the repo first.

## What Changes

- `rules/orchestration.md`:
  - the `blockers` field gains a required **class** (`retryable` | `technical` |
    `decision`) with the response each selects (retry rules table / back-a-stage or stop /
    human with options+recommendation+impact); an uncategorized blocker is
    `class: decision` by default (the human is never skipped by omission);
  - "Output validation" gains a **trust assignment** step between the agent's reply and
    the advance: Hermes classifies each validated outcome `verified` |
    `partially_verified` | `self_reported` | `blocked`, and the classification is
    recorded (in the final report and, when traced, in the trace entry);
  - "Completeness rules" hardens: a critical stage (review / QA / release) does not close
    on `self_reported` — Hermes must have re-verified the claim in the repo
    (`verified`, or `partially_verified` with the gap declared) before the stage advances.
- `rules/observability.md`: the trace-entry schema gains `class` (blocker classes) and
  `trust` (the trust vocabulary) so what the loop decides is auditable after the fact —
  a trace that cannot tell a verified pass from a self-reported one cannot serve as the
  audit source of truth.
- `bin/run-trace` (+ its fixture): prints and verifies `class` and `trust` per entry.
- Two new OpenSpec capabilities (`blocker-classification`, `trust-vocabulary`) and one
  modified (`observability/run-trace` for the new schema fields).

## Impact

- `rules/orchestration.md`, `rules/observability.md`, `bin/run-trace`,
  `fixtures/run-trace/` (schema fixture gains class/trust fields).
- No change to the gate or blocking authority: reviewer and QA still block; the trust
  vocabulary records the *depth* of the validation Hermes already performs, it never
  delegates approving power. An assessment is never a gate (same rule as review-tier).
- No runtime code beyond the run-trace reader; no new dependencies.
