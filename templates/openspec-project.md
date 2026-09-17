# Template: `openspec/project.md` (project product context)

**Usage:** consumed by `workflows/initialize-project.md` to create `openspec/project.md`
**inside each project**. Hermes replaces the `{{variables}}` with the human's inputs and the
facts verified in the repo, and writes the result to `<project-root>/openspec/project.md`.

Filling rules:

- **Nothing invented.** A variable with no answer from the human is replaced by
  `Pending: <specific question>` and reported in `blockers`/`openQuestions`.
- **Repo facts win.** If the declared preferred stack differs from the one the repo
  actually uses, the real one prevails and the divergence is noted.
- **No `{{ }}` remain in the written file**: if a variable could not be resolved, the
  previous rule applies; the placeholder is not left behind.
- **Sections are not deleted**: if a section does not apply yet, it stays with
  `Pending: <what is still to be defined>`.
- **Forbidden** to paste this whole file into the project or copy Hermes agents/workflows:
  the project receives only its `project.md` and the rest of its structure.
- `openspec/project.md` is a **Hermes convention**, not a CLI one: `openspec validate`,
  `list` and `status` ignore it completely (verified in v1.13.0). Its absence blocks the
  other workflows (`rules/project-boundaries.md`).

## Template (copy verbatim and substitute)

```markdown
# Project: {{projectName}}

## Purpose

{{productIdea}}

## Target Users

{{targetUsers}}

## Main Problem

{{mainProblem}}

## MVP Goal

{{mvpGoal}}

## Scope

{{scope}}

## Non-Goals

{{nonGoals}}

## Preferred Stack

{{preferredStack}}

## Business Rules

{{businessRules}}

## Technical Constraints

{{technicalConstraints}}

## Architecture Principles

{{architecturePrinciples}}

## Product Rules

{{productRules}}

## Quality Expectations

{{qualityExpectations}}

## Agentic Workflow Rules

- OpenSpec is the source of truth for this project.
- No feature implementation before an OpenSpec change exists.
- Every change must include proposal.md, tasks.md, and spec.md.
- Every implementation must trace back to a requirement.
- Ambiguous behavior requires human approval.
- Hermes must operate only inside this project root.
```

## Variables

| Variable | Source | If missing |
|---|---|---|
| `{{projectName}}` | input `project name` (verified against the root's `basename` and the remote) | block: without a project name it is not initialized |
| `{{productIdea}}` | input `product idea` | `Pending: what is this product and what problem does it solve?` |
| `{{targetUsers}}` | input `target users` | `Pending: who are the target users?` |
| `{{mainProblem}}` | input `main problem`; if not given, it is **derived** from `product idea` and marked `(derived from product idea)` | `Pending: what is the main problem it solves?` |
| `{{mvpGoal}}` | input `MVP goal` | `Pending: what must the first version achieve?` |
| `{{scope}}` | input `MVP goal` + what the human declares as in scope | `Pending: what is in scope for this first stage?` |
| `{{nonGoals}}` | what the human explicitly declares out of scope | `Pending: what is explicitly left out?` |
| `{{preferredStack}}` | input `preferred stack` + real commands surveyed from the repo | `Pending: project stack and commands?` |
| `{{businessRules}}` | input `business rules` (list) | `Pending: what business rules must the software respect?` |
| `{{technicalConstraints}}` | input `technical constraints` (list) | `Pending: what technical limits apply?` |
| `{{architecturePrinciples}}` | declared by the human; if the repo already has architecture, it is summarized from `docs/architecture/` citing the path | `Pending: what architecture principles govern?` |
| `{{productRules}}` | observable product rules (what the product must and must not do) | `Pending: what product rules apply?` |
| `{{qualityExpectations}}` | the human's expectations + the repo's real gate (tests, coverage, performance) | `Pending: what level of quality is expected?` |

Sections with literal text, **no variables**:

- `## Agentic Workflow Rules` — boilerplate of the SDD system: it is copied as is, without
  editing, adding or removing bullets.

## List format

`{{businessRules}}`, `{{technicalConstraints}}` and the like are rendered as lists:

```markdown
- <rule> — <observable consequence>
- Pending: <question>
```

In `{{preferredStack}}`, the repo's real commands go as a code block, because the
project's gate needs them (build/test/lint/typecheck):

````markdown
| Area | Choice |
|---|---|
| Language / runtime | <...> |
| Frameworks | <...> |
| Data | <...> |
| Infra / deploy | <...> |

```bash
build:      <real command>
test:       <real command>
lint:       <real command>
typecheck:  <real command>
```
````

## Verification after rendering

```bash
cd <project-root>
test -f openspec/project.md && echo "exists"
grep -c '{{' openspec/project.md          # must be 0
grep -n '^# Project: ' openspec/project.md
grep -n '^## Agentic Workflow Rules' openspec/project.md
```

- [ ] No `{{ }}` remain.
- [ ] All 15 sections are present (title + 14 `##`), including `Agentic Workflow Rules` intact.
- [ ] Every declared gap says `Pending:` with a specific question.
- [ ] The file is at `<project-root>/openspec/project.md` and nowhere else.

---

## Appendix — project structure (workflow reference, NOT copied into `project.md`)

```
<project-root>/
  openspec/                      # owner: the project. NEVER global.
    config.yaml                  # written by `openspec init`
    project.md                   # this template, rendered
    specs/                       # durable capabilities (main specs)
      <capability>/spec.md
    changes/                     # active changes
      <change-name>/             # created ONLY by `openspec new change`
        .openspec.yaml
        proposal.md
        design.md                # conditional
        specs/<capability>/spec.md
        tasks.md
      archive/                   # closed changes: YYYY-MM-DD-<name>/
  .hermes/skills/openspec-*      # generated by `openspec init --tools hermes`
  AGENTS.md | .hermes.md         # project rules (commands, style, conventions)
  docs/
    architecture/                # current architecture
    decisions/                   # ADRs
  reports/                       # run reports (initialize-project, review, qa, …)
```

If the repo already has its own places for architecture, decisions or reports, they are
respected and recorded in `openspec/project.md`.

### Block for the project's `AGENTS.md`

```markdown
## Workflow (Hermes SDD)

- Requirements and design live in this repo's `openspec/`. No specs outside the repo.
- No code is written without a validated `openspec/changes/<name>/`
  (`openspec validate "<name>" --type change --json` with no ERROR).
- The change is created with `openspec new change "<name>"`, never by hand.
- Project commands: build `<...>`, test `<...>`, lint `<...>`, typecheck `<...>`.
- Agents report to Hermes; they do not communicate with each other.
- Agents do not modify `~/.hermes/**` nor adopt conventions from other repos.
```

### Adoption checklist

- [ ] Root resolved and with no accidental nested roots (decided and written in `AGENTS.md`).
- [ ] `openspec/project.md` rendered, with no `{{ }}`.
- [ ] `openspec validate --all --json` → 0 failed (or the failures reported as findings).
- [ ] `docs/architecture/`, `docs/decisions/` and `reports/` created (or the repo's own
      places recorded in `project.md`).
- [ ] Project rules and real commands in `AGENTS.md` / `.hermes.md`.
- [ ] Initial capabilities surveyed with `openspec-onboard` (project with code) or the
      first capability created with the first change (new project).
- [ ] Zero product context stored in `~/.hermes/`.
