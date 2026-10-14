#!/bin/sh
# Align a consumer repo to the shared-rules freshness marker: stamp .rules-version
# and install the freshness workflow. Baseline configs are SEEDED only if the repo
# has none; existing configs are repo-specific (baseline + project rules) and are
# never overwritten.
#
# Usage: scripts/sync-rules.sh <consumer-repo-path> [workflow-dir]
# The workflow dir is auto-detected from the repo's origin remote:
#   codeberg.org (Forgejo) -> .forgejo/workflows   |   Gitea (default) -> .gitea/workflows
# Pass an explicit second arg to override.
set -eu

RULES=$(cd "$(dirname "$0")/.." && pwd)
TARGET="${1:?usage: sync-rules.sh <consumer-repo-path> [workflow-dir]}"
[ -d "$TARGET/.git" ] || { echo "not a git repo: $TARGET" >&2; exit 1; }

VER=$(tr -d '[:space:]' < "$RULES/VERSION")

WFDIR="${2:-}"
if [ -z "$WFDIR" ]; then
    remote=$(git -C "$TARGET" remote get-url origin 2>/dev/null || echo "")
    case "$remote" in
        *codeberg.org*) WFDIR=".forgejo/workflows" ;;   # Forgejo reads .forgejo
        *)              WFDIR=".gitea/workflows"   ;;    # Gitea reads .gitea
    esac
fi

for f in .swiftformat .swiftlint.yml; do
    if [ -f "$TARGET/$f" ]; then
        echo "  kept existing $f (repo-specific)"
    else
        cp "$RULES/$f" "$TARGET/$f"
        echo "  seeded $f from baseline (was absent)"
    fi
done
printf '%s\n' "$VER" > "$TARGET/.rules-version"
mkdir -p "$TARGET/$WFDIR"
legacy="$TARGET/$WFDIR/rules-conformance.yml"
if [ -f "$legacy" ] && grep -q '^# Managed by rules-swift' "$legacy"; then
    rm -f "$legacy"
    echo "  removed legacy $WFDIR/rules-conformance.yml (it proved freshness only)"
fi
cp "$RULES/rules-freshness.yml" "$TARGET/$WFDIR/rules-freshness.yml"
echo "  stamped .rules-version=$VER, installed $WFDIR/rules-freshness.yml"
echo "done: $TARGET now tracks shared-rules freshness marker v$VER"
