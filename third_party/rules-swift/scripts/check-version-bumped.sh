#!/bin/sh
# VERSION-bump gate for the rules repo.
#
# If any rule-defining file changes, VERSION must change in the same commit, so
# repos that vendor these rules can tell they are stale by comparing their
# recorded VERSION against this one. VERSION is the single freshness marker; bump
# it every time you change a rule. See VERSION and formatting-and-linting.md.
#
# Runs on every commit (.githooks/pre-commit, over STAGED changes) and in CI
# (.github/workflows/leak-gate.yml, over the diff against a base ref passed as $1).
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
    changed=$(git diff --cached --name-only)          # local pre-commit: staged files
else
    changed=$(git diff --name-only "$1" HEAD)         # CI: base..HEAD
fi

# A "rules change" is what downstream repos adopt: enforced configs, rule docs,
# and the managed freshness/sync contract. The repo's other CI machinery,
# .githooks/, .github/, and bookkeeping files are not downstream artifacts.
rules=$(printf '%s\n' "$changed" \
    | grep -E '(^|/)[^/]+\.md$|^core/|^exp/|^\.swiftformat$|^\.swiftlint\.yml$|^\.pre-commit-config\.yaml$|^rules-freshness\.yml$|^scripts/sync-rules\.sh$' \
    | grep -vxE 'CHANGELOG\.md|CONTRIBUTING\.md|README\.md' \
    || true)

if [ -z "$rules" ]; then
    echo "version-bump gate: OK (no rule files changed)"
    exit 0
fi

if printf '%s\n' "$changed" | grep -qxE 'VERSION'; then
    echo "version-bump gate: OK (rules changed, VERSION -> $(cat VERSION))"
    exit 0
fi

echo "version-bump gate: FAILED" >&2
echo "  These rule files changed but VERSION ($(cat VERSION)) was not bumped:" >&2
printf '    %s\n' $rules >&2
echo "  Edit VERSION in this same change so vendoring repos detect the update." >&2
exit 1
