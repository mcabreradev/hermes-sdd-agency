# ADR-0005: Overwrite guard retains its strength inside the interactive flow

- **Status:** accepted
- **Date:** 2026-09-18
- **OpenSpec change:** interactive-install-menu
- **Deciders:** architect agent

## Context

`guard_dest` (`install.sh:165-197`) protects existing targets: a fresh target
installs cleanly, an existing agency gets a re-install warning, and a target with
unrelated data gets a stronger warning; non-interactive runs abort without
`--yes`. The new menu replaces the interactive prompts, so the guard's
interactive branch must be re-expressed without weakening it.

## Decision

The guard logic and its strengths stay exactly as today. In interactive mode the
warning is rendered inside the summary + confirm step rather than as a bare
`Continue? [y/N]` prompt, and confirming an overwrite of an existing agency
requires an explicit `Yes` (not a defaulted `Enter`).

## Alternatives considered

| Alternative | Why it was discarded |
|---|---|
| Weaken confirmation (default Yes, Enter confirms) | Silent-overwrite protection exists precisely to prevent accidental clobbering; must not regress |
| Keep the separate y/N prompt before the menu | Two-step friction and a different interaction style (type-a-char) inside a raw-key menu flow |
| Let the guard run post-menu with `--yes` semantics | Would bypass the explicit in-flow confirmation the user already saw in the summary |

## Consequences

**Positive:**
- Protection strength is preserved in both non-interactive (abort without `--yes`) and interactive (explicit Yes) paths.
- The user sees the warning in the same frame as what will be installed — context at the moment of decision.

**Negative / costs:**
- Interactive flow carries the overwrite state into the menu renderer, coupling guard classification (agency vs other data) to the summary step.

## Reversibility

Cheap. The guard's non-interactive branch is untouched; the interactive branch
can return to the old y/N prompt by deleting the in-summary rendering.
