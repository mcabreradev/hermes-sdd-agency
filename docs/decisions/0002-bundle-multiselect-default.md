# ADR-0002: Bundle multi-select defaults to all 12 selected

- **Status:** accepted
- **Date:** 2026-09-18
- **OpenSpec change:** interactive-install-menu
- **Deciders:** architect agent

## Context

Today the default install copies all 12 bundles: `BUNDLES=("${ALL_BUNDLES[@]}")`
(`install.sh:40`) unless `--bundles`/`--no-bundles` is passed. The new interactive
bundle step is a multi-select; its initial state determines what a plain
interactive run installs.

## Decision

The bundle multi-select starts with all 12 bundles selected, matching today's
default, so a plain interactive run confirms exactly the same set as today while
letting the user prune before confirming.

## Alternatives considered

| Alternative | Why it was discarded |
|---|---|
| Start with zero selected, require explicit pick | Changes the install set of a plain run (empty bundles) and pushes the all-12 default onto an extra keystroke |
| Start with a "recommended" subset | Invents a new default that diverges from the documented all-12 behavior (README line 67) |
| Remember last run's selection | Explicit non-goal: no selection persistence across runs |

## Consequences

**Positive:**
- Plain interactive runs and plain non-interactive runs install identical sets; no surprise divergence.
- Pruning is a strictly-decreasing operation, so wrong moves are low-cost (re-toggle).

**Negative / costs:**
- Users wanting a small set must deselect 11 items or fall back to `--bundles`; acceptable for a bounded change.

## Reversibility

Cheap. The default is one array initialization in the menu state; changing it
later does not touch flag parsing or the copy engine.
