# Changelog

All notable changes to this project. Format: [Keep a
Changelog](https://keepachangelog.com/en/1.1.0/); versioning: [Semver](https://semver.org/).

The project follows the same discipline it enforces: changes are scoped, evidence-based
and closed with the loop intact. This log does not track every session — it marks
coherent, reviewable increments of the system.

## [Unreleased]

### Added

- **`bin/agency-next`** — answers "which step is next" from **files** instead of a session's
  memory: it reads the OpenSpec CLI's JSON, the git tree, the working-tree fingerprint and the
  review snapshot, and prints one public state (`working` / `checking` / `ready` /
  `needs-decision`), the precise state underneath, the single valid next transition and the
  command that performs it. A missing input **narrows** the answer — every transition it could
  not determine is listed with the reason, so "no run trace", "`gh` not installed" or "no
  remote" never default to the optimistic state. The state is informational: it never blocks,
  merges, archives or replaces a gate, and a human decision is always reported as `ready`.
- **`bin/review-snapshot`** — freezes the review candidate **before** anything reads it: base
  ref, `HEAD` for context, the working-tree content fingerprint and the diff hash. Reviewer and
  QA findings are bound to that snapshot, and `--compare` at delivery reports a `MISMATCH`
  (non-zero) when the tree moved — so evidence can no longer describe content that no longer
  exists. The comparison is content-based, so a rebase/amend/squash that preserves content still
  matches.
- **`bin/review-tier`** — derives review depth (`low`/`medium`/`high`) from the diff's own shape
  using the declared table in `rules/quality.md`: authored lines plus the high-consequence path
  classes (schema/migration, auth, security config, dependency manifests). It prints the rules
  that fired, is informational — it never blocks or replaces `pr-review`'s QA gate — and reports
  "cannot assess" instead of `low` when the diff cannot be measured.
- **Sensitive-path deny list** (`rules/project-boundaries.md`) — the enumerated classes of
  credentials, keys and token files that no agent, bin or workflow may read, print, copy into a
  report or commit. Enforced on evidence, not intent: the `reviewer` greps the declared diff's
  paths against the list (`rules/quality.md`) and a match is a `BLOCKER`.
- **`bin/skill-registry`** — read-only inventory of installed skills: exact `SKILL.md` path,
  name, description and tags per skill, plus explicit flags for the frontmatter defects that make
  a skill load but mis-route (`BLOCK-SCALAR`, `MISSING-DESCRIPTION`, `NO-FRONTMATTER`,
  `UNCLOSED-FRONTMATTER`). Audits the set the agency actually resolves instead of assuming it.
- **Work units and the authored-lines budget** (`rules/coding.md`) — one commit per coherent work
  unit carrying its tests and docs, and an *advisory* ~400-line heuristic for one reviewable
  delivery that never justifies cosmetic deletions, weakened tests or artificial splits. When a
  change crosses it, the delivery strategy (`single-pr` / `chained-pr` / `split-change`) is
  chosen and **recorded** (`workflows/implement-change.md`), so the delivered shape is a decision
  on record instead of an accident of how many commits accumulated.

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

### Changed

- `workflows/qa-change.md` — report-only mode (`qa-only`): same matrix, no fix loop, with a
  health baseline and the worktree fingerprint; verdict bar unchanged.
- `workflows/release-change.md` — Diataxis coverage map + doc/architecture-diagram drift
  check + changelog sell-test, and the closed-tree fingerprint comparison against earlier stages.

The skills and rule concepts were adapted from [garrytan/gstack](https://github.com/garrytan/gstack)
(MIT); only host-agnostic ideas were distilled in, the Claude-specific runtime was left out.

The sensitive-path deny list, the skill registry and the work-unit/budget guidance were adapted
from [Gentleman-Programming/gentle-ai](https://github.com/Gentleman-Programming/gentle-ai) (MIT)
under the same rule: only host-agnostic ideas, no binary, no runtime and no third-party state
machine ported.


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
