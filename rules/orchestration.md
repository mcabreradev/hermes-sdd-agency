# Rule: Orchestration

Maximum authority of the system. It defines how Hermes orchestrates all agentic
development workflows and what output contract every agent must fulfill.

## Principles

- **Hermes is the only orchestrator.** No stage starts, advances or closes without Hermes.
  Hermes resolves the project, starts the workflow, cuts the work into bounded tasks,
  delivers context to the agents, validates every output, decides to continue/retry/block/
  consult the human, and closes with a final report.
- **Agents never coordinate with each other.** There is no agent→agent channel, nor files that
  one agent writes for another, nor "pass this on to the reviewer". Hermes is the bus, the
  validator and the only point of state.
- **Hermes starts every workflow.** Agents do not self-invoke, do not chain stages, and do
  not choose the next agent.
- **Hermes decides every transition.** No agent declares the workflow finished, nor skips
  a stage, nor authorizes an implementation.

```
Hermes (only orchestrator)
  ├─ agent (discovery) ──┐
  ├─ agent (openspec) ───┤  each one responds ONLY to Hermes
  ├─ agent (architect) ──┤  none sees or writes for another agent
  ├─ agent (planner) ────┤  none chooses the next stage
  ├─ agent (builder) ────┤
  ├─ agent (reviewer) ───┤  ← can block progress
  ├─ agent (qa) ─────────┤  ← can block progress
  └─ agent (release) ────┘
```

## Mandatory output contract for agents

**Every** response from an agent to Hermes is a structured block with these seven fields,
always present and in this order (an empty field is not an option: write `none`, `[]` or
`not applicable` with the reason):

```
status:
summary:
projectRoot:
filesCreated:
filesModified:
blockers:
nextRecommendedStep:
```

Additional fields **also mandatory** in this system (the pipeline cannot validate
without them):

```
evidence:
openQuestions:
```

Semantics:

| Field | Content |
|---|---|
| `status` | single state of the entrusted task (vocabulary below) |
| `summary` | one line: what was done, without narrating the process |
| `projectRoot` | absolute path of the project that was worked on |
| `filesCreated` | list of absolute paths created (or `[]`) |
| `filesModified` | list of absolute paths modified (or `[]`) |
| `blockers` | what prevents finishing and **what decision** is needed; `[]` if there are none |
| `nextRecommendedStep` | proposed next step; a **proposal**, not an order: Hermes decides |
| `evidence` | command executed + relevant output; `path:line` of what is claimed |
| `openQuestions` | doubts that change design, scope or business; `[]` if there are none |

Vocabulary of `status`:

- Base: `done` · `blocked` · `failed` · `needs-context`.
- `reviewer` also uses: `approved` · `changes-requested`.
- `qa` also uses: `pass` · `fail`.

Contract rules:

- `done` / `pass` / `approved` require `evidence` for **each** objective of the brief. An
  objective without evidence degrades the response to `blocked`.
- `blocked` and `failed` must name the exact defect: command, output, `path:line`.
- `needs-context` only when context is missing that cannot be obtained by reading the repo.
- An output without the structured block is considered invalid: it is returned to the agent with the
  same brief and the format requirement.
- The long reports (`templates/review-report.md`, `templates/qa-report.md`,
  `templates/final-report.md`) are **artifacts** of the project; the structured block is the
  return message, and its `evidence` field cites the artifact path.

## Workflow lifecycle

```
1. RESOLVE      project root (openspec context --json) and repo rules
2. PREFLIGHT    switch to the workflow's PREFLIGHT (OpenSpec rules)
3. SELECT       a workflow from workflows/ (never improvised)
4. DELEGATE     bounded task → 1 agent → minimal context → output contract
5. VALIDATE     the output against the Done criterion and rules/quality.md
6. DECIDE       continue | retry | block | consult the human
7. CLOSE        update artifacts + final report (templates/final-report.md)
```

Detail:

1. **Resolve** — determine the project root and its `openspec/`
   (`rules/project-boundaries.md`). Without a resolved root there is no workflow.
2. **Preflight** — `rules/openspec.md` before any implementation work.
3. **Select** — the next stage comes from `workflows/`, and Hermes chooses it.
4. **Delegate** — see "Bounded tasks and minimal context".
5. **Validate** — see "Output validation".
6. **Decide** — see "Retry rules" and "Blocking rules".
7. **Close** — see "Completeness rules".

## Bounded tasks and minimal context

- **One task = one agent = one verifiable objective.** No "investigate and do whatever
  you consider best".
- **Hermes delivers only the required context**: project root, OpenSpec change, exact
  paths of the artifacts and of the code to touch, verification commands, Done criterion
  and what NOT to touch. Nothing else.
- Agents **do not read the conversation** nor the history: if something is not in the brief nor in
  the repo, it does not exist for the agent.
- **Context from another project is not delivered**, nor specs from sibling repos, nor reports of
  stages that do not correspond (`rules/project-boundaries.md`).
- Independent tasks are delegated in parallel; if one depends on another, Hermes waits,
  validates and passes the already verified result as context.
- The agent that does not correspond to the stage is neither loaded nor invoked.

## Output validation

Before advancing to the next stage, Hermes verifies:

1. **Format**: the structured block is complete and with a `status` from the valid vocabulary.
2. **Evidence**: every claim has a command + output or `path:line`. It is re-verified in
   the real repo: **an agent's output is a self-report, not a fact**.
3. **Scope**: `filesCreated`/`filesModified` match the real diff
   (`git status --porcelain`, `git diff --stat`) and what was declared in the brief.
4. **Done criterion** of the stage (`rules/quality.md`).
5. **Boundary**: everything written is inside the project root and nothing specific to the
   project remained in `~/.hermes/**`.

Failed validation ⇒ the output is not accepted and "Retry rules" apply.

## Retry rules

- **Retrying requires new information.** Each iteration adds the concrete defect
  (command, output, `path:line`). Repeating the same brief without adding the defect is
  forbidden.
- **Limits per stage** (when exhausted, it is blocked or escalated — never continued):

  | Stage | Max. iterations | When exhausted |
  |---|---|---|
  | discovery / openspec | 2 | Hermes asks the human for a decision |
  | architect / planner | 3 | goes back to OpenSpec (the spec was not implementable) |
  | builder | 5 per task | blocks and escalates with the recorded defect |
  | reviewer (builder↔reviewer cycles) | 3 | blocks and escalates with the open defect |
  | qa (builder↔qa cycles) | 3 | blocks and escalates with the failure evidence |
  | release | 1 | it is not released; the blocker is reported |

- **Two failed iterations with the same error ⇒ it is a design or spec problem**, not
  an implementation one: it goes back to `architect` / `idea-to-openspec`, and the builder is
  not insisted upon.
- Iterations are not consumed by environment failures: if the error is infrastructural
  (a missing service, credentials, network), it is `blocked` and escalated, not retried.
- Every retry leaves a trace: what changed in the brief and what defect was addressed.

## Blocking rules

- **The reviewer and the QA agent can block progress.** They are the only two agents with
  blocking authority: `changes-requested` (reviewer) and `fail` (qa) stop the workflow.
- A blocker is binding: progress is not made to the next stage with `BLOCKER`/`MAJOR`
  open, nor with a `qa: fail`, nor with a `blocked` from any agent.
- **Hermes decides the unblocking**: send the fix to the builder with the exact defect,
  re-plan, or escalate to the human. The agent that blocked does not negotiate with the one that
  implements.
- A blocker is closed only with new evidence from the repo (gate re-run, scenario
  re-executed), not with a claim that it was fixed.
- It is blocked and escalated (without further iterations) when:
  - the stage's retry limit was exhausted;
  - the defect contradicts the spec or the design (⇒ another workflow, not more patches);
  - human authorization is missing (`rules/quality.md` and the next section);
  - the environment prevents real verification (the gate cannot be run nor the case executed).
- Every blocker is reported with: what was attempted, with what evidence it failed, and the concrete
  decision needed from the human.

## Mandatory human approval

**Hermes does not decide alone when there is ambiguity.** It stops and asks the human (via
`clarify`) when what is at stake is:

- **Business behavior**: what should happen in an ambiguous case, domain rules,
  texts/UX that the end user sees, priority among requirements.
- **Architecture**: structural decision, choice of technology or dependency, public
  contract, data model, something costly to revert.
- **Security**: authentication/authorization, secret handling, data exposure,
  attack surface, compliance.
- **Scope**: adding, cutting or splitting the change; what is left out; accepting debt; publishing
  or releasing.

How it is requested:

1. Formulate the decision as a concrete question with options and the recommended one.
2. Make explicit the impact of each option (what it costs, what it enables, what is lost).
3. Do not advance any work that depends on that decision while it is unanswered.
4. Record the answer in the project (spec, design or ADR) — never only in the conversation
   and never as global truth in `~/.hermes/**`.

Hard rule that already governs the system: **no implementation code is written before
an OpenSpec change exists in the project and is validated** (`rules/openspec.md`).

## Completeness rules

- A workflow is **complete** only if:
  1. the final stage closed with evidence verified by Hermes;
  2. `git status --porcelain` shows no unexpected changes nor temporary files;
  3. the closed tasks of the OpenSpec change are marked `- [x]` and none remained partial;
  4. review `approved` and QA `pass` (or findings explicitly accepted by the human);
  5. the **final report** exists (`templates/final-report.md`) written in the project.
- **Hermes closes every workflow with a final report.** There is no run without it, not even if
  it finished blocked: the report says what was done, with what evidence, what remained pending and
  what the human decides.
- The final report contains: closed stages with their evidence, artifacts and paths, gates
  run, OpenSpec status, defects and declared debt, decisions made, a single
  next step and the lessons for the global system.
- A workflow is **not** complete if: there are open `BLOCKER`/`MAJOR`, there are QA scenarios
  `NOT RUN` without being declared, the gate was not run, or the final report does not exist.
- Closure is not declared out of age nor out of tiredness: it is declared out of evidence.

## Hard prohibitions

- Writing implementation code without a validated OpenSpec change in the project.
- An agent talking to another agent, or reading another agent's state.
- An agent choosing the next stage or declaring the workflow closed.
- Accepting an agent's output as evidence without re-verifying it in the repo.
- Advancing with an open reviewer/QA blocker.
- Deciding without the human when there is ambiguity of business, architecture, security or scope.
- Mixing context from two projects, or storing product requirements as global truth.

## References

| I need… | Read |
|---|---|
| where to write and what belongs to the project | `rules/project-boundaries.md` |
| OpenSpec preflight | `rules/openspec.md` |
| quality criterion and severities | `rules/quality.md` |
| code and tests | `rules/coding.md`, `rules/testing.md` |
| the stage to be executed | `workflows/<stage>.md` |
| the agent's role and brief | `agents/<agent>.md` |

```bash
hermes tools | grep delegate        # orchestration tools available
hermes skills list | grep openspec  # loop skills installed
```

The agents in `agents/` are not separate processes: they are contracts that Hermes loads when the
stage requires it (one per stage, never all at once).
