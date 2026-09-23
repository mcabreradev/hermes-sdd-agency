# Design — docs sync after phase 3

## Context

Today's phase 3 (8 merged PRs) added two new evidence bins (`run-trace`,
`change-collision`), two new fixture suites, and changed the skill count (5 mirrored
skills) and the spec count (13). The public surfaces — `index.html` (the GitHub Pages
homepage), `README.md`, `INSTALL.md` and `docs/evidence-bins.md` — still describe the
phase-2 state: 5 bins, 60 skills, 92 pinned test cases, 26 merged PRs, a 5-section
evidence doc, and a homepage that lists `pr-review` *before* `release`.

## Goals / Non-Goals

**Goals:**
- Sync every stale number on the three public surfaces and the evidence doc: bins 5→7,
  skills 60→65, test cases 92→108, PR count, spec count, skill-registry tree size.
- Add the two new bins to `docs/evidence-bins.md` (title, chain, two sections).
- Fix the homepage's loop ordering (release before pr-review).

**Non-Goals:**
- Rewriting the README or homepage structure, redesigning the web, touching skills or
  rules, or adding the remaining ChatGPT backlog (message types, permissions matrix).

## Decisions

### Decision: numbers come from the machine, not from memory

Every number is verified with a command before being written. Measured today:
7 bins, 7 fixture suites, 13 specs, 65 skills, 23 personas + 42 process = 65,
108 pinned cases (16+7+11+27+9+13+25), 39 merged PRs, 185 skills inventoried on the
live tree, 0 defects.

### Decision: the homepage and README keep their current structure

The pages are well-formed; a stale count or a wrong order is a defect, not a reason
to redesign. Minimal targeted edits: badges, stat numbers, the two new bins, the
evidence doc sections, and the loop reorder in the HTML diagram.

### Decision: `docs/evidence-bins.md` gains the two sections

The doc currently documents 5 bins (title says "five"); the chain has 7. Add
sections 6 (`run-trace`) and 7 (`change-collision`) with the same voice — one-liner,
when it runs, its output — and update the title and the "chain in a real run" list.

## Risks / Trade-offs

- **Risk:** the doc drift keeps recurring (new bins land without docs). **Accepted:**
  it is what the fixture suites are for in the code; the docs are synced by
  convention. Not expanding scope to enforce.
- **Risk:** numbers differ from what a reviewer sees if the tree changes between now
  and review. All changes to this repo go through this same loop, so a merge that
  changes bin/skill counts lands after this PR and re-syncs in a future docs pass.
- **Trade-off accepted:** the homepage keeps its one-file no-build setup; a static
  generator is a future change, not part of this sync.

## Delivery strategy

~200 authored lines of prose + HTML; under the advisory ~400; `single-pr`.
