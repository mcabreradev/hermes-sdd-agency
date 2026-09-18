---
name: visual-design-review
description: "Visual QA of a live UI: catch slop, fix with before/after evidence."
---
<!-- hermes-add-skill: concept adapted from gstack /design-review (garrytan/gstack, MIT). -->

# Visual design review

A designer's-eye QA pass on a **live UI**: find visual inconsistencies, spacing and
hierarchy problems, AI-slop patterns, and slow interactions — then fix them, with
before/after evidence. For reviewing a *plan's* design decisions (before code), use the
plan-mode review instead; this one is on a real rendered surface.

## What it looks for

- **Consistency**: the same component/pattern rendered differently across screens; spacing
  and radii that drift; fonts/weights that break hierarchy.
- **Hierarchy**: does the eye land on what matters, in the right order? Flat or noisy — the
  primary action competes with the decorative.
- **AI-slop patterns**: the generic tells — centered everything with no reason, purple-ish
  gradients as a default, icon-every-line filler, lorem-ish placeholder copy, oversized
  hero text with no real promise beneath it.
- **Slow interactions**: anything that isn't instant-feeling; jank on scroll, no transition,
  layout shift, missing feedback on press.

## Evidence / fix loop

- Capture **before** (path/screenshot), state the defect + `path:line`/element, fix it,
  capture **after**. A visual claim needs both; a defect with no evidence and no fix target
  goes back.
- Severity per `rules/quality.md` (a broken primary flow = MAJOR, a stray radius = NIT).
- A fix commits atomically (one defect → one commit), re-verifying after each.
- A claim "colors look off" must name the page, the element, and the specific tension —
  not a vibe.

## Scope

Visual review is about the rendered surface. If a "visual" issue is actually a structural
or data one (wrong thing shown, broken logic), hand it to the normal code review — don't
patch symptoms in CSS.
