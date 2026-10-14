#!/bin/sh
# Complete local verification for this documentation-and-shell repository.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

scripts/leak-gate.sh
scripts/check-namespacing.sh
scripts/check-file-names.sh
scripts/check-links.sh
scripts/check-rule-structure.sh
scripts/check-core-sync.sh
scripts/test-gates.sh
scripts/check-changelog-touched.sh "${1:---working-tree}"
scripts/check-version-bumped.sh "${1:---working-tree}"

echo "repository gate clean"
