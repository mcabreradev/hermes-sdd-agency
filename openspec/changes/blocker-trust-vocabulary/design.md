# Design — Blocker classification and trust vocabulary

## Context

The agency already retries bounded defects, stops circular retries, raises non-trivial
decisions to the human, and re-verifies agent claims in the repo. What is missing is that
each of those behaviors is selected by a **named class** and each validation leaves a
**recorded trust depth**. Requirements that shape the approach: the gates stay human and
reviewer/QA-owned (an assessment is never a gate); the trace (just archived) is the audit
surface, so the new fields must land there too; no new runtime beyond the reader bin.

## Goals / Non-Goals

**Goals:**
- Every blocker carries `class: retryable | technical | decision`, and the workflow
  response is selected by the class (retry table / back-a-stage or stop / human).
- Every validated outcome carries `trust: verified | partially_verified | self_reported |
  blocked`, assigned by Hermes — never self-declared.
- Critical stages (review / QA / release) never close on `self_reported` alone.
- The trace and `bin/run-trace` surface both fields (audit after the fact).

**Non-Goals:**
- Changing who can block (reviewer/QA authority unchanged) or what the gates are.
- Automating retries beyond the existing retry table, or new tooling beyond the reader.
- A numeric/score trust model per agent (a per-agent trust ledger is a later change if
  ever; the vocabulary here is per-outcome, not per-agent).

## Decisions

### Decision: Unclassified blockers default to `decision`

The safe direction: if a class is omitted, the human is consulted, never silently retried
or skipped. An omission must not be able to bypass a human decision — same default as
`cannot-assess` never collapsing to the cheapest tier.

### Decision: Hermes assigns trust, never the agent

The agent reports; Hermes classifies (separation of recommendation and authority, as the
agency already does for transitions). An agent self-declaring its own trust would be the
"agent judging its own work" failure, applied to validation depth.

### Decision: The trace gains `class` and `trust`

The audit surface must record what the loop decided. A trace that cannot distinguish a
verified pass from a self-reported one cannot serve as the source of truth for resume and
audit. The reader prints both; the fixture pins the shapes.

### Decision: No change to the release fingerprint story

The trace stays gitignored per run; the new fields do not change where the log lives.
`bin/run-trace` remains read-only bash + jq. The fixture grows but the append/ignore
properties are unchanged.

## Risks / Trade-offs

- **Risk:** stages forget to classify blockers → the default `decision` escalates to the
  human more often than strictly needed. Accepted: that failure mode is safe (human eyes),
  and the alternative (retry on default) is the dangerous one.
- **Risk:** trust depth recorded after the fact drifts from what Hermes really did.
  **Mitigation:** the classification happens in the same validation step that decides the
  advance; the report/trace entry is written from that decision.
- **Trade-off accepted:** four levels instead of a richer per-agent ledger — per-outcome is
  what the gates need, and a per-agent ledger is a later change if the data ever calls for it.

## Delivery strategy (recorded per rules/coding.md)

Measured against `main`: **341 authored lines** (`git diff --numstat main...HEAD` after
the implementation commits). Under the advisory ~400-line budget; `single-pr` is the
natural shape.
