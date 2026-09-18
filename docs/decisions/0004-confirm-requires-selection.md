# ADR-0004: Confirm with zero selections is a no-op

- **Status:** accepted
- **Date:** 2026-09-18
- **OpenSpec change:** interactive-install-menu
- **Deciders:** architect agent

## Context

The bundle step is a multi-select whose default is all-12. A user can deselect
everything, then press Enter. Confirming an empty selection would either exit the
step with zero bundles (surprising, indistinguishable from `--no-bundles`) or
silently re-select everything (contradicts the user's explicit action).

## Decision

`Enter` with zero selections is a no-op: the step does not advance and no empty
selection can be confirmed. This mirrors `@clack/prompts` `required: true`.

## Alternatives considered

| Alternative | Why it was discarded |
|---|---|
| Confirm empty advances as "no bundles" | A stray full-clear then Enter silently equals `--no-bundles`; requires an extra explicit step to be safe |
| Confirm empty re-selects all | Ignores the user's explicit deselection; confusing |
| Confirm empty shows an error frame then stays | Same effect as a no-op with more code and an extra frame to render |

## Consequences

**Positive:**
- Impossible to install zero bundles by accident; the only paths to zero bundles are `--no-bundles` or an explicit, informed choice.
- Matches the reference interaction model (`required: true`), so muscle memory transfers.

**Negative / costs:**
- A user who genuinely wants zero bundles must cancel (Esc/Ctrl+C) and re-run with `--no-bundles` — an acceptable, explicit route.

## Reversibility

Cheap. One guard in the key handler; removing it restores confirm-any-state.
