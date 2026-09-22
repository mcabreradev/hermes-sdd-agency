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

<!-- Each stage's trust depth (rules/orchestration.md, "Trust vocabulary"): how much of the
     claim Hermes re-verified — verified (re-ran in the repo) / partially_verified (gap
     declared) / self_reported (not re-verified yet) / blocked. A critical stage (review / QA
     / release) never closes on self_reported alone. -->

<!-- If the run is traced (runId in the preflight), give the run log reference:

     bin/run-trace --file reports/<runId>.jsonl
     run: <runId> · change: <name> · entries: <N> · last: <stage> <status>

     The trace is gitignored by design; the summary above is the audit surface.
-->

## OpenSpec status

- Change: `<name>` — <in-progress | archived in changes/archive/YYYY-MM-DD-<name>>
- Tasks: <completed>/<total>
- New/modified capabilities: <list>

## Defects, debt and gaps

<!-- Open findings with severity, declared debt, NOT RUN scenarios, known
     flaky. If there is nothing, say "none". -->

## Review evidence

<!-- The evidence chain that binds this report to content, not claims
     (rules/quality.md). The snapshot freezes the reviewed candidate; the
     fingerprint anchors what this report validated; --compare at delivery
     is the mismatch test. Informational: never a replacement for the gates. -->

- Review snapshot: `reports/review-snapshot.json` (base `<base>`, head `<head>`)
  - Fingerprint: `<fingerprint from bin/no-smoke-worktree>`
  - Diff hash: `<diffHash from review-snapshot>`
- Delivery check: `review-snapshot --compare reports/review-snapshot.json` → `MATCH` / `MISMATCH`

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
