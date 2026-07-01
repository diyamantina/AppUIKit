#!/bin/sh
# Mechanical rules-swift gate for AppUIKit.
# Tailored to this repo: a standalone SwiftPM package (root Sources/ and Tests/)
# with a single library target and its matching test target. Only the rules that
# apply here are enforced; rules that do not apply (a validation layer, a Metal
# parity backend, the ExtremePackaging closure-manifest pattern) are
# intentionally omitted.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

fail=0

fail_check() {
    echo "RULE FAIL: $1" >&2
    fail=1
}

run_check() {
    if ! "$@"; then
        fail=1
    fi
}

require_file() {
    [ -f "$1" ] || fail_check "missing required file: $1"
}

require_dir() {
    [ -d "$1" ] || fail_check "missing required directory: $1"
}

require_executable() {
    [ -x "$1" ] || fail_check "missing executable bit: $1"
}

empty_output() {
    label=$1
    output=$2
    if [ -n "$output" ]; then
        echo "RULE FAIL ($label):" >&2
        echo "$output" >&2
        fail=1
    fi
}

# --- Required repository files (only files that genuinely apply here) ---
require_file AGENTS.md
require_file Package.swift
require_file README.md
require_file .swiftformat
require_file .swiftlint.yml
require_file docs/rules-swift-audit.md
require_file docs/rules-swift-corpus.sha256
require_file third_party/rules-swift/README.md
require_file Sources/AppUIKit/AppUIKit.swift
require_file Sources/AppUIKit/AppUICursor.swift
require_file Sources/AppUIKit/AppUITopLeftView.swift
require_dir Sources
require_dir Tests
require_dir scripts
require_dir .githooks
require_dir third_party/rules-swift

require_executable scripts/check-local-gate.sh
require_executable scripts/check-rules-corpus-coverage.sh
require_executable scripts/check-rules-swift.sh
require_executable scripts/check-namespacing.sh
require_executable scripts/check-style.sh
require_executable scripts/install-hooks.sh
require_executable .githooks/commit-msg
require_executable .githooks/pre-commit

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    hooks_path=$(git config --get core.hooksPath || true)
    [ "$hooks_path" = ".githooks" ] || fail_check "core.hooksPath must be .githooks; run scripts/install-hooks.sh"
fi

# --- Sub-gates that this repo carries ---
run_check scripts/leak-gate.sh
run_check scripts/check-rules-corpus-coverage.sh
run_check scripts/check-namespacing.sh

# --- Audit must carry no unresolved blocker rows ---
audit_blockers=$(
    awk -F '|' '
        /^\|/ {
            for (i = 1; i <= NF; i++) {
                gsub(/^[ \t]+|[ \t]+$/, "", $i)
            }
            if ($3 == "Gap" || $3 == "Partial" || $4 == "Gap" || $4 == "Partial") {
                print $0
            }
        }
    ' docs/rules-swift-audit.md
)
empty_output "rules-swift audit blockers" "$audit_blockers"

# --- package-architecture.md: every source target has a matching test target ---
source_targets=$(
    grep -A2 -E '\.(executableTarget|target)\(' Package.swift \
        | sed -n 's/.*name: "\([^"]*\)".*/\1/p' \
        | sort -u
)
test_targets=$(
    grep -A2 -E '\.testTarget\(' Package.swift \
        | sed -n 's/.*name: "\([^"]*\)".*/\1/p' \
        | sort -u
)
for target in $source_targets; do
    case "$target" in
        *Tests) continue ;;
    esac
    if ! printf '%s\n' "$test_targets" | grep -qx "${target}Tests"; then
        fail_check "source target ${target} has no matching test target ${target}Tests"
    fi
done

# --- concurrency.md and no-shortcuts-first-principles.md: anti-patterns in our code only ---
empty_output "Swift concurrency escape hatches" "$(grep -rnE '@unchecked Sendable|nonisolated\(unsafe\)' Sources/ Tests/ || true)"
empty_output "threading and test-wait anti-patterns" "$(grep -rnE 'DispatchQueue\.main\.async|NSLock|pthread_mutex|XCTestExpectation' Sources/ Tests/ || true)"
empty_output "shortcut patterns" "$(grep -rnE 'try\?|catch \{\}|sleep\(|XCTSkip|swiftlint:disable' Sources/ Tests/ || true)"

# --- framework-policy.md: no non-Apple UI or cross-platform stack names in our sources/docs ---
# Terms are octal-encoded so this script does not itself trip the gate. Case-sensitive
# whole-word, and the vendored corpus and build products are out of scope.
blocked_terms=$(
    for term in \
        "$(printf '\106\154\165\164\164\145\162')" \
        "$(printf '\122\145\141\143\164\040\116\141\164\151\166\145')" \
        "$(printf '\105\154\145\143\164\162\157\156')" \
        "$(printf '\124\141\165\162\151')" \
        "$(printf '\113\157\164\154\151\156')" \
        "$(printf '\103\157\155\160\157\163\145')" \
        "$(printf '\125\156\151\164\171')" \
        "$(printf '\125\156\162\145\141\154')" \
        "$(printf '\130\141\155\141\162\151\156')" \
        "$(printf '\103\157\162\144\157\166\141')" \
        "$(printf '\103\141\160\141\143\151\164\157\162')"
    do
        find . \( -name '*.swift' -o -name '*.md' -o -name 'Package.swift' \) \
            -not -path './.git/*' \
            -not -path './.build/*' \
            -not -path '*/.build/*' \
            -not -path './third_party/*' \
            -not -path './Package.resolved' \
            -exec grep -nH -w -F "$term" {} + 2>/dev/null || true
    done
)
empty_output "non-Apple UI or cross-platform stack mentions" "$blocked_terms"

[ "$fail" = 0 ] || exit 1
echo "rules-swift mechanical gate clean"
