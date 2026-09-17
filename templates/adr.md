# Template: ADR (Architecture Decision Record)

One ADR per decision with lasting consequences, **inside the project** (for example
`docs/adr/NNNN-<slug>.md` or the ADR directory the repo already uses). ADRs belong to the
project, never global.

---

```markdown
# ADR-NNNN: <decision title>

- **Status:** proposed | accepted | superseded by ADR-NNNN | deprecated
- **Date:** <YYYY-MM-DD>
- **OpenSpec change:** <change-name> (or "N/A — foundational decision")
- **Deciders:** <user / architect agent>

## Context

<!-- Situation and constraints that force the decision. Verifiable facts from the repo,
     not opinions. -->

## Decision

<!-- The decision in one or two sentences, in the present tense: "We use X for Y". -->

## Alternatives considered

| Alternative | Why it was discarded |
|---|---|
| <A> | <concrete reason> |
| <B> | <concrete reason> |

## Consequences

**Positive:**
<!-- What it enables, what it simplifies. -->

**Negative / costs:**
<!-- What it complicates, what debt it creates, what becomes hard to revert. -->

## Reversibility

<!-- How much it costs to go back (cheap / expensive / irreversible) and what would have
     to be done. -->
```

## Rules

- It is written **at the moment** the decision is made (inside
  `openspec-to-architecture`), not after implementing.
- An ADR is not edited to change the decision: a new one is created to supersede it and
  the previous one's status is changed.
- Language: what, why and what was discarded. No process narrative nor "Tuesday's
  meeting".
- If the project already has an ADR convention, use it (numbering, folder, format);
  this template is the minimum content, not a mandatory format.
