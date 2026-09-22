# Rule: Code

It applies to any code written by the builder agent. The project decides the style;
Hermes imposes the process and the prohibitions.

## Precondition

- Not a line of implementation is written without a validated OpenSpec change in the
  project (see `rules/openspec.md`). Reading, exploration and analysis always; writing
  code, no.
- The code implements **the change**, not the idea that the agent thinks is best. If the spec is
  incorrect or insufficient, stop and go back to the openspec/architect stage; the decision is
  not improvised inside the code.

## Conventions: local first

- Before writing, read the project's rules (`AGENTS.md`, `.hermes.md`, `CLAUDE.md`,
  `CONTRIBUTING.md`) and follow the repo's: naming, folder structure, error
  handling, formatting, commands.
- **Never import conventions from another project.** A style decision seen in a
  sibling repo is not global: if the active project does not declare it, ask or follow
  the repo's own existing code.
- What is global in Hermes are the prohibitions of this rule, not the code's style.

## Comments

- Do not comment on what the code already says. No JSDoc, docstrings or narrations
  ("initialize the counter", "iterate the list").
- A comment is justified only if it explains a non-obvious **why**: an environment or language
  gotcha, an invariant that is not visible in the code, a workaround with its
  reason. If the comment can be deleted without losing information, it is deleted.

## Form prohibitions

- No speculative abstractions or extension points without a concrete consumer.
- No wrappers "just in case", no `try/catch` around code that cannot fail,
  no flags that nobody enables.
- No dead or commented-out code. If it is not used, it is deleted.
- No mass reformatting, no version bumps, no "I took the opportunity and fixed this other
  thing" within the same step: each of those is a separate change.
- No renaming or moving files outside the change's declared scope.

## Scope and diff

- The agent declares beforehand the files it is going to touch and does not touch others. The
  reviewer compares the real diff against that declaration (`git diff --stat`, `git status`).
- Changes are limited to the scope of the OpenSpec change; new scope detected
  during implementation is reported, not implemented.
- The repo's state is respected: nothing is committed, nothing is pushed and the branch is not
  touched on the agent's initiative unless the workflow explicitly asks for it.

## Work units and commit granularity

- **One commit per coherent work unit.** A work unit is the smallest coherent behavior plus the
  tests and docs that make it verifiable — not a checkpoint, not one commit per edited file, and
  not one commit for the whole change unless the change is itself a single unit.
- Each unit's commit carries its tests and documentation together with the behavior, with a
  Conventional Commit message in the repo's history style (`git log --oneline -20`). A change is
  never split artificially just to produce more commits.
- **Who commits:** the user, or Hermes when the workflow asks for it. The `builder` never commits
  on its own initiative (`agents/builder.md`); when it is not authorized to commit, it reports the
  unit as complete with its evidence and Hermes creates the commit.
- **The progress record** for a unit is the builder's stage-closure report (`templates/final-report.md`)
  carrying that unit's commit hash — not a chat message and not a separate artifact.

## Authored-lines budget (advisory)

- About **400 authored changed lines** (additions + deletions, generated files excluded) is the
  advisory planning heuristic for one reviewable delivery. It is **not** a hard cap, an
  automatic stop, a rework trigger or an acceptance criterion.
- It never justifies deleting spaces, blank lines or comments for cosmetic savings, omitting or
  weakening tests, minifying, adding gratuitous abstractions, or splitting a unit artificially.
- If the correct, clear solution naturally exceeds it, state briefly why and continue — no
  size-only rework loop.
- When a change's running count crosses the budget, the delivery strategy is **chosen and
  recorded** (`single-pr` / `chained-pr` / `split-change`) per
  `workflows/implement-change.md` — the delivered shape is a decision on record, not an accident
  of how many commits accumulated.

## Dependencies and configuration

- Every new dependency is justified in the change's `design.md` (what problem it solves,
  why it is not solved without it). Without justification, the reviewer raises it as MAJOR.
- The repo's version limits and lockfile are respected; a dependency is not updated
  outside the scope.
- Credentials and secrets: never in the code nor in committed files. The project
  defines where they live (`.env`, secret manager); the agent does not invent them nor paste
  them into the code.

## Language and messages

- Code, identifiers, file names, commit messages and branches in **English**;
  the conversation with the user in Spanish.
- Commit messages follow the repo history's style (`git log --oneline -20`);
  if the repo has no style of its own, imperative mood, one line, no emoji and no filler.
- The error texts that the end user sees follow the language the project already uses.

## Domain model

When the architect shaped the change's domain with **Domain-Driven Design**
(`agents/architect.md`), the builder implements **following that model**: entities,
aggregates, value objects, repositories and bounded contexts as designed — not a
deviating structure improvised inside the code. Domain rules live in the domain model,
not spread implicitly across the implementation. On changes the architect chose not to
model with DDD, this rule does not apply.

## Closing the builder stage

Report to Hermes, with evidence, and without claiming more than was done:

- files touched (the real diff list, not the intention);
- repo gate commands executed and their output;
- tasks of `openspec/changes/<name>/tasks.md` marked `- [x]`, only those really
  implemented and verified;
- what was left out and why.
