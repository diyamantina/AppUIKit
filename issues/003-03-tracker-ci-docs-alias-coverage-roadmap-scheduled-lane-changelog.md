# #3 03 tracker, CI, docs: alias-coverage roadmap, scheduled lane, CHANGELOG

- State: open
- Created: 2026-07-03T08:55:40Z
- URL: https://git.aleahim.com/SlayerMotionHQ/AppUIKit/issues/3

## Status (2026-07-16)
Open; not independently re-verified this pass.

Zero issues exist anywhere. Seed the alias-coverage roadmap (which AppKit/UIKit surface pairs are aliased, which are deliberately out of scope). Port a scheduled Gitea build-test lane. Bring CHANGELOG current.

Acceptance: the live tracker holds the roadmap; a scheduled lane is green; CHANGELOG reflects the shipped state.

## Comments

### mihaela - 2026-07-05T08:17:04Z

Cross-linked 2026-07-05: the family-wide CI coordination (runner hardware, lane templates, DEPS_TOKEN pattern, scheduled-canary shape) lives at roadmap#2, which now carries the full child registry and current state. This issue narrows to adopting the shared template here plus this repo's specific wrinkles; the non-macOS runner question is answered there once, not per repo.

### mihaela - 2026-07-18

CI half done: added `.gitea/workflows/build-test.yml`, ported byte-for-byte from PureLayer's own
live sibling lane (roadmap#2's proven shape: style gate + `swift test` on the `macos`-labeled forge
runner, push and manual dispatch, matching the family's actual live pattern where the scheduled
cross-family canary lives centrally in PureConformance rather than per repo). `check-style.sh` and
`swift test` both verified clean locally before pushing (10/10 tests). Not independently confirmed
green ON the forge itself from this machine (no Gitea API/CLI credentials available here to check
the run); the template is proven elsewhere, not newly invented.

Remaining, not attempted: the alias-coverage roadmap (a real content-authoring task: which AppKit/
UIKit surface pairs are aliased vs. deliberately out of scope, needs a systematic pass over
AppUIKit.swift, not guessed at here) and the CHANGELOG currency check.
