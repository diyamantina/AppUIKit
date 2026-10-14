#!/bin/sh
# Synchronize priority: high with the issue body's Priority field on Forgejo.
set -eu

EVENT_PATH=${FORGEJO_EVENT_PATH:?FORGEJO_EVENT_PATH is required}
LABEL='priority: high'

value=$(
    jq -r '.issue.body // ""' "$EVENT_PATH" | awk '
        {
            line = tolower($0)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        }
        line ~ /^##+[[:space:]]+priority$/ { in_priority = 1; next }
        in_priority && line ~ /^##+/ { exit }
        in_priority && line != "" { print line; exit }
    '
)
has=$(jq -r --arg label "$LABEL" 'any(.issue.labels[]?; .name == $label)' "$EVENT_PATH")

action=unchanged
if [ "$value" = high ] && [ "$has" = false ]; then
    action=add
elif [ "$value" != high ] && [ "$has" = true ]; then
    label_id=$(jq -r --arg label "$LABEL" \
        '.issue.labels[] | select(.name == $label) | .id' "$EVENT_PATH")
    [ -n "$label_id" ] || {
        echo "priority label sync: labelled event has no label id" >&2
        exit 1
    }
    action="remove:$label_id"
fi

if [ "${PRIORITY_LABEL_DRY_RUN:-0}" = 1 ]; then
    echo "$action"
    exit 0
fi

case "$action" in
    unchanged)
        exit 0
        ;;
esac

API=${FORGEJO_API_URL:?FORGEJO_API_URL is required}
REPOSITORY=${FORGEJO_REPOSITORY:?FORGEJO_REPOSITORY is required}
TOKEN=${FORGEJO_TOKEN:?FORGEJO_TOKEN is required}
number=$(jq -r '.issue.number' "$EVENT_PATH")
endpoint="$API/repos/$REPOSITORY/issues/$number/labels"

case "$action" in
    add)
        payload=$(jq -cn --arg label "$LABEL" '{labels: [$label]}')
        curl -fsS -X POST \
            -H "Authorization: token $TOKEN" \
            -H 'Content-Type: application/json' \
            --data "$payload" \
            "$endpoint" >/dev/null
        ;;
    remove:*)
        label_id=${action#remove:}
        curl -fsS -X DELETE \
            -H "Authorization: token $TOKEN" \
            "$endpoint/$label_id" >/dev/null
        ;;
esac
