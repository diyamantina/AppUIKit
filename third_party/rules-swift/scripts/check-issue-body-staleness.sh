#!/bin/sh
# Audit open Codeberg issues for the repository's tracker-discipline invariants.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
API=${ISSUES_API:-https://codeberg.org/api/v1/repos/Mihaela/rules-swift/issues?state=open&limit=50}
LABELS_API=${LABELS_API:-https://codeberg.org/api/v1/repos/Mihaela/rules-swift/labels?limit=100}
TMP=
LABEL_TMP=
PHANTOM=$(mktemp "${TMPDIR:-/tmp}/rules-swift-phantom.XXXXXX")
trap 'rm -f "$TMP" "$LABEL_TMP" "$PHANTOM"' EXIT HUP INT TERM

if ! command -v jq >/dev/null 2>&1; then
    echo "issue-body gate: jq is required" >&2
    exit 1
fi

if { [ -z "${ISSUES_JSON:-}" ] || [ -z "${LABELS_JSON:-}" ]; } \
    && ! command -v curl >/dev/null 2>&1; then
    echo "issue-body gate: curl is required for live tracker data" >&2
    exit 1
fi

if [ -n "${ISSUES_JSON:-}" ]; then
    data=$ISSUES_JSON
else
    TMP=$(mktemp "${TMPDIR:-/tmp}/rules-swift-issues.XXXXXX")
    curl -fsSL "$API" > "$TMP"
    data=$TMP
fi

if [ -n "${LABELS_JSON:-}" ]; then
    labels=$LABELS_JSON
else
    LABEL_TMP=$(mktemp "${TMPDIR:-/tmp}/rules-swift-labels.XXXXXX")
    curl -fsSL "$LABELS_API" > "$LABEL_TMP"
    labels=$LABEL_TMP
fi

fail=0
count=$(jq 'length' "$data")
label_count=$(jq 'length' "$labels")

label_drift=$(jq -nr \
    --slurpfile expected "$ROOT/.github/labels.json" \
    --slurpfile actual "$labels" '
        $expected[0][] as $want
        | ($actual[0] | map(select(.name == $want.name)) | first) as $got
        | select($got == null or (($got.color | ascii_downcase) != $want.color))
        | if $got == null then
              "missing: \($want.name)"
          else
              "wrong color: \($want.name) expected=\($want.color) actual=\($got.color)"
          end
    ')
if [ -n "$label_drift" ]; then
    echo "ISSUE BODY FAIL (repository label drift):" >&2
    echo "$label_drift" >&2
    fail=1
fi

missing_status=$(jq -r '
    .[]
    | (.body // "") as $body
    | ($body | [scan("(?m)^##+ .+$")][0] // "") as $first_heading
    | select((($first_heading | test("^##+ Status")) and
              ($body | test("(?m)^##+ Status.*\\n+20[0-9]{2}-[0-9]{2}-[0-9]{2}:"))) | not)
    | .number
' "$data")
if [ -n "$missing_status" ]; then
    echo "ISSUE BODY FAIL (missing dated Status block): $missing_status" >&2
    fail=1
fi

line_anchors=$(jq -r '
    .[]
    | select((.body // "") | test("#[Ll][0-9]+|[A-Za-z0-9._/-]+:[0-9]+"))
    | .number
' "$data")
if [ -n "$line_anchors" ]; then
    echo "ISSUE BODY FAIL (line-number anchor): $line_anchors" >&2
    fail=1
fi

stale_refs=$(jq -r '
    . as $issues
    | [$issues[].number] as $open
    | $issues[] as $issue
    | (($issue.body // "")
       | scan("(?i)(?:blocked on|pending in|depends on|after|gated on|awaits|waiting on)[^\\n#]*#[0-9]+")
       | capture("#(?<number>[0-9]+)").number
       | tonumber) as $reference
    | select(($open | index($reference)) == null)
    | "\($issue.number) -> #\($reference)"
' "$data")
if [ -n "$stale_refs" ]; then
    echo "ISSUE BODY FAIL (blocker reference is not open):" >&2
    echo "$stale_refs" >&2
    fail=1
fi

priority_drift=$(jq -r '
    .[]
    | ((.body // "") | test("(?mi)^##+ Priority[ \\t]*\\r?\\n+high[ \\t]*$")) as $high
    | ([.labels[]?.name] | index("priority: high") != null) as $labelled
    | select($high != $labelled)
    | .number
' "$data")
if [ -n "$priority_drift" ]; then
    echo "ISSUE BODY FAIL (priority body/label drift): $priority_drift" >&2
    fail=1
fi

jq -r '.[] as $issue | (($issue.body // "") | scan("`[^`]+`") | gsub("^`|`$"; "")) as $path | [$issue.number, $path] | @tsv' "$data" \
    | while IFS="$(printf '\t')" read -r number path; do
        case "$path" in
            *' '*|*'<'*|*'>'*|*'('*|*')'*|http:*|https:*|'' ) continue ;;
        esac
        case "$path" in
            */*|*.md|*.swift|*.yml|*.yaml|*.json|*.sh|*.txt|*.toml|*.mmd|*.png|*.jpg|*.jpeg|*.pdf|LICENSE|VERSION)
                [ -e "$ROOT/$path" ] || printf '%s\t%s\n' "$number" "$path"
                ;;
        esac
    done > "$PHANTOM"

phantoms=$(cat "$PHANTOM")
if [ -n "$phantoms" ]; then
    echo "ISSUE BODY FAIL (phantom backtick path):" >&2
    echo "$phantoms" >&2
    fail=1
fi

[ "$fail" = 0 ] || exit 1
echo "issue-body gate clean ($count open items, $label_count labels)"
