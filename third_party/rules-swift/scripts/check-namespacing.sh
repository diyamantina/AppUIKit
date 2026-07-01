#!/bin/sh
# Namespacing gate: one non-private top-level type per file.
# Enforces the "One non-private type per file (mandatory)" rule in code-style.md.
# Runs on every commit (.githooks/pre-commit) and in CI (.github/workflows/leak-gate.yml).
# A file declaring more than one public/package/internal top-level type is a violation;
# mark helper types private/fileprivate so they drop out, or split the file.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCAN="$ROOT/Packages/Sources"
[ -d "$SCAN" ] || SCAN="$ROOT"

violations=$(
    find "$SCAN" -name '*.swift' -not -path '*/.build/*' -not -path '*/.git/*' -print | while IFS= read -r f; do
        count=$(grep -cE '^(public |package |internal )?(actor|struct|enum|protocol|class|final class) [A-Z]' "$f" || true)
        if [ "$count" -gt 1 ]; then
            printf '%s %s\n' "$count" "$f"
        fi
    done
)

if [ -n "$violations" ]; then
    echo "NAMESPACING FAIL (more than one non-private top-level type per file):" >&2
    echo "$violations" >&2
    echo "Fix: split the file, or mark helper types private/fileprivate so they drop out of the count." >&2
    exit 1
fi

echo "namespacing clean ($(find "$SCAN" -name '*.swift' -not -path '*/.build/*' | wc -l | tr -d ' ') swift files)"
