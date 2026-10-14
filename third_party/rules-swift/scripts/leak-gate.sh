#!/bin/sh
# Public-safe leak gate for this repository.
# Runs on every commit (.githooks/pre-commit) and in CI (.github/workflows/leak-gate.yml).
# It enforces only what is safe in a PUBLIC repo: no AI/tool vendor names (outside the
# two attribution rules that discuss them), no machine-absolute paths, no em dashes.
# The private project-name scrub lives in a separate private repository, listing those
# names here would itself be the leak.
set -eu

ROOT=${RULES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
fail=0

# AI/tool vendor names are allowed ONLY in the attribution rules that discuss them,
# and in the agent charter files at the repository ROOT (CLAUDE.md / AGENTS.md): there
# the filename is the tool's addressing interface, function, not attribution. Root
# only; the same name in any nested file still fails.
VEND='\bclaude\b|anthropic|\bopenai\b|chatgpt|\bcopilot\b|\bgemini\b|antigravity'
v=$(grep -rniIE "$VEND" "$ROOT" 2>/dev/null | grep -vE '/\.git/|/\.build/' \
      | grep -vE '(^|[./])(commits|git-discipline)\.md:' \
      | grep -vE '/(\.githooks/commit-msg|scripts/(leak-gate|test-gates)\.sh):' \
      | grep -vE "^$ROOT/(CLAUDE|AGENTS)\.md:" || true)
[ -n "$v" ] && { echo "LEAK GATE FAIL (vendor name outside attribution rules):"; echo "$v" | head; fail=1; }

# Machine-absolute paths leak a local filesystem layout.
p=$(grep -rniIE '/Users/|/Volumes/' "$ROOT" 2>/dev/null | grep -vE '/\.git/|/\.build/|/scripts/leak-gate\.sh:' || true)
[ -n "$p" ] && { echo "LEAK GATE FAIL (machine-absolute path):"; echo "$p" | head; fail=1; }

# No em dashes in any repository text file.
e=$(grep -rlIF "$(printf '\342\200\224')" "$ROOT" 2>/dev/null | grep -vE '/\.git/|/\.build/' || true)
[ -n "$e" ] && { echo "LEAK GATE FAIL (em dash):"; echo "$e"; fail=1; }

# Signature emoji and invisible watermark characters are allowed only where the
# attribution rules name the forbidden byte patterns.
s=$(
    {
        grep -rlIF "$(printf '\360\237\244\226')" "$ROOT" 2>/dev/null
        grep -rlIF "$(printf '\342\234\250')" "$ROOT" 2>/dev/null
        grep -rlIF "$(printf '\342\200\213')" "$ROOT" 2>/dev/null
        grep -rlIF "$(printf '\357\273\277')" "$ROOT" 2>/dev/null
    } | sort -u | grep -vE '/\.git/|/\.build/|/(core/)?(commits|git-discipline)\.md$' || true
)
[ -n "$s" ] && { echo "LEAK GATE FAIL (signature emoji or hidden watermark):"; echo "$s"; fail=1; }

[ "$fail" = 0 ] || { echo "LEAK GATE FAILED for $ROOT" >&2; exit 1; }
echo "leak gate clean ($(find "$ROOT" -type f -not -path '*/.git/*' -not -path '*/.build/*' | wc -l | tr -d ' ') repository files)"
