#!/usr/bin/env bash
# Bring the Persian layer up to date with upstream:
#   bin/update.sh                    # move to upstream's newest version tag
#   bin/update.sh v1.7.30            # or to a given ref
#   UPSTREAM_URL=... bin/update.sh   # against a mirror
#
# Files upstream never touched are copied. Files both sides touched go through a three-way merge, so
# upstream's fixes survive next to ours. Anything that cannot be merged is reported, never
# swallowed. Finish by reviewing, then bin/rerecord.sh, to make this repo's overlay the new truth.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

BASE="${BASE:-$UPSTREAM_SHA}"
REF="${1:-}"
if [ -z "$REF" ]; then
  say "finding the newest upstream tag"
  REF="$(git ls-remote --tags --refs "$UPSTREAM_URL" | awk -F/ '{print $NF}' |
         grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)"
  [ -n "$REF" ] || REF="master"
fi

ensure_clone "$WORK_DIR" "$REF"
git -C "$WORK_DIR" fetch --quiet "$UPSTREAM_URL" "$BASE" 2>/dev/null || true
NEW="$(git -C "$WORK_DIR" rev-parse HEAD)"
BASE_RESOLVED="$(git -C "$WORK_DIR" rev-parse --verify -q "$BASE^{commit}" || true)"

# Which of the files we modified has upstream also modified since the base? Those need a merge.
OVERLAP=""
if [ -n "$BASE_RESOLVED" ]; then
  say "comparing $BASE_RESOLVED -> $NEW for our files"
  MOD_PATHS="$(list_of "$MODIFIED_LIST" | tr '\n' ' ')"
  CHANGED="$(git -C "$WORK_DIR" diff --name-only "$BASE_RESOLVED" "$NEW" -- $MOD_PATHS)"
  OVERLAP="$CHANGED"
else
  warn "base $BASE is not present in $UPSTREAM_URL; assuming upstream moved and merging"
  OVERLAP="$(list_of "$MODIFIED_LIST")"
fi

if [ -z "$OVERLAP" ]; then
  say "upstream did not touch any file we modify -- copying the overlay"
  MODE=clobber bin/apply-overlay.sh "$WORK_DIR"
  verify_overlay "$WORK_DIR" strict
else
  say "upstream also changed $(printf '%s\n' "$OVERLAP" | grep -c . ) of our files; merging:"
  printf '%s\n' "$OVERLAP" | sed 's/^/    /'
  MODE=merge bin/apply-overlay.sh "$WORK_DIR"
  say "checking every file"
  verify_overlay "$WORK_DIR" merge
fi

say "committing on branch $BRANCH"
git -C "$WORK_DIR" checkout -q -B "$BRANCH"
git -C "$WORK_DIR" add -A .
git -C "$WORK_DIR" -c user.name="${GIT_AUTHOR_NAME:-grist-fa}" -c user.email="${GIT_AUTHOR_EMAIL:-grist-fa@local}" \
  commit -q -m "Persian layer on top of $(git -C "$WORK_DIR" describe --tags --always "$REF" 2>/dev/null || git -C "$WORK_DIR" rev-parse --short "$NEW")" \
  || warn "nothing to commit"

echo
say "next steps"
echo "    cd $WORK_DIR && yarn install && yarn run build"
echo "    # then, once it looks right, adopt the merged files as this repo's new overlay:"
echo "    $REPO_ROOT/bin/rerecord.sh $WORK_DIR"
