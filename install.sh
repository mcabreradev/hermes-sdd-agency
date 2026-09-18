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
# Flags:
#   -p, --prefix DIR     Target Hermes home. Defaults to $HERMES_HOME, then
#                        ~/.hermes. If no flag is passed and stdin is a TTY, an
#                        interactive prompt lets you confirm/override it.
#       --bundles a,b,c  Only install the named bundles (comma-separated).
#                        Default: all 12.
#       --no-bundles     Install process tree + skills but skip bundles.
#       --dry-run        Print what would happen; write nothing.
#   -y, --yes            Skip the overwrite confirmation (non-interactive
#                        installs that may touch an existing home).
#   -h, --help           Show this help.

set -euo pipefail

# --- repo constants -----------------------------------------------------------
REPO_URL="${HERMES_SDD_AGENCY_REPO:-https://github.com/mcabreradev/hermes-sdd-agency.git}"

PROCESS_DIRS=(agents workflows rules templates docs)
ALL_BUNDLES=(agency feature bugfix fix idea plan implement architecture review qa release init-project)

# --- option parsing -----------------------------------------------------------
PREFIX=""
BUNDLES=("${ALL_BUNDLES[@]}")
DO_BUNDLES=1
DRY_RUN=0
ASSUME_YES=0

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
                       ~/.hermes. If no flag is passed and stdin is a TTY, an
                       interactive prompt lets you confirm/override it.
      --bundles a,b,c  Only install the named bundles (comma-separated).
                       Default: all 12.
      --no-bundles     Install process tree + skills but skip bundles.
      --dry-run        Print what would happen; write nothing.
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
    --bundles)   IFS=',' read -r -a BUNDLES <<< "$2"; shift 2 ;;
    --bundles=*) IFS=',' read -r -a BUNDLES <<< "${1#*=}"; shift ;;
    --no-bundles) DO_BUNDLES=0; shift ;;
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
trap cleanup EXIT

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
HERMES_HOME="$(resolve_prefix)"
export HERMES_HOME
guard_dest "$HERMES_HOME"
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
  hermes bundles list 2>/dev/null | grep -E 'agency|feature|bugfix|fix|idea|plan|implement|architecture|review|qa|release|init-project' || true
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
