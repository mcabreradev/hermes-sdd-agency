# Template: autonomous-report

Closing report that Hermes issues to the user at the end of an AUTONOMOUS MODE
run (`/do`). It is the artifact the user reads in the morning; it must make the
whole run auditable from one file: what ran, what was assumed, and what the
user should check in the PR before merging.

It does not replace the per-stage reports; it summarizes them.

---

```markdown
# Autonomous report — <change-name>

- **Date:** <YYYY-MM-DD>
- **Project:** <project root>
- **Status:** completed | stopped (non-trivial decision) | escalated (quality wall)
- **PR:** <link to the draft PR awaiting review>
- **Change:** <name> — archived in openspec/changes/archive/ if closed

## What ran

| Stage | Agent | Result | Evidence |
|---|---|---|---|
| discovery | … | done | <path, command, output> |
| openspec | … | done | validate output |
| architect | … | done | design.md, ADRs |
| planner | … | done | tasks.md |
| builder | … | done | git diff --stat, gate |
| reviewer | … | approved | review-report.md |
| builder (fixes) | … | done | gate |
| qa | … | pass | qa-report.md, executed matrix |
| release | … | done | archived + synced |

## Artifacts

<!-- Files created/modified inside the project (paths). -->

## Verification

<!-- Real gates run and their result: validate, build, tests, QA. What was NOT
     run is said here explicitly. -->

## ASSUMED decisions (REVIEW ME — the part a human must check)

<!-- EVERY routine default taken in autonomous mode, as an ADR with path. This
     list is the reason the PR is a draft. One line each:
     what was assumed, where the ADR lives, what would change if you reject it. -->

- <assumption> → `docs/adr/NNNN-<slug>.md` · if rejected: <impact>

## OpenSpec status

- Change: <name> — <in-progress | archived>
- Tasks: <completed>/<total>
- New/modified capabilities: <list>

## Defects, debt and gaps

<!-- Open findings with severity, declared debt, NOT RUN scenarios. "none" if
     truly nothing. -->

## Next step

<!-- Exactly one: "review and approve PR <n>", or the decision the user needs
     to make for the stopped stage. -->

## Lessons for the global system

<!-- Proposals for rules/workflows, for the user to decide. -->
```

## Rules

- The **ASSUMED decisions** section is mandatory and must list every routine
  default taken — an empty run has an empty list, not a missing one. This is
  the contract that makes "sleep on it" auditable.
- A `stopped` status must say exactly what decision is waiting and the options.
- No claims without evidence; the stage table cites where each result lives.
- The PR is a draft **because** the ASSUMED list is there. If a run has zero
  assumptions, the PR is still a draft (the human reviews).
