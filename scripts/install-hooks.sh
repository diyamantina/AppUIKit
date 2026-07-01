#!/bin/sh
# Install and verify tracked git hooks for this clone.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

git config core.hooksPath .githooks

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
# Plant a message the commit-msg hook MUST reject: an em dash (U+2014), which every
# commit-msg variant in this repo family rejects under github-discipline Rule 5.2.
printf 'test\n\nbad em dash \342\200\224 here\n' > "$tmp"

if .githooks/commit-msg "$tmp" >/dev/null 2>&1; then
    echo "install-hooks: commit-msg hook did not reject the planted style violation." >&2
    exit 1
fi

echo "hooks installed: $(git config --get core.hooksPath)"
