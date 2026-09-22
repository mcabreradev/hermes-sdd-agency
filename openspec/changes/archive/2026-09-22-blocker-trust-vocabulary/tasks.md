## 1. Blocker classes in the orchestration rule

- [x] 1.1 `rules/orchestration.md` — the `blockers` field gains the required class
      (`retryable` | `technical` | `decision`) with the response each selects; an
      uncategorized blocker is treated as `class: decision` — verifies:
      `grep -qE "retryable|technical|decision" rules/orchestration.md && grep -q "class: decision" rules/orchestration.md`
- [x] 1.2 The retry/blocking rules bind each class to its response (retry consumes an
      iteration; technical → back-a-stage or stop, never circular retry; decision →
      human with options + recommendation + impact) — verifies:
      `grep -q "circular retry" rules/orchestration.md || grep -q "back a stage" rules/orchestration.md; grep -q "recommendation + impact" rules/orchestration.md`

## 2. Trust vocabulary in the orchestration rule

- [x] 2.1 `rules/orchestration.md` — "Output validation" assigns a trust level
      (`verified` | `partially_verified` | `self_reported` | `blocked`) after Hermes
      validates the reply, made by Hermes never by the agent — verifies:
      `grep -q "self_reported" rules/orchestration.md && grep -q "verified" rules/orchestration.md`
- [x] 2.2 "Completeness rules" — a critical stage (review / QA / release) does not close
      on `self_reported` alone — verifies:
      `grep -q "self_reported" rules/orchestration.md && grep -qE "review|QA|release" rules/orchestration.md`

## 3. Trace schema + reader keep the audit surface honest

- [x] 3.1 `rules/observability.md` — the trace-entry schema gains `class` and `trust`
      fields — verifies: `grep -q "\`class\`" rules/observability.md && grep -q "\`trust\`" rules/observability.md`
- [x] 3.2 `bin/run-trace` prints blocker `class` and `trust` per entry; the fixture pins
      a done/blocked/parked set carrying both fields — verifies: the fixture suite runs
      green (`bash fixtures/run-trace/check.sh` exit 0) and its sample entries carry
      `class`/`trust`

## 4. Close the loop

- [x] 4.1 The final-report template surfaces the trust vocabulary (per-stage trust in the
      verification section) — verifies: `grep -q "trust" templates/final-report.md`
- [x] 4.2 `openspec validate` green on the change and the fixture suites run — verifies:
      `openspec validate --all` failed == 0
