# Rule: SDD trigger and language

When to run the full SDD agency loop, and the language contract for everything
it produces.

## Full SDD flow

A request that proposes a problem or feature to analyze runs the **complete agency
loop**, starting from analysis of the feature/problem:

```
idea-to-openspec → openspec-to-architecture → plan-change
  → implement-change → review-change → qa-change → release-change
```

Flow, unless the change is classified as minimal or cosmetic by `rules/openspec.md`
("Task size and fast path"):

- **Analyze first.** The problem/feature is examined by the discovery/openspec agents
  before any planning or code. No stage starts from a half-understood idea.
- **Full role set.** Discovery, openspec, architect, planner, builder, reviewer, qa,
  release — loaded stage by stage, one per stage, never all at once (`rules/orchestration.md`).
- **Independent stages run in parallel** via `delegate_task`; dependent stages wait for
  Hermes to verify the previous output first.
- **Each agent returns the mandatory envelope** (status / summary / projectRoot /
  filesCreated / filesModified / blockers / nextRecommendedStep / evidence / openQuestions).
- **Outputs are re-verified in the repo** before advancing (`git status --porcelain`,
  `git diff --stat`, re-run the gate). An agent's reply is a self-report, not a fact.
- **Only reviewer and qa may block.** Two failures with the same error ⇒ the spec is
  wrong, go back a stage, not in circles.
- **Ambiguity of business, architecture, security or scope ⇒ ask the human** (options +
  recommendation + impact) and write the answer into the project as spec/ADR.
- **Every workflow closes with a final report** in the project (`templates/final-report.md`),
  and a completed change is archived + specs synced as part of closure (never optional).

A request that just says "run the workflow / /agencia / 'los agentes'" also enters this
flow; the trigger does not depend on the exact wording. Minimal and cosmetic changes
follow the fast path in `rules/openspec.md`, not this full loop.

## Language contract

Everything the SDD system produces is written in **English** — and only in English:

- specs and deltas (`openspec/`)
- architecture, design.md, ADRs
- analysis, review and qa reports
- code, identifiers, file names, branch names
- commit messages and PRs
- documentation

The **only** exception is the conversation with the user, which is always in **Spanish**:
every reply to the user — including one-line acknowledgements and
closing summaries of a task that ran entirely in English — is in Spanish. Tool output,
code blocks, paths, slugs and commands stay English by design; the prose around them
does not. A reply to the user in English or any third language is a failure.

These two sides never leak into each other: never write product/analysis prose in Spanish
into specs or reports, and never answer the user in English or a third language.
