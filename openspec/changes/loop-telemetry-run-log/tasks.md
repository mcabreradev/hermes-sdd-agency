## 1. Define the run-trace schema and rule

- [ ] 1.1 Add `rules/observability.md` defining the trace-entry schema (stage, status, files created/modified, evidence, blockers, decisions/ASSUMED, timestamp, run id) and the rule that the run log is the source of truth for resume/audit — verifies: `grep -q "run-trace" rules/observability.md`
- [ ] 1.2 Document the "log is additive — never changes the evidence-first gate or reviewer/QA blocking authority" boundary — verifies: `grep -q "additive" rules/observability.md`

## 2. Write the run-trace reader

- [ ] 2.1 Add `bin/run-trace` that reads a run log and emits the audit summary (stages, status, blockers, cycles, ASSUMED) from the structured log alone — verifies: `bin/run-trace --file <sample-run.json>` returns the summary
- [ ] 2.2 Add a minimal sample run-log fixture proving the reader handles done/blocked/parked entries — verifies: `bin/run-trace --file <fixture>` exits 0 and prints all entries

## 3. Wire trace recording into the stages

- [ ] 3.1 `workflows/idea-to-openspec.md` records its closure trace entry — verifies: `grep -q "run-trace" workflows/idea-to-openspec.md`
- [ ] 3.2 `workflows/openspec-to-architecture.md` records its closure trace entry — verifies: `grep -q "run-trace" workflows/openspec-to-architecture.md`
- [ ] 3.3 `workflows/plan-change.md` records its closure trace entry — verifies: `grep -q "run-trace" workflows/plan-change.md`
- [ ] 3.4 `workflows/implement-change.md` records its closure trace entry — verifies: `grep -q "run-trace" workflows/implement-change.md`
- [ ] 3.5 `workflows/review-change.md` records its closure trace entry — verifies: `grep -q "run-trace" workflows/review-change.md`
- [ ] 3.6 `workflows/qa-change.md` records its closure trace entry — verifies: `grep -q "run-trace" workflows/qa-change.md`
- [ ] 3.7 `workflows/release-change.md` records its closure trace entry — verifies: `grep -q "run-trace" workflows/release-change.md`

## 4. Park-and-resume in autonomous mode

- [ ] 4.1 `workflows/autonomous-change.md` records a "parked — decision needed" trace entry at a non-trivial decision and the resume path from that stage — verifies: `grep -q "parked" workflows/autonomous-change.md`

## 5. Reports and docs cross-reference

- [ ] 5.1 `templates/final-report.md` cites/logs the run trace in the report — verifies: `grep -q "run-trace" templates/final-report.md`
- [ ] 5.2 Update `README.md`, `docs/sdd-feature-lifecycle.md` and `docs/FAQ.md` to mention the run trace — verifies: `grep -q "run-trace" README.md`
