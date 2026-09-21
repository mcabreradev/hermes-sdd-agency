# Hermes SDD orchestration system

Entry point. Hermes orchestrates; each project owns its specs.

> **How to invoke it:** `/agency` (or `/init-project`, `/idea`, `/architecture`, `/plan`,
> `/implement`, `/review`, `/qa`, `/release`). Full guide: `~/.hermes/HOW-TO-INVOKE-THE-AGENCY.md`
> · `hermes bundles list`

## What this is

Reusable global instructions for building software in any project with the
OpenSpec loop. **It contains no project's requirements.** Hermes provides the process
(agents, workflows, rules, templates); the project provides the product (`openspec/`,
code, docs, tests).

## Structure

```
~/.hermes/
  agents/      discovery · openspec · architect · planner · builder · reviewer · qa · release · pr-reviewer
  workflows/   initialize-project · idea-to-openspec · openspec-to-architecture ·
               plan-change · implement-change · review-change · qa-change · release-change ·
               pr-review
  rules/       orchestration · project-boundaries · openspec · quality · coding · testing
  templates/   openspec-project · proposal · tasks · spec · architecture · adr ·
               review-report · qa-report · initialize-project-report · final-report
```

Each role additionally has **personas and method** (aitmpl skills): the persona provides the
expertise, the role file provides the contract, and the stage workflow indicates which ones
to load. The detail lives in the `hermes-sdd-orchestration` skill
(`references/external-personas.md`); the "Persona and method" section of each agent is the
local reminder.

## How it is used

1. **Resolve the project** (always first):

   ```bash
   cd <project-root> && pwd -P
   openspec context --json            # root.path must match the expected root
   test -f openspec/project.md || echo "MISSING → initialize-project"
   ```

   If the root is ambiguous or `openspec/project.md` is missing, we do not proceed: `initialize-project`
   (or human confirmation). See the fail-safe in `rules/project-boundaries.md`.

2. **Read only what is needed**: the relevant rule + the stage workflow + the agent
   that executes it (and its personas). Not all agents are loaded at once.
3. **Load the personas** that the workflow names, with `skill_view(name='<slug>')`. If a
   skill is not installed, it is reported in `blockers` instead of improvising the role.
4. **Execute the workflow** step by step; each stage delegates to the corresponding agent with a
   self-contained brief and validates the output against its Done criterion.
5. **Close** with `templates/final-report.md`.

Canonical sequence:

```
initialize-project → idea-to-openspec → openspec-to-architecture → plan-change
   → implement-change → review-change → qa-change → release-change
```

## Rules that are never broken

1. **No implementation code is written without a validated OpenSpec change.**
2. **OpenSpec lives in each project's repo**, never in Hermes, never shared.
3. **Hermes operates against the current project root**; it never mixes context from sibling
   projects.
4. **Agents do not talk to each other**: all communication goes through Hermes, which validates.
5. **Product requirements are never global truth**: what is specific to the project lives
   in the project. No client or product requirement is stored in `~/.hermes/**`.
6. **Evidence > assertion**: an agent's output is verified in the repo before
   being accepted.
7. **Specs from sibling projects are never read**, nor are one project's requirements applied to
   another.
8. **`openspec/project.md` is mandatory** in the project: if it is missing,
   `initialize-project` is run before any other workflow.
9. **Every report declares the `projectRoot` of the run**; if it does not match the verified
   root, the report is rejected.

## Reading map by task

| I need to… | Read |
|---|---|
| understand who orchestrates and how | `rules/orchestration.md` |
| when the full SDD loop runs vs the fast path, and the language contract | `rules/sdd.md` |
| know where to write and what belongs to the project | `rules/project-boundaries.md` |
| create/validate/archive a change | `rules/openspec.md` + `workflows/idea-to-openspec.md` |
| the quality and reporting standard | `rules/quality.md` |
| write code and tests | `rules/coding.md` + `rules/testing.md` |
| start a project | `workflows/initialize-project.md` |
| close a change | `workflows/release-change.md` |
| an artifact's template | `templates/<artifact>.md` |
| walk the whole feature lifecycle (idea → PRD → … → release) | `docs/sdd-feature-lifecycle.md` |
| concrete copy-paste scenarios per level (feature/bugfix/fix/init) | `docs/usage-examples.md` |
| complete study change (proposal/spec/tasks real shape) | `docs/example-change/` |
| which persona/method to load at a stage | the agent's "Persona and method" section + `hermes-sdd-orchestration` |

## System state

- OpenSpec CLI on this machine: `~/.local/bin/openspec` v1.13.0 (`openspec-*` skills in
  `~/.hermes/openspec-global/.hermes/skills`, via `skills.external_dirs`).
- Global code conventions: those of `rules/coding.md` (prohibitions); the rest of the
  style is dictated by each project.
- The agents in `agents/` are not separate processes: they are contracts that Hermes loads and
  applies when delegating (`delegate_task`) or when executing the stage itself.
- **Personas and process skills**: 23 personas in `~/.hermes/skills/agents/` + 11 process
  skills in `~/.hermes/skills/`, installed from aitmpl. They cost one index line per
  session (~60 chars each): install only what a stage actually uses.
