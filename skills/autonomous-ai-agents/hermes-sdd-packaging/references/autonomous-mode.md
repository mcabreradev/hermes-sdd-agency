# Autonomous mode for the SDD agency (the `do` bundle pattern)

How to give the SDD agency a fully-autonomous path that still respects its own
rules. Captured as a design reference from the `do` capability; the design was
user-approved, the implementation may be partial — treat this as the pattern,
not as a finished/validated end-to-end flow.

## The `/feature` HARD-GATE is by design, not a bug

The feature bundle stops after brainstorming and waits for explicit user design
approval ("> no implementation until the user approves the design"). A user who
expects autonomous progress past the questions is NOT hitting a bug — the gate
by design is only opened by the user. The fix is an explicit autonomous mode
that relaxes the gate declaratively, never a silent loosening of the feature
bundle itself.

## Autonomous mode relaxes human-approval rules via declared defaults

The SDD agency's core rules make Hermes stop and ask the human on ambiguity of
**business / architecture / security / scope** (rules/orchestration.md "Mandatory
human approval", rules/sdd.md). A 100%-autonomous `do` mode contradicts that
heart — build it as an explicit override at the workflow/bundle level, never as
a rewrite of the standing rules. Carry a decision table with conservative defaults:

| Decision point | Default in autonomous mode |
|---|---|
| Business | Not invented. If the idea doesn't define the rule, implement the minimal behavior, mark **"ASSUMED — verify in PR"**, record an ADR. |
| Architecture | Follow the project's existing stack/patterns (AGENTS.md, tech stack). Path of least resistance; no new deps unless standard for the stack. |
| Security | Always the most conservative: no credentials, no expanded attack surface, standard practices. **Real security risk (auth/secrets/exposure) STOPS and escalates — never decided alone, even autonomous.** |
| Scope | Never expand. New scope is cut off and recorded as another change. No versioning/publish decisions: the terminal is a PR. |

Each default taken is written as an ADR in the project and listed in the final
report, so the human reviews all of them in the PR and corrects silently if needed.

## Terminal state: PR (draft) awaiting human review

Autonomous mode never merges, never publishes, never tags. It chains
discovery → openspec → architect → planner → builder → reviewer → (bugfix loop)
→ QA → release, then opens a PR for the human to review and merge. The human is
the final gate; the agent's only "publish" is the PR itself.

## Honest caveat for the user

The builder↔reviewer↔QA loop is same-model self-validation: the reviewer shares
the builder's blind spots, so a green PR can still carry silent design debt.
Recommend test-driving `do` on a throwaway project and reading the first PR's
ADRs end-to-end before trusting it on a real codebase. "do" shines on
routine/well-bounded features and refactors; it is dangerous on the first build
of a novel domain or anything touching real contract/security.

## When proposing the autonomous mode

Present the tension plainly (autonomy contradicts the human-approval rules),
offer a confidence-threshold variant (routine sleeps, non-trivial design wakes)
when the user picks "100% autonomous always", and respect the choice once made.
