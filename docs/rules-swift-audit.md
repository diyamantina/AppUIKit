# rules-swift Audit

Date: 2026-06-30. Rows re-verified 2026-07-05 after the conformance pass.

This audit checks AppUIKit against the `rules-swift` rule set, pinned in snapshot
mode at `third_party/rules-swift` (commit `97dc70f`). It separates green gates from
honest gaps. A row left at `Gap` or `Partial` keeps `scripts/check-rules-swift.sh`
red, which is the intended behavior until the repo actually conforms.

## Current Verdict

| Area | Status | Evidence |
|---|---|---|
| Corpus pin / coverage | Pass | `check-rules-corpus-coverage.sh` -> clean, 68 files, pinned via snapshot. |
| Codified mechanical rules | Pass | `check-rules-swift.sh` -> exit 0 ("rules-swift mechanical gate clean"). |
| Local mechanical gates | Pass | `check-local-gate.sh` -> exit 0 (rules gate, style gate, `swift build`, `swift test`). |
| Hook installation | Pass | `install-hooks.sh` sets `core.hooksPath=.githooks`; commit-msg self-test (em dash) rejected. |
| Namespacing | Pass | `check-namespacing.sh` -> exit 0. The 3 file-scope types formerly in `AppUIKit.LayoutDirection.swift` now live one per file (`LayoutDirectionManager.swift`, `ConnectionPointCalculator.swift`, `DirectionalSymbols.swift`), no behavior change. |
| Formatting (SwiftFormat) | Pass | `swiftformat . --config .swiftformat --lint` -> 0/23 files require formatting. |
| Linting (SwiftLint) | Pass | `swiftlint --config .swiftlint.yml` -> no violations. |
| Style gate (em dash / attribution) | Pass | `check-style.sh` -> exit 0; the em dash in `.github/workflows/swift-macos.yml` reworded with a colon. |
| Public-safe leak gate | Pass | `leak-gate.sh` -> exit 0. The session loader now cites the vendored `third_party/rules-swift` snapshot (no machine-absolute path) and the per-machine table via the user-global rules loader; `README.md`, `CONTRIBUTING.md`, and `docs/definition-of-done.md` no longer name the loader file. |
| Build | Pass | `swift build` -> Build complete. |
| Tests | Pass | `swift test` -> 10 tests in 1 suite passed. |
| Framework policy | Pass | Banned non-Apple-stack scan over owned Swift/Markdown -> clean. |
| Concurrency and shortcuts | Pass | No `@unchecked Sendable`, `nonisolated(unsafe)`, `try?`, `catch {}`, `sleep(`, `XCTSkip`, or `swiftlint:disable` in `Sources/`/`Tests/`. |
| Test-target pairing | Pass | `AppUIKit` has matching `AppUIKitTests` (`package-architecture.md`). |
| Validation coverage gate | Not applicable | No validation layer; this is a UI abstraction shim, not a parsing/validation surface. |
| Pre-UI layer | Not applicable | Verified by module inspection: single-module UIKit/AppKit component (renderer) package with no framework-free model tier to confine, so the import-confinement gate (`ui/pre-ui-layer.md` point 5) does not apply. |
| DocC documentation | Pass | `Sources/AppUIKit/AppUIKit.docc` curated catalog; `swift package generate-documentation` (Swift-DocC plugin 1.4.3+) builds with no documentation warnings. |
| Multi-renderer UI proof | Not applicable | Single UIKit/AppKit abstraction shim, not a multi-backend renderer. |
| Public CI backstop | Pass | Workflows invoke the gates: `style.yml` runs `check-style.sh`, `check-commit-attribution.sh`, `check-namespacing.sh`; `rules-swift.yml` runs the corpus pin plus the full strict gate as required steps; `swift-macos.yml` runs format, lint, build, test. |

## Public Corpus Coverage

Rules corpus last read: 2026-06-30 (pin 97dc70f).

Rules corpus file count: 68.

<!--
  Every Markdown or shell file in the pinned rules-swift corpus MUST appear as a
  backticked path in the table below. scripts/check-rules-corpus-coverage.sh
  fails if any corpus file is missing here, and re-derives the count above, so
  no public rule source can be silently omitted or changed without updating this
  audit. If the corpus changes, update the count and the rows together.
-->

The local gate verifies that every Markdown or shell file in the public
`rules-swift` checkout selected by `RULES_SWIFT_DIR` is named in this section and
that the pinned snapshot matches its recorded digest. That does not mean every
rule is fully satisfied; it means no public rule source can be silently omitted.

| Public rule source | Coverage |
|---|---|
| `.github/pull_request_template.md` | Listed |
| `business-rules-and-constraints.md` | Listed |
| `CHANGELOG.md` | Listed |
| `code-style.md` | Listed |
| `concurrency.md` | Listed |
| `CONTRIBUTING.md` | Listed |
| `CONVENTIONS.md` | Listed |
| `core/brainstorming.md` | Listed |
| `core/commits.md` | Listed |
| `core/file-naming.md` | Listed |
| `core/first-principles-analysis.md` | Listed |
| `core/folder-grouping.md` | Listed |
| `core/git-discipline.md` | Listed |
| `core/no-shortcuts-first-principles.md` | Listed |
| `core/oracle-first.md` | Listed |
| `core/proof-discipline.md` | Listed |
| `core/README.md` | Listed |
| `core/round-trip-transformation.md` | Listed |
| `core/rules.md` | Listed |
| `core/self-improve.md` | Listed |
| `core/systematic-debugging.md` | Listed |
| `core/testing-discipline.md` | Listed |
| `core/verification.md` | Listed |
| `core/writing-plans.md` | Listed |
| `cross-platform.md` | Listed |
| `dependency-injection.md` | Listed |
| `documentation-search.md` | Listed |
| `documentation.md` | Listed |
| `domain-first.md` | Listed |
| `exp/app-target.md` | Listed |
| `exp/build-performance.md` | Listed |
| `exp/common-mistakes.md` | Listed |
| `exp/critical-rules.md` | Listed |
| `exp/dependency-management.md` | Listed |
| `exp/implementation-patterns.md` | Listed |
| `exp/migration.md` | Listed |
| `exp/package-swift.md` | Listed |
| `exp/README.md` | Listed |
| `exp/testing.md` | Listed |
| `exp/verification.md` | Listed |
| `exp/when-to-create.md` | Listed |
| `formatting-and-linting.md` | Listed |
| `framework-policy.md` | Listed |
| `linux-server.md` | Listed |
| `namespacing.md` | Listed |
| `openapi-generated.md` | Listed |
| `package-architecture.md` | Listed |
| `package-import-contract.md` | Listed |
| `package-structure.md` | Listed |
| `parsing-rules.md` | Listed |
| `README.md` | Listed |
| `scripts/check-namespacing.sh` | Listed |
| `scripts/leak-gate.sh` | Listed |
| `shared-protocols.md` | Listed |
| `testing.md` | Listed |
| `ui/appkit-views.md` | Listed |
| `ui/colors.md` | Listed |
| `ui/components.md` | Listed |
| `ui/flowspec.md` | Listed |
| `ui/fonts.md` | Listed |
| `ui/native-per-platform.md` | Listed |
| `ui/pom.md` | Listed |
| `ui/pre-ui-layer.md` | Listed |
| `ui/swiftui-views.md` | Listed |
| `ui/three-renderers.md` | Listed |
| `ui/uikit-views.md` | Listed |
| `ui/view-models.md` | Listed |
| `validation-rules.md` | Listed |

## Rule Matrix

<!--
  One row per rule file that applies to this repo. Status is one of:
  Pass, Partial, Gap, or Not applicable (with a reason). Partial and Gap rows
  are read by scripts/check-rules-swift.sh as blockers, so they keep the gate
  red until resolved. Cite evidence (a command and its output) for Pass rows.
-->

| Rule file | Applies | Status | Evidence or gap |
|---|---:|---|---|
| `core/no-shortcuts-first-principles.md` | Yes | Pass | No shortcut patterns in `Sources/`/`Tests/`. |
| `concurrency.md` | Yes | Pass | No concurrency escape hatches in owned code. |
| `framework-policy.md` | Yes | Pass | Banned-stack scan clean over owned files. |
| `code-style.md` (namespacing) | Yes | Pass | One non-private type per file; `check-namespacing.sh` clean after the LayoutDirection split. |
| `formatting-and-linting.md` | Yes | Pass | SwiftFormat lint clean; SwiftLint clean. |
| `package-architecture.md` | Yes | Pass | `AppUIKit` paired with `AppUIKitTests`. |
| `documentation.md` (DocC) | Yes | Pass | Curated `AppUIKit.docc` catalog; documentation build warning-free. |
| `core/git-discipline.md` (style/leak) | Yes | Pass | `check-style.sh` and `leak-gate.sh` both exit 0 after the workflow and docs scrub. |
| `validation-rules.md` | No | Not applicable | No validation layer. |
| `ui/pre-ui-layer.md` | No | Not applicable | Renderer-layer component package; no model tier to keep display-free (verified by module inspection). |
| `ui/three-renderers.md` | No | Not applicable | Single UIKit/AppKit shim. |

## Remediation Record

All five items from the original remediation list are done (2026-07-05):

1. The extra file-scope types moved out of
   `Sources/AppUIKit/AppUIKit.LayoutDirection.swift` into
   `LayoutDirectionManager.swift`, `ConnectionPointCalculator.swift`, and
   `DirectionalSymbols.swift`; `check-namespacing.sh` is green and the suite
   still passes (10 tests in 1 suite).
2. The em dash in `.github/workflows/swift-macos.yml` reworded with a colon.
3. The public-leak hits scrubbed: the session loader cites the vendored
   `third_party/rules-swift` snapshot instead of a machine-absolute path and
   refers to the user-global rules loader generically; `README.md`,
   `CONTRIBUTING.md`, and `docs/definition-of-done.md` describe the rules via
   `AGENTS.md` and the vendored snapshot.
4. A curated `.docc` catalog added under `Sources/AppUIKit` with the
   Swift-DocC plugin dependency; the documentation build is warning-free.
5. CI backstop: the workflows run the gates directly, and the full strict
   rules gate is a required step in `rules-swift.yml` (it installs hooks first
   because the gate verifies `core.hooksPath`).

The honest status is: AppUIKit conforms to the applicable `rules-swift` corpus
(snapshot pin at `97dc70f`) and `scripts/check-rules-swift.sh` exits 0. The gate
stays strict, so any future regression flips it red again.
