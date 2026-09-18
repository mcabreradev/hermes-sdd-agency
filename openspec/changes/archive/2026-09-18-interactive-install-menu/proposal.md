## Why

`install.sh` today installs the agency with plain, line-by-line `printf` and two bare `read` prompts (target prefix, and a plain `Continue? [y/N]` overwrite guard). It is functionally correct but its UX is dated: a user who runs `bash <(curl …)` lands in a terminal that asks one `printf` question and prints raw progress lines. Modern installer CLIs (notably `npx skills add`) present an interactive, navigable menu — arrow keys, space-to-toggle multi-select, live search, clack-style step icons — that makes the install feel professional and gives the user control over what gets installed. Replicating that interaction model makes the agency's first contact (its installer) match the polish of the system it installs.

## What Changes

- The interactive path of `install.sh` becomes a navigable, arrow-key driven menu modeled on `npx skills add`: a clack-style intro, a multi-select of bundles to install (with live type-to-filter search, space toggle, enter confirm, esc cancel), the target-prefix prompt, and a summary + confirm step before anything is copied.
- The existing flags (`-p/--prefix`, `--bundles`, `--no-bundles`, `--dry-run`, `-y/--yes`, `-h/--help`) keep working and stay the non-interactive path; the menu only appears when stdin is a TTY and the user doesn't supply overrides that make the choice already determined.
- Non-interactive runs remain silent-safe: no TTY → fall back to defaults exactly as today, never hang on a prompt.
- The overwrite guard keeps its protection but acquires the same menu style when interactive.

## Capabilities

### New Capabilities

- `installer.interactive-menu`: the interactive, arrow-key/multi-select installer experience, incl. search, toggling, summary, confirm, cancel, and TTY-detection fallback.

### Modified Capabilities

(none — no existing spec capability targets the installer UX)

## Impact

- **Code:** `install.sh` grows a menu/rendering section (raw-key reading, redraw, ANSI). No new runtime dependency — pure Bash 3.2 with `stty`, `read -s`, ANSI escapes (portable to macOS default bash).
- **Behavior preserved:** all existing flags, defaults, guard logic and piped-mode flow remain; only the interactive path is re-skinned and the prefix prompt becomes a menu-driven selection.
- **Docs:** `INSTALL.md` and the README's "Install" section updated to describe the new interactive flow and confirm the flags still work.
- **No data, no API, no schema** outside the script itself.
