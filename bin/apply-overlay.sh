#!/usr/bin/env bash
# Apply this repo's Persian layer onto a grist-core checkout.
#
#   MODE=merge   (default) upstream's own edits to the same files are kept next to ours, via a
#                three-way merge. Conflicts are reported, never swallowed.
#   MODE=clobber our copy of every file wins outright. Only the files in patch/files.txt change.
#
# Usage: bin/apply-overlay.sh [path-to-grist-core]
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

TREE="${1:-$WORK_DIR}"
MODE="${MODE:-merge}"
[ -d "$TREE/.git" ] || die "$TREE is not a git checkout; run bin/checkout.sh first"
cd "$TREE"

if [ -n "$(git status --porcelain)" ]; then
  die "$TREE has uncommitted changes; commit or discard them first"
fi

if [ "$MODE" = "clobber" ]; then
  say "copying $(list_of "$FILES_LIST" | wc -l | tr -d ' ') overlay files (clobber)"
  for f in $(list_of "$FILES_LIST"); do
    mkdir -p "$(dirname "$f")"
    cp "$OVERLAY_DIR/$f" "$f"
  done
else
  say "adding $(list_of "$ADDED_LIST" | wc -l | tr -d ' ') new files"
  for f in $(list_of "$ADDED_LIST"); do
    mkdir -p "$(dirname "$f")"
    cp "$OVERLAY_DIR/$f" "$f"
  done

  say "merging patch/fa-modified.patch (three-way)"
  if ! git apply --3way "$PATCH_FILE"; then
    echo
    warn "the patch did not apply cleanly; these files are left with conflict markers:"
    git ls-files -u | awk '{print $4}' | sort -u | sed 's/^/    /'
    echo
    echo "Resolve them in $TREE, then run:  bin/verify.sh $TREE"
    echo "If you would rather keep our version untouched:  MODE=clobber bin/apply-overlay.sh $TREE"
    exit 2
  fi
fi

say "staged result"
git add -A .
git status --short | sed 's/^/    /'
exit 0
