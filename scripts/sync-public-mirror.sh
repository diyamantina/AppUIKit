#!/usr/bin/env bash
set -euo pipefail

# Rebuilds the public GitHub mirror (github.com/diyamantina/AppUIKit) from this
# repo's full history, with CLAUDE.md and AGENTS.md stripped from every commit.
#
# This repo has no Actions runner, so this does not run automatically on push.
# Re-run manually after any commit that should reach the public mirror.
#
# Requires: git-filter-repo, gh (authenticated as diyamantina).

EXCLUDE_PATHS=(CLAUDE.md AGENTS.md)
SOURCE_REMOTE="https://git.aleahim.com/SlayerMotionHQ/AppUIKit.git"
TARGET_REMOTE="https://github.com/diyamantina/AppUIKit.git"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

git clone --quiet "$SOURCE_REMOTE" "$work/AppUIKit"
cd "$work/AppUIKit"

filter_args=()
for path in "${EXCLUDE_PATHS[@]}"; do
  filter_args+=(--path "$path")
done

git filter-repo --force --invert-paths "${filter_args[@]}"

token="$(gh auth token --user diyamantina)"
git remote add public "https://diyamantina:${token}@github.com/diyamantina/AppUIKit.git"
git push --force public main
git push --force public --tags

echo "Synced to $TARGET_REMOTE, excluding: ${EXCLUDE_PATHS[*]}"
