# #2 02 execute the re-tag verdict from SuperSplit#2

- State: open
- Created: 2026-07-03T08:55:40Z
- Labels: bug
- URL: https://git.aleahim.com/SlayerMotionHQ/AppUIKit/issues/2

## Status (2026-07-27)

Still open, unresolved. `git tag -l` in this repo returns no tags, so the `from: "0.1.9"` requirement in README.md cannot resolve; the only mitigation in place is SuperSplit's `Package.swift` floating on `branch: "main"` (line 25), which is a workaround, not the acceptance-criteria decision. The gating decision issue, SlayerMotionHQ/SuperSplit#2, is itself still open, so neither branch of the acceptance (re-tag and go versioned, or write down floating-main as policy) has landed. No commit or doc change satisfies this issue's acceptance criteria yet.

## Status (2026-07-16)
Open; not independently re-verified this pass.

The 0.1.x tags of this package did not survive the forge migration and exist in no clone; SuperSplit's from: 0.1.9 requirement was floated to main on 2026-07-03. When the registered owner decision (SlayerMotionHQ/SuperSplit#2) lands: either recreate a tagged release history here starting from a defensible commit (no archaeology-by-guess), or record floating-main as policy in README and CHANGELOG.

Acceptance: consumers can either resolve this package by version again, or the floating policy is written down where a consumer will look.
