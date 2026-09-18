## 1. Rendering + input helpers

- [x] 1.1 Add ANSI/color helpers (`_dim`, `_cyan`, `_green`, `_y`, `_red`) and cursor show/hide, emitting raw escapes — verifies: `bash -n install.sh` passes, helpers referenced in the menu functions
- [x] 1.2 Add raw-key reader: `stty -icanon min 1 -echo`, `IFS= read -rsn1` loop mapping arrows (`\e[A/B/C/D`), space/enter/esc/Ctrl+C, with `trap` restoring `stty sane` + `\e[?25h` — verifies: `install.sh --dry-run` on a TTY captures keys and restores the terminal
- [x] 1.3 Add frame redraw: clear via `\e[{N}A` + `\e[J` and re-emit; hide cursor during draw, show after — verifies: `bash -n` passes

## 2. Bundle multi-select prompt

- [x] 2.1 Implement the multi-select list: cyan `❯` cursor column, green `●`/dim `○` toggles, dim `│` rails, arrow navigation, space toggle, enter confirm, esc/ctrl-c cancel, zero-selection Enter is a no-op — verifies: `bash -n` passes; exercised in a TTY dry-run
- [x] 2.2 Add live type-to-filter: typed chars append to query, filter items case-insensitively (via `tr`) on label substring, show query in a search line, backspace edits it — verifies: `bash -n` passes
- [x] 2.3 Add "Select All" toggle row with partial state (`◐` when mixed) — verifies: `bash -n` passes

## 3. Target-prefix + summary + confirm steps

- [x] 3.1 Replace the bare prefix `read` with a menu-styled prompt showing the default (`~/.hermes`) and letting the user accept it or type an override — verifies: `bash -n` passes; interactive dry-run skips when `-p` given
- [x] 3.2 Render a clack-style install summary (target, bundle set, overwrite warning when an agency exists) and a `● Yes / ○ No` confirm; No aborts without writing — verifies: `bash -n` passes; interactive dry-run shows summary
- [x] 3.3 Wire the interactive flow into the top-level guard: show the menu only when stdin is a TTY; keep the non-interactive path and all flags (`--bundles`, `--no-bundles`, `-p`, `--dry-run`, `-y`, `-h`) byte-for-byte, skip menu steps whose choice a flag already pinned — verifies: `install.sh --dry-run` (no TTY) prints the same non-interactive output as before

## 4. Docs

- [x] 4.1 Update `INSTALL.md` to describe the interactive menu and confirm the flags still work — verifies: file mentions arrow/space/enter navigation and the unchanged flags
- [x] 4.2 Update `README.md` "Install" section with a short note about the interactive flow — verifies: file mentions the interactive menu
