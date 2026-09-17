---
name: hermes-sdd-orchestration
description: "Use when running the Hermes SDD agent agency on a project."
version: 1.0.0
metadata:
  hermes:
    tags: [orchestration, sdd, openspec, agents, workflows, multi-agent]
    related_skills: [openspec-sdd, hermes-external-skills-and-agents, hermes-agent]
---

# Hermes SDD orchestration — the agency

How this machine runs software projects: Hermes is the **only orchestrator**; eight agent
roles do the work; OpenSpec holds the requirements **inside each project repo**.

Load `openspec-sdd` alongside this skill for the CLI mechanics (validators, archive traps,
root resolution). This skill is the process layer above it.

## When to use

Any request to plan, build, review, verify or ship a feature in a project; "run the
workflow"; "initialize the project"; "the agency"; "los agentes". Also load it before
editing anything under `~/.hermes/{agents,workflows,rules,templates}`.

**Shortest invocation:** the `/agencia` slash command (a skill bundle that loads this skill
plus `openspec-sdd` and injects the orchestrator protocol). Per stage: `/init-proyecto`,
`/idea`, `/arquitectura`, `/plan`, `/implementar`, `/review`, `/qa`, `/release` —
`hermes bundles list` shows them all. If the bundle is not available, this skill still
autoloads on the phrases above; the human-facing cheat sheet lives in
`~/.hermes/HOW-TO-INVOKE-THE-AGENCY.md`.

## Layout — process is global, product is local

```
~/.hermes/
  agents/      discovery openspec architect planner builder reviewer qa release (+README.md)
  workflows/   initialize-project idea-to-openspec openspec-to-architecture plan-change
               implement-change review-change qa-change release-change
  rules/       orchestration project-boundaries openspec quality coding testing
  templates/   openspec-project proposal tasks spec architecture adr
               review-report qa-report initialize-project-report final-report
```

`agents/README.md` is the entry point and reading map. Each workflow names its agent, its
preflight, its retry limit and its exit criteria — read the workflow before running a stage.

**A project owns** its `openspec/`, source, docs, tests and product context. **Hermes owns**
the process. Never store a project's requirements, domain rules or client facts in
`~/.hermes/**`; never copy global agents/workflows into a project.

## The sequence

```
initialize-project → idea-to-openspec → openspec-to-architecture → plan-change
  → implement-change → review-change → qa-change → release-change
```

One agent per stage. Independent stages may run in parallel (`delegate_task`); dependent
ones wait for Hermes to verify the previous output first.

## First run — exercise the loop before trusting it

The role files and the envelope are **contracts, not enforcement**: nothing validates an
agent's reply mechanically, so the loop is only as good as the brief. Before running the
agency on a large change (a 50+ task change is the wrong place to discover this), pick a
3–5 task change in a real project and run it end to end with real delegations — preflight,
builder, review, qa, release.

Expect the first envelope to come back incomplete, or with `evidence` that restates the
brief instead of quoting a command and its output. That is the signal to make the brief
stricter — name the exact command to run and the exact output to paste back — rather than
to add another paragraph to `rules/`.

Independent verification beats trusting a self-report: after any stage, re-check the claim
in the repo (`git status --porcelain`, `git diff --stat`, re-run the gate) before it unlocks
the next stage.

## Hard gate: no code without a validated change

`implement-change` does not start until all of these pass from the project root:

```bash
test -f openspec/project.md                        # else run initialize-project first
openspec context --json                            # root.path == expected root
openspec validate "<name>" --type change --json     # no ERROR (read the JSON, not the exit)
openspec instructions apply --change "<name>" --json  # state: ready | all_done
grep -rn '^## [A-Z]* Requirements' openspec/changes/<name>/specs/*/spec.md \
  | grep -vE 'ADDED|MODIFIED|REMOVED|RENAMED'        # any hit = inert delta; no output expected
```

A green `validate` is not a valid change: it judges structure, never whether the delta says what
the author meant. Two failures pass the CLI and still void the change — a requirement with no
`#### Scenario:`, and requirements filed under an invented header (e.g. `## UNCHANGED Requirements`)
that `validate`, `list` and `archive` all skip, so the change's central invariant (typically "no
breaking API changes") silently does not exist. Run the grep above and read every `issues[]` entry,
not the verdict. Detail, plus the empty-`openspec/specs/` case: `references/spec-artifact-validity.md`.

## Agent contract — mandatory envelope

`rules/orchestration.md` is the single source of truth for the format. Every agent reply to
Hermes carries all of these, none omitted (a no-op is `[]`, not a missing key):

```
status               done | blocked | failed | needs-context
                     (+ approved | changes-requested for reviewer; + pass | fail for qa)
summary              one line, no process narration
projectRoot          absolute path — must equal the root Hermes verified
filesCreated         absolute paths (or [])
filesModified        absolute paths (or [])
blockers             what stops it + which decision is needed (or [])
nextRecommendedStep  a proposal only; Hermes decides the transition
evidence             command + output, or path:line
openQuestions        doubts that change design, scope or business (or [])
```

- A `done` / `pass` / `approved` without evidence for **each** briefed objective degrades to
  `blocked`. A missing envelope field makes the reply invalid — return it to the agent with
  the same brief and the format requirement.
- **Agents never talk to each other.** No agent-to-agent file, no "pass this to the reviewer".
  Hermes is the only bus; agent output is a self-report until re-verified in the repo
  (`git status --porcelain`, `git diff --stat`, re-run the gate).
- The brief is self-contained: root, change name, exact paths, verification command, Done
  criterion, what NOT to touch. Agents do not read the conversation and get no context from
  other projects.

## Loop, blocking and completion

- **Retry limits**: discovery/openspec 2 · architect/planner 3 · builder 5 per task ·
  builder↔reviewer 3 · builder↔qa 3 · release 1. Retrying requires new information (the exact
  defect: command, output, `path:line`); repeating the same brief is forbidden. Two failures
  with the same error means the design or the spec is wrong — go back a stage, not in circles.
- **Only reviewer and qa may block.** No stage advances with an open BLOCKER/MAJOR, a
  `qa: fail` or any `blocked`. The agent that blocked never negotiates with the one implementing.
- **Ask the human** when business behavior, architecture, security or scope is ambiguous
  (options + recommendation + impact; write the answer into the project as spec/ADR, never
  into `~/.hermes/**`).
- **Complete** means: final stage verified by Hermes, clean `git status`, tasks ticked only
  where implemented, review `approved` + qa `pass`, and a final report written in the project
  (`templates/final-report.md`). Every workflow ends with that report — including a blocked one.

## Project boundaries that bite

- One root per stage. `openspec context --json` switches root silently with the cwd when
  nested roots exist; compare `root.path` against the expected root (with `pwd -P` — macOS
  `/tmp` is `/private/tmp`). Never proceed on the "most likely" root: block and report the
  literal JSON output.
- Read `openspec/` only from the current root. Never sibling repos, never reuse another
  project's requirements or conventions. Multiple projects requested ⇒ separate workflows.
- `openspec/project.md` is the marker that a project entered the loop — a Hermes convention
  the OpenSpec CLI ignores. Gate on `test -f`, never on a CLI verdict.
- A project whose root is not a git repo has no project-local skill discovery; say so.

## Reporting to this user

- **All agency documentation, code, identifiers, commits, file names and specs are in
  English.** Conversation with the user is in Spanish.
- **Every reply to the user is in Spanish — no exceptions.** This includes one-line
  acknowledgements, status updates and closing summaries after a task that ran entirely in
  English. Tool output, code blocks, paths, slugs and commands stay English by design; the
  prose around them does not. A reply in the wrong language (English, or any third language)
  is a failure: say so plainly in the next turn — the sent message cannot be recalled — and
  restate the content in Spanish.
- Deliverables close with the same envelope the agents use — status / summary / projectRoot /
  filesCreated / filesModified / blockers / nextRecommendedStep — plus what was actually
  verified and what is left. No replay of the process.
- Never claim a stage passed without a real command output behind it. If a gate could not be
  run, say so as `blocked` with the reason.

## References

- `references/external-personas.md` — the aitmpl personas and process skills that back each
  role, how to install them, where the installer really writes, and the upstream defects that
  make a converted persona silently useless.
- `references/stack-selection.md` — stack choice under the agency (persona coverage, the
  decision table), and the migration decisions: how to pick Rust vs Go vs not migrating, and the
  boundary-tax / consumer / non-serializable-surface checks to run before accepting a port plan.
- `references/performance-headroom.md` — how to measure the current engine's headroom before a
  performance-motivated rewrite (the floor / empty-expression / hand-compiled rows, equivalence
  checks, and what to propose when a local win exists).
- `references/spec-artifact-validity.md` — what `openspec validate` does not catch in a change's
  delta (invented requirement headers, scenario-less requirements, `## MODIFIED` with no target),
  with the detection greps.
