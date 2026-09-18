# Project: hermes-sdd-agency

## Purpose

An opinionated **Spec-Driven Development** orchestration system for Hermes Agent. Hermes is the sole orchestrator; eight agent roles do the work; OpenSpec holds the requirements inside each project repo. This repo ships the **process** (rules, agents, workflows, templates, skill bundles, personas) — it contains no project's requirements.

## Target Users

Developers who use Hermes Agent and want to manage software projects through a spec-driven agency loop (`/agency`, `/feature`, `/bugfix`, `/fix`, `/do`, per-stage slash commands).

## Main Problem

(derived from product idea) Teams/agents writing code without first validating a spec leads to untraceable, unverifiable features. This system enforces a hard gate — no implementation code before a validated OpenSpec change exists in the project.

## MVP Goal

Provide a single-command installer (`install.sh`) that merges the process tree, skills and bundles into a Hermes home, plus the landing page and documented workflows to run the full agency loop.

## Scope

The process assets shipped in this repo: `agents/`, `workflows/`, `rules/`, `templates/`, `skill-bundles/`, `skills/agents/`, `docs/`, plus `index.html` (landing) and `install.sh` (installer). Changes to any of these.

## Non-Goals

- No project's requirements or client facts stored in `~/.hermes/**`.
- No product feature implementation that belongs to a project using the agency (the agency ships process, not product).
- No auto-install of third-party persona skills (`npx skills add` / `hermes plugins`) — the installer warns, never installs.

## Preferred Stack

| Area | Choice |
|---|---|
| Language / runtime | Bash 3.2+ (macOS `read -s`, ANSI escapes) for `install.sh`; Markdown for process assets |
| Frameworks | None (Hermes Agent + OpenSpec CLI provide the runtime surface) |
| Data | None (repo is a process/skill carrier) |
| Infra / deploy | GitHub Pages for the landing page (`index.html`), git + GitHub (`gh`) for the repo |

```bash
build:      none required (static docs + bash script)
lint:       none standardized in-repo at present
test:       none standardized in-repo at present (install.sh is exercised manually on a temp Hermes home)
typecheck:  none (no code)
```

## Business Rules

- Pending: none declared beyond "installer must merge (never wipe) and be idempotent — safe to re-run", which the code itself already implements and documents.

## Technical Constraints

- Bash must be portable to macOS default (bash 3.2) — no bash 4+ associative arrays, no GNU-only `read` flags.
- Piped mode (`bash <(curl -fsSL ...)`) must self-clone to a temp dir, install, and clean up.
- Non-interactive runs (no TTY) must not hang on prompts; they fall back to defaults or require `--yes` for overwrite protection.
- The installer must never install third-party skills by itself (only warn) — a hard project rule.

## Architecture Principles

- **Process is global, product is local** (`rules/project-boundaries.md`): Hermes provides the process; the project provides the product.
- The repo is a skill/process carrier: no compiled product, no runtime dependency beyond Bash + OpenSpec CLI.
- Evidence > assertion: every agent output is re-verified in the repo before it advances the loop.
- No implementation code without a validated OpenSpec change (`rules/openspec.md`).

## Product Rules

- The installer's UX must match modern interactive CLI conventions (arrow-key menus, space-to-toggle multi-select, enter to confirm) — the requested change.
- All scripts, docs, specs, commits and PRs are written in English; the conversation with the user is in Spanish.
- `install.sh` stays idempotent and merging after any UX change.

## Quality Expectations

No test harness exists today; `install.sh` is validated by `bash -n` (syntax), exercising it with `--dry-run`, and installing into a temp `--prefix`. The landing page is a static HTML deliverable. Reviewer + QA stages in the agency loop provide the quality gate.

## Agentic Workflow Rules

- OpenSpec is the source of truth for this project.
- No feature implementation before an OpenSpec change exists.
- Every change must include proposal.md, tasks.md, and spec.md.
- Every implementation must trace back to a requirement.
- Ambiguous behavior requires human approval.
- Hermes must operate only inside this project root.
