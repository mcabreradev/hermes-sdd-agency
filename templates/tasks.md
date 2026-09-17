# Template: tasks.md (change plan)

Structure aligned with `openspec instructions tasks --change "<name>" --json`.
It is written by the `planner` to `openspec/changes/<name>/tasks.md`. The `builder` marks
`- [x]` **only** upon implementing and verifying.

---

```markdown
## 1. <Task group>

- [ ] 1.1 <verifiable task, ≤ 1 day> — verifies: `<command or evidence>`
- [ ] 1.2 <verifiable task> — verifies: `<command or evidence>`

## 2. <Task group>

- [ ] 2.1 <verifiable task> — verifies: `<command or evidence>`
```

## Rules

- One task = one unit verifiable on its own. "Implement module X" is not a task;
  "expose `<function>` that returns `<contract>` + test for scenario Y" is.
- The checkbox format is read by the CLI: `- [ ]` pending, `- [x]` complete. Do not use
  other markers or sub-lists that break the count (`totalTasks` in `openspec list --json`).
- Order by real dependency, not by convenience. The first group delivers something
  executable early.
- Include tests, docs and ADRs within the change's scope.
- Do not include: generic review/QA tasks (they are workflow stages) nor mark `- [x]`.
- Coverage: every requirement of the delta must be covered by at least one task. No
  orphan requirements.
- No tasks that depend on open decisions: that indicates the design is missing.

## Plan verification

```bash
openspec status --change "<name>" --json          # artifacts and applyRequires
openspec instructions apply --change "<name>" --json
openspec validate "<name>" --type change --json
```

The change becomes `ready` when `tasks` exists and `validate` has no `ERROR`.
