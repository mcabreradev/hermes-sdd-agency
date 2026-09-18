# ADR-0001: Interactive menu shows only on a TTY with unpinned choices

- **Status:** accepted
- **Date:** 2026-09-18
- **OpenSpec change:** interactive-install-menu
- **Deciders:** architect agent

## Context

`install.sh` serves two audiences: piped installs (`bash <(curl …)`, CI, `-y`)
that must never block on input, and interactive runs that currently use two bare
`printf` + `read` prompts (`install.sh:113-119`, `:173-192`). Adding a full-screen
menu must not change what non-interactive runs do: the non-interactive path is a
tested, documented contract (README, INSTALL.md) and stays byte-for-byte as today.

## Decision

We show the interactive menu only when stdin is a TTY **and** the choice is not
already pinned by a flag: `--bundles`/`--no-bundles` skip the bundle step,
`-p` skips the prefix step. `--dry-run` still shows the menu (it writes nothing)
but short-circuits before any copy. Every other combination follows today's
non-interactive flow unchanged.

## Alternatives considered

| Alternative | Why it was discarded |
|---|---|
| Always show the menu, flags pre-fill answers | Breaks piped/`--yes` runs that must not read stdin; changes current non-interactive behavior |
| Show the menu whenever stdin is a TTY, ignoring flags | Redundant steps: a user who passed `--bundles` would be asked to re-pick bundles |
| Separate `--interactive` opt-in flag | Adds a flag nobody asked for and diverges from the `npx skills add` model being mirrored |

## Consequences

**Positive:**
- Non-interactive contract is untouched; the QA gate can re-run piped/`--yes` paths unchanged.
- Menu appears exactly when a human is present and has an unpinned choice — matches the clack behavior it re-skins.

**Negative / costs:**
- Flag+TTY interplay is a small matrix to keep in sync as flags evolve; a future flag that pins a choice must also be wired into the gate.

## Reversibility

Cheap. The gate is a single guard before the menu renderer; reverting to the two
bare `read` prompts restores the old interactive path without touching flag
parsing or the non-interactive flow.
