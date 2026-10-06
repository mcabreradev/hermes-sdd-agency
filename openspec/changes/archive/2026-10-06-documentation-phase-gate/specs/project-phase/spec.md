## Purpose

A project's phase — documentation, or implementation — is a fact in the repository that a human
sets and any agent reads, so "is code allowed here yet?" is answered by the tree instead of by a
conversation an agent never saw. In the documentation phase, application code paths must be
absent from the tree: the gate refuses to let them be introduced and allows them to be removed.

## ADDED Requirements

### Requirement: A project declares its phase in the repository

A project SHALL declare its phase in `openspec/project.md` as a `## Phase` block naming the phase
and the application-code paths that phase governs. The declaration SHALL be authored by the human
(product owner), and no agent SHALL set or change the phase on its own initiative. When a
declaration is missing, the phase SHALL be reported as undetermined rather than inferred from the
code that happens to be present.

#### Scenario: A project in the documentation phase declares it

- **WHEN** a project's `openspec/project.md` carries a `## Phase` block with `documentation`
- **THEN** any reader of the repository can determine the phase without the conversation, and the
  gate reads that declaration as its input

#### Scenario: The code present is not the answer

- **WHEN** a project carries application code under its declared application-code paths and its
  phase is `documentation`
- **THEN** the phase is still `documentation` — the presence of code never reclassifies the phase

#### Scenario: An agent does not open the implementation phase

- **WHEN** an agent considers that the documentation is complete enough to start
- **THEN** it proposes opening the phase to the human and SHALL NOT write the phase change itself

### Requirement: In the documentation phase no application code is introduced

`bin/phase-gate` SHALL refuse — non-zero exit, naming the offending paths — when the declared
phase is `documentation` and the resulting tree carries a tracked file under the declared
application-code paths. The refusal SHALL hold regardless of whether the change proposing that
code is validated and apply-ready: a valid change is not an authorization to implement.

#### Scenario: A validated change proposes application code in the documentation phase

- **WHEN** the change is complete, apply-ready and validated, and it adds a file under the
  declared application-code paths
- **THEN** the gate refuses and names the paths, and the implementation stage does not start

#### Scenario: A change removes application code in the documentation phase

- **WHEN** the change deletes the files under the declared application-code paths and adds none
- **THEN** the resulting tree carries no such file and the gate passes

#### Scenario: The implementation phase adds no phase constraint

- **WHEN** the declared phase is `implementation`
- **THEN** the gate passes and reports the phase, imposing nothing beyond the existing change gate

### Requirement: The verdict is derived from the tree, and a removal is not an introduction

The gate SHALL derive its verdict from the resulting tree rather than from the change's diff, so
that a removal passes while an introduction is refused, and so that the same tree yields the same
verdict no matter which branch, worktree or commit is asked.

#### Scenario: The same tree is inspected twice

- **WHEN** the command runs twice over an unchanged tree
- **THEN** both runs print the identical phase and verdict, because nothing is derived from a
  session, a clock or a diff range

#### Scenario: A worktree's copies do not count as the project's tree

- **WHEN** the project holds ignored worktrees containing application code and its own tree holds
  none
- **THEN** the gate reads the project's own tree and passes, because an ignored worktree copy is
  not the project's state

### Requirement: An undeclared or unreadable phase is never read as permission

When the phase cannot be determined — no `openspec/project.md`, no `## Phase` block, an
unrecognized phase value, or a declaration whose application-code paths are empty — the gate MUST
NOT report a pass. It MUST report that it cannot assess, exit non-zero, and name what it could not
read, so that a missing declaration is never silently equivalent to an open implementation phase.

#### Scenario: No phase is declared

- **WHEN** the project has no `## Phase` block in `openspec/project.md`
- **THEN** the verdict is cannot-assess with a non-zero exit and the missing declaration is named,
  and the gate never prints the passing verdict

#### Scenario: The phase value is not recognized

- **WHEN** the declared phase is a value the gate does not implement
- **THEN** the verdict is cannot-assess naming the unrecognized value, because an unknown phase is
  not evidence that implementation is permitted

### Requirement: The phase gate binds the loop and the merge

The implementation workflow's preflight SHALL run the phase gate, and a consuming project SHALL be
able to run it in its CI. A refusal SHALL be surfaced as a blocker whose class is `decision` — the
phase is the human's to open — and not retried, reclassified or worked around.

#### Scenario: The implementation preflight runs the gate

- **WHEN** `implement-change` is invoked for a project whose phase is `documentation`
- **THEN** the preflight fails the phase gate and the workflow does not start

#### Scenario: The refusal asks the human, it does not loop

- **WHEN** the gate refuses during the implementation stage
- **THEN** the blocker is `decision` and names opening the phase as the human's choice, so the
  agent does not retry, narrow the change or reclassify the work to proceed

#### Scenario: The project's CI fails on the same verdict

- **WHEN** the consuming project runs the gate in CI against a tree that introduces application
  code in the documentation phase
- **THEN** CI fails, so a change that reached a branch without the preflight is still stopped
  before it merges
