## Context

The agency's sequence is documented (`rules/sdd.md`, the per-stage workflows) and the OpenSpec CLI
already derives the artifact state of a change. What does not exist is a single place that answers
"where does this change stand, and what is the one valid next step" from the repository rather than
from a session's recollection. The result is that `continue-change` re-derives the pending stage by
hand each time (checkboxes plus `git diff`), and anything the derivation cannot see is silently
treated as "nothing to do here".

Constraints from the project: bash 3.2 portability, no runtime beyond Bash + the OpenSpec CLI,
evidence over assertion, and — from `rules/orchestration.md` — that only `reviewer` and `qa` may
block and that nothing may gain an approval authority over delivery. The command must therefore be
read-only and informational by construction, not by discipline.

## Goals / Non-Goals

**Goals:**

- One command that reads the state from files and prints the single valid next transition.
- A deterministic answer: same inputs, same output, no clock or session dependence.
- Declared precision: an input it cannot read is named, never silently defaulted.
- The four public states a human reads, over a precise internal vocabulary.

**Non-Goals:**

- Acting on the state (running the transition, merging, archiving). It reports; the orchestrator
  and the user decide and act.
- Replacing the OpenSpec CLI's artifact state or the workflows' preflights. It composes them.
- A state store or daemon. State is derived on demand from files; nothing new is persisted.
- Requiring the run trace (`loop-telemetry-run-log`) or `gh`. Both raise precision; neither is a
  precondition, and their absence is reported as a declared limit.
- Porting Gentle-AI's binary or its receipt/authority protocol. Only the idea is taken: read the
  state so the next step does not depend on who is asking.

## Decisions

### Decision: Read from files, never from a session's context

- **What:** the command's inputs are the OpenSpec CLI's JSON (`list`, `status`, `instructions
  apply`), the git tree and `bin/no-smoke-worktree`, a `bin/review-snapshot` manifest when one
  exists, and `gh` for the PR state when a remote is configured.
- **Why:** this is the property that makes the answer worth anything — two sessions, two machines
  or the same person a month later must agree. Every input is therefore re-derivable by anyone
  with the repository.
- **Discarded alternative:** carrying state forward in a session file or in memory — rejected: it
  makes the answer depend on who ran what before, which is the failure this replaces.
- **Consequences:** the command can be wrong only about what it cannot read, and that is exactly
  what it must declare.

### Decision: Four public states over a precise internal vocabulary

- **What:** the printed state is one of `working`, `checking`, `ready`, `needs-decision`; the
  precise state (`READY_TO_APPLY`, `IMPLEMENTING`, `NEEDS_FIX`, `READY_TO_REVIEW`, `NEEDS_REVIEW`,
  `READY_TO_QA`, `QA_FAILED`, `PR_OPEN_CI_RED`, `READY_TO_MERGE`, `ARCHIVE_PENDING`,
  `STALE_EVIDENCE`) is printed underneath it.
- **Why:** a human scanning the output needs a small, stable vocabulary that answers "is this
  mine to decide?"; the precise state is what a workflow needs for the transition. Conflating
  them gives either an unreadable list or a decision the human cannot act on.
- **Discarded alternative:** a numeric score or a single flat state list — rejected: a score
  invites optimizing the number, and a flat list does not separate "the machine is waiting on
  work" from "the decision is yours".
- **Consequences:** each public state maps to exactly one class of transition; the spec pins that
  a human decision is always `ready`, never `working`.

### Decision: A missing input narrows the answer, it never optimizes it

- **What:** when the run trace is absent, `gh` is missing, or the repository has no remote, the
  command still reports what the remaining inputs prove and lists every transition it could not
  determine with the reason.
- **Why:** the repo's standing discipline is that a failed assessment never becomes the optimistic
  default (the same rule `bin/review-tier` carries). A state machine that silently degrades to
  "continue" would hide exactly the evidence gaps the change exists to surface.
- **Discarded alternative:** fail hard when `gh` is absent — rejected: the remote is optional for
  most stages, and refusing to answer at all would make the command useless in local-only repos.
  Assuming "CI green" instead — rejected: that is the optimistic default in its purest form.
- **Consequences:** the output has a precision section that is empty when every input was
  readable; a consumer can tell a complete verdict from a narrowed one.

### Decision: Read-only and explicitly informational

- **What:** the command writes nothing, blocks nothing, and states in its own output that the
  gates remain the reviewer's and QA's verdicts.
- **Why:** `rules/orchestration.md` grants blocking authority to `reviewer` and `qa` only, and
  the repo has twice paid for a guard that quietly became an authority. Making the informational
  nature part of the output (not only of the rule) means a consumer that misreads it can be
  corrected by the command's own text.
- **Discarded alternative:** let the command exit non-zero on a blocked-looking state, so a script
  could gate on it — rejected: that is an approval authority in disguise, and the repo's rule is
  that the human owns delivery.
- **Consequences:** the exit status encodes only "the state was determined" vs "it could not be",
  never a workflow verdict.

## Delivery strategy (recorded per `workflows/implement-change.md`)

**Choice: `chained-pr`.**

This change is delivered as the third slice of the chain, based on `agent/rdd-lite` (PR #19),
which is itself based on `agent/agency-guardrails` (PR #18). It touches
`rules/orchestration.md`, `workflows/continue-change.md`, README/INSTALL/CHANGELOG — overlapping
the two earlier slices' file sets, which the repo's orchestration rule serializes rather than
runs in parallel. `single-pr` would duplicate both earlier diffs into this PR; `split-change` is
unwarranted because this is the last independent piece of the same decision (adopt Gentle-AI's
deterministic-state discipline).

## Risks / Trade-offs

- **Risk:** the state is treated as a gate ("it says ready, so it can ship"). **Mitigation:** the
  informational nature is stated in the output itself and in the spec, and the gates are named;
  the precise state cites the evidence it read.
- **Risk:** the command's own view of the sequence drifts from the workflows. **Mitigation:** the
  transition table is declared in `rules/orchestration.md` and the command implements that table,
  so a drift is a rule change to review, not a code-only divergence.
- **Risk:** an unreadable input is misclassified as an absent one, hiding a real gap.
  **Mitigation:** distinct reasons per input in the precision section ("no trace", "gh not
  installed", "no remote"), so the operator knows which condition to fix.
- **Trade-off accepted:** without the run trace, `NEEDS_FIX` (a builder mid-correction) cannot be
  distinguished from `IMPLEMENTING`; the command declares that limit rather than guessing. The
  trace change raises the precision with no change to this command's interface.
