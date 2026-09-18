---
name: diagram-triplet
description: "Turn a description/mermaid source into excalidraw + SVG/PNG, fully offline."
---
<!-- hermes-add-skill: concept adapted from gstack /diagram (garrytan/gstack, MIT). -->

# Diagram triplet

Turn an English description (or existing mermaid source) into a **triplet** of artifacts:
the editable source, a hand-drawn-style editable `.excalidraw` file, and rendered SVG/PNG
for embedding. Fully offline — no cloud diagram service.

## Outputs

- **Source**: mermaid (or the text description) as the canonical, re-editable form.
- **`.excalidraw`**: opens on excalidraw.com or the local Excalidraw app, hand-drawn
  aesthetic, editable.
- **SVG + PNG**: cleanly rendered for docs, specs, presentations.

## How (host-agnostic approach)

- Produce/keep the mermaid source first — it is the durable form.
- For the rendered SVG/PNG, use the project's available renderer (e.g. mermaid-cli
  installed in the project, or the agent's diagram/drawing tooling) to export. If the
  renderer is unavailable in the environment, report the source + `.excalidraw` (or a draft
  render) and note the missing step as a `blocked` gap — never fabricate a rendered image the
  renderer didn't produce.

## Rules

- The diagram must match the actual system/flow it documents — a pretty but wrong diagram is
  worse than none. Cross-check against code/real behavior.
- Diagram drift is a real defect: when architecture changes, the architecture diagram changes
  too or the old one is flagged as stale (`document-release`).
