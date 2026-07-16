#!/bin/sh
# Install and verify tracked git hooks for this clone.
set -eu

# Resolve TMPDIR to the mounted external volume with the most free space, per the
# fleet-wide Scratch & Build Storage Policy; fall back to internal with a warning
# if none is mounted. Respects a TMPDIR the caller already exported.
if [ -z "${TMPDIR:-}" ]; then
    ext_dir=""
    ext_free=0
    for vol in /Volumes/*/; do
        [ -d "$vol" ] || continue
        name=$(basename "$vol")
        [ "$name" = "Macintosh HD" ] && continue
        free=$(df -k "$vol" 2>/dev/null | awk 'NR==2{print $4}')
        case "$free" in ''|*[!0-9]*) continue ;; esac
        if [ "$free" -gt "$ext_free" ]; then
            ext_dir=$vol
            ext_free=$free
        fi
    done
    if [ -n "$ext_dir" ]; then
        TMPDIR="${ext_dir}scratch/tmp"
    else
        echo "warning: no external volume mounted, scratch temp files will use the internal drive" >&2
        TMPDIR="/tmp"
    fi
    mkdir -p "$TMPDIR"
    export TMPDIR
fi

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
