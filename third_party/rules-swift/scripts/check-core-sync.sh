#!/bin/sh
# Require core/ to match the engineering-discipline source byte-for-byte.
set -eu

ROOT=${RULES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
TARGET=${CORE_TARGET_DIR:-$ROOT/core}
SOURCE=${CORE_SOURCE_DIR:-}
TMP=$(mktemp -d "${TMPDIR:-/tmp}/rules-swift-core-sync.XXXXXX")
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

if [ -z "$SOURCE" ]; then
    sibling=$(cd "$ROOT/.." 2>/dev/null && pwd)/rules-engineering-discipline
    if [ -d "$sibling/.git" ]; then
        SOURCE=$sibling
    else
        command -v git >/dev/null 2>&1 || {
            echo "core sync gate: git is required to fetch the upstream source" >&2
            exit 1
        }
        git clone -q --depth 1 \
            https://codeberg.org/Mihaela/rules-engineering-discipline.git \
            "$TMP/source"
        SOURCE=$TMP/source
    fi
fi

[ -d "$SOURCE" ] || { echo "core sync gate: source not found: $SOURCE" >&2; exit 1; }
[ -d "$TARGET" ] || { echo "core sync gate: target not found: $TARGET" >&2; exit 1; }

source_manifest=$TMP/source-files
target_manifest=$TMP/target-files
: > "$source_manifest"
: > "$target_manifest"

for file in "$SOURCE"/*.md "$SOURCE"/LICENSE; do
    [ -f "$file" ] || continue
    name=${file##*/}
    case "$name" in CHANGELOG.md|CONTRIBUTING.md) continue ;; esac
    echo "$name" >> "$source_manifest"
done
for file in "$TARGET"/*.md "$TARGET"/LICENSE; do
    [ -f "$file" ] || continue
    echo "${file##*/}" >> "$target_manifest"
done
sort -o "$source_manifest" "$source_manifest"
sort -o "$target_manifest" "$target_manifest"

if ! diff -u "$source_manifest" "$target_manifest"; then
    echo "CORE SYNC FAIL (vendored file set differs from upstream)" >&2
    exit 1
fi

fail=0
while IFS= read -r name; do
    if ! cmp -s "$SOURCE/$name" "$TARGET/$name"; then
        echo "CORE SYNC FAIL: $name differs" >&2
        fail=1
    fi
done < "$source_manifest"

[ "$fail" = 0 ] || exit 1
count=$(wc -l < "$source_manifest" | tr -d ' ')
echo "core sync gate clean ($count vendored files)"
