## Context

`install.sh` is a Bash 3.2 script (macOS-default-compatible) that merges the agency's process tree, skills and bundles into a Hermes home. Today its interactive path is plain `printf` + two bare `read` prompts. The task is to re-skin that interactive path to match the `npx skills add` interaction model (research: vercel-labs/skills `search-multiselect` prompt built on `@clack/prompts` + raw `readline`). Everything needed is reachable in portable Bash: `stty`, `read -s -n1`, ANSI escapes, Unicode glyphs.

## Goals / Non-Goals

**Goals:**
- Interactive TTY path becomes a navigable arrow-key menu: clack-style intro (`◆/◇/■` step icons, cyan `❯` cursor, green `●`/dim `○` toggles, dim `│` rails), bundle multi-select with live type-to-filter, a target-prefix step, an install summary and a final `● Yes / ○ No` confirm.
- Full-frame redraw via `\e[{N}A` + `\e[J`; hide/show cursor; raw-key input restored on exit via `trap`.
- Preserve all existing flags and non-interactive behavior exactly.

**Non-Goals:**
- Not replicating clack's exact note-box geometry, the 6-gray ASCII "SKILLS" wordmark, or wcwidth double-width row accounting for CJK (labels here are short ASCII).
- No new dependencies (no node, no clack); pure Bash 3.2.
- No remembered-selection persistence across runs.

## Decisions

1. **Menu shows only when stdin is a TTY AND the choice is not already pinned by flags.** If the user passed `--bundles`/`--no-bundles`, skip the bundle step (pre-select and continue to prefix/summary). If `-p` given, skip the prefix step. If `--dry-run`, still show the menu (dry-run writes nothing) but short-circuit before actual copy. This mirrors `npx skills add` skipping steps when flags pin the answer.
2. **The bundle multi-select defaults to all-12 selected** (matching today's default), so a plain interactive run confirms the same set as today while giving the user the option to prune.
3. **Raw-key loop uses `stty -icanon min 1 -echo` + `IFS= read -rsn1`**, reading the escape sequence for arrows (`\e[A` etc.). `Ctrl+C`/`Esc` → cancel. `Enter` with zero selections is a no-op (nothing selected → cannot confirm empty), mirroring `required: true`.
4. **Overwrite guard keeps its strength**: the guard logic stays; interactive mode renders the warning inside the summary + confirm, explicitly requiring Yes over an existing agency.
5. **Rendering helpers** (`_dim`, `_cyan`, `_green`, `_y`, etc.) emit hardcoded ANSI escapes rather than `tput`, to avoid terminfo variance on macOS; `trap` restores `stty sane` + `\e[?25h`.

## Risks / Trade-offs

- **TTY/frame edge cases** on very short terminals (menu taller than screen): mitigated by cap on visible window (searchable list collapses, detail pane dropped) — acceptable approximation, not a full clack re-implementation.
- **Redraw flicker** if the user's terminal doesn't buffer: mitigated by emitting one full `\e[{N}A\e[J+frame` atomically per keypress.
- **Bash 3.2 portability**: case-insensitive search needs `tr` lowercase (no `${x,,}`), kept local and dependency-free.
- Behavior divergence risk is the main trade-off: any new code path could regress the existing piped/`--yes` behavior → the implementation adds a test mode (`--dry-run`) and the QA gate re-runs the non-interactive paths unchanged.
