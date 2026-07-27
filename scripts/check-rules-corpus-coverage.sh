#!/bin/sh
# Ensures the pinned rules-swift corpus is present at its recorded version and that
# the audit names every public rules-swift source file.
#
# Two pin mechanisms are supported (auto-detected):
#   submodule mode: the corpus is a git submodule at third_party/rules-swift; the
#     submodule commit IS the pin (preferred for tool repos).
#   snapshot mode:  the corpus is a plain vendored copy at third_party/rules-swift,
#     pinned by docs/rules-swift-corpus.sha256 (preferred for source-published repos
#     that must avoid `--recursive` clones).
# Override RULES_SWIFT_DIR to audit against a live local checkout during dev.
set -eu

# Resolve TMPDIR to the mounted external volume with the most free space, per the
# fleet-wide Scratch & Build Storage Policy; fall back to internal with a warning
# if none is mounted. Respects a TMPDIR the caller already exported.
if [ -z "${TMPDIR:-}" ]; then
    ext_dir=""
    ext_free=0
    for vol in /Volumes/*/; do
        [ -d "$vol" ] || continue
        name=$(basename "$vol")
        [ "$name" = "Macintosh HD" ] && continue
        free=$(df -k "$vol" 2>/dev/null | awk 'NR==2{print $4}')
        case "$free" in ''|*[!0-9]*) continue ;; esac
        if [ "$free" -gt "$ext_free" ]; then
            ext_dir=$vol
            ext_free=$free
        fi
    done
    if [ -n "$ext_dir" ]; then
        TMPDIR="${ext_dir}scratch/tmp"
    else
        echo "warning: no external volume mounted, scratch temp files will use the internal drive" >&2
        TMPDIR="/tmp"
    fi
    mkdir -p "$TMPDIR"
    export TMPDIR
fi

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

RULES_SWIFT_DIR=${RULES_SWIFT_DIR:-"$ROOT/third_party/rules-swift"}
AUDIT=docs/rules-swift-audit.md
MANIFEST=docs/rules-swift-corpus.sha256
fail=0
file_count=0
pin_mode="none"

fail_check() {
    echo "RULE FAIL: $1" >&2
    fail=1
}

if [ ! -f "$AUDIT" ]; then
    fail_check "missing rules-swift audit: $AUDIT"
elif [ ! -d "$RULES_SWIFT_DIR" ] || [ -z "$(ls -A "$RULES_SWIFT_DIR" 2>/dev/null)" ]; then
    fail_check "rules-swift corpus absent at $RULES_SWIFT_DIR (run: git submodule update --init --recursive, or restore the vendored snapshot)"
else
    # --- Pin verification: submodule status, else snapshot digest. ---
    if [ -f .gitmodules ] && grep -q 'third_party/rules-swift' .gitmodules; then
        pin_mode="submodule"
        status=$(git submodule status third_party/rules-swift 2>/dev/null || echo "?unknown")
        # A '+' or '-' prefix means the working submodule drifted off the recorded commit.
        case "$status" in
            [-+]*) fail_check "rules-swift submodule not at pinned commit ($status); run: git submodule update --init --recursive" ;;
        esac
    elif [ -f "$MANIFEST" ]; then
        pin_mode="snapshot"
        actual=$(mktemp "$TMPDIR/rules-swift-corpus.XXXXXX")
        (
            cd "$RULES_SWIFT_DIR"
            find . -type f \( -name '*.md' -o -name '*.sh' \) -not -path '*/.git/*' -print0 \
                | LC_ALL=C sort -fz \
                | xargs -0 shasum -a 256 \
                | sed 's|  ./|  |'
        ) > "$actual"
        if ! cmp -s "$actual" "$MANIFEST"; then
            echo "RULE FAIL: rules-swift snapshot digest changed; update $MANIFEST and $AUDIT together" >&2
            diff -u "$MANIFEST" "$actual" >&2 || true
            fail=1
        fi
        rm -f "$actual"
    else
        fail_check "no corpus pin found: add a git submodule (third_party/rules-swift) or a snapshot digest ($MANIFEST)"
    fi

    file_count=$(
        find "$RULES_SWIFT_DIR" -type f \( -name '*.md' -o -name '*.sh' \) \
            -not -path '*/.git/*' | wc -l | tr -d ' '
    )

    if ! grep -Fq "Rules corpus file count: $file_count" "$AUDIT"; then
        fail_check "rules-swift audit must record current corpus file count: $file_count"
    fi

    missing=$(
        find "$RULES_SWIFT_DIR" -type f \( -name '*.md' -o -name '*.sh' \) -not -path '*/.git/*' \
            | sed "s|^$RULES_SWIFT_DIR/||" \
            | sort \
            | while IFS= read -r rel; do
                grep -Fq "\`$rel\`" "$AUDIT" || echo "$rel"
            done
    )
    if [ -n "$missing" ]; then
        echo "RULE FAIL: rules-swift audit missing corpus files:" >&2
        echo "$missing" | sed 's/^/  /' >&2
        fail=1
    fi
fi

[ "$fail" = 0 ] || exit 1
echo "rules-swift corpus coverage clean ($file_count files, pinned via $pin_mode)"
