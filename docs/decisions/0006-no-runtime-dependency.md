# ADR-0006: No new runtime dependency — parity with the portable Bash stack

- **Status:** accepted
- **Date:** 2026-09-18
- **OpenSpec change:** interactive-install-menu
- **Deciders:** architect agent

## Context

The reference interaction model (`npx skills add`, built on `@clack/prompts` +
raw `readline`) runs on Node. The installer's contract is a single self-contained
Bash 3.2 script that runs from a clone or piped via curl (`install.sh:10-16`),
with no install step of its own. The change re-skins the interactive path only.

## Decision

We keep the installer dependency-free: pure Bash 3.2, no node, no clack, no
wcwidth table. The goal is parity with the project's existing portable bash
stack — a faithful re-skin in Bash, not a clack port. Non-goals are recorded
accordingly: no clack note-box geometry, no `SKILLS` wordmark, no CJK
double-width row accounting (labels are short ASCII).

## Alternatives considered

| Alternative | Why it was discarded |
|---|---|
| Shell out to `npx @clack/prompts` / node script | Adds a runtime dependency, network fetch, and version drift to an installer whose selling point is one portable command |
| Dependency on `dialog`/`whiptail` | Not present by default on macOS; same portability objection |
| Python/tkinter or other interpreters | macOS ships Python 3 but relying on its presence/version narrows the target matrix for no benefit |
| Embed a wcwidth table for alignment | Real (CJK) width accounting is overkill for short ASCII labels; explicitly a non-goal |

## Consequences

**Positive:**
- Installer keeps running with only what Bash 3.2 and macOS coreutils already provide; piped installs stay as fast and dependency-free as today.
- The full-frame look is achieved with stty + `read` + ANSI escapes — the same primitives ADR-0003 relies on.

**Negative / costs:**
- Visual fidelity is an approximation of clack, not a copy: rendering differences are visible to users who know the reference.
- Future richer interactions (multi-width glyphs, real pane layout) would require revisiting this decision.

## Reversibility

Cheap to moderate. All interaction is inside the menu layer; swapping it for a
node-based prompt would change only that layer, but would introduce the
dependency this ADR deliberately rejects until then.
