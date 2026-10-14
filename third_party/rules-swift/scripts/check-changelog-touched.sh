#!/bin/sh
# Require CHANGELOG.md whenever the vendored rule baseline changes.
set -eu

ROOT=${RULES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
cd "$ROOT"

if [ "${1:-}" = "--working-tree" ]; then
    changed=$(
        {
            git diff HEAD --name-only
            git ls-files --others --exclude-standard
        } | sort -u
    )
elif [ "${1:-}" = "" ]; then
    changed=$(git diff --cached --name-only)
else
    changed=$(git diff --name-only "$1" HEAD)
fi

rules=$(printf '%s\n' "$changed" \
    | grep -E '(^|/)[^/]+\.md$|^core/|^exp/|^\.swiftformat$|^\.swiftlint\.yml$|^\.pre-commit-config\.yaml$|^rules-freshness\.yml$|^scripts/sync-rules\.sh$' \
    | grep -vxE 'CHANGELOG\.md|CONTRIBUTING\.md|README\.md' \
    || true)

if [ -z "$rules" ]; then
    echo "changelog gate: OK (no rule files changed)"
    exit 0
fi

if printf '%s\n' "$changed" | grep -qx 'CHANGELOG.md'; then
    echo "changelog gate: OK (rule changes documented)"
    exit 0
fi

echo "changelog gate: FAILED" >&2
echo "  These rule files changed without CHANGELOG.md:" >&2
printf '    %s\n' $rules >&2
exit 1
