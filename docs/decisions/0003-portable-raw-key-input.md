# ADR-0003: Raw-key input and rendering via portable Bash 3.2

- **Status:** accepted
- **Date:** 2026-09-18
- **OpenSpec change:** interactive-install-menu
- **Deciders:** architect agent

## Context

The installer targets macOS's stock Bash 3.2 (`install.sh:1`, `set -euo pipefail`
works there). A full-frame arrow-key menu needs per-key input and redraws.
Constraints: no Bash 4+ features such as `${x,,}` or associative arrays, no
GNU-only flags, and `tput` output varies across macOS terminfo databases.

## Decision

We implement the raw-key loop and rendering with portable Bash 3.2 primitives:
`stty -icanon min 1 -echo` together with `IFS= read -rsn1` for per-key reads,
hand-decoding ANSI escape sequences for arrows (CSI A/B/C/D), hardcoded ANSI
escapes (`\e[` sequences) for all rendering instead of `tput`, and a `trap` that
restores `stty sane` plus the cursor (`\e[?25h`) on exit. Case-insensitive search
uses `tr` for lowercase (no `${x,,}`).

## Alternatives considered

| Alternative | Why it was discarded |
|---|---|
| `tput` for cursor/color codes | Terminfo variance between macOS terminfo databases yields different escape output; hardcoded ANSI is deterministic |
| Bash 4+ features (assoc arrays, `${x,,}`) | Breaks on macOS's stock `/bin/bash` (3.2); installer must run unchanged on macOS |
| External input lib (node/readline, `dialog`) | Violates the no-new-dependency constraint; a ~40-line portable loop covers the need |
| `read -e` line editing | Line mode, not raw key mode; cannot deliver arrow-key navigation or toggles |

## Consequences

**Positive:**
- Runs on the same Bash 3.2 the script already requires; no terminfo or GNU-coreutils dependency.
- Full control of frame redraw (`\e[{N}A` + `\e[J`, cursor hide) and guaranteed terminal restore via `trap`.

**Negative / costs:**
- Hand-decoding ESC sequences is fiddly; must distinguish lone ESC (cancel) from `\e[` + letter sequences, and guard against partial reads with `min 1`.
- Redraw correctness depends on emitting one atomic `\e[{N}A\e[J+frame` per keypress to avoid flicker on unbuffered terminals.

## Reversibility

Cheap. The raw-input layer is self-contained; reverting to the prior
`printf` + `read` prompts removes it entirely, and the trap-based restore
guarantees a clean terminal either way.
