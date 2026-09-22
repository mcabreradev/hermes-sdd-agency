# Hermes SDD Agency

[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](LICENSE)
[![OpenSpec](https://img.shields.io/badge/OpenSpec-1.13+-blue.svg)](INSTALL.md)
[![Made for Hermes Agent](https://img.shields.io/badge/made%20for-Hermes%20Agent-orange.svg)](https://hermes-agent.nousresearch.com/)
[![Site](https://img.shields.io/badge/website-live-teal.svg)](https://mcabreradev.github.io/hermes-sdd-agency/)
![Status: public](https://img.shields.io/badge/status-public-brightgreen.svg)

An opinionated **Spec-Driven Development** orchestration system for [Hermes
Agent](https://hermes-agent.nousresearch.com/). Hermes is the sole orchestrator;
eight agent roles do the work; [OpenSpec](https://github.com/Fission-AI/OpenSpec)
holds the requirements **inside each project repo**.

Process is global, product is local: this repo ships the **process** (rules, agents,
workflows, templates, skill bundles, personas). It contains **no project's
requirements** — OpenSpec lives in each project's own `openspec/`.

## What's inside

```
agents/         role contracts (discovery · openspec · architect · planner ·
                builder · reviewer · qa · release) + README entry point
workflows/      initialize-project · idea-to-openspec · openspec-to-architecture ·
                plan-change · implement-change · review-change · qa-change · release-change
rules/          orchestration · project-boundaries · openspec · sdd · quality ·
                coding · testing
templates/      openspec-project · proposal · spec · tasks · architecture · adr ·
                review-report · qa-report · initialize-project-report · final-report
docs/           sdd-feature-lifecycle · usage-examples · FAQ
bin/            no-smoke-worktree — content-fingerprint of the working tree
                (binds reviewer/QA evidence to the exact tree they validated)
                skill-registry — read-only inventory of installed skills
                (exact SKILL.md path + description, flags defective frontmatter)
                review-snapshot — freezes the review candidate before anything reads it
                (content fingerprint + diff hash; --compare detects that the tree moved)
                review-tier — derives review depth (low/medium/high) from the diff
                (declared rules in rules/quality.md; informational, never a gate)
                agency-next — the derived state + the one valid next transition
                (read from files; informational, never blocks or authorizes)
skill-bundles/  /agency /feature /bugfix /fix and per-stage slash commands
skills/agents/  domain-expertise personas installed from aitmpl.com
```

One principle, everywhere (`rules/project-boundaries.md`): **Hermes provides the
process; the project provides the product.** Global instructions are reusable and never
carry a product requirement; product knowledge lives in the project's repo.

## The central gate

> **No implementation code is written before a validated OpenSpec change exists in the
> project.** `rules/openspec.md`

Order: `explore → propose → validate → apply → verify → archive`.

Three task levels, decided by Hermes (`rules/openspec.md` "Task size and fast path"):

| Level | Examples | Path |
|---|---|---|
| **Cosmetic** — no behavior change | typo, indentation, local rename | Direct edit, no OpenSpec change |
| **Minimal** — bounded, with behavior | bug fix + regression test, error message | OpenSpec change with `skip_specs: true` |
| **Feature** — business rules / contract / architecture | new functionality, API change | **Full loop** with delta spec, personas, formal QA |

Language contract (`rules/sdd.md`): **everything the system produces is written in
English** — specs, code, branches, commits, PRs, documentation. The only exception is
the conversation with the user.

## Install (into another Hermes)

**One command:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mcabreradev/hermes-sdd-agency/main/install.sh)
```

It asks where to install (default `~/.hermes`) via an interactive menu when
run in a terminal — arrow keys to navigate, space to toggle bundles, type to
filter, Enter to confirm, Esc/Ctrl+C to cancel; nothing is written until you
confirm the summary. On that final Yes/No confirm, `↑/←` picks **Yes**, `↓/→`
picks **No**, and the keys **y**/**n** work too — it defaults to **No** so an
overwrite can't ride a stray Enter. It merges the process tree, skills and
bundles, and is idempotent — safe to re-run. Piped runs (like the one-command
form above, stdin not a TTY) skip the menu and use the defaults. Flags:
`-p <home>` target (also honors
`$HERMES_HOME`), `--bundles a,b,c` subset, `--no-bundles`, `--dry-run`, `-y` to skip the
overwrite confirmation on non-interactive runs. Or clone and run `./install.sh` to skip the
re-download. Full guide in `INSTALL.md`.

### Enabling `/feature` (discovery skills)

`/feature` runs a **discovery-first** loop: it loads `superpowers:brainstorming`,
`grill-with-docs`, `grilling` and `domain-modeling` before any planning or code
(HARD-GATE: no implementation until the design is approved). Those four skills are
**not** shipped by this repo. Install them once on the target:

```bash
hermes plugins install obra/superpowers --enable       # brainstorming
npx skills@latest add mattpocock/skills                # the other three (entire set)
# or just the three:
#   npx skills@latest add mattpocock/skills -a hermes-agent \
#     --skill grilling --skill grill-with-docs --skill domain-modeling
```

The `install.sh` warns (never installs) when `/feature` is selected and these skills
are missing. Without them, `/feature` still runs the SDD loop; only its discovery step
cannot resolve its skills. `/agency` and the other stage bundles are unaffected.

### `/do` — autonomous mode (run the loop while you sleep)

`/do` runs the full agency loop end-to-end with minimal human input — discovery,
spec, plan, build, review, bugfix loop, QA, and a final **PR (draft)** awaiting your
review. You merge in the morning. It never publishes, tags or merges itself.

It is governed by a **confidence gate**: routine decisions (follow the existing
stack, minimal behavior, don't expand scope) run automatically with every decision
recorded as an ADR and flagged `ASSUMED — verify in PR`. The moment a stage hits a
**non-trivial** decision — a contract/API change, data-model change, real security
risk (auth/secrets/exposure), an ambiguous business rule that changes visible
behaviour, or something costly to revert — it stops that stage and waits for you.
"Routine sleeps, non-trivial wakes."

Every run ends with `templates/autonomous-report.md` in the project listing what
ran and every `ASSUMED` decision, so the PR is auditable. For routine, well-scoped
features this is exactly "go to sleep, wake up to a feature"; for a new domain or
anything touching a contract/security it stops and asks. Try it first on a toy
project, then read the first PR's ASSUMED list cover-to-cover before trusting it
overnight. See `workflows/autonomous-change.md`.

### `/continue` — continue an existing change

`/continue` continues when a **validated OpenSpec change already exists**
(proposal/spec/tasks, e.g. via `/feature`) and you want the rest of the loop run:
code → review → QA → archive+sync, ending with the **existing PR draft updated**.
It detects the state (`openspec list`/`status`, git, PR) rather than assuming it,
so it never re-runs discovery/spec already done and never opens a second PR. Same
confidence gate as `/do` (routine sleeps, non-trivial wakes). See
`workflows/continue-change.md`.

## Evidence you can verify: `no-smoke-worktree`

A claim that a stage "reviewed" or "tested" the work is a self-report. `bin/no-smoke-worktree`
prints a **content fingerprint** of the working tree (git `write-tree` over a temp index) that
binds an agent's evidence to the exact content it actually saw — it survives rebase/amend, and
changes when **any** source (including untracked files) changes.

Reviewer, QA and release stages record the fingerprint of the tree they worked on; at merge
time `release-change` compares them. A mismatch means the shipped tree was validated on older
content → re-review/re-test before landing. Enforced in `rules/quality.md`.

## Every run leaves a structured trace: `run-trace`

The loop also keeps a **machine-readable memory of each run**. Each stage appends a
structured trace entry (stage, change, status, files, evidence, blockers, decisions/ASSUMED,
run id, next step, timestamp) to `reports/run-<run-id>.jsonl` — the single source of truth
for resuming a partial run and auditing what happened, so a dead session or a parked
decision doesn't force re-reading prose. `bin/run-trace` emits the run summary from the log
alone. The trace is additive (it mirrors the envelope, `rules/observability.md`) and lives in
the project, never in `~/.hermes/**` (`rules/project-boundaries.md`); it is gitignored so a
growing log never disturbs the `no-smoke-worktree` release fingerprint.

## Complementary skills (`skills/`)

Beyond the personas and OpenSpec mechanics, the repo ships process skills for the loop:

- **implement** `test-driven-development` — **hard rule at the build stage**:
  behavior-bearing work — backends, business logic, API endpoints, bug fixes — is written
  test-first (RED→GREEN→REFACTOR) with no agent discretion to skip it; only
  behavior-free code is declared `not applicable` with a reason.
  `domain-modeling` — DDD the architect applies when the domain merits it. Both wired
  into `rules/testing.md`, `agents/builder.md` and `agents/architect.md`.
- **review** `review-structural` — diff scan for SQL, LLM trust-boundary, conditional side effects.
- **qa** `code-health` (0-10 score), report-only mode in `qa-change`.
- **plan** `plan-scope-review` — pick a scope mode (expand / hold / strip) before planning.
- **reliability** `web-performance-benchmark` (Core Web Vitals), `project-learnings`
  (`.context/learnings.jsonl`), `developer-experience-review` (plan vs reality).
- **design** `visual-design-review`, `design-exploration`, `design-to-html`, `diagram-triplet`.
- **docs / security** `document-diataxis` (coverage map, used by `release-change`),
  `security-evidence-first` (attacker·boundary·impact·challenge).

For a full walkthrough of the idea → release path, see `docs/sdd-feature-lifecycle.md`.
For copy-paste scenarios (feature, bug fix, cosmetic, init, resume) see
`docs/usage-examples.md`. Frequently asked questions: `docs/FAQ.md`. For a complete
study change showing the real `proposal.md` / `spec.md` / `tasks.md` shape, see
`docs/example-change/`. A rendered landing page is live at
**[mcabreradev.github.io/hermes-sdd-agency/](https://mcabreradev.github.io/hermes-sdd-agency/)**.

See also `CONTRIBUTING.md` (how to change the agency) and `CHANGELOG.md` (release
history).

Always re-verify an agent's claim in the repo (`git status --porcelain`,
`git diff --stat`, re-run the gate) — **an agent's output is a self-report, not a fact**.

## Rules that are never broken

1. No implementation code without a validated OpenSpec change.
2. OpenSpec lives in each project's repo, never in Hermes.
3. Hermes operates against the current project root; never mixes sibling-project context.
4. Agents never talk to each other; every output goes to Hermes, which validates.
5. Product requirements are never global truth.
6. Evidence > assertion; outputs are re-verified in the repo.
7. Every report declares `projectRoot`.
8. `openspec/project.md` is mandatory in the project.

## License

MIT — see `LICENSE`. The persona skills under `skills/agents/` are installed from
aitmpl.com and keep their upstream provenance in their `SKILL.md` frontmatter.
