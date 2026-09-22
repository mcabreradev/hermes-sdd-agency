## Why

"Which step is next?" is today answered by the orchestrator's judgment, re-derived from scratch in
every session. The OpenSpec CLI already knows the state of a change's *artifacts*
(`isPlanningComplete`, `isComplete`, `applyRequires`, task progress), but nothing answers the
question the agency actually asks: given the change, the tree, its recorded evidence and the
open PR, what is the one valid next transition — and is the next decision mine or the human's?

Two failure modes follow from leaving it to judgment. A session that guesses differently from the
last one re-does work or skips a gate; and a stage that cannot be determined (no trace, no
fingerprint, a stale review) is silently defaulted to "continue", which is exactly how evidence
gets lost. Gentle-AI's strongest idea is that the workflow's state is read **from files** so two
runs on two machines, a month apart, return the same answer — and that an unknown answer is
reported as unknown, never as the optimistic one.

## What Changes

- New **`bin/agency-next`** — a read-only command that derives the agency's state from files and
  prints one of four public states (`working`, `checking`, `ready`, `needs-decision`) together
  with the exact next transition and the command that performs it. The state underneath is
  precise (`READY_TO_APPLY`, `IMPLEMENTING`, `NEEDS_FIX`, `READY_TO_REVIEW`, `NEEDS_REVIEW`,
  `READY_TO_QA`, `QA_FAILED`, `PR_OPEN_CI_RED`, `READY_TO_MERGE`, `ARCHIVE_PENDING`,
  `STALE_EVIDENCE`); the four public states are what a human reads.
- It reads only: the OpenSpec CLI's JSON, the git tree and the working-tree fingerprint
  (`bin/no-smoke-worktree`), a review snapshot when one exists (`bin/review-snapshot`), and the
  open PR's state through `gh` when a remote is configured.
- **It never guesses.** A missing input (no trace, no `gh`, an unreadable root, no remote) is
  reported as a **declared precision limit** with the affected transitions named — the command
  falls back to what OpenSpec + git can prove and says so, instead of inventing a state.
- **The human is never automated away:** `ready` means the next decision belongs to the user
  (merge, archive, a scope call) — the command proposes, it does not act.
- `rules/orchestration.md` gains the state/transition table; `workflows/continue-change.md` uses
  it to resume, and the per-stage bundles can call it at preflight.

## Capabilities

### New Capabilities

- `agency-state`: deriving the agency's state and its single valid next transition from files,
  with the declared precision limits when an input is unavailable, and the rule that the state is
  informational and read-only.

## Impact

- **Files modified:** `rules/orchestration.md`, `workflows/continue-change.md`, `README.md`,
  `INSTALL.md`, `CHANGELOG.md`.
- **New files:** `bin/agency-next`, `fixtures/agency-next/check.sh`.
- **No runtime dependency added** — bash 3.2, the OpenSpec CLI the repo already requires, git,
  and `gh` only when a remote exists (its absence is a declared precision limit, not a failure).
- **Degradation is a requirement, not a fallback:** the `loop-telemetry-run-log` change adds the
  structured run trace this command gains precision from when it lands. Until then the command
  must work from OpenSpec + git + the review snapshot alone and declare what it cannot see —
  never assume the optimistic state.
- **Concepts adapted from** [Gentleman-Programming/gentle-ai](https://github.com/Gentleman-Programming/gentle-ai)
  (MIT): reading the workflow state from files so the next transition is deterministic, and the
  four public states. Ideas only — no binary, no runtime, no third-party state machine.
