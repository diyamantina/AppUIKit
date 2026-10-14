#!/bin/sh
# Enforce the core/rules.md state -> apply -> prove spine for binding rule files.
set -eu

ROOT=${RULES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
fail=0
RESULT=$(mktemp "${TMPDIR:-/tmp}/rules-swift-structure.XXXXXX")
trap 'rm -f "$RESULT"' EXIT HUP INT TERM

find "$ROOT" -type f -name '*.md' \
    -not -path '*/.git/*' \
    -not -path '*/.build/*' \
    -not -path '*/.github/*' \
    -print | while IFS= read -r file; do
        relative=${file#"$ROOT"/}
        case "$relative" in
            README.md|CHANGELOG.md|CONTRIBUTING.md|conventions.md|core/README.md|exp/README.md)
                continue
                ;;
        esac

        if ! grep -qiE '^(#{1,4} (Acceptance check|Verification|.*checklist|How to self-audit|Mechanical enforcement|CI guard|CI enforcement|CI requirements|Audit)|Acceptance check:)' "$file"; then
            echo "$relative"
        fi
    done > "$RESULT"

missing=$(cat "$RESULT")
if [ -n "$missing" ]; then
    echo "RULE STRUCTURE FAIL (no acceptance or verification section):" >&2
    echo "$missing" >&2
    fail=1
fi

[ "$fail" = 0 ] || exit 1
echo "rule structure gate clean"
