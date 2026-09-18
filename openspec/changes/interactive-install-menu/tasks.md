## 1. Rendering + input helpers

- [ ] 1.1 Add ANSI/color helpers (`_dim`, `_cyan`, `_green`, `_y`, `_red`) and cursor show/hide, emitting raw escapes — verifies: `bash -n install.sh` passes, helpers referenced in the menu functions
- [ ] 1.2 Add raw-key reader: `stty -icanon min 1 -echo`, `IFS= read -rsn1` loop mapping arrows (`\e[A/B/C/D`), space/enter/esc/Ctrl+C, with `trap` restoring `stty sane` + `\e[?25h` — verifies: `install.sh --dry-run` on a TTY captures keys and restores the terminal
- [ ] 1.3 Add frame redraw: clear via `\e[{N}A` + `\e[J` and re-emit; hide cursor during draw, show after — verifies: `bash -n` passes

## 2. Bundle multi-select prompt

- [ ] 2.1 Implement the multi-select list: cyan `❯` cursor column, green `●`/dim `○` toggles, dim `│` rails, arrow navigation, space toggle, enter confirm, esc/ctrl-c cancel, zero-selection Enter is a no-op — verifies: `bash -n` passes; exercised in a TTY dry-run
- [ ] 2.2 Add live type-to-filter: typed chars append to query, filter items case-insensitively (via `tr`) on label substring, show query in a search line, backspace edits it — verifies: `bash -n` passes
- [ ] 2.3 Add "Select All" toggle row with partial state (`◐` when mixed) — verifies: `bash -n` passes

## 3. Target-prefix + summary + confirm steps

- [ ] 3.1 Replace the bare prefix `read` with a menu-styled prompt showing the default (`~/.hermes`) and letting the user accept it or type an override — verifies: `bash -n` passes; interactive dry-run skips when `-p` given
- [ ] 3.2 Render a clack-style install summary (target, bundle set, overwrite warning when an agency exists) and a `● Yes / ○ No` confirm; No aborts without writing — verifies: `bash -n` passes; interactive dry-run shows summary
- [ ] 3.3 Wire the interactive flow into the top-level guard: show the menu only when stdin is a TTY; keep the non-interactive path and all flags (`--bundles`, `--no-bundles`, `-p`, `--dry-run`, `-y`, `-h`) byte-for-byte, skip menu steps whose choice a flag already pinned — verifies: `install.sh --dry-run` (no TTY) prints the same non-interactive output as before

## 4. Docs

- [ ] 4.1 Update `INSTALL.md` to describe the interactive menu and confirm the flags still work — verifies: file mentions arrow/space/enter navigation and the unchanged flags
- [ ] 4.2 Update `README.md` "Install" section with a short note about the interactive flow — verifies: file mentions the interactive menu
