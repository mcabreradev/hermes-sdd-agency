---
name: hermes-sdd-orchestration
description: "Use when running the Hermes SDD agent agency on a project."
version: 1.0.0
metadata:
  hermes:
    tags: [orchestration, sdd, openspec, agents, workflows, multi-agent]
    related_skills: [openspec-sdd, hermes-external-skills-and-agents, hermes-agent]
---

# Hermes SDD orchestration — the agency

How this machine runs software projects: Hermes is the **only orchestrator**; eight agent
roles do the work; OpenSpec holds the requirements **inside each project repo**.

Load `openspec-sdd` alongside this skill for the CLI mechanics (validators, archive traps,
root resolution). This skill is the process layer above it.

## When to use

Any request to plan, build, review, verify or ship a feature in a project; "run the
workflow"; "initialize the project"; "the agency"; "los agentes". Also load it before
editing anything under `~/.hermes/{agents,workflows,rules,templates}`.

**Shortest invocation:** the `/agency` slash command (a skill bundle that loads this skill
plus `openspec-sdd` and injects the orchestrator protocol). Per stage: `/init-project`,
`/idea`, `/architecture`, `/plan`, `/implement`, `/review`, `/qa`, `/release`, `/pr-review` —
`hermes bundles list` shows them all. If the bundle is not available, this skill still
autoloads on the phrases above; the human-facing cheat sheet lives in
`~/.hermes/HOW-TO-INVOKE-THE-AGENCY.md`.

## Layout — process is global, product is local

```
~/.hermes/
  agents/      discovery openspec architect planner builder reviewer qa release
               pr-reviewer (+README.md)
  workflows/   initialize-project idea-to-openspec openspec-to-architecture plan-change
               implement-change review-change qa-change release-change pr-review
  rules/       orchestration project-boundaries openspec quality coding testing
  templates/   openspec-project proposal tasks spec architecture adr
               review-report qa-report initialize-project-report final-report
```

`agents/README.md` is the entry point and reading map. Each workflow names its agent, its
preflight, its retry limit and its exit criteria — read the workflow before running a stage.

**A project owns** its `openspec/`, source, docs, tests and product context. **Hermes owns**
the process. Never store a project's requirements, domain rules or client facts in
`~/.hermes/**`; never copy global agents/workflows into a project.

## The sequence

```
initialize-project → idea-to-openspec → openspec-to-architecture → plan-change
  → implement-change → review-change → qa-change → release-change
  → pr-review      (post-open, domain-experienced review of the published PR)
```

`pr-review` is the **post-open** quality gate: it runs *after* a PR is published
and CI is green, and drives the PR to `approved` with a domain-persona reviewer
(backend/frontend per the diff), a builder↔reviewer loop (max 3 cycles), and a
**mandatory formal QA gate** (`qa-expert` executing the scenarios against the
running app + real DB — review approval alone does not close the PR). For
infra/data/dep changes it also runs report-only QA on merged `main` after merge.
It never merges. See `workflows/pr-review.md`. The pre-merge adversarial gate
remains `review-change`.

One agent per stage. Independent stages may run in parallel (`delegate_task`); dependent
ones wait for Hermes to verify the previous output first.

Independent verification beats trusting a self-report: after any stage, re-check the claim
in the repo (`git status --porcelain`, `git diff --stat`, re-run the gate) before it unlocks
the next stage.

## Parallelization and worktree ownership

- **Derive the parallel decision with `bin/change-collision` — do not eyeball the file
  sets.** Before dispatching two changes concurrently, run `bin/change-collision --base
  <ref> --a <refA> --b <refB>`: `parallelizable` (no overlapping paths, no shared
  high-risk family: schema/migrations, `openspec/`, contracts/auth, dependency manifests)
  → may run in parallel, each change in its own worktree. `collision` (overlapping paths,
  or both changes touch the same high-risk family even without literal overlap) → run
  sequentially. `cannot assess` (empty diff, bad base, unresolved ref — non-zero exit) →
  **no parallel dispatch until the diff is measurable; never read it as `parallelizable`.**
  The verdict decides ordering, never approval. When in doubt, prefer sequential: two
  parallel builders on one checkout clobber each other's half-applied edits, and each
  `bunx prisma generate` / spec-regenerate picks up the other's intermediate state.
- **A builder's self-report that mentions a "sibling"/"concurrent" agent is noise.** Even with
  clean serialization (you cancelled the phantom child), a builder may still spin a narrative
  of cooperating with another agent to explain half its work. Treat it as unverified: read
  `git log --oneline` + `git status --porcelain` and confirm each commit is real, on-branch,
  and owned by the stage — not by whom the report credits. The "sibling committed most of it"
  claim is how an agent papers over its own messy handoff.
- **Every `delegate_task` entry MUST carry a `goal` field.** If the schema call omits it, the
  whole dispatch is rejected with "Task N is missing a 'goal'"; write `goal` + `context`
  together or the dispatch wastes a round-trip.
- **A delegated result that arrives truncated must be recovered from its stored copy, never
  guessed at.** A long reviewer report comes back cut mid-finding and the visible tail can read as
  a verdict while the decisive detail (a BLOCKER's mechanism, a path) sits in the omitted middle.
  The delivery names the file holding the full text and the offset to resume at; read it, and the
  live transcript under the delegation cache for the raw run. Acting on the visible fragment is
  acting on a summary you did not read.
- **Brief the reviewer to attack the change's own TESTS, not just its artifact.** A harness, a
  fixture or a `verifies:` line is authored by the same hand as the code, so it is where a
  fabricated pass hides: a suite that exits 0 because no case could build, a tick whose command
  cannot execute on this shell, a status captured through a pipe. Name that surface in the dispatch
  ("confirm the suite fails when its scaffolding is broken") — it is otherwise outside any
  reviewer's default reading.
- **A `delegate_task` dispatch that dies with "tasks must be a JSON array" on a large brief is
  usually the payload's `output_schema`, not the context prose.** Isolate with a one-line probe
  first. Agency stage briefs (builder/reviewer/qa) do NOT need `output_schema`: the envelope is
  enforced in the prose, so drop the schema and re-dispatch.
- **When an audit/verification subagent is the source of a claim you report to the user, reproduce
  its headline defect yourself with your own command before stating it as a fact.** Migue challenged
  a "formularios conectados" close that rested on a subagent's verdict, and on an agency review the
  subagent flagged a real parser bug that had to be reproduced by hand before it could be fixed. A
  forwarded audit is a self-report, not a verification.
- **A dispatch whose result you must read as data (a per-item list of findings) needs an
  `output_schema`; a prose report gets truncated.** A reviewer returning a dozen findings with
  evidence runs to tens of thousands of characters and arrives cut in the middle. Schema the
  per-finding shape (`{finding, status, verification_command, observed_output}`) so it survives
  intact; if the dispatch is rejected on the schema, drop it and enforce the shape in the prose.
- **Do not edit the tree while a subagent reviewer/auditor is reading it.** A fix applied mid-review
  invalidates the run and forces a fresh dispatch, and the reviewer may be reporting against content
  that no longer exists. Wait for the verdict, then apply every finding in one pass; if you want
  progress meanwhile, open the next batch in a different worktree.
- **On a re-review, brief the numbered prior findings verbatim and require CONFIRMED-CLOSED or
  REFUTED per finding with its command and observed output** — never a self-reported "fixed" — and
  name the surface the fix touched so the reviewer attacks the repair too, not just the original.
- **On an existing implementation branch (continue-mode), brief the builder to commit
  thematically as it goes and hand off a clean `git status`.** Explicitly say: thematic English
  commits are allowed; leave `git status` empty at handoff.
- **A file-scope/docs-cleanup phase must NOT be briefed to touch agent-instruction `CLAUDE.md`
  files.** A background subagent has no interactive prompt for protected files, so writes time
  out ("silence is not consent"). Brief builders to SKIP them and surface as a human-owned
  follow-up. BUT in foreground with the human at the keyboard, the orchestrator's own edit CAN
  land on approval — do it yourself interactively when the user is present and asks.
- **A fresh worktree lacks gitignored GENERATED code the build resolves (`@/generated/*`,
  `src/generated/prisma`, openapi types).** Say in the builder brief: after `bun install`,
  re-run the repo's generator with dummy env (no DB needed for generate).
- **A build step running in a generated dir is not a source regression — scope the gate to the
  touched module.** Repo-wide lint noise elsewhere is not this change's failure; confirm the
  touched module and the full gate exit 0.
- **Brief the builder AND qa to run the repo's strict test-type gate, not just `typecheck` —
  and when a change widens an interface, to grep test mocks too.** `bun run typecheck` often
  excludes `src/**/*.test.ts`, so adding a method breaks hand-rolled `as X` mocks invisible to
  typecheck but caught by `typecheck:test`. Put in the brief: run `typecheck:test` + `format:check`
  and grep the test tree for `as <Interface>` casts.
- **A push that only deletes remote branches can be blocked by the repo's pre-push `format:check`
  hook when the worktree has no `node_modules`** (prettier: not found, exit 127). For a pure-
  deletion push use `git push origin --delete --no-verify <branch>`; keep `--no-verify` off any
  push that carries commits.
- **Squash-merged PR branches are not recognized as merged by git.** After a squash merge the
  head-branch tip is a new single commit on main, not an ancestor, so `git branch --merged`
  reports it as NOT merged and `git branch -d` refuses — expected, not a failed merge. Judge by
  `gh pr view <n> --json state` → `MERGED`, then clean with `git worktree remove` + `git branch -D`.
- **A change scaffolded by the CLI in the main tree stays behind as untracked residue when the
  work is authored in a worktree.** After merge+cleanup, inspect `git status --short` in `main`
  and back up then remove any duplicate untracked `openspec/changes/<slug>/` residue.
- **A docs/tooling-only worktree has no `node_modules`, so `bun run format:check` fails there.**
  Use `bunx prettier --write <file>` and read its `(unchanged)` verdict instead of the exit code.
- **A multi-PR refactor campaign is not one decision: each batch re-runs the confidence gate, and
  the LAST batch is the one that bites.** Stop the `/do` the moment a batch would force a new
  repository surface for infra or an anti-pattern; offer options (declared debt vs dedicated infra
  repository) rather than mechanically applying the batch's pattern.
- **A decomposition/god-file plan must verify module topology before relocating a method.** Moving
  a method that depends on a repo token can force a circular module dependency; keep such methods
  in the source service and document the acyclic-minimal rationale.
- **The human's "mergea" on a batch is consent to merge AND full cleanup; do not re-ask per PR.**
  Run merged PRs serially — `gh pr merge <n> --squash`, re-verify `gh pr view <n> --json state`=
  MERGED + `git fetch` + inspect the squash commit before the next — then cleanup every merged
  worktree + local/remote `agent/*` branch, `git pull --ff-only` local main, and sweep the
  scaffold residue.
- **`gh pr merge` does not print a robust confirmation — re-verify after every merge.** After
  `gh pr merge <n> --squash`, confirm with `gh pr view <n> --json state` and `git log origin/main`,
  before deleting branches or merging the next. Silence = unverified.
- **A builder that self-reports `done` routinely leaves the change's `tasks.md` unticked.** Before
  `openspec archive`, read `tasks.md` fresh and tick each box only against a real repo check; then
  prettier-and-commit the ticked file. Ticks are also lost when branches are rebuilt by selective
  cherry-pick — re-ticking before every archive is mandatory.
- **A closure archive freezes stale things unless reconciled BEFORE `openspec archive`:** (1)
  unticked tasks, (2) design/spec decisions the builder silently changed, (3) empty `Purpose` on
  newly-synced specs. Correct the change dir + delta spec to match what was really implemented,
  THEN archive, THEN write each `Purpose`, THEN prettier + validate + commit. Archive the corrected
  version — never archive-then-patch.
- **A builder that leaves a task open with a "works anyway" justification that contradicts an
  approved design decision is a scope deviation, not a completion — surface it, never absorb it.**
  Write it as a human decision explicitly into the PR body and keep the task open; resolving it
  either way is a scope call the human owns.
- **Uncommitted plan artifacts in `main` (tasks.md, design.md, specs) do not reach a fresh worktree.**
  Mirror the plan files into the worktree or commit them onto the branch first; verify the task
  count inside the worktree before briefing the builder.
- **`gh pr create`/`edit` bodies are ALWAYS written to a temp file and passed with `--body-file`;
  never an inline `--body` string.** Bash interprets backticks and `$sequence`, so a body lands
  mangled. Write the file, pass `--body-file`, confirm it survived with `gh pr view <n> --json body`.
- **Planning cards created on the Hermes kanban land in `ready` and the gateway dispatcher spawns
  real workers from them.** Park each card immediately after creating it; `block --kind needs_input`
  is the correct park for "waiting on Migue" (`dependency` auto-promotes and leaks a respawnable
  card). Keep the board in `todo` for phase cards and chain with `link parent child`.

## Hard gate: no code without a validated change

`implement-change` does not start until all of these pass from the project root:

```bash
test -f openspec/project.md                        # else run initialize-project first
openspec context --json                            # root.path == expected root
openspec validate "<name>" --type change --json     # no ERROR (read the JSON, not the exit)
openspec instructions apply --change "<name>" --json  # state: ready | all_done
grep -rn '^## [A-Z]* Requirements' openspec/changes/<name>/specs/*/spec.md \
  | grep -vE 'ADDED|MODIFIED|REMOVED|RENAMED'        # any hit = inert delta; no output expected
```

A green `validate` is not a valid change: it judges structure, never whether the delta says what
the author meant. Two failures pass the CLI and still void the change — a requirement with no
`#### Scenario:`, and requirements filed under an invented header (e.g. `## UNCHANGED Requirements`)
that `validate`, `list` and `archive` all skip. Run the grep above and read every `issues[]` entry,
not the verdict.

## Agent contract — mandatory envelope

`rules/orchestration.md` is the single source of truth for the format. Every agent reply to
Hermes carries all of these, none omitted (a no-op is `[]`, not a missing key):

```
status               done | blocked | failed | needs-context
                     (+ approved | changes-requested for reviewer; + pass | fail for qa)
summary              one line, no process narration
projectRoot          absolute path — must equal the root Hermes verified
filesCreated         absolute paths (or [])
filesModified        absolute paths (or [])
blockers             what stops it + which decision is needed (or [])
nextRecommendedStep  a proposal only; Hermes decides the transition
evidence             command + output, or path:line
openQuestions        doubts that change design, scope or business (or [])
```

- A `done` / `pass` / `approved` without evidence for **each** briefed objective degrades to
  `blocked`. A missing envelope field makes the reply invalid — return it to the agent with
  the same brief and the format requirement.
- **Agents never talk to each other.** No agent-to-agent file, no "pass this to the reviewer".
  Hermes is the only bus; agent output is a self-report until re-verified in the repo
  (`git status --porcelain`, `git diff --stat`, re-run the gate).
- The brief is self-contained: root, change name, exact paths, verification command, Done
  criterion, what NOT to touch. Agents do not read the conversation and get no context from
  other projects.

## Loop, blocking and completion

- **Blockers carry a class that selects the allowed response** (`rules/orchestration.md`,
  "Blocker classes"): `retryable` (recoverable defect → bounded retry, consumes an
  iteration of the stage's limit), `technical` (contradicts spec/design, change-change
  conflict → no circular retry: another agent, back a stage, or the two-failures rule),
  `decision` (data-model change, public contract, architecture, cost, business rule →
  the **human** decides: options + recommendation + impact; nothing that depends on it
  advances while unanswered). **Unclassified defaults to `decision`** — never silently
  retried or skipped by omission. Same `class` values flow into the trace.
- **Assign a trust level after validating, never accept a self-declared one.**
  `rules/orchestration.md`, "Trust vocabulary": `verified` (Hermes re-ran the claim in
  the repo), `partially_verified` (only part re-verified — the unverified part is
  declared), `self_reported` (nothing re-verified yet), `blocked` (open blocker; no
  dependent stage advances). The assigned level is recorded in the stage report and the
  trace entry. **Critical stages (review, QA, release) never close on `self_reported`:**
  re-verify the decisive claim in the repo, or declare the part that cannot be verified,
  before the stage advances.
- **Retry limits**: discovery/openspec 2 · architect/planner 3 · builder 5 per task ·
  builder↔reviewer 3 · builder↔qa 3 · release 1. Retrying requires new information (the exact
  defect: command, output, `path:line`); repeating the same brief is forbidden. Two failures
  with the same error means the design or the spec is wrong — go back a stage, not in circles.
- **Only reviewer and qa may block.** No stage advances with an open BLOCKER/MAJOR, a
  `qa: fail` or any `blocked`. The agent that blocked never negotiates with the one implementing.
- **Ask the human** when business behavior, architecture, security or scope is ambiguous
  (options + recommendation + impact; write the answer into the project as spec/ADR, never
  into `~/.hermes/**`).
- **Complete** means: final stage verified by Hermes, clean `git status`, tasks ticked only
  where implemented, review `approved` + qa `pass`, and a final report written in the project
  (`templates/final-report.md`). Every workflow ends with that report — including a blocked one.

## Gate honesty under a flaky suite

- **When the repo-wide test gate fails, prove the cause before trusting a "flake" claim — and
  don't accept a task marked `[x]` on a gate that exits non-zero.** Verify it yourself: the
  touched suites pass standalone, AND the identical failure reproduces on the pristine baseline
  commit. Only then is the gate failure genuinely environmental.
- **A task checkbox `[x]` whose verification is "gate passes" must NOT be ticked when the gate
  exits 1, even if 100% of the failures are environmental.** Tick it only on a truly green run;
  otherwise leave it `[ ]` and record the flake so the PR review is the human's call.
- **Never fix a markdown report the hard way against a formatter hook.** Run prettier and commit
  before pushing.

## Project boundaries that bite

- One root per stage. `openspec context --json` switches root silently with the cwd when
  nested roots exist; compare `root.path` against the expected root (with `pwd -P` — macOS
  `/tmp` is `/private/tmp`). Never proceed on the "most likely" root: block and report the
  literal JSON output.
- Read `openspec/` only from the current root. Never sibling repos, never reuse another
  project's requirements or conventions. Multiple projects requested ⇒ separate workflows.
- `openspec/project.md` is the marker that a project entered the loop — a Hermes convention
  the OpenSpec CLI ignores. Gate on `test -f`, never on a CLI verdict.
- A project whose root is not a git repo has no project-local skill discovery; say so.

## Reporting to this user

- **All agency documentation, code, identifiers, commits, file names and specs are in
  English.** Conversation with the user is in Spanish.
- **Changelogs are a short, appealing summary, not a spec dump.** Add an own entry per PR,
  in English, capturing what the user can see (feature/fix + impact), not every decision or
  endpoint. The user's standing rule: "el changelog no dar toda la información, solo un
  resumen atractivo y directo." Keep each bullet to what a reader should know; leave the
  details to the spec/design/ADR that the merge already carries.
- **Every reply to the user is in Spanish — no exceptions.** This includes one-line
  acknowledgements, status updates and closing summaries after a task that ran entirely in
  English. Tool output, code blocks, paths, slugs and commands stay English by design; the
  prose around them does not. A reply in the wrong language (English, or any third language)
  is a failure: say so plainly in the next turn and restate the content in Spanish.
- **During autonomous execution, don't stream progress; only surface blockers and
  super-critical confirmations.** Migue's explicit standing instruction: "no tienes que estar
  mándandome mensaje de lo que vas haciendo... Solo mándame mensaje si hay un blocker o una
  súper confirmación de algo demasiado importante." While executing a long task autonomously,
  do NOT send per-step updates; send a message only for a genuine blocker or a super-critical
  confirmation he must act on himself. This overrides the default of keeping the user informed.
- **Never label a status or a wait as a decision.** Writing "pending your decision" on something
  that is merely in flight (a subagent running, a check pending) invents an approval request that
  does not exist, and the user will rightly ask "which decision?" — with nothing to answer. If you
  were asked for a decision and there is none, say that plainly, correct the wording, and restate
  what is really pending (a state) versus what is actually theirs to choose. A question to the user
  carries a real fork (options + recommendation); a state is reported, not asked.
- Deliverables close with the same envelope the agents use — status / summary / projectRoot /
  filesCreated / filesModified / blockers / nextRecommendedStep — plus what was actually
  verified and what is left. No replay of the process.
- **PRs are opened OPEN, never draft.** Migue's standing rule: "luego de crear el pr dejalo
  abierto." After creating the PR run `gh pr ready <n>` if opened as draft, confirm
  `gh pr view <n> --json isDraft` is `false`, then report the open URL. Applies to every change
  that ships through this loop.
- Never claim a stage passed without a real command output behind it. If a gate could not be
  run, say so as `blocked` with the reason.

## References

- `references/external-personas.md` — the aitmpl personas and process skills that back each
  role, how to install them, where the installer really writes, and the upstream defects that
  make a converted persona silently useless.
- `references/stack-selection.md` — stack choice under the agency (persona coverage, the
  decision table), and the migration decisions.
- `references/performance-headroom.md` — how to measure the current engine's headroom before a
  performance-motivated rewrite.
- `references/spec-artifact-validity.md` — what `openspec validate` does not catch in a change's
  delta, with the detection greps.
- `references/repo-gate-flake.md` — how to prove a red `bun run test` is a pre-existing
  environmental flake before trusting a "flake" claim.
- `references/postgres-migration-pitfalls.md` — Postgres-side migration domain notes.
