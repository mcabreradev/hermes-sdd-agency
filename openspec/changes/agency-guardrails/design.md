## Context

The agency already states three related rules, but each in a form that depends on judgment:

- "Agents do not read or commit secrets" exists as conduct guidance in `rules/quality.md`
  without an enumerated path list, so nothing can be matched mechanically and nothing can be
  grepped at review time.
- The installed-skill set is discovered dynamically by Hermes' loader (with the collision rules
  documented in the maintenance skill); there is no inventory command, so "which skills exist,
  and is this one's frontmatter valid?" is answered by hand.
- `rules/coding.md` commits work and `workflows/implement-change.md` briefs the builder per
  task batch, but nothing bounds how large a delivered diff may grow before it stops being
  honestly reviewable. The lifecycle doc names the risk; no rule acts on it.

Constraints that shape this design, from `openspec/project.md` and the repo's own rules: bash
3.2 portability (no bash-4 associative arrays, no GNU-only flags), no runtime dependency beyond
Bash + the OpenSpec CLI, evidence over assertion (`rules/quality.md`), and the declared-diff
rule (`rules/quality.md`) that already makes a reviewer compare touched files against a
declared list.

## Goals / Non-Goals

**Goals:**

- A literal, enumerable sensitive-path list that can be matched by `grep`, plus a review-time
  check that produces evidence instead of relying on intent.
- A read-only inventory command for installed skills that doubles as a frontmatter linter.
- A commit-granularity rule with an advisory size heuristic and a recorded delivery strategy,
  so a large change becomes chained/stacked pull requests by decision, not by accident.

**Non-Goals:**

- A secret scanner over file *content* (entropy heuristics, regex sweeps for tokens). The deny
  list is about path classes an agent must not touch; content scanning is a different change.
- Redaction tooling, secret rotation, or any integration with a secret manager.
- A machine-readable (JSON) skill index. The registry is a human/inspection command; the
  loader's own index stays authoritative for resolution.
- Porting anything that needs Gentle-AI's binary, its runtimes (Engram, GGA, its TUI), or its
  state machine bound to its own ODD/SDD artifacts.
- Enforcing the size heuristic mechanically (a script that refuses a large commit). It is
  advisory by requirement.

## Decisions

### Decision: The deny list lives in `rules/project-boundaries.md`, not a new rules file

- **What:** the enumerated patterns and the enforcement rule are added to the existing
  boundaries rule, under a new section; no `rules/security.md` is created.
- **Why:** the deny list *is* a project-boundary concern (what an agent may touch of the host),
  and the rule is already the file every agent is pointed at for boundary questions. A separate
  file adds a resolution hop for a list that fits in twenty lines, and `rules/quality.md`
  already cross-references boundaries.
- **Discarded alternative:** inline the list in each agent's file — rejected: four copies drift.
  A new `rules/security.md` — rejected: premature; content scanning may later justify it, and
  that change can move the list then.
- **Consequences:** `rules/quality.md`'s reviewer section references the deny-list grep
  explicitly, so the enforcement location is unambiguous.

### Decision: Enforcement is a reviewer grep over the declared diff, reported as a BLOCKER

- **What:** the `reviewer` stage greps the paths in the declared diff against the deny list and
  reports a match as `BLOCKER` with `path:line`.
- **Why:** the repo's existing pattern is evidence-bound review (`rules/quality.md`: the
  declared diff rule + the content fingerprint). A grep produces a command and an output — an
  evidence line — instead of an assurance. It reuses the machinery already in the workflow
  (`workflows/review-change.md` already re-runs the gate and compares touched files).
- **Discarded alternative:** a pre-commit hook that blocks the path — rejected for this change:
  the agency's checks live in the loop, hooks impose tooling on target projects the repo does
  not own, and the boundary rule must hold even where no hook is installed.
- **Consequences:** `workflows/review-change.md` gains the check as an explicit step of the
  reviewer brief, and the `reviewer` agent's Done criterion includes it.

### Decision: `bin/skill-registry` is bash 3.2, read-only, frontmatter parsed by `sed`/`awk`

- **What:** the command walks each `--root` for `SKILL.md`, extracts the YAML frontmatter block
  (name, description, tags) with `sed`/`awk`, and prints a stable, human-readable record per
  skill; defective frontmatter (block-scalar description, missing/empty description, missing
  block) is marked explicitly.
- **Why:** it must run everywhere the agency runs, including a bare macOS shell, exactly like
  `bin/no-smoke-worktree` (the established `bin/` pattern: bash + zero dependencies). `jq`
  exists on this machine but the project's constraint is portability, not what this laptop has.
- **Discarded alternative:** Python (present as `python3`, but the repo's bins are bash and
  Python adds a runtime the spec excludes). YAML parsing via a real parser — rejected: a full
  YAML library is a dependency; the frontmatter subset used here (three scalar keys) is safely
  parseable line-wise, and the block-scalar case is precisely the defect to *detect*, not to
  parse correctly.
- **Consequences:** the awk parser must be tolerant of unknown extra keys (it ignores them) and
  must not mistake a `description:` inside the body for frontmatter. Detection rules are
  documented in the command's `--help`.

### Decision: The size heuristic is advisory and delivery strategy is recorded

- **What:** ~400 authored changed lines (additions + deletions, generated excluded) per
  reviewable delivery; when a change crosses it, one of `single-pr` / `chained-pr` /
  `split-change` is chosen and recorded in the change's artifacts.
- **Why:** the rule must not become a size-only rework loop (a real failure mode of mechanical
  caps: deleting comments, splitting artificially, weakening tests to fit a number). Stating it
  as advisory with an explicit list of things it never justifies removes that incentive while
  keeping the useful signal and making the delivery shape a recorded decision.
- **Discarded alternative:** a hard cap enforced by a script — rejected: it optimizes for the
  number instead of reviewability, and any correct-but-large unit would need a bypass that
  erodes the rule. Leaving the budget unstated — rejected: that is today's state, where a
  2,000-line diff arrives with no decision on record.
- **Consequences:** `workflows/implement-change.md` gains the budget + strategy step at brief
  time and at stage closure; `rules/coding.md` gains the commit-granularity rule that the
  workflow references.

## Risks / Trade-offs

- **Risk:** the deny list is finite, so a sensitive path outside it passes. **Mitigation:** the
  list is explicitly extensible and Hermes-owned; the spec requires the enumerated classes,
  not completeness, and the review check is additive to judgment, never a replacement for it.
- **Risk:** a hand-rolled frontmatter parser mis-reads an unusual but valid `SKILL.md`.
  **Mitigation:** the command reports what it parsed verbatim and flags rather than guesses;
  unknown keys are ignored, and a parse failure marks the record defective instead of printing
  a wrong description.
- **Risk:** the advisory budget is ignored in practice. **Mitigation:** the strategy must be
  *recorded*, so the omission is visible in the change's artifacts and in review; the recorded
  choice is inspectable even when the answer is `single-pr`.
- **Trade-off accepted:** the registry is not wired into the bundle resolver or the loader's
  collision logic — it is an inspection tool. Wiring it into resolution would couple a
  diagnostic command to Hermes internals and change loading behavior, which this change does
  not authorize.
- **Trade-off accepted:** the deny-list grep can only see *paths*, so a secret embedded in a
  normal-looking file is not caught by it. Content-level scanning is declared out of scope
  rather than implied as covered.
