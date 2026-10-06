# Changelog

All notable changes to this project. Format: [Keep a
Changelog](https://keepachangelog.com/en/1.1.0/); versioning: [Semver](https://semver.org/).

The project follows the same discipline it enforces: changes are scoped, evidence-based
and closed with the loop intact. This log does not track every session — it marks
coherent, reviewable increments of the system.

## [Unreleased]

### Fixed

- **Public surfaces back in sync**: README, the GitHub Pages homepage (`index.html`) and
  INSTALL now count the real tree — 7 evidence bins (`run-trace`, `change-collision`
  added), 68 skills, 108 pinned test cases, 39 merged PRs. The homepage's loop diagram
  runs `release` before `pr-review` (the canonical order) and `docs/evidence-bins.md`
  documents the two new bins.

### Added

- **The build stage gains its craft — `build-craft`, `bug-diagnosis`, `module-design`.** The agency
  enforced test-first as a hard rule and never said what makes a test worth keeping, where a test
  belongs, or how to find a bug whose cause is not yet visible. Three process skills close the gap,
  each loaded by the stage that needs it: `build-craft` (seams named and agreed **before the first
  test** — an undeclared seam is not written at; the three anti-patterns: implementation-coupled,
  **tautological** — the assertion recomputes the expected value the way the code does, so it passes
  by construction — and horizontal slicing; one vertical slice at a time), `bug-diagnosis` (a command
  that goes **red on this bug** before any hypothesis, a minimised repro, falsifiable predictions, and
  the fix landing at a seam that exercises the real pattern) and `module-design` (the vocabulary a
  structural dispute is settled against — module, interface, depth, seam, adapter, leverage, locality
  — plus the deletion test and "the interface is the test surface"). `rules/testing.md` keeps the
  obligation and now carries the craft in two new sections ("Test craft", "Diagnosis before a fix");
  `agents/builder.md` loads the three methods, `agents/reviewer.md` checks them against the real diff
  (tautological / implementation-coupled / horizontal slicing / a regression test that passes without
  the fix = `MAJOR`; an undeclared seam or a pass-through module = `MINOR`), and `rules/quality.md`
  carries both rows. No new bin, no dependency: the checks are **review** — an agent reading the diff
  against the contract.

- **The DDD trigger is explicit signals, and the reviewer verifies the contract** — domain-driven
  design stops being a judgment call. The architect evaluates five objective signals on every
  change (an invariant that must hold across operations; an entity with identity and lifecycle; a
  term defined or redefined; a boundary between two business capabilities; vocabulary drift
  already present) and records the evaluation **whether or not it fires**, so the skip is
  reviewable instead of unstated. When a signal fires, the ubiquitous language lands in the
  project's `CONTEXT.md` (glossary format, `_Avoid_` synonyms), the change's design carries a
  `## Domain` section (vocabulary resolution, entities/aggregates with their invariants, capability
  boundaries) and the reviewer checks it against the real diff — glossary conformance, invariants
  covered by tests that fail when violated, code against the declared model, and trigger verdict
  against the diff (`MAJOR` for the content violations, `BLOCKER` when the anchoring artifact is
  missing). Verification is **review**, the mechanism the repo's own doctrine names for meaning: no
  new bin, no dependency. Wired into `agents/architect.md`/`agents/reviewer.md`,
  `templates/architecture.md`, `templates/adr.md`, `rules/coding.md`, `rules/quality.md`,
  `workflows/openspec-to-architecture.md` and the `/architecture` bundle (which now loads
  `domain-modeling`, the method its own role file requires).

- **`bin/phase-gate` — the phase is now a fact in the repository, not a memory.** A project
  declares its phase in `openspec/project.md` (`## Phase`), and the gate refuses application code
  under the declared paths while that phase is `documentation`. It closes the half of the hard rule
  that prose could not: a project accumulated 23 source files across five increments, each one
  carrying a validated change and a green gate — every step compliant, the outcome wrong. A
  validated change is **necessary, never sufficient** now, and an undeclared phase reports
  `cannot assess` (exit 2) rather than passing, because the cheap default would be "implementation
  is fine". Wired into `rules/openspec.md`, `rules/coding.md`, `agents/builder.md`,
  `workflows/implement-change.md` and `rules/orchestration.md` (blocker class `decision`, precise
  state `PHASE_GATED`); `agency-next` no longer proposes `implement-change` in a documentation-phase
  project; the project's CI is the backstop. `docs/phase-gate.md`, 12 fixture cases, and a
  near-miss pair so a pattern widened for recall is caught.

- **Homepage rebuilt as a conversion landing** — the GitHub Pages site now sells the
  outcome, not the inventory: "your AI developer, with receipts" above the fold, the
  three failures it solves (memory, smoke, mood) named before the product, a
  verifiable proof (this repo is the demo), the loop as four plain scenes, and one
  install CTA that closes the page. Same hum theme, still a single static file.

- **The full agency skill set is now public** — the mirror gains the five process
  skills that previously lived only under `~/.hermes`: `agency-invocation` (the
  `/agency` and per-stage bundle cheat sheet), `sdd-agency-maintenance` (extending and
  auditing the agency instance, task-size levels), `release-closure` (the merge →
  changelog → cleanup tail of the loop), `sdd-agency-export` (how this mirror itself is
  built and sanitized) and `hermes-sdd-packaging` (the portable packaging set), each
  with its references. A reader who follows `sdd-agency-export` to fork a working
  agency now gets a repo that contains the definition of "complete".

- **`hermes-sdd-orchestration` skill back in sync** — the public repo mirror now carries
  the full live skill: every session-born pitfall (merger one-liner, truncated-result
  recovery, sibling-noise tripwire, kanban gating, archive reconciliation order) and all
  six references, including the two live-only guides. The parallelization section now
  teaches `bin/change-collision` verdicts (`parallelizable` / `collision` /
  `cannot assess`, high-risk families) instead of the old union-of-paths rule, and the
  loop section teaches blocker classes (`retryable` / `technical` / `decision`,
  unclassified → `decision`) plus the trust vocabulary (`verified` /
  `partially_verified` / `self_reported` / `blocked`) with the hard gate: review, QA and
  release never close on `self_reported`.

- **`bin/change-collision`** — decides change ordering from the file sets instead of
  by hand: `--base <ref> --a <refA> --b <refB>` prints `parallelizable` (no path
  overlap, no shared high-risk family) / `collision` (overlapping paths, or both
  changes touch schema/migrations, `openspec/`, contracts/auth or dependency
  manifests — even without literal overlap) / `cannot assess` (unmeasurable diff,
  never a parallelizable default). Wired into `rules/orchestration.md`
  ("Parallel execution of changes"): run it before dispatching two changes
  concurrently; a `collision` verdict runs them sequentially, an unmeasurable diff
  never dispatches in parallel. The verdict decides ordering, never approval — the
  gates stay the reviewer's and QA's.

- **Blocker classes + trust vocabulary** (`rules/orchestration.md`) — every blocker
  now carries a `class` that picks the allowed response by rule, not by re-reading the
  situation: `retryable` (bounded retry, consumes an iteration) · `technical` (no
  circular retry: back a stage or stop) · `decision` (the human decides, options +
  recommendation + impact). An unclassified blocker defaults to `decision` — the human
  is never skipped by omission. And every validated outcome gets a **trust level**
  (`verified` / `partially_verified` / `self_reported` / `blocked`) assigned by Hermes,
  never self-declared, recorded in the report and the trace. Hard rule: critical stages
  (review / QA / release) never close on a self-reported gate. Trace schema and
  `bin/run-trace` surface both fields.

- **`bin/run-trace` + `rules/observability.md`** — the loop now keeps a structured,
  machine-readable memory of each run: every stage records its closure as a trace
  entry (`reports/<runId>.jsonl`, NDJSON, gitignored so the growing log can never
  break the release fingerprint), and `bin/run-trace` emits the audit summary
  (stages, status, blockers, ASSUMED) and the exact resume point straight from the
  log. Autonomous mode parks a non-trivial decision as an auditable `parked` entry,
  and `continue-change` resolves where a run stopped from the trace — checkboxes
  become the cross-check, not the guess. The envelope gains a `runId` threaded
  through every brief of a run. Run-level metrics stay out of scope by design.

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
  a skill load but mis-route (`BLOCK-SCALAR` for a block/folded indicator with no body,
  `MISSING-DESCRIPTION`, `NO-FRONTMATTER`, `UNCLOSED-FRONTMATTER`). A block/folded scalar
  **with** a body is legal YAML and inventories as healthy. Audits the set the agency actually
  resolves instead of assuming it, and is pinned by `fixtures/skill-registry/check.sh` (12 cases).
- **Work units and the authored-lines budget** (`rules/coding.md`) — one commit per coherent work
  unit carrying its tests and docs, and an *advisory* ~400-line heuristic for one reviewable
  delivery that never justifies cosmetic deletions, weakened tests or artificial splits. When a
  change crosses it, the delivery strategy (`single-pr` / `chained-pr` / `split-change`) is
  chosen and **recorded** (`workflows/implement-change.md`), so the delivered shape is a decision
  on record instead of an accident of how many commits accumulated.
- **`docs/agency-flow.svg` + `scripts/gen-agency-diagram.mjs`** — a single
  hand-built SVG of the full orchestration flow (stage 0 → release → open PR →
  post-open `pr-review` gate), replacing the stale mermaid block in
  `docs/sdd-feature-lifecycle.md` with an image that renders in GitHub and in
  any viewer. The generator script is the single source of truth (mermaid's
  `<foreignObject>` output is stripped by GitHub, so the flow is drawn as pure
  SVG text); `docs/agency-flow.mmd` remains as the editable source.
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

The sensitive-path deny list, the skill registry and the work-unit/budget guidance were adapted
from [Gentleman-Programming/gentle-ai](https://github.com/Gentleman-Programming/gentle-ai) (MIT)
under the same rule: only host-agnostic ideas, no binary, no runtime and no third-party state
machine ported.

The build craft (`build-craft`, `bug-diagnosis`, `module-design`) was adapted from
[mattpocock/skills](https://github.com/mattpocock/skills) (MIT) under the same rule. Distilled in:
three host-agnostic disciplines — the craft that makes test-first produce a test worth keeping, the
diagnosis loop that precedes a fix, and the vocabulary for a module's shape. **Not** taken: no
router skill, no `/setup-*` command that would write a second source of truth for where a repo's
decisions live, no slash commands duplicating this agency's bundles, no host runtime, no installer,
no dependency — the three files are prose and the checks they enable are review.


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
