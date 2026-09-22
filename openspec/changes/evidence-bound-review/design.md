## Context

`rules/quality.md` already carries the anti-smoke idea: a working-tree content fingerprint
(`bin/no-smoke-worktree`) that reviewer, QA and release record, compared at merge time, with a
mismatch treated as a blocker. That rule works and stays. What it does not do is (a) fix *which*
content a review describes at the moment the review starts, and (b) scale review depth to the
diff's risk. Today both depend on the agent remembering a rule and choosing a depth.

Constraints from the project: bash 3.2 portability, no runtime beyond Bash + the OpenSpec CLI,
evidence over assertion, and the declared-diff rule the reviewer already applies. Anything this
change adds must be read-only and must not become a new approval authority — the repo's standing
rule is that only `reviewer` and `qa` may block, and `pr-review` owns the formal QA gate.

## Goals / Non-Goals

**Goals:**

- One snapshot, taken before a review starts, that fixes the content the review describes.
- A delivery-time comparison that turns "the tree moved after the review" into a blocker with
  both values named, instead of a judgment call.
- A deterministic tier derived from declared rules, reported with its reason, that selects review
  depth and nothing else.

**Non-Goals:**

- Replacing `bin/no-smoke-worktree` or the fingerprint rule in `rules/quality.md`. The snapshot
  composes with it: the fingerprint is one of the fields it freezes.
- A new approval mechanism, a gate, or anything that authorizes a merge. The tier is
  informational; delivery stays human-owned.
- Content-level secret scanning, secret redaction, or a change to the QA gate.
- Porting Gentle-AI's RDD implementation (its Go binary, its receipt/authority state machine, its
  acknowledgement protocol). Only the two ideas are taken: freeze the candidate before reading
  it, and make review depth follow the diff's risk rather than the model's opinion.
- Automatic remediation after a mismatch (auto re-review, auto revert). The mismatch is reported;
  what to do is the orchestrator's and the user's call.

## Decisions

### Decision: The snapshot is a file written by a read-only bin, not a new state manager

- **What:** `bin/review-snapshot` computes base, `HEAD`, the content fingerprint and the diff
  hash, and writes them to a snapshot path (default under the project's `reports/`, overriding
  with `--out`). It never writes to git's index or refs.
- **Why:** the repo's `bin/` pattern is small, read-only bash tools that produce evidence; a
  snapshot is evidence, not state. Writing it to a file (rather than printing it and hoping the
  operator records it) is what makes a later comparison mechanical — the same reason the run
  trace exists as NDJSON instead of prose.
- **Discarded alternative:** a git tag or a dedicated ref to "freeze" the candidate — rejected:
  it mutates repository state for something that is evidence, and a ref cannot describe a dirty
  working tree (the common case mid-change). A commit — rejected: it forces a history mutation to
  do a review.
- **Consequences:** the snapshot path becomes the thing reviewer/QA briefs cite. It must be
  gitignored (a snapshot of a moving tree would otherwise break the very fingerprint it records —
  the same trap the run trace documented), and `--out` lets a caller place it elsewhere.

### Decision: The comparison is content-based, so history rewrites do not block

- **What:** the comparison uses the content fingerprint (a `git write-tree` over the working
  tree) and the diff hash, never `HEAD` identity. `HEAD` is recorded for context only.
- **Why:** `bin/no-smoke-worktree`'s documented property is that identical content hashes the same
  across rebase/amend/squash. A comparison keyed on a commit sha would block delivery after any
  history rewrite that preserved content, which is exactly the false positive the existing rule
  avoids.
- **Discarded alternative:** compare commit shas — rejected: brittle, blocks legitimate rewrites.
- **Consequences:** the spec states that a comment/rebase/squash preserving content must not
  block; the fixtures must include that case.

### Decision: The tier rules live in `rules/quality.md` as a declared table

- **What:** the high-consequence path classes and the size bounds are written in the rule, and
  `bin/review-tier` implements that table and prints which rules fired.
- **Why:** the same reasoning as the deny list: a rule that lives in code alone cannot be
  reviewed or contradicted, and a reviewer must be able to say "this path is high-consequence per
  the table" instead of debating judgment. Printing the fired rules is what makes the tier
  falsifiable.
- **Discarded alternative:** keep the thresholds as constants inside the bin — rejected: the
  classifier would then be unauditable, and changing it would be a code change with no rule to
  review against.
- **Consequences:** the fixtures must cover, per rule class, one case that fires it and one that
  does not, so a rule with no matching case fails loudly.

### Decision: An unassessable diff is not a low tier

- **What:** when the diff cannot be measured, the command reports "cannot assess" — never `low`.
- **Why:** the repo's standing failure discipline ("never assume low risk from a failed
  assessment") exists precisely because a missing measurement silently becomes an optimistic
  default. A tier that degrades to `low` on error would turn every tooling problem into a shallow
  review.
- **Discarded alternative:** default to `medium` on error — rejected: still an invented value;
  the honest output is "unknown", and the caller decides.
- **Consequences:** the exit contract distinguishes "assessed" from "not assessed", and the spec
  carries a scenario for it.

## Delivery strategy (recorded per `workflows/implement-change.md`)

**Choice: `chained-pr`.**

This change is delivered as a chain on top of `agent/agency-guardrails` (PR #18), not as an
independent PR: the two changes touch the same process files (`rules/quality.md`,
`workflows/review-change.md`, `agents/reviewer.md`, `README.md`, `INSTALL.md`, `CHANGELOG.md`),
and the repo's orchestration rule is that changes with overlapping file sets are **serialized,
never run in parallel** — two builders on one file set clobber each other's half-applied edits.
The branch is therefore based on the guardrails branch, and this PR's base ref is that branch;
when guardrails merges, this slice rebases onto `main` and its base retargets.

`split-change` was rejected: the frozen-candidate and tier work is the second half of one
decision (adopt Gentle-AI's evidence discipline), and it has no lifecycle of its own.
`single-pr` was rejected: it would duplicate the guardrails diff into this PR.

## Risks / Trade-offs

- **Risk:** an extra manual step (take the snapshot) gets skipped. **Mitigation:** the
  `review-change` preflight gains the step and the reviewer brief cites the snapshot path, so a
  missing snapshot surfaces at the point of use rather than at delivery.
- **Risk:** the tier is treated as an authority ("green tier, so it can ship"). **Mitigation:**
  the spec states the tier selects depth and nothing else, and that an unavailable assessment is
  never `low`; the QA gate of `pr-review` is untouched.
- **Risk:** the high-consequence path classes drift from real risk. **Mitigation:** they are a
  declared table in the rule, so extending them is a reviewable rule change, and the fixtures pin
  one case per class.
- **Trade-off accepted:** the tier is a coarse three-value scale rather than a score. A numeric
  score invites optimizing the number; three named depths map to three concrete review shapes.
