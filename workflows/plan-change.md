# Workflow: plan-change

Turns the validated and designed change into a granular, verifiable and ordered
execution plan, inside the change's `tasks.md`.

- **Agents:** `planner`
- **Rules:** `rules/openspec.md`, `rules/quality.md`, `rules/testing.md`
- **Output:** `openspec/changes/<name>/tasks.md` ready to implement.
- **Personas/method:** `task-decomposition-expert` · `writing-plans` (the plan is written for whoever executes it without context).

## 0. Preflight (Hermes)

```bash
cd <project-root>
test -f openspec/project.md || echo "MISSING project.md → initialize-project (blocking)"
openspec context --json                                 # root.path == <project-root>
openspec status --change "<name>" --json
openspec instructions apply --change "<name>" --json    # review state/contextFiles
```

- Validated change (without `ERROR`) and closed design (or `design.md` present). If the
  design is missing, run `openspec-to-architecture` first; you do not plan blindly.
- `applyRequires` must include `tasks`: that is exactly what this workflow produces.

## 1. Breakdown (`planner` agent)

Brief: project root, change, spec and design paths, repo commands, Done
criterion, and the instruction to **not expand scope**.

The agent writes `tasks.md` with the OpenSpec format:

```
## 1. <Group>

- [ ] 1.1 <verifiable task, ≤ 1 day>
- [ ] 1.2 <verifiable task>
```

Rules:

- One task = one verifiable unit; "implement the module" is not a task.
- Order by real dependency; the first group delivers something executable early.
- Each task indicates **how it is verified** (test command, expected evidence).
- It includes tests, docs and ADRs within the change's scope.
- It does not include generic review/QA tasks (those are stages), nor does it mark `- [x]` (that is the builder's job).

## 2. Plan validation (Hermes)

- [ ] Every requirement of the spec has at least one task (complete requirement → task map).
- [ ] No task requires a technical decision that is still open.
- [ ] No task adds unspecified scope.
- [ ] Granularity: no task hides more than one day or several decisions.

Loop: maximum 3 iterations. If new scope appears, it does not go into this change: it is reported
as a proposal for another change (`openQuestions`) and the human decides.

## 3. Plan closure

```bash
openspec status --change "<name>" --json
openspec validate "<name>" --type change --json
```

The change becomes `ready` to implement (`instructions apply` → `state: ready`).

## Output

Report (`templates/final-report.md`): groups and number of tasks, requirement → task map,
verification commands per task, new scope detected, and next step
(`implement-change`).

## Typical errors

- A plan that decides architecture instead of `architect` (unrecorded decisions appear).
- Tasks that are not verifiable ⇒ impossible to know whether the stage finished.
- `tasks.md` rewritten every time something changes: if the plan changes at its core, the scope
  changed and you have to talk about the change, not the plan.
