#!/usr/bin/env bash
# Check a grist-core tree against this repo's overlay, file by file.
#   bin/verify.sh [tree] [strict|merge]
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
verify_overlay "${1:-$WORK_DIR}" "${2:-strict}"
