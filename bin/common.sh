#!/usr/bin/env bash
# Shared helpers for the scripts in bin/.
#
# The idea of this repository: grist-core stays upstream, and this repo holds only the files that
# make it Persian -- the whole Jalali calendar, RTL, and the fa catalogue. Everything here is a
# *merge*, not a replacement: when upstream touches one of the files we also touched, its change is
# kept next to ours instead of being silently thrown away.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERLAY_DIR="$REPO_ROOT/overlay"
PATCH_FILE="$REPO_ROOT/patch/fa-modified.patch"
FILES_LIST="$REPO_ROOT/patch/files.txt"
ADDED_LIST="$REPO_ROOT/patch/added-files.txt"
MODIFIED_LIST="$REPO_ROOT/patch/modified-files.txt"
LOCK_FILE="$REPO_ROOT/UPSTREAM.lock"

# The lock file records where this overlay came from. An environment variable wins over it, so the
# scripts can be pointed at a mirror or a different work tree without editing anything.
_ENV_UPSTREAM_URL="${UPSTREAM_URL:-}"
_ENV_WORK_DIR="${WORK_DIR:-}"
# shellcheck disable=SC1090
. "$LOCK_FILE"
[ -n "$_ENV_UPSTREAM_URL" ] && UPSTREAM_URL="$_ENV_UPSTREAM_URL"
[ -n "$_ENV_WORK_DIR" ] && WORK_DIR="$_ENV_WORK_DIR"

WORK_DIR="${WORK_DIR:-$REPO_ROOT/work/grist-core}"
BRANCH="${BRANCH:-fa}"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
note() { printf '    %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

list_of() { tr -d '\r' < "$1" | grep -v '^[[:space:]]*$' || true; }

# Clone upstream (shallow-ish) at $1 into $2. Reuses an existing clone when it is still there, so
# repeated runs are cheap.
ensure_clone() {
  local dest="$1" ref="$2"
  if [ -d "$dest/.git" ]; then
    say "updating existing clone at $dest"
    # --tags: a tag name is a perfectly good thing to ask for, and fetch-by-sha or a
    # shallow-pruned clone would otherwise leave it unresolvable right after a successful fetch.
    git -C "$dest" fetch --quiet --tags --force "$UPSTREAM_URL" "$ref" 2>/dev/null \
      || git -C "$dest" fetch --quiet --tags --force "$UPSTREAM_URL"
  else
    mkdir -p "$(dirname "$dest")"
    say "cloning $UPSTREAM_URL at $ref"
    git clone --quiet --no-checkout "$UPSTREAM_URL" "$dest"
  fi
  # Resolve before checking out. Otherwise a ref the clone does not have dies as
  #   fatal: git checkout: --detach does not take a path argument 'v1.7.22'
  # which reads like a git bug and points nowhere useful.
  if ! git -C "$dest" rev-parse --verify -q "${ref}^{commit}" >/dev/null 2>&1; then
    die "'$ref' is not a commit in $UPSTREAM_URL. Pass a tag, branch or sha that exists there
    (\`git ls-remote --tags $UPSTREAM_URL | tail -5\` shows the recent ones), or leave the
    argument empty to use UPSTREAM.lock."
  fi
  git -C "$dest" checkout --quiet --detach "$ref"
  git -C "$dest" reset --quiet --hard "$ref"
  # NOTE: this wipes untracked files in the tree -- including a node_modules you may have
  # installed there. Run yarn install only after checkout/update, or point WORK_DIR elsewhere.
  git -C "$dest" clean -ffd
}

# Every overlay file must end up byte-identical to what this repo carries, except for the files
# where upstream has moved and the merge legitimately combined both sides.
verify_overlay() {
  local tree="$1" mode="${2:-strict}"
  local failed=0 drifted=0 f
  for f in $(list_of "$FILES_LIST"); do
    if [ ! -f "$tree/$f" ]; then
      printf 'MISSING      %s\n' "$f"; failed=$((failed + 1)); continue
    fi
    if cmp -s "$OVERLAY_DIR/$f" "$tree/$f"; then
      printf 'ok           %s\n' "$f"
    elif [ "$mode" = "merge" ]; then
      printf 'merged       %s  (differs from overlay: upstream changed it too)\n' "$f"
      drifted=$((drifted + 1))
    else
      printf 'DIFFERS      %s\n' "$f"; failed=$((failed + 1))
    fi
  done
  if [ "$failed" -gt 0 ] && [ "$mode" != "merge" ]; then
    die "$failed file(s) did not match the overlay. Re-record them (see README, «چطور این بسته را به‌روز نگه دارم»)."
  fi
  return 0
}
