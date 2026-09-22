# Design — orchestration skill sync

## Context

The live `~/.hermes` skill accumulated the hard-won pitfalls from real sessions (the
"merger" one-liner, the truncated-result recovery, the sibling-noise tripwire, the
kanban gating, the archive reconciliation order...). The repo mirror never got them.
Separately, three process changes (PRs #32/#33, #34/#35) shipped rules the skill does
not teach.

## Goals / Non-Goals

**Goals:**
- Make the repo mirror a faithful public copy of the live skill (body + all references).
- Teach the v2 process in the skill: derived collision verdict, blocker classes, trust
  vocabulary.
- After merge, sync back to `~/.hermes` so live and repo agree.

**Non-Goals:**
- Rewriting the envelope or retry limits (unchanged).
- Touching any other skill or rule.
- Addressing the remaining ChatGPT backlog (message types, permissions matrix).

## Decisions

### Decision: Baseline is a one-way repo ← live copy

Verified superset before touching anything (repo ⊃ live = 0 lines; live ⊃ repo = 154
lines for SKILL.md; refs `external-personas`, `performance-headroom`, `stack-selection`
identical sizes, `spec-artifact-validity` live ⊃ repo, and `postgres-migration-pitfalls`
+ `repo-gate-flake` live-only):
- copy `$HOME/.hermes/.../SKILL.md` over the repo copy;
- copy the six live references under the repo skill dir (two new files);
- **the repo mirror gains the two live-only references and the live SKILL.md.**

Then apply ONLY teaching edits to the SKILL.md body — a bounded, verifiable delta that
stays visible in the diff (no wholesale rewrite). Two edits, each greppable:

1. `## Parallelization and worktree ownership` — replace the union-of-paths rule with
   the derived verdict: `bin/change-collision --base <ref> --a <refA> --b <refB>` →
   `parallelizable` (may parallel), `collision` (sequential, naming paths/family), and
   `cannot assess` (no parallel dispatch until measurable — never a parallelizable
   default, non-zero exit). Keep the sibling-noise tripwire bullet.
2. `## Loop, blocking and completion` — add two bullets: the three blocker classes
   (`retryable` → bounded retry with fresh info; `technical` → another agent /
   back-a-stage / two-failures rule; `decision` → human with options+recommendation+
   impact, no advancing) and the trust vocabulary (`verified` / `partially_verified` /
   `self_reported` / `blocked`, assigned by Hermes after re-verification — never
   self-declared — and the hard gate: review/QA/release never close on `self_reported`).

### Decision: References stay live-precise, no rewrite

The six references are copied as-is. `spec-artifact-validity` gains 12 lines in the
repo copy because live is richer; nothing repo-unique is lost. If a reference ever
diverges from live semantics later, it becomes a follow-up change, not a silent edit
inside this one.

### Decision: Two sync destinations, two commits

- Commit in repo (this feature): the mirror + teaching edits.
- After merge: copy to `~/.hermes/skills/software-development/hermes-sdd-orchestration/`
  with the same safe-copy guard used for rules (compare pre-copy line counts of
  overlapping files; copy only when the repo copy ⊇ live, which the baseline guarantees).

## Risks / Trade-offs

- **Risk:** the sync overwrites a concurrent live-only edit (Migue edits the live skill
  while the mirror PR is in flight). **Mitigation:** the pre-copy diff check re-runs at
  sync time; live-only deltas added since baseline are surfaced, not overwritten.
- **Risk:** teaching edits drift from the rules again. **Mitigation:** the spec pins the
  three teachings; the PR body names the exact greps a future auditor runs.
- **Trade-off accepted:** the repo mirror carries session pitfalls written with this
  machine in mind. Public readers of the mirror get a fuller, more honest skill; there is
  no internal-only information in it (no credentials, no client data).

## Delivery strategy

Measured after implementation: **440 authored lines** (`git diff --numstat main...HEAD`),
over the advisory ~400-line budget. Strategy: **`single-pr`**.

- **Why `single-pr`:** the excess is one coherent capability — the 334-line live SKILL.md
  sync (154 lines of restored pitfalls + 2 restored references) and the two bounded
  teaching edits (~44 lines), all one file's history. There are no independently
  shippable slices: the mirror sync alone would be a 1:1 copy with no rule change, and
  the teaching edits are meaningless without the sync (they teach machinery absent from
  the old mirror).
- **Why not `chained-pr`:** the mirror commit and the teaching commit land in the same
  file; a chained PR would carry the earlier unmerged commit into the second PR's diff.
- **Why not `split-change`:** the spec owns both faces of the same capability
  (`skill-sync`): mirror parity and teaching parity.

After merge: copy repo → `~/.hermes` with the pre-copy diff guard (baseline guarantees
repo ⊇ live; live-only deltas since baseline are surfaced, not overwritten).
