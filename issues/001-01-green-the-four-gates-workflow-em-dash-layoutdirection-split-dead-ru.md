# #1 01 green the four gates: workflow em dash, LayoutDirection split, dead rules links, hooks

- State: closed
- Created: 2026-07-03T08:55:40Z
- URL: https://git.aleahim.com/SlayerMotionHQ/AppUIKit/issues/1

## Status (2026-07-16)
Open; not independently re-verified this pass.

check-style.sh exits 1 on an em dash inside .github/workflows/swift-macos.yml (a dead workflow flagging its own corpse; remove the dead workflows with it). check-namespacing.sh exits 1 on 3 file-scope types in Sources/AppUIKit/AppUIKit.LayoutDirection.swift. leak-gate.sh exits 1 on dead github.com/mihaelamj/rules-swift links in CONTRIBUTING.md and README.md plus the agent charter file's reference. core.hooksPath unset. Found by the 2026-07-03 definition-of-done assessment (docs/definition-of-done.md).

Acceptance: all four gates exit 0.

### mihaela - 2026-07-17 (closing)

Re-verified against current code rather than trusted stale, three of the four were already fixed
(no code change needed, and none required by this pass): `check-style.sh` exits 0 (the workflow em
dash is gone); `check-namespacing.sh` exits 0, confirmed by running the gate's own exact grep
pattern against `AppUIKit.LayoutDirection.swift` directly (zero top-level type declarations left
in that file today, its content already lives in `LayoutDirectionManager.swift`); `leak-gate.sh`
exits 0. The one genuinely still-open item was `core.hooksPath`, unset on this clone; ran
`scripts/install-hooks.sh`, which sets it and self-verifies the commit-msg hook rejects a planted
em-dash violation.

Verified: all four gates exit 0 individually, `check-all.sh` (style + namespacing + swiftformat
--lint + swiftlint --strict + build + test) reports "All checks passed", 10/10 package tests pass.
No source changes needed; `core.hooksPath` is a local git-config setting, not a tracked file, so
there is nothing to commit for this closure beyond this note.
