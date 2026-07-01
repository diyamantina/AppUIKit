#!/bin/sh
# Full local gate. GitHub Actions are not assumed for this repo family.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

# The pinned corpus must be checked out, or the rules gate cannot verify anything.
if [ ! -e third_party/rules-swift/README.md ]; then
    echo "check-local-gate: rules-swift submodule not initialized; run: git submodule update --init --recursive" >&2
    exit 1
fi

# Hooks are a real part of the gate. A clone that skipped install must fail loud,
# not silently run with no commit-msg/attribution enforcement.
hooks_path=$(git config --get core.hooksPath || true)
if [ "$hooks_path" != ".githooks" ]; then
    echo "check-local-gate: git hooks not installed (core.hooksPath='$hooks_path'); run: scripts/install-hooks.sh" >&2
    exit 1
fi

scripts/check-rules-swift.sh
scripts/check-style.sh
swift build
swift test
