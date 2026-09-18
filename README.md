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

1. Clone this repo somewhere stable.
2. **Install each bundle** (repeat for the ones you want):
   ```bash
   hermes skills install /path/to/hermes-sdd-agency/skill-bundles/<name>.yaml
   ```
   or place the `.yaml` files in `~/.hermes/skill-bundles/`.
3. **Copy the global process tree** into the target `~/.hermes/`:
   ```bash
   cp -R agents workflows rules templates docs ~/.hermes/
   ```
   and the personas into `~/.hermes/skills/agents/`.
4. Restart the session (skills load fresh per conversation).
5. In any project: run `/agency` (or `/feature`, `/bugfix`, `/fix`) and go.

For a full walkthrough of the idea → release path, see `docs/sdd-feature-lifecycle.md`.
For copy-paste scenarios (feature, bug fix, cosmetic, init, resume) see
`docs/usage-examples.md`. Frequently asked questions: `docs/FAQ.md`. For a complete
study change showing the real `proposal.md` / `spec.md` / `tasks.md` shape, see
`docs/example-change/`. A rendered landing page is live at
**[mcabreradev.github.io/hermes-sdd-agency/](https://mcabreradev.github.io/hermes-sdd-agency/)**.

See also `CONTRIBUTING.md` (how to change the agency) and `CHANGELOG.md` (release
history).

## First run calibration

The loop is **contract, not enforcement**: nothing validates an agent's reply
mechanically, so the loop is only as good as the brief. Before trusting it on a large
change, run a small (3–5 task) change end to end with real delegations — preflight,
builder, review, qa, release — and make the briefs stricter from what the first
envelope reveals.

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
