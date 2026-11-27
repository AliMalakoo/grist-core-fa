#!/usr/bin/env bash
# Produce a buildable grist-core with the Persian layer applied, in work/grist-core.
#   bin/checkout.sh              # upstream ref from UPSTREAM.lock
#   bin/checkout.sh v1.7.30      # any tag/branch/sha of upstream
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

REF="${1:-$UPSTREAM_SHA}"
ensure_clone "$WORK_DIR" "$REF"
say "upstream is at $(git -C "$WORK_DIR" rev-parse --short HEAD) ($(git -C "$WORK_DIR" describe --tags --always 2>/dev/null || true))"
MODE="${MODE:-clobber}" bin/apply-overlay.sh "$WORK_DIR"
say "checking every file matches the overlay"
verify_overlay "$WORK_DIR" strict
