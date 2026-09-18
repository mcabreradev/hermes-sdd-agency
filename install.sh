#!/usr/bin/env bash
#
# Hermes SDD Agency — single-command installer
#
# Installs the agency into a Hermes home (default: $HERMES_HOME or ~/.hermes),
# merging (not wiping) the process tree, the skills, and the skill bundles.
#
# Two ways to run it:
#
#   1. From a clone:
#        git clone https://github.com/mcabreradev/hermes-sdd-agency.git
#        cd hermes-sdd-agency
#        ./install.sh
#
#   2. Piped (self-clones to a temp dir, installs, cleans up):
#        bash <(curl -fsSL https://raw.githubusercontent.com/mcabreradev/hermes-sdd-agency/main/install.sh)
#
# When stdin is a TTY you get an arrow-key installer menu (npx skills
# add-style): pick bundles with space, type to filter, then confirm the
# summary with Yes. Piped/CI runs (stdin not a TTY) skip the menu entirely
# and use the exact current defaults — they never wait for keyboard input.
#
# Flags:
#   -p, --prefix DIR     Target Hermes home. Defaults to $HERMES_HOME, then
#                        ~/.hermes. In the interactive menu this step is
#                        skipped and the flag value is used directly.
#       --bundles a,b,c  Only install the named bundles (comma-separated).
#                        Default: all 12. Skips the bundle step in the menu.
#       --no-bundles     Install process tree + skills but skip bundles.
#                        Also skips the bundle step in the menu.
#       --dry-run        Print what would happen; write nothing. The menu is
#                        still shown when stdin is a TTY.
#   -y, --yes            Skip the overwrite confirmation (non-interactive
#                        installs that may touch an existing home).
#   -h, --help           Show this help.

set -euo pipefail

# --- repo constants -----------------------------------------------------------
REPO_URL="${HERMES_SDD_AGENCY_REPO:-https://github.com/mcabreradev/hermes-sdd-agency.git}"

PROCESS_DIRS=(agents workflows rules templates docs bin)
ALL_BUNDLES=(agency feature bugfix fix idea plan implement architecture review qa release init-project do continue)

# --- option parsing -----------------------------------------------------------
PREFIX=""
BUNDLES=("${ALL_BUNDLES[@]}")
DO_BUNDLES=1
DRY_RUN=0
ASSUME_YES=0
BUNDLES_PINNED=0

usage() {
  cat <<'HELP'
Hermes SDD Agency — single-command installer

Installs the agency into a Hermes home (default: $HERMES_HOME or ~/.hermes),
merging (not wiping) the process tree, the skills, and the skill bundles.

Two ways to run it:

  1. From a clone:
       git clone https://github.com/mcabreradev/hermes-sdd-agency.git
       cd hermes-sdd-agency
       ./install.sh

  2. Piped (self-clones to a temp dir, installs, cleans up):
       bash <(curl -fsSL https://raw.githubusercontent.com/mcabreradev/hermes-sdd-agency/main/install.sh)

Flags:
  -p, --prefix DIR     Target Hermes home. Defaults to $HERMES_HOME, then
                       ~/.hermes. In the interactive menu this step is
                       skipped and the flag value is used directly.
      --bundles a,b,c  Only install the named bundles (comma-separated).
                       Default: all 12. Skips the bundle step in the menu.
      --no-bundles     Install process tree + skills but skip bundles.
                       Also skips the bundle step in the menu.
      --dry-run        Print what would happen; write nothing. The menu is
                       still shown when stdin is a TTY.
  -y, --yes            Skip the overwrite confirmation (non-interactive
                       installs that may touch an existing home).
  -h, --help           Show this help.
HELP
}
err() { printf 'install: %s\n' "$*" >&2; }
die() { err "$*"; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--prefix) PREFIX="$2"; shift 2 ;;
    --prefix=*)  PREFIX="${1#*=}"; shift ;;
    --bundles)   BUNDLES_PINNED=1; IFS=',' read -r -a BUNDLES <<< "$2"; shift 2 ;;
    --bundles=*) BUNDLES_PINNED=1; IFS=',' read -r -a BUNDLES <<< "${1#*=}"; shift ;;
    --no-bundles) DO_BUNDLES=0; BUNDLES_PINNED=1; shift ;;
    --dry-run)    DRY_RUN=1; shift ;;
    -y|--yes)     ASSUME_YES=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) die "unknown argument: $1 (see --help)" ;;
  esac
done

# --- source resolution --------------------------------------------------------
# Local mode: the process/skills dirs sit right next to this script.
# Piped mode: we are not inside a clone, so self-clone into a temp dir.
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || echo "$PWD")"
local_mode=1
for d in "$script_dir/agents" "$script_dir/skill-bundles"; do
  [[ -d "$d" ]] || { local_mode=0; break; }
done

SRC_DIR="$script_dir"
TMP_DIR=""
cleanup() { [[ -z "$TMP_DIR" ]] || rm -rf "$TMP_DIR"; return 0; }
# _menu_fini additionally restores the terminal if the interactive menu was
# active, so a Ctrl+C never leaves echo/canonical mode off or the cursor hidden.
trap 'cleanup; _menu_fini' EXIT

# --- target resolution ----------------------------------------------------------
resolve_prefix() {
  local default="${HERMES_HOME:-$HOME/.hermes}"
  if [[ -n "$PREFIX" ]]; then
    printf '%s' "$PREFIX"
    return
  fi
  if [[ -t 0 ]]; then
    printf 'Install into [%s]: ' "$default" >&2
    IFS= read -r ans
    printf '%s' "${ans:-$default}"
  else
    printf '%s' "$default"
  fi
}

# --- interactive menu ---------------------------------------------------------
# Entirely behind a [[ -t 0 ]] gate (see the main flow below): piped/CI runs
# never execute a line here, so the non-interactive contract (default prefix,
# guard abort without --yes, exact install output) is untouched.
#
# Portable-Bash 3.2 constraints (ADR-0003/0006): hardcoded ANSI escapes only
# (no tput — terminfo varies across macOS), no ${x,,}, no associative arrays,
# no GNU-only flags. Case-insensitive filtering folds via `tr A-Z a-z`.
# Selection state is a bitmask (bit i+1 = item i selected), because Bash 3.2
# has no associative arrays and `declare -n` is unreliable there.
_MENU_G=$'\033[32m'    # green  — active step icon, selected toggle
_MENU_C=$'\033[36m'    # cyan   — cursor/highlight, accents
_MENU_D=$'\033[2m'     # dim    — rails, unselected toggle, hints
_MENU_Y=$'\033[33m'    # yellow — warnings
_MENU_R=$'\033[31m'    # red    — cancelled icon
_MENU_0=$'\033[0m'     # reset
_MENU_B=$'\033[46m'    # bg cyan (pill)
_MENU_K=$'\033[30m'    # black fg on the bg-cyan pill
_MENU_ACTIVE=0

_menu_init() { if (( ! _MENU_ACTIVE )); then _MENU_ACTIVE=1; trap '_menu_trap' INT; stty -icanon min 1 -echo 2>/dev/null || true; fi; }
_menu_fini() { if (( _MENU_ACTIVE )); then _MENU_ACTIVE=0; trap - INT; printf '\033[?25h' 2>/dev/null || true; stty sane 2>/dev/null || true; fi; }
# The INT trap is registered only while the menu owns the terminal (see
# _menu_init/_menu_fini), so a Ctrl+C during the actual install keeps the
# shell's default behavior and never prints a wrong "nothing was installed".
_menu_trap() { printf '\n%saborted by user (Ctrl+C) — nothing was installed%s\n' "$_MENU_R" "$_MENU_0" >&2; _menu_fini; exit 1; }

# Whole-frame redraw: cursor to screen top, clear down, re-emit every line of
# the current state. Fixed-height per phase, so `\e[99A` + `\e[J` always clears
# whatever the previous frame drew (ADR-0003's atomic redraw).
_menu_popcount() {
  local i n=0
  for (( i = 0; i < ${#MENU_ITEMS[@]}; i++ )); do
    if (( ( _MENU_SEL >> ( i + 1 ) ) & 1 )); then n=$(( n + 1 )); fi
  done
  MENU_N_SEL=$n
}
# Rebuild _VIS = original indices of rows that match the current filter.
_menu_vis() {
  local i folded
  _VIS=(); _VISN=0
  for i in "${!MENU_ITEMS[@]}"; do
    if [[ -n "$_MENU_QUERY" ]]; then
      folded="$(printf '%s' "${MENU_ITEMS[$i]}" | tr 'A-Z' 'a-z')"
      folded_query="$(printf '%s' "$_MENU_QUERY" | tr 'A-Z' 'a-z')"
      [[ "$folded" == *"$folded_query"* ]] || continue
    fi
    _VIS+=("$i"); _VISN=$(( _VISN + 1 ))
  done
}
# Position of _MENU_CUR inside _VIS (-1 when filtered out).
_menu_vispos() {
  local i
  for i in "${!_VIS[@]}"; do
    [[ "${_VIS[$i]}" == "$_MENU_CUR" ]] && { printf '%s' "$i"; return; }
  done
  printf '%s' "-1"
}
_menu_frame() {
  local i toggle curmark p
  printf '\033[?25l\033[99A\033[J'
  printf '%b%b Hermes SDD Agency %b %b◇%b %s\n' "$_MENU_B" "$_MENU_K" "$_MENU_0" "$_MENU_G" "$_MENU_0" "$MENU_TITLE"
  printf '\n'
  if [[ "$_MENU_PHASE" == "bundles" ]]; then
    _menu_vis
    printf '%b◆%b Select bundles to install (all %d by default)\n' "$_MENU_G" "$_MENU_0" "${#MENU_ITEMS[@]}"
    printf '%b%b│%b  %b●%b select (space)   %b↑↓%b move   %b⌫%b filter   %b↵%b confirm\n' \
      "$_MENU_D" "$_MENU_C" "$_MENU_0" "$_MENU_G" "$_MENU_0" "$_MENU_C" "$_MENU_0" "$_MENU_C" "$_MENU_0" "$_MENU_G" "$_MENU_0"
    _menu_popcount
    # Viewport: up to 9 rows + the Select All row; scroll follows the cursor.
    if [[ -n "$_MENU_QUERY" ]]; then
      p="$(_menu_vispos)"
      if (( p >= 0 )); then
        if (( p > _MENU_TOP + 8 )); then _MENU_TOP=$(( p - 8 )); fi
        if (( p < _MENU_TOP )); then _MENU_TOP=$p; fi
      fi
    else
      _MENU_TOP=0
    fi
    for (( j = _MENU_TOP; j < _VISN && j < _MENU_TOP + 9; j++ )); do
      i="${_VIS[$j]}"
      if [[ "$i" == "$_MENU_CUR" ]]; then curmark="${_MENU_C}❯"; else curmark="  "; fi
      if (( ( _MENU_SEL >> ( i + 1 ) ) & 1 )); then toggle="${_MENU_G}●"; else toggle="${_MENU_D}○"; fi
      printf '%b%b│%b %s %b%s%b %s\n' "$_MENU_D" "$_MENU_C" "$_MENU_0" "$curmark" "$toggle" "$_MENU_0" "${MENU_ITEMS[$i]}"
    done
    # Select All row with partial state (◐ when mixed). Cursor sentinel is
    # the literal "all", which never collides with a bundle name.
    if [[ "$_MENU_CUR" == "all" ]]; then curmark="${_MENU_C}❯"; else curmark="  "; fi
    if (( ( _MENU_SEL & _MENU_MASK ) == _MENU_MASK )); then toggle="${_MENU_G}●";
    elif (( ( _MENU_SEL & _MENU_MASK ) == 0 )); then toggle="${_MENU_D}○";
    else toggle="${_MENU_Y}◐"; fi
    printf '%b%b│%b %s %b%s%b Select All\n' "$_MENU_D" "$_MENU_C" "$_MENU_0" "$curmark" "$toggle" "$_MENU_0"
    if (( _VISN == 0 )); then
      printf '%b%b│%b  %sno matches%s\n' "$_MENU_D" "$_MENU_C" "$_MENU_0" "$_MENU_D" "$_MENU_0"
    fi
    printf '%b%b│%b  %b>%b %s\n' "$_MENU_D" "$_MENU_C" "$_MENU_0" "$_MENU_C" "$_MENU_0" "$_MENU_QUERY"
  else
    if (( BUNDLES_PINNED )); then
      if (( DO_BUNDLES )); then
        printf '%b◇%b Bundles: %b%s%b\n' "$_MENU_G" "$_MENU_0" "$_MENU_D" "${BUNDLES[*]:-}" "$_MENU_0"
      else
        printf '%b◇%b Bundles: none (%s)\n' "$_MENU_G" "$_MENU_0" "--no-bundles"
      fi
    else
      printf '%b◇%b %d bundles selected\n' "$_MENU_G" "$_MENU_0" "$MENU_N_SEL"
    fi
    printf '\n'
  fi
  if [[ -n "$MENU_DEST" ]]; then
    printf '%b◇%b Install location: %s\n' "$_MENU_G" "$_MENU_0" "$MENU_DEST"
  elif [[ "$_MENU_PHASE" == "prefix" ]]; then
    printf '%b◆%b Where to install?\n' "$_MENU_G" "$_MENU_0"
    printf '%b%b│%b  %b>%b %b%s%b\n' "$_MENU_D" "$_MENU_C" "$_MENU_0" "$_MENU_C" "$_MENU_0" \
      "$( [[ -n "$_MENU_TYPED" ]] && printf '%s' "$_MENU_TYPED" || printf '%s' "$MENU_DEFAULT" )" "$_MENU_D"
  fi
  if [[ "$_MENU_PHASE" == "confirm" ]]; then
    _menu_box "$MENU_DEST"
    printf '\n'
  fi
  if [[ "$_MENU_PHASE" == "confirm" ]] && (( ! MENU_DONE )); then
    printf '%b◆%b Install into %b%s%b?\n' "$_MENU_G" "$_MENU_0" "$_MENU_C" "$MENU_DEST" "$_MENU_0"
    if (( _MENU_CONF == 0 )); then
      printf '%b%b│%b  %b❯ %b●%b Yes%b    ○ No\n' "$_MENU_D" "$_MENU_C" "$_MENU_0" "$_MENU_C" "$_MENU_G" "$_MENU_0" "$_MENU_D"
    else
      printf '%b%b│%b     ● Yes%b   %b❯ %b○%b No\n' "$_MENU_D" "$_MENU_C" "$_MENU_0" "$_MENU_D" "$_MENU_C" "$_MENU_D" "$_MENU_0"
    fi
    printf '%b%b│%b  %b↑%b/%b←%b %bYes%b   %b↓%b/%b→%b %bNo%b   %by/n%b ↵ confirm   %b⌫%b cancel\n' \
      "$_MENU_D" "$_MENU_C" "$_MENU_0" "$_MENU_C" "$_MENU_0" "$_MENU_C" "$_MENU_0" "$_MENU_G" "$_MENU_0" "$_MENU_C" "$_MENU_0" "$_MENU_C" "$_MENU_0" "$_MENU_G" "$_MENU_0" "$_MENU_C" "$_MENU_0" "$_MENU_D" "$_MENU_0"
  elif (( MENU_DONE )); then
    printf '%b◇%b  Yes — installing\n' "$_MENU_G" "$_MENU_0"
  fi
  printf '\033[?25h'
}
# Clack-style summary box (approximate geometry, per ADR-0006 non-goal).
_menu_box() {
  local dest="$1"
  # Split locals: within one `local` statement, expansions run before any
  # binding, so ${#dest} would hit `set -u` (unbound) on first use.
  local w=$(( ${#dest} + 14 )) bar
  (( w < 40 )) && w=40
  bar="$(printf '─%.0s' $(seq 1 $(( w - 2 ))))"
  printf '%b%b┌%s┐%b\n' "$_MENU_B" "$_MENU_K" "$bar" "$_MENU_0"
  printf '%b%b│%b  %bHermes SDD Agency%b\n' "$_MENU_B" "$_MENU_K" "$_MENU_B" "$_MENU_G" "$_MENU_0"
  printf '%b%b│%b  target:   %b%s%b\n' "$_MENU_B" "$_MENU_K" "$_MENU_0" "$_MENU_C" "$dest" "$_MENU_0"
  if (( DO_BUNDLES && ! BUNDLES_PINNED )); then
    printf '%b%b│%b  bundles:  %b%d%b\n' "$_MENU_B" "$_MENU_K" "$_MENU_0" "$_MENU_0" "$MENU_N_SEL" "$_MENU_0"
  elif (( DO_BUNDLES )); then
    printf '%b%b│%b  bundles:  %b%s%b\n' "$_MENU_B" "$_MENU_K" "$_MENU_0" "$_MENU_0" "${BUNDLES[*]:-}" "$_MENU_0"
  else
    printf '%b%b│%b  bundles:  %bnone%b\n' "$_MENU_B" "$_MENU_K" "$_MENU_0" "$_MENU_0" "$_MENU_0"
  fi
  if [[ -d "$dest/agents" ]]; then
    printf '%b%b│%b  overwrite:%b existing agency — will merge/overwrite %b\n' "$_MENU_B" "$_MENU_K" "$_MENU_0" "$_MENU_Y" "$_MENU_0"
  elif [[ -n "$(ls -A "$dest" 2>/dev/null)" ]]; then
    printf '%b%b│%b  overwrite:%b existing home data — will merge on top %b\n' "$_MENU_B" "$_MENU_K" "$_MENU_0" "$_MENU_Y" "$_MENU_0"
  else
    printf '%b%b│%b  overwrite:%b fresh — safe to install %b\n' "$_MENU_B" "$_MENU_K" "$_MENU_0" "$_MENU_0" "$_MENU_0"
  fi
  printf '%b%b└%s┘%b\n' "$_MENU_B" "$_MENU_K" "$bar" "$_MENU_0"
}
# Read one key; the escape parser uses a 0.1s stty window (VMIN=0,VTIME=1) so a
# bare Esc cancels without hanging, while arrow sequences arrive atomically.
_menu_key() {
  local k2="" k3=""
  # -d '' makes read treat NUL as the delimiter: without it, bash 3.2 read
  # returns an EMPTY variable on CR/LF (its own line terminators), so Enter
  # would never advance the menu.
  if ! IFS= read -r -s -n 1 -d '' key; then key="eof"; return; fi
  case "$key" in
    $'\x1b')
      # bash 3.2 read ignores VMIN/VTIME without -t (it would block forever),
      # so the continuation reads carry their own integer -t 1 timeout: a real
      # arrow delivers "[" + letter immediately; a bare Esc times out on each
      # read and resolves to cancel instead of hanging the loop.
      IFS= read -r -s -n 1 -d '' -t 1 k2 || k2=""
      # Some terminals send arrow keys in SS3 form (\eOA/\eOB…) instead of
      # CSI (\e[A/\e[B…) — map both so arrow navigation works on any client.
      if [[ "$k2" == "O" ]]; then
        IFS= read -r -s -n 1 -d '' -t 1 k3 || k3=""
        case "$k3" in
          A) key="up" ;;
          B) key="down" ;;
          C) key="right" ;;
          D) key="left" ;;
          *) key="esc" ;;
        esac
        return
      fi
      [[ "$k2" == "[" ]] || { key="esc"; return; }
      IFS= read -r -s -n 1 -d '' -t 1 k3 || k3=""
      case "$k3" in
        A) key="up" ;;
        B) key="down" ;;
        C) key="right" ;;
        D) key="left" ;;
        *) key="esc" ;;
      esac
      ;;
    $' ') key="space" ;;
    $'\n'|$'\r') key="enter" ;;
    $'\x7f'|$'\b') key="backspace" ;;
    $'\x03') key="ctrl-c" ;;
  esac
}
# Interactive entry point (TTY-only, called from the main flow): walks the
# unpinned steps (bundles → prefix → confirm) and writes nothing until the
# summary confirm returns Yes (ADR-0001, ADR-0005).
menu_run() {
  local i p picked=()
  MENU_TITLE="Interactive install"
  MENU_DEFAULT="${HERMES_HOME:-$HOME/.hermes}"
  # Default No on the summary confirm: installing always needs an explicit
  # selection of Yes first (spec: leaving the default aborts, nothing writes;
  # ADR-0005: an overwrite must never ride a default Enter).
  _MENU_QUERY="" _MENU_TYPED="" _MENU_CUR=0 _MENU_TOP=0
  _MENU_CONF=1
  MENU_DEST="" MENU_DONE=0 MENU_N_SEL=0
  _MENU_PHASE="prefix"
  if (( ! BUNDLES_PINNED )); then
    _MENU_PHASE="bundles"
    MENU_ITEMS=("${BUNDLES[@]}")
    _MENU_SEL=0 _MENU_MASK=0
    for (( i = 0; i < ${#MENU_ITEMS[@]}; i++ )); do
      _MENU_SEL=$(( _MENU_SEL | ( 1 << ( i + 1 ) ) ))
      _MENU_MASK=$(( _MENU_MASK | ( 1 << ( i + 1 ) ) ))
    done
    _menu_popcount
  fi
  # -p pins the prefix step but never the bundle step (ADR-0001): only when
  # bundles are also pinned do we start straight at the confirm.
  if [[ -n "$PREFIX" ]] && (( BUNDLES_PINNED )); then
    MENU_DEST="$PREFIX"
    _MENU_PHASE="confirm"
  fi
  _menu_init
  _menu_frame
  while :; do
    _menu_key
    case "$key" in
      up)
        if [[ "$_MENU_PHASE" == "bundles" ]]; then
          _menu_vis
          if [[ "$_MENU_CUR" == "all" ]]; then
            if (( _VISN > 0 )); then _MENU_CUR="${_VIS[$(( _VISN - 1 ))]}"; fi
          else
            p="$(_menu_vispos)"
            if (( p > 0 )); then _MENU_CUR="${_VIS[$(( p - 1 ))]}"; fi
          fi
        elif [[ "$_MENU_PHASE" == "confirm" ]]; then
          _MENU_CONF=0   # up = Yes
        fi
        ;;
      down)
        if [[ "$_MENU_PHASE" == "bundles" ]]; then
          _menu_vis
          if [[ "$_MENU_CUR" == "all" ]]; then
            if (( _VISN > 0 )); then _MENU_CUR="${_VIS[0]}"; fi
          else
            p="$(_menu_vispos)"
            if (( p == -1 )); then
              if (( _VISN > 0 )); then _MENU_CUR="${_VIS[0]}"; fi
            elif (( p == _VISN - 1 )); then
              _MENU_CUR="all"
            else
              _MENU_CUR="${_VIS[$(( p + 1 ))]}"
            fi
          fi
        elif [[ "$_MENU_PHASE" == "confirm" ]]; then
          _MENU_CONF=1   # down = No
        fi
        ;;
      left)
        if [[ "$_MENU_PHASE" == "confirm" ]]; then
          _MENU_CONF=0   # left = Yes (horizontal layout)
        fi
        ;;
      right)
        if [[ "$_MENU_PHASE" == "confirm" ]]; then
          _MENU_CONF=1   # right = No (horizontal layout)
        fi
        ;;
      space)
        if [[ "$_MENU_PHASE" == "bundles" ]]; then
          if [[ "$_MENU_CUR" == "all" ]]; then
            if (( ( _MENU_SEL & _MENU_MASK ) == _MENU_MASK )); then
              _MENU_SEL=$(( _MENU_SEL & ~_MENU_MASK ))
            else
              _MENU_SEL=$(( _MENU_SEL | _MENU_MASK ))
            fi
          else
            _MENU_SEL=$(( _MENU_SEL ^ ( 1 << ( _MENU_CUR + 1 ) ) ))
          fi
        elif [[ "$_MENU_PHASE" == "confirm" ]]; then
          _MENU_CONF=$(( 1 - _MENU_CONF ))
        elif [[ "$_MENU_PHASE" == "prefix" ]]; then
          # In the prefix field space is a literal character to type,
          # not a toggle (the menu is not in the bundle phase).
          _MENU_TYPED="$_MENU_TYPED "
        fi
        ;;
      backspace)
        [[ -n "$_MENU_QUERY" ]] && _MENU_QUERY="${_MENU_QUERY%?}"
        [[ -n "$_MENU_TYPED" ]] && _MENU_TYPED="${_MENU_TYPED%?}"
        ;;
      enter)
        if [[ "$_MENU_PHASE" == "bundles" ]]; then
          _menu_popcount
          (( MENU_N_SEL > 0 )) || { key=""; _menu_frame; continue; }   # ADR-0004: empty confirm never advances; reset key so a held/repeat Enter needs a fresh keypress
          _MENU_PHASE="prefix"
          if [[ -n "$PREFIX" ]]; then
            # -p pins the prefix answer; skip that step and confirm directly.
            MENU_DEST="$PREFIX"
            _MENU_PHASE="confirm"
          fi
        elif [[ "$_MENU_PHASE" == "prefix" ]]; then
          MENU_DEST="${_MENU_TYPED:-$MENU_DEFAULT}"
          _MENU_PHASE="confirm"
        elif [[ "$_MENU_PHASE" == "confirm" ]]; then
          if (( _MENU_CONF == 0 )); then
            MENU_DONE=1
            _menu_frame
            break
          else
            _menu_fini
            printf '\n%saborted by user — nothing was installed%s\n' "$_MENU_R" "$_MENU_0" >&2
            exit 1
          fi
        fi
        ;;
      esc|ctrl-c|eof)
        _menu_fini
        printf '\n%saborted by user — nothing was installed%s\n' "$_MENU_R" "$_MENU_0" >&2
        exit 1
        ;;
      *)
        if [[ "$_MENU_PHASE" == "confirm" ]]; then
          # Direct y/n keys toggle the confirm without relying on arrow-key
          # encoding (SS3 vs CSI varies across terminals).
          if [[ "$key" == "y" || "$key" == "Y" ]]; then _MENU_CONF=0;
          elif [[ "$key" == "n" || "$key" == "N" ]]; then _MENU_CONF=1; fi
          continue
        fi
        [[ "$key" =~ ^[[:print:]]$ ]] || continue
        if [[ "$_MENU_PHASE" == "bundles" ]]; then
          [[ "$key" == " " ]] || _MENU_QUERY="$_MENU_QUERY$key"
          _menu_vis
          # When the filter hides the cursor row, land on the first match so
          # the frame always shows a highlighted row.
          if (( _VISN > 0 )); then
            p="$(_menu_vispos)"
            if (( p == -1 )); then _MENU_CUR="${_VIS[0]}"; fi
          fi
        elif [[ "$_MENU_PHASE" == "prefix" ]]; then
          _MENU_TYPED="$_MENU_TYPED$key"
        fi
        ;;
    esac
    _menu_frame
  done
  # Commit: reduce BUNDLES to the confirmed selection (mask → names).
  if (( ! BUNDLES_PINNED )); then
    for (( i = 0; i < ${#MENU_ITEMS[@]}; i++ )); do
      if (( ( _MENU_SEL >> ( i + 1 ) ) & 1 )); then picked+=("${MENU_ITEMS[$i]}"); fi
    done
    # `:-` guards the empty case: on bash 3.2 `${arr[@]}` unexpands fatally
    # under `set -u`, while `${arr[@]:-}` expands to nothing.
    BUNDLES=("${picked[@]:-}")
    [[ -n "${BUNDLES[*]:-}" ]] || BUNDLES=("${ALL_BUNDLES[@]}")
  fi
  HERMES_HOME="$MENU_DEST"
  export HERMES_HOME
  _menu_fini
  printf '\n'
}

install_from() {
  local src="$1"
  printf 'Installing Hermes SDD Agency into: %s\n' "$HERMES_HOME"

  if (( DRY_RUN )); then
    printf '  would copy: %s\n' "${PROCESS_DIRS[*]} skills -> $HERMES_HOME/"
    if (( DO_BUNDLES )); then
      printf '  would copy bundles: %s -> $HERMES_HOME/skill-bundles/\n' "${BUNDLES[*]}"
    fi
    return
  fi

  # 1. Process tree + skills (merge, like cp -R). Source paths are prefixed
  #    with $src so the script works from any cwd (piped mode installs from a
  #    temp clone).
  mkdir -p "$HERMES_HOME"
  local src_dirs=()
  for d in "${PROCESS_DIRS[@]}"; do src_dirs+=("$src/$d"); done
  cp -R "${src_dirs[@]}" "$src/skills" "$HERMES_HOME/"
  printf '  copied process tree + skills into %s/\n' "$HERMES_HOME"

  # 2. Bundles: copy the selected .yaml into $HERMES_HOME/skill-bundles/. The
  #    presence of a bundle .yaml there is what registers it (hermes bundles
  #    reads the dir); no hermes skills install step needed.
  if (( DO_BUNDLES )); then
    mkdir -p "$HERMES_HOME/skill-bundles"
    for b in "${BUNDLES[@]}"; do
      local yaml="$src/skill-bundles/$b.yaml"
      if [[ -f "$yaml" ]]; then
        cp "$yaml" "$HERMES_HOME/skill-bundles/"
        printf '  registered bundle /%s\n' "$b"
      else
        err "bundle not found in repo: $b (skipped)"
      fi
    done
  fi
}

# --- overwrite guard ----------------------------------------------------------
# Protects the user from silently overwriting an existing home: a fresh,
# empty target installs cleanly; an existing agency gets a re-install warning;
# a target with other data gets a stronger warning. In non-interactive runs
# the guard aborts unless --yes is passed.
guard_dest() {
  local dest="$1"
  (( ! DRY_RUN )) || return 0                      # dry-run writes nothing
  [[ -e "$dest" ]] && [[ -n "$(ls -A "$dest" 2>/dev/null)" ]] || return 0  # empty/fresh

  if [[ -d "$dest/agents" ]]; then
    if (( ASSUME_YES )); then
      printf 'Updating existing agency in %s (--yes).\n' "$dest"
    elif [[ -t 0 ]]; then
      printf 'An Hermes SDD Agency install already exists in %s.\n' "$dest"
      printf 'This will merge/overwrite its process tree, skills and bundles.\n'
      printf 'Continue? [y/N] ' >&2
      IFS= read -r ans
      [[ "${ans,,}" =~ ^(y|yes)$ ]] || { err "aborted by user"; exit 1; }
    else
      die "target '$dest' already has an agency and stdin is not a TTY (no '--yes'); aborting to avoid an accidental overwrite"
    fi
  else
    # Target exists, has content, but no agency marker: could be a real,
    # unrelated Hermes home (configs, other skills). Warn strongly.
    if (( ASSUME_YES )); then
      printf 'Installing over existing (non-agency) data in %s (--yes).\n' "$dest"
    elif [[ -t 0 ]]; then
      printf 'WARNING: %s already exists and has other data, but no agency.\n' "$dest"
      printf 'The install will copy the process tree and skills on top of it.\n'
      printf 'Continue? [y/N] ' >&2
      IFS= read -r ans
      [[ "${ans,,}" =~ ^(y|yes)$ ]] || { err "aborted by user"; exit 1; }
    else
      die "target '$dest' exists with other data and stdin is not a TTY (no '--yes'); aborting to avoid an accidental overwrite"
    fi
  fi
}

# --- preflight ---------------------------------------------------------------
command -v hermes >/dev/null 2>&1 || die "required: 'hermes' is not on PATH (install Hermes Agent first)"

# --- resolve and prepare source ---------------------------------------------
if [[ -t 0 ]]; then
  # Interactive path: the arrow-key menu walks bundles → prefix → summary →
  # confirm, and writes nothing until an explicit Yes. guard_dest is skipped
  # here because the menu's summary renders the same classification (existing
  # agency vs other data vs fresh) inside the confirm frame and requires that
  # explicit Yes — the guard's interactive branch, in-menu (ADR-0005).
  menu_run
else
  # Non-interactive path: byte-for-byte the original flow. stdin is not a TTY
  # (piped curl, CI, --yes), so resolve_prefix uses the default and guard_dest
  # aborts unless --yes — exactly as before the menu existed.
  HERMES_HOME="$(resolve_prefix)"
  export HERMES_HOME
  guard_dest "$HERMES_HOME"
fi
if (( local_mode )); then
  install_from "$SRC_DIR"
else
  TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hermes-sdd-agency.XXXXXX")"
  if (( DRY_RUN )); then
    printf '  would clone %s into a temp dir and install from there\n' "$REPO_URL"
  else
    printf 'Cloning agency source (piped mode)…\n'
    git clone --depth 1 "$REPO_URL" "$TMP_DIR/src"
    install_from "$TMP_DIR/src"
  fi
fi

# --- post-install checks ------------------------------------------------------
if (( DO_BUNDLES && ! DRY_RUN )); then
  printf '\nInstalled slash commands:\n'
  hermes bundles list 2>/dev/null | grep -E 'agency|feature|bugfix|fix|idea|plan|implement|architecture|review|qa|release|init-project|do|continue' || true
fi

# Warn (never install) when the /feature bundle is present but its discovery
# skills are not — so a /feature user knows what to run, without this installer
# reaching into third-party plugin/skill installers (npx, hermes plugins).
warn_feature_deps() {
  local need=()
  [[ -d "$HERMES_HOME/skills/grilling" ]]         || need+=(grilling)
  [[ -d "$HERMES_HOME/skills/grill-with-docs" ]] || need+=(grill-with-docs)
  [[ -d "$HERMES_HOME/skills/domain-modeling" ]] || need+=(domain-modeling)
  ((${#need[@]})) || return 0
  printf '\nnote: /feature loads discovery skills missing from this home:\n'
  printf '  %s\n' "${need[*]}"
  printf '  install them once (see INSTALL.md):\n'
  printf '    hermes plugins install obra/superpowers --enable\n'
  printf '    npx skills@latest add mattpocock/skills\n'
}
feature_selected=0
for b in "${BUNDLES[@]}"; do [[ "$b" == "feature" ]] && feature_selected=1; done
if (( DO_BUNDLES && feature_selected && ! DRY_RUN )); then
  warn_feature_deps
fi

command -v openspec >/dev/null 2>&1 \
  || err "note: 'openspec' CLI not found (>= 1.13.0) — required to run the /agency loop. See INSTALL.md."

printf '\nRestart your Hermes session, then run /agency (or /feature, /bugfix, /fix) in a project.\n'
