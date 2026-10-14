#!/bin/sh
# Enforce the document/asset naming contract from core/file-naming.md.
set -eu

# Force the C locale for every glob/case bracket expression below. Under a
# UTF-8 locale, /bin/sh on macOS (Apple's frozen bash 3.2) collates [A-Z]
# against locale rules rather than strict ASCII order, so *[A-Z]*) can match
# an all-lowercase name like "namespacing.md". The C locale is the only one
# where [A-Z] means exactly the 26 uppercase ASCII letters.
export LC_ALL=C

ROOT=${RULES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
RESULT=$(mktemp "${TMPDIR:-/tmp}/rules-swift-file-names.XXXXXX")
trap 'rm -f "$RESULT"' EXIT HUP INT TERM

find "$ROOT" -mindepth 1 \
    -not -path '*/.git' -not -path '*/.git/*' \
    -not -path '*/.build' -not -path '*/.build/*' \
    -print | while IFS= read -r path; do
        relative=${path#"$ROOT"/}
        name=${path##*/}

        case "$relative" in
            Sources/*|*/Sources/*|Tests/*|*/Tests/*|src/*|*/src/*)
                continue
                ;;
        esac

        case "$name" in
            *' '*|*'('*|*')'*|*'['*|*']'*|*'&'*|*.)
                echo "$relative: invalid separator or special character" >> "$RESULT"
                ;;
        esac

        if LC_ALL=C printf '%s' "$name" | grep -q '[^ -~]'; then
            echo "$relative: non-ASCII name" >> "$RESULT"
        fi

        case "$relative" in
            .github|.github/*)
                continue
                ;;
        esac
        case "$name" in
            README*|LICENSE|CHANGELOG*|CONTRIBUTING*|CODEOWNERS|NOTICE|AUTHORS|VERSION|Package.swift|Package.resolved|Package@*.swift|Dockerfile|Makefile|Gemfile|Rakefile|Podfile|Cartfile|Fastfile)
                continue
                ;;
        esac

        case "$name" in
            *[A-Z]*) echo "$relative: uppercase name" >> "$RESULT" ;;
        esac
        case "$name" in
            *_*) echo "$relative: underscore separator" >> "$RESULT" ;;
        esac
        case "$name" in
            *.heic|*.HEIC) echo "$relative: convert HEIC to JPEG" >> "$RESULT" ;;
        esac
    done

findings=$(cat "$RESULT")
if [ -n "$findings" ]; then
    echo "FILE NAME FAIL:" >&2
    echo "$findings" >&2
    exit 1
fi

echo "file-name gate clean"
