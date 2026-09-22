# Hermes SDD Agency — the AI dev shop that audits itself

> An opinionated, Spec-Driven Development orchestration system for [**Hermes Agent**](https://hermes-agent.nousresearch.com/). One orchestrator, nine agent roles, and a review chain that turns "trust me" into hashes — OpenSpec holds the requirements **inside each project's repo**.

![MIT](https://img.shields.io/badge/license-MIT-purple.svg) ![OpenSpec 1.13+](https://img.shields.io/badge/OpenSpec-1.13+-blue.svg) ![for Hermes Agent](https://img.shields.io/badge/made%20for-Hermes%20Agent-orange.svg) ![5 evidence bins](https://img.shields.io/badge/evidence%20bins-5-teal.svg) ![60 skills](https://img.shields.io/badge/skills-60-brightgreen.svg) ![15 bundles](https://img.shields.io/badge/bundles-15-blueviolet.svg) ![install 1 command](https://img.shields.io/badge/install-1%20command-success)

## 📖 Contents

- [⚡ TL;DR](#-tldr)
- [🎯 The pitch](#-the-pitch)
- [📁 Repository layout](#-repository-layout)
- [🔄 The loop & the gate](#-the-loop--the-gate)
- [🔗 The evidence chain (5 bins)](#-the-evidence-chain-5-bins)
- [🤖 Agent roles](#-agent-roles)
- [🎚️ Task levels](#-task-levels)
- [🧠 Skill catalog (60 skills · 23 personas + 37 process)](#-skill-catalog-60-skills--23-personas--37-process)
- [🧪 Fixture suites](#-fixture-suites)
- [📜 Operating rules](#-operating-rules)
- [🚀 Quick start](#-quick-start)
- [🐕 How this repo eats its own dogfood](#-how-this-repo-eats-its-own-dogfood)

## ⚡ TL;DR

| | |
|---|---|
| **What** | The **process** of a Spec-Driven Development agency: rules, agent contracts, workflows, templates, skills and 15 slash-command bundles — reusable in any project |
| **Orchestrator** | Hermes is the **only bus**. Agents never talk to each other; every output returns to Hermes and is **re-verified in the repo** |
| **The gate** | No implementation code before a **validated OpenSpec change** exists in the project |
| **Who can block** | Only the **reviewer** and **qa** — open BLOCKER/MAJOR or `qa: fail` halts the loop |
| **Evidence** | 5 bins turn claims into hashes: a stage validates content it can point at, or it doesn't advance |
| **Product vs process** | This repo ships **process only**; no project's requirements live here — those live in each project's own `openspec/` |
| **Install** | `bash <(curl -fsSL …/install.sh)` — one command, guarded against overwrites |
| **Autonomous** | `/do` runs the whole loop end-to-end and ends in a PR for your morning review |

## 🎯 The pitch

AI coding agents forget, improvise, and self-report. Three failures break every AI-assisted workflow unless you build against them:

1. **Context amnesia** — a new session starts from zero and asks you what the files already answer. State lives in memory instead of the repo.
2. **Smoke** — an agent says "I tested it" about content it may never have seen, or a tree that changed five minutes later. The review describes code that no longer exists.
3. **Depth by mood** — big migrations get skimmed, small fixes get three passes, because review depth follows whoever is on shift instead of the diff's real risk.

The fix is structural: **state in files, evidence as hashes, review depth derived from the diff.** An agent's output is a self-report until a command proves it — always re-verify in the repo.

## 📁 Repository layout

```
agents/         agent contracts (discovery · openspec · architect · planner ·
                builder · reviewer · pr-reviewer · qa · release) + README
bin/            the 5 evidence bins: no-smoke-worktree · skill-registry ·
                review-snapshot · review-tier · agency-next
rules/          orchestration · openspec · sdd · quality · coding · testing ·
                project-boundaries
workflows/      initialize-project · idea-to-openspec · openspec-to-architecture ·
                plan-change · implement-change · review-change · qa-change ·
                release-change · pr-review · autonomous-change · continue-change
templates/      final-report · review-report · qa-report · adr · spec · tasks · …
docs/           evidence-bins · sdd-feature-lifecycle · usage-examples · FAQ
skill-bundles/  15 slash-command bundles: /agency /feature /do /review /qa …
skills/         60 process skills (23 agency personas + 37 workflow skills)
fixtures/       5 runnable test suites that pin the bins themselves
openspec/specs/ 7 capability specs — the agency's own requirements, versioned
```

One principle, everywhere (`rules/project-boundaries.md`): **Hermes provides the process; the project provides the product.** Global instructions are reusable and never carry a product requirement; product knowledge lives in the project's repo.

## 🔄 The loop & the gate

```
┌─────────────── the canonical loop ───────────────────────────────┐
│  0 initialize-project   (no code)                                │
│  1 discovery · idea / PRD                                        │
│  2 openspec · proposal + deltas     ◄── GATE: validate, no ERROR │
│  3 architect · design + ADRs                                     │
│  4 planner · tasks.md                                            │
│  5 builder · code + tests (TDD by hard rule)                     │
│  6 reviewer · adversarial diff    ◄── can BLOCK (BLOCKER/MAJOR)  │
│  7 qa · executes the scenarios   ◄── can BLOCK (qa: fail)        │
│  8 release · notes + archive + sync + evidence-comparison         │
└──────────────────────────────────────────────────────────────────┘
   gate: no code without a validated change · two failures with the
   same error ⇒ the spec is wrong, go back a stage — never in circles
```

Hermes is the only orchestrator: it decides which stage runs, delegates one bounded task per agent, validates every output in the real repo, applies retries and blockers, asks the human on ambiguity, and closes with a final report. Order: `initialize-project → discovery → propose → validate → plan → apply → verify → release`.

## 🔗 The evidence chain (6 bins)

One principle: **an agent's report is a self-report, not a fact.** Five small commands read files, print hashes, and never trust memory. The chain: **freeze → tier → review → compare**. Full step-by-step guide with real outputs: [`docs/evidence-bins.md`](docs/evidence-bins.md).

| Bin | Question it answers | When it runs |
|---|---|---|
| `no-smoke-worktree` | What is the exact content of this tree, right now? | every stage that claims evidence |
| `review-snapshot` | Which candidate was frozen before the review? | **before** the reviewer/QA read a thing |
| `review-tier` | How deep should this review go? | from the diff itself, before the review |
| `agency-next` | What is the single next step, and why? | every checkpoint, from files alone |
| `run-trace` | What happened in this run — and where did it stop? | resume / audit: reads `reports/<runId>.jsonl` |
| `skill-registry` | Which skills actually resolve — and which mis-route? | after any install/sync |

- **`no-smoke-worktree`** — content fingerprint of the working tree (tracked + untracked + ignored). Reviewer, QA and release record it; a mismatch at delivery means the evidence describes content that no longer exists. Survives rebase/amend; changes when any source changes.
- **`review-snapshot`** — freezes the candidate **before** anything reads it (base, HEAD, fingerprint, diff hash). Findings bind to that snapshot; `--compare` at delivery is content-based, so a clean rebase matches while a real change trips the alarm.
- **`review-tier`** — depth from the diff's shape: ≤400 authored lines ⇒ `medium`; schema/migration, auth, security config or dependency manifests ⇒ `high`; an unmeasurable diff ⇒ `cannot assess`, **never** a rubber-stamp `low`. Informational — never blocks.
- **`agency-next`** — the derived state + the single valid next transition, read from files. A missing input **narrows** the answer; it never defaults to optimistic, and it never blocks, merges or archives.
- **`skill-registry`** — read-only inventory: exact `SKILL.md` path, description, tags, and flags for the frontmatter defects that make a skill load but mis-route (`BLOCK-SCALAR` content-less indicator, `MISSING-DESCRIPTION`, `NO-FRONTMATTER`, `UNCLOSED-FRONTMATTER`). Pinned by its own fixture suite.

All five are informational or evidence-bound: they surface truth, they never silently approve. The gates remain the reviewer's and QA's verdicts.

## 🤖 Agent roles

| Role | Responsibility | Writes code? | Can block? |
|---|---|---|---|
| `discovery` | Explores the domain, writes the PRD, bounds vague ideas | No | — |
| `openspec` | Scaffolds the validated change: proposal, delta specs, scenarios | No | — |
| `architect` | Boundaries, contracts, rejected alternatives, ADRs | No | — |
| `planner` | Breaks the change into granular, verifiable tasks | No | — |
| `builder` | **The only stage that writes code** — test-first by hard rule | **Yes** | — |
| `reviewer` | Adversarial review of the diff against the spec, design, rules | No | **Yes** |
| `pr-reviewer` | Formal QA gate on the **PR itself** before it closes | No | **Yes** |
| `qa` | Validates **real behavior** against the spec scenarios by executing them | No | **Yes** |
| `release` | Release notes, archive, spec sync, evidence-comparison, final report | No | — |

Every output returns in the mandatory envelope (`status / summary / projectRoot / filesCreated / filesModified / blockers / nextRecommendedStep / evidence / openQuestions`), and Hermes re-verifies every claim against the real repo before the next stage.

## 🎚️ Task levels

| Level | Examples | Path |
|---|---|---|
| **Cosmetic** — no behavior change | typo, indentation, local rename | direct edit, no OpenSpec change |
| **Minimal** — bounded, with behavior | bug fix + regression test, error message | OpenSpec change with `skip_specs: true` |
| **Feature** — business rules / contract / architecture | new functionality, API change | **full loop** with delta spec, personas, formal QA + PR gate |

Language contract (`rules/sdd.md`): **everything the system produces is English** — specs, code, branches, commits, PRs, docs. The only exception is the conversation with the user.

## 🧠 Skill catalog (60 skills · 23 personas + 37 process)

Descriptions read from each skill's own `SKILL.md` frontmatter — generated by the repo's own `skill-registry` bin, so the catalog can't drift from what ships.

<details>
<summary><b>🧠 Agency personas — the roles that do the work</b> — 23 skills</summary>

| Skill | What it does |
|---|---|
| `architect-reviewer` | Review code for architectural consistency and patterns. |
| `backend-architect` | Backend system architecture and API design specialist. |
| `backend-developer` | Building server-side APIs, microservices |
| `code-architect` | Designs feature architectures by analyzing existing... |
| `code-reviewer` | Conduct comprehensive code reviews focusing on code quality |
| `code-simplifier` | Simplifies and refines code for clarity, consistency |
| `codebase-explorer` | Deep-dive analysis of unfamiliar codebases; mental model |
| `debugger` | Diagnose and fix bugs, identify root causes of failures |
| `error-detective` | Diagnose why errors are occurring in your system |
| `fullstack-developer` | Build complete features spanning database, API |
| `git-workflow-manager` | Design, establish, or optimize Git workflows |
| `legacy-modernizer` | Modernizing legacy systems that need incremental... |
| `pragmatic-architect` | Build, review, and refactor code based on the Pragmatic... |
| `prd` | Generate a comprehensive Product Requirements Document... |
| `qa-expert` | Validates real behavior against the spec scenarios by executing them. |
| `research-technical-spike` | Systematically research and validate technical spike... |
| `sdd-spec-writer` | Spec-driven development specs: executable contracts. |
| `security-auditor` | Conducting comprehensive security audits |
| `supply-chain-security` | Audit software supply chain: deps, artifacts, SLSA. |
| `task-decomposition-expert` | Break down a complex, multi-step goal into an... |
| `technical-debt-manager` | Expert technical debt analyst for code health |
| `test-engineer` | Test automation and quality assurance specialist. |
| `typescript-pro` | Implementing TypeScript code requiring advanced type... |
</details>

<details>
<summary><b>⚙️ Process & workflow skills — loaded on demand inside the stages</b> — 37 skills</summary>

| Skill | What it does |
|---|---|
| `architecture-decision-records` | Comprehensive patterns for creating, maintaining |
| `code-health` | Score repo quality 0-10 from real tool output, with befor... |
| `code-review-checklist` | Comprehensive checklist for conducting thorough code... |
| `commit-smart` | Analyze staged/unstaged changes and create semantic... |
| `context-architecture` | Audit a codebase and bind every claim it makes about itself to a mechanism that fails when the claim... |
| `design-exploration` | Generate multiple design variants, compare, and collect s... |
| `design-to-html` | Turn an approved design or description into clean, depend... |
| `developer-experience-review` | Audit a developer-facing surface: onboarding, docs, CLI; ... |
| `diagram-triplet` | Turn a description/mermaid source into excalidraw + SVG/P... |
| `dispatching-parallel-agents` | Facing 2+ independent tasks that can be worked on... |
| `document-diataxis` | Generate complete, structured docs with the Diataxis quar... |
| `e2e-testing-patterns` | Build reliable, fast, and maintainable end-to-end test... |
| `executing-plans` | You have a written implementation plan to execute in a... |
| `openspec-apply-change` | Implement tasks from an OpenSpec change. Use when the use... |
| `openspec-archive-change` | Archive a completed change in the experimental workflow. ... |
| `openspec-bulk-archive-change` | Archive multiple completed changes at once. Use when arch... |
| `openspec-continue-change` | Continue working on an OpenSpec change by creating the ne... |
| `openspec-explore` | Enter explore mode - a thinking partner for exploring ide... |
| `openspec-ff-change` | Fast-forward through OpenSpec artifact creation. Use when... |
| `openspec-new-change` | Start a new OpenSpec change using the experimental artifa... |
| `openspec-onboard` | Guided onboarding for OpenSpec - walk through a complete ... |
| `openspec-propose` | Propose a new change with all artifacts generated in one ... |
| `openspec-sync-specs` | Sync delta specs from a change to main specs. Use when th... |
| `openspec-update-change` | Update an OpenSpec change by revising its existing planni... |
| `openspec-verify-change` | Verify implementation matches change artifacts. Use when ... |
| `plan-scope-review` | Choose a scope mode for a plan before planning: expand, h... |
| `project-learnings` | Persistent per-project learnings, versioned with the code... |
| `qa-test-planner` | Generate comprehensive test plans, manual test cases |
| `requirements-clarity` | Clarify ambiguous requirements through focused dialogue... |
| `review-structural` | Scan a diff for structural defects before landing; SQL, t... |
| `security-evidence-first` | Security review: evidence before assurance; attacker, bou... |
| `software-development` | Invoke the SDD agency: /agency and per-stage bundles. |
| `verification-before-completion` | About to claim work is complete, fixed, or passing |
| `visual-design-review` | Visual QA of a live UI: catch slop, fix with before/after... |
| `web-performance-benchmark` | Baseline Core Web Vitals and bundle size; before/after on... |
| `writing-plans` | You have a spec or requirements for a multi-step task |
</details>

> Generated from `skills/**/SKILL.md` frontmatter by `bin/skill-registry` — the catalog's source of truth is the repo.

## 🧪 Fixture suites

The bins are pinned by **runnable suites**, not by fixtures that never run. A suite that can't run fails loudly (exit 3), never passes silently.

| Suite | Pins |
|---|---|
| `fixtures/sensitive-paths/check.sh` | the deny-list matches every documented row |
| `fixtures/skill-registry/check.sh` | 13 detector cases incl. the false-positive shapes it was fixed for |
| `fixtures/review-tier/check.sh` | tier derivation (26 cases) |
| `fixtures/review-snapshot/check.sh` | freeze/compare semantics (10 cases) |
| `fixtures/agency-next/check.sh` | the state machine (15 cases, throwaway repos) |

## 📜 Operating rules

| Rule | Purpose |
|---|---|
| `orchestration.md` | Hermes is the only orchestrator; agents never talk to each other, never read each other's state |
| `openspec.md` | **The gate**: no code without a validated OpenSpec change — no exceptions |
| `sdd.md` | When the full loop runs vs the fast path; language contract (everything produced is English) |
| `quality.md` | Quality is verifiability — evidence binds to content, never to claims; frozen-candidate + review tier |
| `coding.md` | Work-unit commits (~400-line heuristic for one reviewable delivery); scope declared and diffed |
| `testing.md` | Behavior-bearing work is **test-first** (TDD) by hard rule; only behavior-free code is exempted with a reason |
| `project-boundaries.md` | Strict isolation: process vs product vs `~/.hermes`; sensitive-path deny list enforced on evidence |

## 🚀 Quick start

**One command** installs the process tree, skills and 15 bundles into a Hermes home (default `~/.hermes`; interactive menu, guarded against accidental overwrites, idempotent):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mcabreradev/hermes-sdd-agency/main/install.sh)
```

Then, in any project:

```bash
hermes        # > let's run SDD: add SSO login to the web app
/agency       # run the loop stage by stage
/feature      # feature-level (full loop, discovery-first)
/do           # autonomous: run the whole loop, end in a PR for your morning review
/continue     # resume an existing change from its pending stage, update the PR
```

For `/feature`'s discovery step, install the four discovery skills once (`superpowers:brainstorming` + mattpocock's `grilling`, `grill-with-docs`, `domain-modeling`) — the installer warns, never installs. Full guide: `INSTALL.md`.

## 🐕 How this repo eats its own dogfood

This repository is maintained **by the process it ships**: every feature here went through the same loop — an OpenSpec change, adversarial review, a formal PR QA gate (#15), a frozen-candidate evidence chain (#19), and the fix of a false positive (`skill-registry`) that a real reviewer caught because the loop demands evidence over assertion. The skill catalog above is generated by one of the bins it ships. If one day this README becomes a self-report, the loop is designed to notice.

---

*The process is the product. [MIT](LICENSE) — the persona skills under `skills/agents/` keep their upstream provenance (aitmpl.com) in their frontmatter.*
