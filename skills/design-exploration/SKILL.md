---
name: design-exploration
description: "Generate multiple design variants, compare, and collect structured feedback."
---
<!-- hermes-add-skill: concept adapted from gstack /design-shotgun (garrytan/gstack, MIT). -->

# Design exploration

Explore a UI problem by generating several distinct design variants, putting them side by
side, and collecting structured feedback to iterate. Use when a feature has a visual shape
the user hasn't seen yet and a single design would be a guess.

## How

1. **Brief** — state the page/feature, the users, and the one thing the design must
   communicate first (the hierarchy goal). No brief, no variants.
2. **Generate N variants (3-5)** that differ in a *meaningful* structural way — layout,
   hierarchy, or visual language — not just color swap. Different angles on the problem.
3. **Compare** — put them in a visible comparison (grid / separate views with the same
   scale reference).
4. **Collect structured feedback** — per variant, on the same axes: does the primary action
   land first? Is the content scannable? Does the tone match the product? Not "I like A".
5. **Iterate** — combine the strongest elements or go a level deeper on the favorite, then
   re-present. Stop when a variant satisfies the brief, not at a fixed count.

## Rules

- Variants must be **comparable** (same content, same browser scale) or the comparison is
  meaningless.
- Feedback is captured as observations about the brief's hierarchy goal, never as a mood vote.
- If the user asked for one design, don't shotgun — that's a different task. Only invoke
  when options are actually wanted.
