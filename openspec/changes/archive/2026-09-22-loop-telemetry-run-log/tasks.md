## 1. Define the run-trace schema and rule

- [x] 1.1 Add `rules/observability.md` defining the trace-entry schema fields (stage, change, status, files created/modified, evidence, blockers, decisions/ASSUMED, run id, next recommended step, timestamp) — verifies: `grep -qE "stage|status|blockers|runId|change|timestamp" rules/observability.md`
- [x] 1.2 Document the "log is additive — never changes the evidence-first gate or reviewer/QA blocking authority" boundary and the complete envelope status vocabulary — verifies: `grep -q "additive" rules/observability.md && grep -q "approved" rules/observability.md`
- [x] 1.3 Update `rules/orchestration.md` so the mandatory envelope gains a `runId` field threaded through every stage brief/entry of a run — verifies: `grep -q "runId" rules/orchestration.md`

## 2. Write the run-trace reader and a fixture

- [x] 2.1 Add `bin/run-trace` (bash + `jq`, read-only) that reads a run log and emits the audit summary (stages, status, blockers, ASSUMED) from the structured NDJSON alone — verifies: `bin/run-trace --file <sample-run.jsonl>` exits 0 and prints each stage with status/blockers/ASSUMED
- [x] 2.2 Add a minimal sample run-log fixture `fixtures/run-trace/sample.jsonl` with done / blocked / parked entries and confirm the reader handles all three — verifies: `bin/run-trace --file <fixture>` exits 0 and prints the done, blocked and parked entries

## 3. Wire trace recording into the stages

Each stage records its trace entry at closure with the run id from the brief and appends to `reports/run-<run-id>.jsonl`. Verification exercises the append (a fixture run), not a mere mention.

- [x] 3.1 `workflows/idea-to-openspec.md` records its closure trace entry — verifies: run a fixture preflight and confirm `reports/run-<run-id>.jsonl` gains a valid entry (`jq` parses it and the stage field is `idea-to-openspec`)
- [x] 3.2 `workflows/openspec-to-architecture.md` records its closure trace entry — verifies: fixture append yields a valid entry with the stage field `openspec-to-architecture`
- [x] 3.3 `workflows/plan-change.md` records its closure trace entry — verifies: fixture append yields a valid entry with the stage field `plan-change`
- [x] 3.4 `workflows/implement-change.md` records its closure trace entry — verifies: fixture append yields a valid entry with the stage field `implement-change`
- [x] 3.5 `workflows/review-change.md` records its closure trace entry — verifies: fixture append yields a valid entry with the stage field `review-change`
- [x] 3.6 `workflows/qa-change.md` records its closure trace entry — verifies: fixture append yields a valid entry with the stage field `qa-change`
- [x] 3.7 `workflows/release-change.md` records its closure trace entry — verifies: fixture append yields a valid entry with the stage field `release-change`

## 4. Park-and-resume in autonomous and continue mode

- [x] 4.1 `workflows/autonomous-change.md` records a "parked — decision needed" trace entry (stage named, status `needs-context`, decision in blockers/openQuestions) at a non-trivial decision — verifies: `grep -q "parked" workflows/autonomous-change.md` and a fixture non-trivial stop appends a parked entry (`jq` shows status `needs-context`)
- [x] 4.2 `workflows/continue-change.md` reads the run log's last parked/closed entry to determine the exact stage to resume from (trace as source of truth, checkboxes as cross-check) — verifies: `grep -q "run-trace" workflows/continue-change.md`

## 5. Keep the release fingerprint stable

- [x] 5.1 Add `reports/run-*.jsonl` to `.gitignore` so the growing trace never breaks the `no-smoke-worktree` fingerprint — verifies: `grep -q "reports/run-\\*.jsonl" .gitignore` and `bin/no-smoke-worktree` before/after a fixture append yields the same hash

## 6. Reports and docs cross-reference

- [x] 6.1 `templates/final-report.md` cites/logs the run trace — verifies: `grep -q "run-trace" templates/final-report.md`
- [x] 6.2 Update `README.md`, `docs/sdd-feature-lifecycle.md` and `docs/FAQ.md` to mention the run trace — verifies: `grep -q "run-trace" README.md docs/sdd-feature-lifecycle.md docs/FAQ.md`
