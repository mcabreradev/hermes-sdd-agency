# installer-interactive-menu Specification

## Purpose
When `install.sh` runs interactively (stdin is a TTY), it presents a navigable, arrow-key driven installer menu modeled on `npx skills add` instead of bare `printf` lines — multi-select bundles with live search, a target-prefix step, an install summary and a final confirm, with all existing flags/behavior preserved as the non-interactive path.

## Requirements

### Requirement: Interactive menu activates only on a TTY and honors flags

The interactive menu is shown only when stdin is a TTY and the user has not already pinned the relevant choices with flags that make them unambiguous. Non-interactive runs use the existing defaults and never block on a prompt.

#### Scenario: Interactive menu on a TTY with default flags
- **WHEN** `install.sh` runs with stdin a TTY and no bundling/prefix flags that pin the choice
- **THEN** it shows the interactive menu (intro, bundle multi-select, prefix step, summary, confirm) and writes nothing to the target until the user confirms

#### Scenario: Non-interactive run does not hang
- **WHEN** `install.sh` runs with stdin not a TTY (e.g. piped `bash <(curl …)`) and no `--yes`
- **THEN** it uses the existing default prefix and bundle set, applies the overwrite guard non-interactively (aborting unless `--yes`), and never waits for keyboard input

#### Scenario: `--bundles`/`--no-bundles` are honored in the menu
- **WHEN** the interactive menu is active and the user filters/toggles bundles, or the run was invoked with `--bundles a,b,c` / `--no-bundles`
- **THEN** the final installed bundle set matches the toggled selection, and the menu pre-selects the flag-provided set

### Requirement: Bundle multi-select supports search, toggle and confirm

The interactive bundle step lets the user type to filter the list, press space to toggle, arrows to move, enter to confirm and esc to cancel, in the `npx skills add` style.

#### Scenario: Type-to-filter narrows the list
- **WHEN** the user types characters in the bundle selection step
- **THEN** the visible items are filtered (case-insensitive substring) to those whose label matches, and the filter is shown in the search line

#### Scenario: Space toggles a bundle, Enter confirms
- **WHEN** the user presses space on an item, then presses Enter
- **THEN** that item's selected state flips (unselected → selected), and after Enter the confirmed selection is passed to the install step

#### Scenario: Esc cancels the install
- **WHEN** the user presses Esc (or Ctrl+C) during the interactive flow
- **THEN** the script prints a cancellation notice and exits without writing anything to the target

### Requirement: Install summary and confirm precede any write

Before any files are merged/overwritten, the interactive flow shows a clack-style summary (target, bundle set, whether it overwrites an existing agency) and asks the user to confirm; the install only proceeds after an explicit Yes.

#### Scenario: Summary shown, No aborts
- **WHEN** the summary is shown and the user chooses No (or leaves default No) at the confirm step
- **THEN** the script aborts without modifying the target, with a clear message

#### Scenario: Existing agency gets an overwrite warning in the summary
- **WHEN** the target already contains an agency install (`$dest/agents` exists) and the run is interactive
- **THEN** the summary highlights the overwrite and requires an explicit Yes (never silently re-merges without interactively confirming, matching the current guard)

### Requirement: ANSI/rendering stays portable to macOS default bash

The menu uses only Bash 3.2-safe constructs: `stty` raw-key input, `read -s -n1`, ANSI escapes and Unicode glyphs, with no Bash 4+ associative arrays and no reliance on GNU-only flags.

#### Scenario: Renders on macOS default bash
- **WHEN** `install.sh` runs under `/bin/bash` (bash 3.2) on macOS with a TTY
- **THEN** the menu redraws, colors and glyphs render correctly and there are no syntax or portability errors (bash -n passes)
