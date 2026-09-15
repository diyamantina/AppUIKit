# Contributing

Thanks for your interest in AppUIKit, the cross-framework (AppKit + UIKit)
namespace layer for the SlayerMotion family. The notes below keep changes
consistent with the rest of the family.

The GitHub repository is a read-only mirror of the canonical source: every sync
rewrites it, so pull requests opened on GitHub cannot be merged and are closed
automatically. Issues and Discussions are open there. To propose a change, open
an issue describing it; it will be picked up from there.

## Getting set up

- Swift 6.0+, Xcode 16+, macOS 14+ / iOS 17+.
- A single SwiftPM package. Build and test from the repository root:

```sh
swift build
swift test
```

To check the UIKit branch (the host build only exercises AppKit), cross-compile
for the simulator:

```sh
swift build --triple arm64-apple-ios17.0-simulator --sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)"
```

## Before you propose a change

- **Build and test** on both platforms. State the pass/fail counts in the issue.
- **Format and lint:** `swiftformat --lint . --config .swiftformat` and
  `swiftlint --config .swiftlint.yml --strict`. These also run in the pre-commit
  hook; install it once per clone with `git config core.hooksPath .githooks`.
- **Keep one concern per change.** No unrelated refactors.
- **Add or update a test** for every behavior change or bug fix.
- **Update `CHANGELOG.md`** under `## [Unreleased]` for anything API-visible.

## Rules

This package follows the canonical `rules-swift` rule set, vendored in snapshot mode under
`third_party/rules-swift`; see `AGENTS.md`.

## Code style

- One non-private type per file; file name equals the type name.
- 4-space indentation, lines <= 180 characters, trailing commas in multiline literals.
- Make impossible states unrepresentable; never force-unwrap in production code.
- New aliases or helpers must compile on both the AppKit and UIKit branches.

## Commits

Use Conventional Commits: `<type>(<scope>): summary`, for example
`feat: add NSUIToolbar aliases`. Common types: `feat`, `fix`, `chore`, `test`,
`docs`, `refactor`, `build`. No tool attribution and no em dashes in the message
(enforced by the commit-msg hook). Squash fixups locally before sharing.

## Branches

- Branch from up-to-date `main`: `feat/<slug>` or `fix/<slug>`.

## Reporting bugs and requesting features

Open a GitHub issue with steps to reproduce, the observed vs expected behavior,
and your platform / Swift version.
