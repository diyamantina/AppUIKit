# #1 01 green the four gates: workflow em dash, LayoutDirection split, dead rules links, hooks

- State: closed
- Created: 2026-07-03T08:55:40Z
- Closed: 2026-07-17T20:33:20Z
- URL: https://git.aleahim.com/SlayerMotionHQ/AppUIKit/issues/1

## Status (2026-07-16)
Open; not independently re-verified this pass.

check-style.sh exits 1 on an em dash inside .github/workflows/swift-macos.yml (a dead workflow flagging its own corpse; remove the dead workflows with it). check-namespacing.sh exits 1 on 3 file-scope types in Sources/AppUIKit/AppUIKit.LayoutDirection.swift. leak-gate.sh exits 1 on dead github.com/mihaelamj/rules-swift links in CONTRIBUTING.md and README.md plus the agent charter file's reference. core.hooksPath unset. Found by the 2026-07-03 definition-of-done assessment (docs/definition-of-done.md).

Acceptance: all four gates exit 0.
