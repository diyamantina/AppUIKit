#!/bin/sh
# Negative controls for the repository gates. A gate not seen red is unproven.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/rules-swift-gates.XXXXXX")
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

if grep -Eq '\\x[[:xdigit:]]{2}' \
    "$ROOT/scripts/leak-gate.sh" "$ROOT/.githooks/commit-msg"; then
    echo "gate test failed: byte matchers must use portable octal escapes" >&2
    exit 1
fi

mkdir -p "$TMP/priority-label"
printf '%s\n' '{"issue":{"number":1,"body":"## Priority\n\nhigh","labels":[]}}' \
    > "$TMP/priority-label/add.json"
printf '%s\n' '{"issue":{"number":1,"body":"### Priority\n\nnormal","labels":[{"id":7,"name":"priority: high"}]}}' \
    > "$TMP/priority-label/remove.json"
printf '%s\n' '{"issue":{"number":1,"body":"### Priority\n\nhigh","labels":[{"id":7,"name":"priority: high"}]}}' \
    > "$TMP/priority-label/unchanged.json"
test "$(FORGEJO_EVENT_PATH="$TMP/priority-label/add.json" PRIORITY_LABEL_DRY_RUN=1 \
    "$ROOT/scripts/sync-priority-label.sh")" = add
test "$(FORGEJO_EVENT_PATH="$TMP/priority-label/remove.json" PRIORITY_LABEL_DRY_RUN=1 \
    "$ROOT/scripts/sync-priority-label.sh")" = remove:7
test "$(FORGEJO_EVENT_PATH="$TMP/priority-label/unchanged.json" PRIORITY_LABEL_DRY_RUN=1 \
    "$ROOT/scripts/sync-priority-label.sh")" = unchanged

expect_hook() {
    expected=$1
    label=$2
    content=$3
    file="$TMP/message"
    printf '%b\n' "$content" > "$file"
    if "$ROOT/.githooks/commit-msg" "$file" >/dev/null 2>&1; then
        actual=0
    else
        actual=1
    fi
    if [ "$actual" -ne "$expected" ]; then
        echo "gate test failed: $label expected failure=$expected, got failure=$actual" >&2
        exit 1
    fi
}

expect_hook 0 "valid Conventional Commit" 'docs(readme): clarify setup'
expect_hook 1 "invalid type" 'banana: invalid type'
expect_hook 1 "long subject" 'docs(readme): explain the complete repository verification contract in excessive detail'
expect_hook 1 "automated co-author" 'docs(readme): clarify setup\n\nCo-Authored-By: Codex'
expect_hook 1 "assisted attribution" 'docs(readme): clarify setup\n\nAssisted-by: ChatGPT'
expect_hook 1 "em dash" 'docs(readme): clarify setup \342\200\224 now'
expect_hook 1 "trailing period" 'docs(readme): clarify setup.'
expect_hook 1 "breaking footer absent" 'feat(api)!: change response format'
expect_hook 0 "breaking change complete" 'feat(api)!: change response format\n\nBREAKING CHANGE: migrate callers to the new response value'
expect_hook 1 "breaking marker absent" 'feat(api): change response format\n\nBREAKING CHANGE: migrate callers to the new response value'
expect_hook 1 "long body line" 'docs(readme): clarify setup\n\nThis explanation is deliberately longer than seventy-two characters so wrapping enforcement is proven.'
expect_hook 0 "comment text ignored" 'docs(readme): clarify setup\n# Co-Authored-By: Codex \342\200\224 ignored comment'
expect_hook 1 "signature emoji" 'docs(readme): clarify setup \360\237\244\226'
expect_hook 1 "hidden watermark" 'docs(readme): clarify setup\342\200\213'

printf 'docs(test): planted trailer\n\nCo-Authored-By: Codex\n' > "$TMP/message"
if "$ROOT/.githooks/commit-msg" "$TMP/message" > "$TMP/hook-output" 2>&1; then
    echo "gate test failed: planted attribution trailer passed" >&2
    exit 1
fi
grep -q 'Rule 5.1' "$TMP/hook-output"

mkdir -p "$TMP/broken-links"
printf '[missing](missing-file)\n\n[reference]: absent/reference.md\n' > "$TMP/broken-links/README.md"
if RULES_ROOT="$TMP/broken-links" "$ROOT/scripts/check-links.sh" >/dev/null 2>&1; then
    echo "gate test failed: link gate accepted missing inline and reference targets" >&2
    exit 1
fi

mkdir -p "$TMP/leak"
printf 'bad \342\200\224 dash\n' > "$TMP/leak/note.md"
if RULES_ROOT="$TMP/leak" "$ROOT/scripts/leak-gate.sh" >/dev/null 2>&1; then
    echo "gate test failed: leak gate accepted an em dash" >&2
    exit 1
fi

mkdir -p "$TMP/signature-leak"
printf 'bad \360\237\244\226 signature\n' > "$TMP/signature-leak/note.txt"
if RULES_ROOT="$TMP/signature-leak" "$ROOT/scripts/leak-gate.sh" >/dev/null 2>&1; then
    echo "gate test failed: leak gate accepted a signature emoji" >&2
    exit 1
fi
mkdir -p "$TMP/signature-rule"
printf 'forbidden pattern: \360\237\244\226\n' > "$TMP/signature-rule/commits.md"
RULES_ROOT="$TMP/signature-rule" "$ROOT/scripts/leak-gate.sh" >/dev/null

mkdir -p "$TMP/namespacing"
printf 'public struct One {}\npublic struct Two {}\n' > "$TMP/namespacing/Two.swift"
if RULES_ROOT="$TMP/namespacing" "$ROOT/scripts/check-namespacing.sh" >/dev/null 2>&1; then
    echo "gate test failed: namespacing gate accepted two top-level types" >&2
    exit 1
fi

mkdir -p "$TMP/file-names"
printf 'bad name\n' > "$TMP/file-names/Bad_Name.txt"
printf 'bad name\n' > "$TMP/file-names/bad name.txt"
printf 'bad name\n' > "$TMP/file-names/bad&name.txt"
non_ascii=$(printf 'bad-\305\276.txt')
printf 'bad name\n' > "$TMP/file-names/$non_ascii"
if RULES_ROOT="$TMP/file-names" "$ROOT/scripts/check-file-names.sh" > "$TMP/file-name-output" 2>&1; then
    echo "gate test failed: file-name gate accepted invalid fixture names" >&2
    exit 1
fi
grep -q 'uppercase name' "$TMP/file-name-output"
grep -q 'underscore separator' "$TMP/file-name-output"
grep -q 'invalid separator or special character' "$TMP/file-name-output"
grep -q 'non-ASCII name' "$TMP/file-name-output"

# Positive control: a known-clean fixture must pass. Without this, a gate that
# flags everything (the 2026-07-12 locale bug: bash 3.2's case bracket ranges
# collate [A-Z] against the ambient UTF-8 locale, matching all-lowercase names
# too) still satisfies every must-fail expectation above and ships silently.
mkdir -p "$TMP/file-names-clean"
printf 'ok\n' > "$TMP/file-names-clean/clean-name.md"
printf 'ok\n' > "$TMP/file-names-clean/README.md"
if ! RULES_ROOT="$TMP/file-names-clean" "$ROOT/scripts/check-file-names.sh" >/dev/null 2>&1; then
    echo "gate test failed: file-name gate rejected a clean fixture" >&2
    exit 1
fi

mkdir -p "$TMP/rule-structure"
printf '# Binding Rule\n\nMUST do the thing.\n' > "$TMP/rule-structure/example.md"
if RULES_ROOT="$TMP/rule-structure" "$ROOT/scripts/check-rule-structure.sh" >/dev/null 2>&1; then
    echo "gate test failed: rule-structure gate accepted a binding rule with no proof section" >&2
    exit 1
fi

mkdir -p "$TMP/core-source" "$TMP/core-target"
printf '# Core Rule\n' > "$TMP/core-source/example.md"
printf '# Core Rule\n' > "$TMP/core-target/example.md"
CORE_SOURCE_DIR="$TMP/core-source" CORE_TARGET_DIR="$TMP/core-target" \
    "$ROOT/scripts/check-core-sync.sh" >/dev/null
printf '\nDrift.\n' >> "$TMP/core-target/example.md"
if CORE_SOURCE_DIR="$TMP/core-source" CORE_TARGET_DIR="$TMP/core-target" \
    "$ROOT/scripts/check-core-sync.sh" >/dev/null 2>&1; then
    echo "gate test failed: core-sync gate accepted a divergent vendored file" >&2
    exit 1
fi

mkdir -p "$TMP/version"
git -C "$TMP/version" init -q
printf '1.0.0\n' > "$TMP/version/VERSION"
printf '# Changelog\n' > "$TMP/version/CHANGELOG.md"
printf '# Rule\n' > "$TMP/version/example.md"
printf 'name: freshness\n' > "$TMP/version/rules-freshness.yml"
git -C "$TMP/version" add VERSION CHANGELOG.md example.md rules-freshness.yml
git -C "$TMP/version" -c user.name=Gate -c user.email=gate@example.invalid commit -qm 'docs(rule): seed fixture'
printf '\nChanged.\n' >> "$TMP/version/example.md"
if RULES_ROOT="$TMP/version" "$ROOT/scripts/check-version-bumped.sh" --working-tree >/dev/null 2>&1; then
    echo "gate test failed: version gate accepted a rule edit without VERSION" >&2
    exit 1
fi
printf '1.0.1\n' > "$TMP/version/VERSION"
RULES_ROOT="$TMP/version" "$ROOT/scripts/check-version-bumped.sh" --working-tree >/dev/null
if RULES_ROOT="$TMP/version" "$ROOT/scripts/check-changelog-touched.sh" --working-tree >/dev/null 2>&1; then
    echo "gate test failed: changelog gate accepted a rule edit without CHANGELOG.md" >&2
    exit 1
fi
printf '\n- Changed the rule.\n' >> "$TMP/version/CHANGELOG.md"
RULES_ROOT="$TMP/version" "$ROOT/scripts/check-changelog-touched.sh" --working-tree >/dev/null
git -C "$TMP/version" add VERSION CHANGELOG.md example.md
git -C "$TMP/version" -c user.name=Gate -c user.email=gate@example.invalid commit -qm 'docs(rule): change fixture'
printf 'on: push\n' >> "$TMP/version/rules-freshness.yml"
if RULES_ROOT="$TMP/version" "$ROOT/scripts/check-version-bumped.sh" --working-tree >/dev/null 2>&1; then
    echo "gate test failed: version gate ignored the managed freshness workflow" >&2
    exit 1
fi
if RULES_ROOT="$TMP/version" "$ROOT/scripts/check-changelog-touched.sh" --working-tree >/dev/null 2>&1; then
    echo "gate test failed: changelog gate ignored the managed freshness workflow" >&2
    exit 1
fi

printf '%s\n' '[{"number":1,"body":"### Priority\n\nhigh\n\nBlocked on #2. See `missing/file.md` at README.md:10","labels":[]}]' > "$TMP/issues.json"
if ISSUES_JSON="$TMP/issues.json" LABELS_JSON="$ROOT/.github/labels.json" "$ROOT/scripts/check-issue-body-staleness.sh" > "$TMP/issues-output" 2>&1; then
    echo "gate test failed: issue-body gate accepted stale fixture data" >&2
    exit 1
fi
grep -q 'missing dated Status' "$TMP/issues-output"
grep -q 'line-number anchor' "$TMP/issues-output"
grep -q 'priority body/label drift' "$TMP/issues-output"
grep -q 'phantom backtick path' "$TMP/issues-output"
grep -q 'blocker reference is not open' "$TMP/issues-output"
printf '%s\n' '[{"number":1,"body":"### Status (YYYY-MM-DD)\n\n2026-07-11: open.\n\n### Priority\n\nnormal","labels":[]}]' > "$TMP/issues.json"
ISSUES_JSON="$TMP/issues.json" LABELS_JSON="$ROOT/.github/labels.json" "$ROOT/scripts/check-issue-body-staleness.sh" >/dev/null

printf '%s\n' '[]' > "$TMP/labels.json"
if ISSUES_JSON="$TMP/issues.json" LABELS_JSON="$TMP/labels.json" "$ROOT/scripts/check-issue-body-staleness.sh" > "$TMP/labels-output" 2>&1; then
    echo "gate test failed: tracker gate accepted a missing repository label set" >&2
    exit 1
fi
grep -q 'repository label drift' "$TMP/labels-output"

mkdir -p "$TMP/consumer"
git -C "$TMP/consumer" init -q
git -C "$TMP/consumer" remote add origin https://codeberg.org/example/consumer.git
mkdir -p "$TMP/consumer/.forgejo/workflows"
printf '# Managed by rules-swift legacy workflow\n' > "$TMP/consumer/.forgejo/workflows/rules-conformance.yml"
"$ROOT/scripts/sync-rules.sh" "$TMP/consumer" >/dev/null
test -f "$TMP/consumer/.forgejo/workflows/rules-freshness.yml"
test ! -e "$TMP/consumer/.forgejo/workflows/rules-conformance.yml"
grep -q 'does not claim' "$TMP/consumer/.forgejo/workflows/rules-freshness.yml"
grep -q 'runs-on: ubuntu-latest' "$TMP/consumer/.forgejo/workflows/rules-freshness.yml"
printf '# Consumer-owned semantic checks\n' > "$TMP/consumer/.forgejo/workflows/rules-conformance.yml"
"$ROOT/scripts/sync-rules.sh" "$TMP/consumer" >/dev/null
grep -q 'Consumer-owned semantic checks' "$TMP/consumer/.forgejo/workflows/rules-conformance.yml"

echo "gate fault-injection tests clean (14 message cases; priority label, link, leak, namespacing, file-name, rule-structure, core-sync, version, changelog, issue-body negatives; freshness migration)"
