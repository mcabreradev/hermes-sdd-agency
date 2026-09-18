# Changelog

All notable changes to this project. Format: [Keep a
Changelog](https://keepachangelog.com/en/1.1.0/); versioning: [Semver](https://semver.org/).

The project follows the same discipline it enforces: changes are scoped, evidence-based
and closed with the loop intact. This log does not track every session — it marks
coherent, reviewable increments of the system.

## [Unreleased]

- None pending.

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
