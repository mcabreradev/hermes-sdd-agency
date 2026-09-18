# Workflow: qa-change

Validates the real behavior against the spec's scenarios, with execution. The last filter
before closure.

- **Agents:** `qa` (and `builder` for the fixes)
- **Rules:** `rules/testing.md`, `rules/quality.md`, `rules/openspec.md`
- **Output:** QA report (`templates/qa-report.md`) + verdict.
- **Personas/method:** `qa-expert` + `test-engineer` · `qa-test-planner` (scenario → case → result matrix) · `e2e-testing-patterns` for the full path.

## 0. Preflight (Hermes)

```bash
cd <project-root>
test -f openspec/project.md || echo "MISSING project.md → initialize-project (blocking)"
openspec context --json                                 # root.path == <project-root>
openspec instructions apply --change "<name>" --json
git status --porcelain
<repo gate command>
```

- Requires review `approved` (or `approved` with debt accepted and recorded by Hermes).
- Hermes fixes the scope: change, scenarios to validate, environment available and how it is
  brought up. If the project has no way of being run in this environment, that is decided here
  (and the QA report will be `blocked` with the reason).

## 1. Execution (`qa` agent)

Brief: project root, change, spec paths (source of the scenarios), review
report, repo commands, and the Done criterion: complete scenario → case → real result
matrix; no `PASS` without execution.

Agent rules: it validates behavior, it does not read code to conclude; it retries failures
once to rule out the environment; it reports flaky with both outputs; the scenarios that cannot be
run are marked `NOT RUN` with the reason.

### Report-only mode (`qa-only`)

When the brief asks for **report-only** (or the change is being QA'd before any fix is
authorized), the `qa` agent produces the same matrix **without fixing anything**:

- Complete scenario → case → real result matrix, with `FAIL` + reproduction steps and
  "expected vs actual" for every defect — but **no** builder correction cycle runs.
- Output includes a **health summary** (see `code-health`) as the before-score baseline, so a
  later fixing pass can show the before/after.
- The report's verdict is `fail` if any `BLOCKER`/`MAJOR` defect exists, `pass` only when the
  matrix is clean — report-only does not change the closure bar, it only skips the fix loop.
- Record the **`worktree-no-smoke` fingerprint** so the report is bound to the exact tree
  that was exercised (see `rules/quality.md`).

## 2. Validation of the report (Hermes)

- Every `PASS` must have executed evidence (command + output).
- Every `FAIL` must bring reproduction steps and the "expected vs actual".
- Without real execution, the stage does not close even if the report says `pass`.

## 3. Correction cycle (builder)

For each `BLOCKER`/`MAJOR` defect: brief to the `builder` with the scenario, the reproduction
steps and the expected fix. Require the regression test that fails without the fix.

- Max. 3 builder ↔ QA cycles. On the third with the defect still alive: escalate to the user with
  the evidence.
- After each correction: re-run the gate and the affected scenario (and the rest of the
  matrix if the change was broad).
- If the defect contradicts the spec (the spec asks for something undesirable or ambiguous): stop and
  propose a spec change.

## 4. Closure

With the complete matrix and no blocking defects, the stage closes and enables
`release-change`.

## Output

Report (`templates/final-report.md`): matrix state, open/closed defects,
non-verifiable scenarios (verifiability gaps), cycles used, and next step
(`release-change`).

## Typical errors

- QA that trusts the builder's tests without executing the real path.
- Marking a scenario `PASS` "by reading the code".
- Not recording the `NOT RUN`: the verifiability gaps become invisible debt.
- Correcting in QA (mixing roles): the fix goes back to the builder and brings a regression test.
