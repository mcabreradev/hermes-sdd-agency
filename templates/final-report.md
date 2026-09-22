# Template: final-report

Closing report that Hermes issues to the user when finishing a workflow (or when
escalating). It is the only artifact that summarizes the run; it does not replace the
reports of each stage.

---

```markdown
# Final report — <workflow> / <change-name>

- **Date:** <YYYY-MM-DD>
- **Project:** <project root>
- **Status:** completed | partial | blocked | escalated to the user

## What was done

<!-- One line per closed stage, with its artifact and path. Without narrating the process. -->

| Stage | Agent | Result | Evidence |
|---|---|---|---|
| <stage> | <agent> | <done/blocked> | <path, command, output> |

<!-- For the build stage, one row per coherent work unit, with that unit's commit
     identity in Evidence (`<hash> <subject>`). The commit is Hermes' action, per
     rules/coding.md; the builder reports the unit, Hermes records the hash. -->

## Artifacts

<!-- Files created/modified inside the project (paths), and nothing global unless
     the workflow justifies it. -->

## Verification

<!-- The real gates run and their result: OpenSpec validate, build, tests, QA.
     If something was not run, it is said here. -->

```bash
<command>
<summary output>
```

## OpenSpec status

- Change: `<name>` — <in-progress | archived in changes/archive/YYYY-MM-DD-<name>>
- Tasks: <completed>/<total>
- New/modified capabilities: <list>

## Defects, debt and gaps

<!-- Open findings with severity, declared debt, NOT RUN scenarios, known
     flaky. If there is nothing, say "none". -->

## Run trace

<!-- The structured per-run log and its audit summary (rules/observability.md). The
     trace is the source of truth for resume/audit; the report links it, it does not
     replace it. -->

- Run id: `<run-<UTC ISO-8601 compact>>`
- Trace: `reports/run-<run-id>.jsonl`
- Summary: `bin/run-trace --file reports/run-<run-id>.jsonl` → `<output>`

## Decisions made

<!-- Decisions recorded in the run (ADRs, design) with their path. -->

## Next step

<!-- Exactly one, actionable: the next workflow, or the decision the
     user needs. -->

## Lessons for the global system

<!-- What should change in Hermes's rules/ workflows/ agents/ templates/ as a result of
     this run (if anything). It is a proposal; the user decides. -->
```

## Rules

- No claims without evidence: every row of the stage table cites where the
  result is.
- Debt and gaps are declared explicitly; "all good" with `NOT RUN` scenarios is a
  false report.
- A single "next step", concrete and actionable.
- The report lives in the project; only the lessons for the global system are proposed to
  `~/.hermes/**`.
