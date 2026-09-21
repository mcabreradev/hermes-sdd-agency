# Changelog

All notable changes to this project. Format: [Keep a
Changelog](https://keepachangelog.com/en/1.1.0/); versioning: [Semver](https://semver.org/).

The project follows the same discipline it enforces: changes are scoped, evidence-based
and closed with the loop intact. This log does not track every session — it marks
coherent, reviewable increments of the system.

## [Unreleased]

### Added

- **`test-driven-development` by hard rule at the build stage** + **`domain-modeling`
  (DDD) when the domain merits it** — every behavior-bearing piece of work — backends,
  business logic, API endpoints, bug fixes — is written test-first (RED→GREEN→REFACTOR);
  no agent discretion to skip test-first for code that carries business logic, only
  behavior-free code (config, generated code, throwaway prototypes) is declared `not
  applicable` with a reason. The architect shapes the domain with DDD only when the
  business rules justify it. Wired into `rules/testing.md`,
  `agents/builder.md`/`agents/architect.md`, `workflows/implement-change.md`,
  `rules/coding.md` and the lifecycle docs. Fewer regressions shipped, more correct code added.
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

### Added

- **`workflows/pr-review.md`** — post-open code review stage (`pr-review` agent + domain
  personas by diff: `backend-developer`/`fullstack-developer`/`typescript-pro`/`code-reviewer`/
  `security-auditor`), builder↔reviewer alignment loop (max 3 cycles), inline GitHub comments.
  Registered as `/pr-review`, in the `autonomous-change` closure, and in the orchestration
  sequence. `pr-review` never merges.

### Changed

- `workflows/qa-change.md` — report-only mode (`qa-only`): same matrix, no fix loop, with a
  health baseline and the worktree fingerprint; verdict bar unchanged.
- `workflows/release-change.md` — Diataxis coverage map + doc/architecture-diagram drift
  check + changelog sell-test, and the closed-tree fingerprint comparison against earlier stages.
- **`pr-review` now requires a formal QA gate before closure** — review approval + green CI
  are no longer enough to close a PR as QA-confirmed. A `qa-expert` executes the spec
  scenarios against the running app + real DB (`qa-change`); `pass` is mandatory; post-merge
  report-only QA recommended for data-layer/runtime/core-dep changes. Wired into
  `workflows/pr-review.md`, `skill-bundles/pr-review.yaml` and the orchestration skill.

### Fixed

- **Repo→live sync no longer wipes curated skill content.** A `cp` from a repo worktree
  (thin ~169-line export of `hermes-sdd-orchestration`) overwrote the live `~/.hermes` copy
  (300+ lines carrying the curated pitfalls) and destroyed that knowledge. Guard written into
  `sdd-agency-maintenance`: compare source/target line counts before any `cp` into `~/.hermes`,
  re-apply a single edit with `patch` when the live copy is richer, and verify the count
  before AND after a sync. The live copy was restored and kept richer.

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
