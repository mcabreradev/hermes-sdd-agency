## Purpose

Deriving where a change actually stands and which single transition is valid next, from files
rather than from a session's memory: so the same state is read by any session, a re-run a month
later agrees with the first, and a state that cannot be determined is reported as undetermined
instead of defaulting to the optimistic one.

## ADDED Requirements

### Requirement: One next transition, derived from files

`bin/agency-next` MUST be a read-only command that derives the state of the active change from
the available inputs and prints **one** public state (`working`, `checking`, `ready` or
`needs-decision`), the precise state underneath it, the single next transition, and the command
that performs it. The inputs MUST be taken from files and commands, never from a session's
context: the OpenSpec CLI's JSON output, the git tree, and the working-tree content fingerprint.

#### Scenario: A change whose planning is complete and whose tasks are untouched

- **WHEN** the change's artifacts are complete and its task progress is zero or partial
- **THEN** the public state is `working`, the precise state is the apply-ready one, and the next
  transition is `implement-change` with that command printed

#### Scenario: The same tree is inspected twice

- **WHEN** the command runs twice over an unchanged tree, change and repository state
- **THEN** both runs print identical states and transitions, because nothing is derived from a
  session's memory or a clock

#### Scenario: Tasks are complete and no review evidence exists

- **WHEN** every task is ticked and no review snapshot for the change can be found
- **THEN** the public state is `checking` and the next transition is the review stage, with the
  missing evidence named rather than assumed to have happened

### Requirement: An undetermined state is never the optimistic one

When an input the state depends on is unavailable — no run trace, no `gh`, an unreadable root, a
repository with no remote, or a review snapshot whose content no longer matches the tree — the
command MUST NOT report the optimistic state. It MUST report `needs-decision` (or `checking`, for
a mismatch that obliges re-review) and **name every transition whose verdict it could not
determine**, so the precision limit is declared instead of hidden behind a confident answer.

#### Scenario: A review snapshot no longer matches the tree

- **WHEN** a review snapshot exists for the change and the working-tree fingerprint does not
  match it
- **THEN** the precise state is the stale-evidence one, the transition is re-review, and the
  mismatch is reported with both fingerprints

#### Scenario: An input is unavailable

- **WHEN** an input cannot be read (no trace available yet, `gh` missing, no remote configured)
- **THEN** the command still reports the state it can prove from the remaining inputs, and lists
  the transitions it could not determine with the reason — it never substitutes a guess for the
  missing input

#### Scenario: No active change

- **WHEN** the repository has no active OpenSpec change
- **THEN** the command reports that state plainly with the transition that starts one, instead of
  inventing a stage

### Requirement: The state is informational and the human keeps the decision

The reported state MUST be informational and MUST NOT block a stage, authorize a merge, archive
or close a change, or replace any gate (`review-change`, `qa-change`, the formal QA gate of
`pr-review`). When the next transition is a human decision (merging a PR, archiving a change, a
scope call), the public state MUST be `ready` and the transition MUST say that the decision is
the user's.

#### Scenario: A PR is open, reviewed and CI-green

- **WHEN** the change's PR is open with green checks and its review and QA evidence is current
- **THEN** the public state is `ready`, and the reported transition names merging as the user's
  decision — the command does not merge, approve or close anything

#### Scenario: The state is used as evidence of a gate passing

- **WHEN** a workflow or agent treats a `ready` state as proof that review or QA passed
- **THEN** that is a defect: the command's own output states which evidence it read, and the
  gates remain the reviewer's and QA's verdicts, not the state's
