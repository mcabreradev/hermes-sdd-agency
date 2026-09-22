# Workflow: implement-change

Implements the tasks of the OpenSpec change. It is the only stage where code is written, and
only after preflight enables it.

- **Agents:** `builder` (and `planner` if a section has to be re-planned)
- **Rules:** `rules/openspec.md`, `rules/coding.md`, `rules/testing.md`, `rules/quality.md`
- **Method:** test-driven by **hard rule** (`rules/testing.md`) — the builder implements
  behavior-bearing tasks test-first (RED→GREEN→REFACTOR); backend/business logic is never
  written without its failing test first, and only behavior-free code is declared `not
  applicable` in the report.
- **Output:** code + tests for the change, tasks marked `- [x]` with evidence.
- **Personas/method:** `fullstack-developer` / `typescript-pro` · **`test-driven-development` (hard rule)** · `executing-plans` (batches with checkpoint) · `dispatching-parallel-agents` if there are independent tasks · `debugger`/`error-detective` when a task gets stuck.

## 0. Preflight (Hermes) — blocking

```bash
cd <project-root>
test -f openspec/project.md                 # if missing → initialize-project (blocking)
openspec context --json                     # root.path == <project-root>
openspec status --change "<name>" --json
openspec validate "<name>" --type change --json            # without ERROR
openspec instructions apply --change "<name>" --json       # state: ready | all_done
```

**Without these steps in the green, this workflow does not start.** If the change is missing, go back to
`idea-to-openspec`; if the project root or `openspec/project.md` is missing, run
`initialize-project` (`rules/project-boundaries.md`). This is the system's hard rule: there
is no code without a validated change.

In addition, read from the repo (do not invent): the real build, test, lint, typecheck
commands, and the state of the working tree (`git status --porcelain`) to know where you are starting from.

## 1. Cycle per task (`builder` agent)

Brief per bounded batch of tasks (not "implement the whole change" at once):

- project root, change name, spec/design/tasks paths;
- the exact tasks to implement and their verification criterion;
- files it may touch (declared scope);
- repo gate command;
- what NOT to do: touch `openspec/specs/`, commit, reformat outside scope, expand
  scope, weaken tests.

The agent delivers the mandatory envelope of `rules/orchestration.md`. **Hermes verifies in
the repo** before accepting: `git diff --stat`, files touched vs declared
(`filesCreated`/`filesModified`), gate actually run.

## 2. Iterations and cutoffs

- Max. 5 iterations per task, each with the exact defect (command, output,
  `path:line`). Repeating the same brief without adding the defect is prohibited.
- Two failed iterations with the same error ⇒ the problem is design's or spec's: go back
  to `openspec-to-architecture` / `idea-to-openspec`, do not insist on builder.
- If new scope appears: it is cut off, reported, and the user decides whether it is another change.
- If the change needs to modify a requirement of the spec: stop and use
  `openspec-update-change` (do not edit specs from the code).

## 3. Stage closure

```bash
openspec instructions apply --change "<name>" --json      # task progress
git diff --stat
<repo gate>                                                # build / lint / test / typecheck
```

- [ ] All the tasks of the brief implemented and marked `- [x]` with evidence.
- [ ] Repo gate green (real, run; if it could not be run ⇒ `blocked`).
- [ ] Diff limited to the declared scope; no collateral changes.
- [ ] Specs and `design.md` intact (if the code diverged from the design, it is reported).
- [ ] Each coherent work unit closed with its own commit carrying its tests and docs
      (`rules/coding.md`: work units and commit granularity).
- [ ] Authored-lines budget checked (`git diff --numstat <base>...HEAD`, generated files
      excluded) and, if the change crossed the advisory ~400-line budget, the **delivery
      strategy is recorded** — see the section below.

## 4. Delivery strategy when the budget is crossed

The advisory budget (`rules/coding.md`) is only useful if crossing it produces a *decision*.
Before opening the **next** PR of a change whose running authored-line count has crossed it:

1. Choose one strategy and **write it into the change's artifacts** (`design.md` or
   `tasks.md`, or the report when the change has neither room):

   | Strategy | When | Shape |
   |---|---|---|
   | `single-pr` | the excess is small and the reviewer accepts one larger diff | one PR, the choice recorded |
   | `chained-pr` | the change is one behavior delivered in slices | a chain of PRs, each based on the previous slice; slice boundaries (which commits each PR holds) recorded |
   | `split-change` | the excess is independent work, not a slice | stop; the excess becomes its own OpenSpec change per `rules/openspec.md` |

2. For `chained-pr`, cut the slices along the work units already committed — never re-split the
   work to fit a number, and never deliver a slice whose tests do not pass on its own base.
3. Record the strategy and the slice boundaries **before** the PR is opened, so the delivered
   shape is inspectable in review. A `single-pr` choice is a valid outcome; an *unrecorded*
   choice is the defect this step exists to prevent.

**Scope creep is not a delivery strategy.** Work that the change did not authorize is
`split-change` (reported, not absorbed), per `rules/coding.md` and `rules/openspec.md`.

## Output

Report (`templates/final-report.md`): closed tasks, files touched, gate output,
pending tasks, declared debt, and next step (`review-change`).

## Typical errors

- Starting without preflight because "the change is already there, only the code is missing".
- Accepting the builder's self-report without looking at the diff.
- Marking `- [x]` with partial functionality.
- Retrying the same design error in a loop.
