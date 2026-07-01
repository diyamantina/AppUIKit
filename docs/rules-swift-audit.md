# rules-swift Audit

Date: 2026-06-30

This audit checks AppUIKit against the Swift rule set at
<https://github.com/mihaelamj/rules-swift>, pinned in snapshot mode at
`third_party/rules-swift` (commit `97dc70f`). It separates green gates from honest
gaps. A row left at `Gap` or `Partial` keeps `scripts/check-rules-swift.sh` red,
which is the intended behavior until the repo actually conforms.

## Current Verdict

| Area | Status | Evidence |
|---|---|---|
| Corpus pin / coverage | Pass | `check-rules-corpus-coverage.sh` -> clean, 68 files, pinned via snapshot. |
| Codified mechanical rules | Gap | `check-rules-swift.sh` is strict and exits non-zero while the Gap rows below remain. |
| Local mechanical gates | Gap | `check-local-gate.sh` is gated by the strict rules gate. |
| Hook installation | Pass | `install-hooks.sh` sets `core.hooksPath=.githooks`; commit-msg self-test (em dash) rejected. |
| Namespacing | Gap | `check-namespacing.sh` reports 3 file-scope types in `Sources/AppUIKit/AppUIKit.LayoutDirection.swift` (pre-existing; source left untouched per file ownership). |
| Formatting (SwiftFormat) | Pass | `swiftformat . --config .swiftformat --lint` -> 0/20 files require formatting. |
| Linting (SwiftLint) | Pass | `swiftlint --config .swiftlint.yml` -> no violations. |
| Style gate (em dash / attribution) | Gap | `check-style.sh` flags a pre-existing em dash in `.github/workflows/swift-macos.yml` (CI workflow; owner scrub). |
| Public-safe leak gate | Gap | `leak-gate.sh` flags pre-existing vendor-name references to `CLAUDE.md` in `README.md`, `CONTRIBUTING.md`, `CLAUDE.md`, and a `/Volumes` path in `CLAUDE.md` (owner files; scrub deferred). |
| Build | Pass | `swift build` -> Build complete. |
| Tests | Not re-run | Suite not re-run during migration; run via the repo's own gate. |
| Framework policy | Pass | Banned non-Apple-stack scan over owned Swift/Markdown -> clean. |
| Concurrency and shortcuts | Pass | No `@unchecked Sendable`, `nonisolated(unsafe)`, `try?`, `catch {}`, `sleep(`, `XCTSkip`, or `swiftlint:disable` in `Sources/`/`Tests/`. |
| Test-target pairing | Pass | `AppUIKit` has matching `AppUIKitTests` (`package-architecture.md`). |
| Validation coverage gate | Not applicable | No validation layer; this is a UI abstraction shim, not a parsing/validation surface. |
| Pre-UI layer | Not applicable | Verified by module inspection: single-module UIKit/AppKit component (renderer) package with no framework-free model tier to confine, so the import-confinement gate (`ui/pre-ui-layer.md` point 5) does not apply. |
| DocC documentation | Gap | No `.docc` catalog under `Sources/` (`documentation.md`). |
| Multi-renderer UI proof | Not applicable | Single UIKit/AppKit abstraction shim, not a multi-backend renderer. |
| Public CI backstop | Gap | `.github/workflows` exist but are not wired to these gates; deferred to the CI phase. |

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
| `code-style.md` (namespacing) | Yes | Gap | 3 file-scope types in `AppUIKit.LayoutDirection.swift` (owner decision). |
| `formatting-and-linting.md` | Yes | Pass | SwiftFormat lint clean; SwiftLint clean. |
| `package-architecture.md` | Yes | Pass | `AppUIKit` paired with `AppUIKitTests`. |
| `documentation.md` (DocC) | Yes | Gap | No `.docc` catalog. |
| `core/git-discipline.md` (style/leak) | Yes | Gap | Pre-existing em dash in CI workflow; vendor-name and `/Volumes` references in owner docs. |
| `validation-rules.md` | No | Not applicable | No validation layer. |
| `ui/pre-ui-layer.md` | No | Not applicable | Renderer-layer component package; no model tier to keep display-free (verified by module inspection). |
| `ui/three-renderers.md` | No | Not applicable | Single UIKit/AppKit shim. |

## Required Remediation

Ordered by how much they unblock the gate:

1. Split or privatize the extra file-scope types in
   `Sources/AppUIKit/AppUIKit.LayoutDirection.swift` so `check-namespacing.sh`
   goes green (owner decision; source untouched in this migration).
2. Scrub the pre-existing em dash in `.github/workflows/swift-macos.yml`.
3. Scrub the public-leak hits: the `CLAUDE.md` vendor-name references in
   `README.md`, `CONTRIBUTING.md`, and `CLAUDE.md`, and the `/Volumes` path in
   `CLAUDE.md` (owner files).
4. Add a `.docc` documentation catalog under `Sources/AppUIKit`.
5. CI backstop: wire the local gates into `.github/workflows`; deferred to the
   CI phase.

Until those items are complete, the honest status is: AppUIKit has strict rule
enforcement wired in (snapshot pin at `97dc70f`, green corpus/format/lint/build/
framework/concurrency/test-pairing gates), and that enforcement correctly fails
while the repo does not yet fully conform to the entire `rules-swift` corpus.
