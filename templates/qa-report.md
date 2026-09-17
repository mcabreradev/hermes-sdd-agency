# Template: qa-report

Report from the `qa` agent to Hermes. It is written to the path indicated by the brief
(inside the project).

---

```markdown
# QA — <change-name>

- **Date:** <YYYY-MM-DD>
- **Project root:** <absolute path verified with `openspec context --json`>
- **Environment:** <OS, runtime, how the project was brought up>
- **Repo gate:** `<command>` → <green/red, output summary>
- **Verdict:** pass | fail | blocked

## Scenario matrix

| # | Scenario (spec) | Case run | Result | Evidence |
|---|---|---|---|---|
| 1 | <#### Scenario: ...> | <command/steps> | PASS / FAIL / NOT RUN | <output or reason> |
| 2 | ... | ... | ... | ... |

## Defects

### BLOCKER

- **Scenario:** <which one>. **Observed:** <what happens>. **Expected:** <what should
  happen>. **Reproduce:**
  ```
  <steps or command>
  ```
  **Evidence:** <real output, error text>.

### MAJOR

- ...

### MINOR

- ...

## Flaky

<!-- Tests or cases that pass only on retry, with both results. -->

## Verifiability gaps

<!-- NOT RUN scenarios and why (environment, non-automatable interaction, external
     service). These are visible debt, not approved. -->

## Validated critical path

<!-- The end-user path described in proposal.md: what was run and what was observed. -->
```

## Rules

- Every scenario of the delta spec appears in the matrix: none is omitted silently.
- `PASS` with no executed evidence is not PASS. `NOT RUN` is a valid answer and carries a
  reason.
- Failures come with reproduction and "expected vs actual"; without that, the correction
  brief cannot be built.
- QA does not fix: the fix goes back to the builder and brings a regression test.
