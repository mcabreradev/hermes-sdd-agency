---
name: design-to-html
description: "Turn an approved design or description into clean, dependency-free HTML."
---
<!-- hermes-add-skill: concept adapted from gstack /design-html (garrytan/gstack, MIT). The gstack
     runtime (Pretext) is not portable here; this keeps the *standard*: approved design → self-contained
     HTML, text that reflows, no heavy deps. -->

# Design to HTML

Turn an approved design (mockup, layout, or a clear user description) into clean,
self-contained, production-quality **HTML/CSS** with zero or minimal runtime dependencies.

## What "good" means here

- **The text actually reflows** — layout adapts to content, heights are computed, nothing is
  a fixed-pixel box that breaks at a different font scale or width.
- **Zero/small deps** — the page carries its own CSS; no framework loaded for a static page
  unless the project already uses one.
- **Matches the design** — spacing, hierarchy, typography and color follow the approved
  mockup, not a reinterpretation.
- Correct semantics (headings, landmarks, labels) and keyboard/screen-reader usability come
  standard, not as an afterthought.

## Workflow

1. Confirm the design is approved and named; if it's a description without an approved
   shape, that's a design step, do the design first.
2. Build the page as self-contained HTML/CSS per the design.
3. Verify rendering (view it / measure) and that it reflows at a narrower width and a larger
   text scale.
4. Report the file and what was verified (per `rules/quality.md`).

## Rules

- No speculative framework or component library "just because". If it doesn't need a runtime,
   it doesn't get one.
- A design you don't fully understand is a question, not a guess — ask before building.
