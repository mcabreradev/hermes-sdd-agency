# Template: reports/initialize-project.md

Initialization report, written **in the project** (`reports/initialize-project.md`) by
`workflows/initialize-project.md`. It is the artifact that records the context with which
the repo entered the SDD loop.

---

```markdown
# Project initialization — <project name>

- **Date:** <YYYY-MM-DD>
- **Project root:** <absolute path verified with `pwd -P` + `openspec context --json`>
- **Run by:** Hermes (`workflows/initialize-project.md`)
- **Status:** completed | blocked | partial

## Repository verification

<!-- How it was confirmed that this was the intended repo (step 2 of the workflow). -->

```bash
pwd -P
basename "$(pwd -P)"
git rev-parse --show-toplevel 2>/dev/null || echo "no-git"
git remote -v 2>/dev/null || echo "no-remote"
openspec context --json
```

- OpenSpec root: <path> (`source: <nearest>`, `role: openspec_root`)
- Nested root detected? <no | yes: root fixed at <path>>
- Git repo? <yes/no — consequences if not>

## Inputs received

| Input | Value | Source |
|---|---|---|
| Project name | <...> | human |
| Product idea | <...> | human |
| Target users | <...> | human |
| MVP goal | <...> | human |
| Preferred stack | <...> | human |
| Business rules | <...> | human |
| Technical constraints | <...> | human |

**Pending** (unanswered inputs, written as `Pending:` in `project.md`):

- <pending question>

**Divergences detected** between what was declared and the real repo:

- <e.g.: declared stack X, the repo uses Y — Y prevails, verified in <path:line>>

## OpenSpec status

- Root: <path> · `config.yaml` present · default schema: <spec-driven>
- Active changes: <none | list with completed/total tasks>
- Existing capabilities: <none | list with requirementCount>
- `openspec validate --all --json`: <totals: X passed, Y failed>

## Structure created

| Path | Status | Note |
|---|---|---|
| `openspec/` | created by `openspec init --tools hermes` \| already existed | |
| `openspec/project.md` | created | local product context |
| `docs/architecture/` | created \| already existed | place for current architecture |
| `docs/decisions/` | created \| already existed | project ADRs |
| `reports/` | created \| already existed | run reports |
| `reports/initialize-project.md` | created | this file |

## Repository surveyed

- **Real stack:** <language/runtime/frameworks/data>
- **Commands:** build `<...>` · test `<...>` · lint `<...>` · typecheck `<...>`
- **Structure:** <relevant top-level directories>
- **Tests:** <where they live, how they are run, state>
- **Existing documentation:** <AGENTS.md / README / docs, and what they cover>

## What was NOT created (on purpose)

- [ ] Product implementation code (it is born with a validated OpenSpec change).
- [ ] Build/lint/CI scaffolding not explicitly requested by the human.
- [ ] Copies of Hermes agents, workflows or global rules inside the repo.

## Closure verification

```bash
test -f openspec/project.md && test -d docs/architecture && test -d docs/decisions \
  && test -f reports/initialize-project.md && echo "initialization OK"
git status --porcelain
```

- [ ] `openspec/project.md` exists.
- [ ] `docs/architecture/` exists.
- [ ] `docs/decisions/` exists.
- [ ] `reports/initialize-project.md` exists (this file).
- [ ] No feature implementation created.
- [ ] Nothing written outside the project root.

## Next step

<recommended workflow — usually `idea-to-openspec` with the first MVP idea, or
`openspec-onboard` if the project already has code and capabilities must be surveyed>
```
