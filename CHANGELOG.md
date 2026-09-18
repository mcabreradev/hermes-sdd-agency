# Changelog

All notable changes to this project. Format: [Keep a
Changelog](https://keepachangelog.com/en/1.1.0/); versioning: [Semver](https://semver.org/).

The project follows the same discipline it enforces: changes are scoped, evidence-based
and closed with the loop intact. This log does not track every session — it marks
coherent, reviewable increments of the system.

## [Unreleased]

### Added

- **`bin/no-smoke-worktree`** — content fingerprint of the working tree (git `write-tree`
  over a temp index; survives rebase/amend, changes on any source change incl. untracked).
  Reviewer/QA/release stages now record it and `release-change` compares, so evidence is
  bound to the exact tree that was validated (anti-"smoke"). Enforced in `rules/quality.md`.
- **Complementary skills** (`skills/`): `review-structural` (SQL / LLM trust-boundary /
  conditional side-effect diff scan), `code-health` (0-10 score, trends), `project-learnings`
  (`.context/learnings.jsonl` per project), `web-performance-benchmark` (Core Web Vitals,
  before/after), `plan-scope-review` (the four scope modes), `visual-design-review`,
  `design-exploration`, `design-to-html`, `diagram-triplet`, `developer-experience-review`,
  `document-diataxis` (coverage map), `security-evidence-first` (attacker·boundary·impact·challenge).
- **`install.sh`** now copies `bin/` into the target home (`PROCESS_DIRS` + INSTALL/README sync).

### Changed

- `workflows/qa-change.md` — report-only mode (`qa-only`): same matrix, no fix loop, with a
  health baseline and the worktree fingerprint; verdict bar unchanged.
- `workflows/release-change.md` — Diataxis coverage map + doc/architecture-diagram drift
  check + changelog sell-test, and the closed-tree fingerprint comparison against earlier stages.

The skills and rule concepts were adapted from [garrytan/gstack](https://github.com/garrytan/gstack)
(MIT); only host-agnostic ideas were distilled in, the Claude-specific runtime was left out.


## [0.1.0] - 2026-09-17

Snapshot of the agency as it stands today: the complete SDD loop as a versionable,
public, installable kit.

### Added

- **Process tree**: `rules/` (orchestration, project-boundaries, openspec, sdd,
  quality, coding, testing), `agents/` (8 role contracts + README entry point),
  `workflows/` (initialize → idea → architecture → plan → implement → review → qa →
  release), `templates/` (10 artifact templates).
- **Skill bundles**: `/agency` and the per-stage commands `/init-project`, `/idea`,
  `/architecture`, `/plan`, `/implement`, `/review`, `/qa`, `/release`, plus the
  task-level triggers `/feature`, `/bugfix`, `/fix`.
- **Skills**: 23 domain personas under `skills/agents/`, the orchestration layer
  (`hermes-sdd-orchestration`, `openspec-sdd`), 11 per-role process skills, and the 12
  OpenSpec CLI mechanics (`openspec-explore` … `openspec-archive-change`).
- **Task-size fast path** (`rules/openspec.md`): three levels — cosmetic (no change),
  minimal (`skip_specs`, with regression test), feature (full loop). Decided by Hermes,
  never self-assigned.
- **Language contract** (`rules/sdd.md`): everything the system produces is in English;
  the only exception is the conversation with the user.
- **Docs**: `docs/sdd-feature-lifecycle.md` (the full path, with Mermaid diagrams),
  `docs/usage-examples.md` (copy-paste scenarios, envelope sample, classifier and gate
  diagrams), `INSTALL.md` (two install paths + verification).
- **Repo meta**: `README.md`, `LICENSE` (MIT), `CONTRIBUTING.md`, `.gitignore`.

### Known limitations

- None.

[0.1.0]: https://github.com/mcabreradev/hermes-sdd-agency/releases/tag/v0.1.0
