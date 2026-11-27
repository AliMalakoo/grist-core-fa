#!/usr/bin/env bash
# After a merge -- or any deliberate change to the Persian layer -- refresh this repo so its overlay
# and fa-modified.patch describe the result:
#
#   bin/update.sh                              # merged tree in work/grist-core
#   bin/rerecord.sh work/grist-core            # adopt it here
#   bin/rerecord.sh work/grist-core BASE=v1.7.30   # diff against that upstream ref instead
#
# Copy the new overlay/* and patch/* into this repo's main branch when you commit them.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

TREE="${1:-$WORK_DIR}"
[ -d "$TREE/.git" ] || die "$TREE is not a git checkout"

say "recording $(list_of "$FILES_LIST" | wc -l | tr -d ' ') files from $TREE"
for f in $(list_of "$FILES_LIST"); do
  [ -f "$TREE/$f" ] || die "$f is missing from $TREE -- remove it from patch/files.txt if it was deleted on purpose"
  mkdir -p "$OVERLAY_DIR/$(dirname "$f")"
  cp "$TREE/$f" "$OVERLAY_DIR/$f"
done

# The patch is what lets a future update merge instead of clobber, so it has to be cut against the
# upstream commit the tree is based on. Our own commit on top is skipped when there is one.
BASE="${BASE:-}"
if [ -z "$BASE" ]; then
  BASE="$(git -C "$TREE" rev-parse --verify -q "$UPSTREAM_SHA^{commit}" 2>/dev/null || true)"
fi
if [ -z "$BASE" ]; then
  BASE="$(git -C "$TREE" rev-parse --verify -q "$BRANCH^" 2>/dev/null || git -C "$TREE" rev-parse HEAD)"
  warn "could not find the recorded base; cutting the patch against $BASE"
fi

say "regenerating fa-modified.patch against $(git -C "$TREE" rev-parse --short "$BASE")"
git -C "$TREE" diff --binary --no-color "$BASE" -- $(list_of "$MODIFIED_LIST" | tr '\n' ' ') > "$PATCH_FILE.tmp"
if [ -s "$PATCH_FILE.tmp" ]; then
  mv "$PATCH_FILE.tmp" "$PATCH_FILE"
else
  rm -f "$PATCH_FILE.tmp"
  die "empty patch: the tree matches $BASE, so nothing was applied there. Run apply-overlay.sh first."
fi

# Remember the base, so the next update starts from the same place this patch was cut against.
sed -i.bak "s/^UPSTREAM_SHA=.*/UPSTREAM_SHA=$(git -C "$TREE" rev-parse "$BASE")/" "$LOCK_FILE" && rm -f "$LOCK_FILE.bak"
say "done"
echo
echo "Check it round-trips, then commit:"
echo "    $REPO_ROOT/bin/checkout.sh && $REPO_ROOT/bin/verify.sh"
echo "    git add -A && git commit -m 'Persian layer rebased on $(git -C "$TREE" rev-parse --short "$BASE")'"
