# Definition of Done

Status: assessed 2026-07-03 against `main` (family walk stop 20, assessed with AppUIControls and AppUIResizableControls). The suite is GREEN on a clean build: 10 tests in 1 suite. Four gates are red (style, namespacing, leak, local-gate), all small; the tracker is empty everywhere; and this repo is the subject of the program's registered re-tagging decision.

## What AppUIKit is

The cross-framework namespace layer for imperative AppKit and UIKit code: one set of `AppUI*` aliases plus a few semantic helpers so a single source file targets macOS and iOS without an `#if` at every type reference. Deliberately not a framework: controls and editor surfaces live downstream in AppUIControls. Dependency-free.

## Findings

- **Suite green** (10/1, clean build); dependency-free as chartered.
- **Style gate red**: an em dash inside `.github/workflows/swift-macos.yml`, a dead workflow file flagging its own corpse.
- **Namespacing gate red**: 3 file-scope types in `AppUIKit.LayoutDirection.swift`.
- **Leak gate red**: dead `github.com/mihaelamj/rules-swift` links in CONTRIBUTING.md and README.md; CLAUDE.md's `~/.claude` reference.
- **Hooks uninstalled**; rules-corpus green; CI is the Gitea rules-freshness lane only.
- **The tags question lives here.** SuperSplit's manifest used to require `from: 0.1.9` of this package; the 0.1.x tags did not survive the migration and exist nowhere. The owner decision (re-tag on the forge versus floating-main policy) is registered as SlayerMotionHQ/SuperSplit#2 and this repo executes whichever verdict lands.

## Punch list

Filed live as issues 1 through 3 under the epic (issue 4).

1. **Green the four gates.** The workflow em dash goes with the dead workflows themselves; the three-type file splits; the dead links move to the vendored-snapshot truth; hooks installed.
2. **Execute the re-tag verdict.** When SuperSplit#2 is decided: either recreate a tagged release history here (starting from a defensible commit, not archaeology-by-guess) or record floating-main in README and CHANGELOG.
3. **Tracker, CI, docs.** Seed the alias-coverage roadmap (which AppKit/UIKit surface pairs are aliased, which are out of scope), a scheduled Gitea build-test lane, CHANGELOG current.

## Verdict

A tiny, correct, dependency-free layer doing exactly its chartered job, with an afternoon of hygiene and one decision it does not own but must execute.
