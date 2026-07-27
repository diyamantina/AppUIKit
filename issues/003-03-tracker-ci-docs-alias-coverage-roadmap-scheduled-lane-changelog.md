# #3 03 tracker, CI, docs: alias-coverage roadmap, scheduled lane, CHANGELOG

- State: open
- Created: 2026-07-03T08:55:40Z
- Labels: enhancement
- URL: https://git.aleahim.com/SlayerMotionHQ/AppUIKit/issues/3

## Status (2026-07-27)

Still open, partially done, matching the prior 2026-07-26 status block with no change since. `.gitea/workflows/build-test.yml` (added in 338c985) covers the CI-lane portion but only triggers on push/manual dispatch, deliberately delegating the scheduled canary to PureConformance per its own header comment, so the "scheduled lane" acceptance leaf is not literally met in this repo. `grep -rn -i alias-coverage --include=*.md .` turns up no roadmap document anywhere in the tree, only restatements of the requirement itself in docs/definition-of-done.md and issues/003-*.md. CHANGELOG.md is current. Two of three acceptance items remain unmet.

## Status (2026-07-26)

OPEN, PARTIAL. The live tracker is seeded, `.gitea/workflows/build-test.yml` exists, and `CHANGELOG.md` reflects the shipped documentation/rules state. No alias-coverage roadmap was found, and the workflow has push/manual triggers only while delegating the scheduled canary to PureConformance. The roadmap and scheduled-lane acceptance remain.

---

## Status (2026-07-16)
Open; not independently re-verified this pass.

Zero issues exist anywhere. Seed the alias-coverage roadmap (which AppKit/UIKit surface pairs are aliased, which are deliberately out of scope). Port a scheduled Gitea build-test lane. Bring CHANGELOG current.

Acceptance: the live tracker holds the roadmap; a scheduled lane is green; CHANGELOG reflects the shipped state.

## Comments

### mihaela - 2026-07-05T08:17:04Z

Cross-linked 2026-07-05: the family-wide CI coordination (runner hardware, lane templates, DEPS_TOKEN pattern, scheduled-canary shape) lives at roadmap#2, which now carries the full child registry and current state. This issue narrows to adopting the shared template here plus this repo's specific wrinkles; the non-macOS runner question is answered there once, not per repo.
