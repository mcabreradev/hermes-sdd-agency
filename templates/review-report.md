# Template: review-report

Report from the `reviewer` agent to Hermes. It is written to the path indicated by the
brief (inside the project; typically next to the change or in the repo's reports
directory).

---

```markdown
# Review — <change-name>

- **Date:** <YYYY-MM-DD>
- **Project root:** <absolute path verified with `openspec context --json`>
- **Diff base:** <commit/branch>
- **Scope:** <files/range reviewed>
- **Verdict:** approved | changes-requested | blocked

## Evidence

<!-- Commands run and their relevant output. The repo's gate, re-run by the
     reviewer (or declared as not run and why). -->

```
<command>
<relevant output>
```

## Spec compliance

| Requirement / Scenario | Status | Evidence |
|---|---|---|
| <requirement> | covered / partial / not covered | <path:line or test> |

## Findings

### BLOCKER

- **<path:line>** — <what is wrong>. **Impact:** <real consequence>. **Proposed fix:**
  <what to do>.

### MAJOR

- **<path:line>** — ...

### MINOR

- **<path:line>** — ...

### NIT

- **<path:line>** — ...

## Undeclared scope

<!-- Files touched outside the list declared by the builder, or declared files
     that were not touched. Each one is a finding. -->

## Declared debt (what can be left)

<!-- MINOR/NIT that do not block, with the reason they are left. -->

## Spec questions

<!-- Ambiguities that affect approval. -->
```

## Rules

- A finding with no `path:line` or without evidence does not go into the report.
- The verdict cannot be `approved` with open `BLOCKER`/`MAJOR`.
- The reviewer does not implement the fix: they deliver verifiable material so that Hermes
  builds the correction brief for the builder.
- The report does not include style opinions beyond what the project rules and
  `rules/coding.md` declare.
