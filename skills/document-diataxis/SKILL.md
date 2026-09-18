---
name: document-diataxis
description: "Generate complete, structured docs with the Diataxis quartet: tutorial, how-to, reference, explanation."
---
<!-- hermes-add-skill: Diataxis framework (Diátaxis, diataxis.fr) — the same framework gstack
     /document-generate and /document-release (garrytan/gstack, MIT) are built on. -->

# Document with Diataxis

Generate complete, structured docs for a feature, module, or project using the **Diataxis**
four-quadrant model. Invoke it when a docs gap exists (or `/document-release` finds one).

## The four types — and the trap of mixing them

| Type | Answers | Tone / shape |
|---|---|---|
| **Tutorial** | A newcomer's first success: *learning-oriented* | A guided path, step-by-step, one lesson. Not a reference dump. |
| **How-to** | *Task-oriented*: fix one problem | A recipe: the goal, the steps, the expected result. Focused and reusable. |
| **Reference** | *Information-oriented*: look things up | Exhaustive, precise, structured (commands, API surface, fields, options). |
| **Explanation** | *Understanding-oriented*: why it works this way | Background, context, decisions, the rationale. No step-by-step. |

The failure mode is writing everything as one undifferentiated blob. Decide which quadrant
a reader in that moment needs, and write for it — don't fold a tutorial's hand-holding into
the reference, or bury a how-to inside an explanation.

## How

1. **Coverage map**: for the scope, list the four quadrants and mark which are covered and
   which are gaps (this is the map `document-release` checks for drift).
2. **Fill the gaps** by quadrant, using the project's existing doc structure and tone.
3. Each doc states its quadrant's contract: a tutorial walks, a how-to solves, a reference
   enumerates, an explanation argues.

## Rules

- Docs match what actually shipped (`document-release` cross-checks the diff). A doc that
  describes a design the code no longer has is a defect, not an improvement.
- Reference is exhaustive, how-to is minimal, tutorial is sequential, explanation is
  rationale. Do not pad.
