# Swift coding rules (canonical)

[![license: CC BY 4.0 (prose), MIT (code)](https://img.shields.io/badge/license-CC%20BY%204.0%20prose%2C%20MIT%20code-blue)](LICENSE)

The canonical, scrubbed Swift coding rules. This is the **Swift domain**: the
language- and platform-specific craft of writing Swift well. It sits on top of a
vendored **core spine** of cross-cutting engineering discipline (see
[`core/`](core/)).

Each file here is one Swift rule area. [conventions.md](conventions.md) is the short overview; this
repository is the full set, with the cross-cutting discipline vendored under
[`core/`](core/). Examples use a sample tile-based static site generator named
Tiledown (the `TileKit` library plus the `tile-down` executable); replace the
example names with your project's when you adopt these.

## Repository verification

Run the complete local gate before proposing a change:

```sh
scripts/check-repo.sh
```

The gate requires `git`, a POSIX shell, Perl, and `jq`; the live issue-body audit
also requires `curl`. The core-sync check uses a sibling
`rules-engineering-discipline` clone when present and otherwise fetches the public
upstream. A missing verifier is a failure, not a skipped check.

The Codeberg origin uses Forgejo. Forgejo reads `.github/workflows` as a fallback
when `.forgejo/workflows` is absent, but a workflow file alone does not prove that
Actions are enabled or that a matching runner is online. The local gate output is
therefore the authoritative evidence for this repository.

These gates describe the current tree and enforce future commits. The published
history contains legacy commit subjects that predate the current hook; preserving
public commit identities takes precedence over rewriting that history.

The scheduled tracker gate runs `scripts/check-issue-body-staleness.sh` against
open Codeberg issues and compares repository labels with `.github/labels.json`.
Run it manually when auditing tracker state between schedules.

## The core spine

The cross-cutting engineering discipline that governs *how* work is done and
reported, independent of language or domain, lives in [`core/`](core/). The Swift
rules here do not duplicate it; they build on it. Read the core spine first:

- `core/no-shortcuts-first-principles.md` - the core ethic: no shortcuts, derive
  from first principles, hold to Knuth's standard of care.
- `core/oracle-first.md` - build the answer key before the system: the Oracle,
  comparison law, failure report, unsupported-case classification, and parity gate.
- `core/proof-discipline.md` - framing a correctness claim as separately provable
  layers, each with an explicit epistemic status.
- `core/round-trip-transformation.md` - any two-way transform (parse/print,
  encode/decode) is one invertible description, proven by the round-trip law.
- `core/first-principles-analysis.md` - depth target for analysis, plus
  measurement discipline (every number traceable to a command).
- `core/verification.md` - no "done" without fresh command output.
- `core/testing-discipline.md` - real tests on every change; a build is not a test.
- `core/systematic-debugging.md` - reproduce, isolate, explain, then fix.
- `core/brainstorming.md` and `core/writing-plans.md` - design and planning gates
  before non-trivial work.
- `core/commits.md`, `core/git-discipline.md` - Conventional Commits; issues,
  labels, branches, PRs, remotes.
- `core/file-naming.md`, `core/folder-grouping.md` - filename conventions and when
  to flatten one-file folders.
- `core/rules.md`, `core/self-improve.md` - authoring rules for an agent, and when
  a recurring correction should become one.

## Where an app starts

Before any UI framework is named, an app starts at its business rules and the
domain that enforces them.

- [business-rules-and-constraints.md](business-rules-and-constraints.md) -
  MANDATORY, the first artifact: the business rules written as explicit checkable
  statements, plus the constraints that bound them (which external REST services
  and their contracts, what compliance, which auth model), defined up front.
- [domain-first.md](domain-first.md) - MANDATORY: an app starts at the domain and
  business rules, framework-free and headless-provable; the UI framework is the
  last, reversible, and plural choice, never the first decision.

## Language and platform craft (engine, today)

- [code-style.md](code-style.md) - namespacing discipline, file naming,
  one-type-per-file.
- [namespacing.md](namespacing.md) - caseless `enum` vs `struct` vs `class` for
  namespace anchors.
- [dependency-injection.md](dependency-injection.md) - no singletons, inject every
  collaborator through `init`, protocol seams.
- [concurrency.md](concurrency.md) - Swift 6 strict concurrency: `Sendable`,
  actors, `@MainActor`.
- [cross-platform.md](cross-platform.md) - the same sources build on Apple
  platforms and Linux (and Windows where noted); guard platform-divergent code
  behind a protocol seam.
- [linux-server.md](linux-server.md) - server-side operational rules for the
  `serve` command and any networking.
- [app-intents.md](app-intents.md) - MANDATORY for Siri, Shortcuts, and Spotlight
  actions: one adapter target, intents in a package declared by `AppIntentsPackage`,
  dependencies registered not passed, every word a localized resource the system
  resolves late, plural forms per language, and how to test the languages.
- [versioning.md](versioning.md) - MANDATORY for anything that ships a version: one
  `VERSION` file read as Semantic Versioning 2.0.0, the store's short version is the
  core only, the build number is the first-parent commit count of the release branch,
  generated by a build-tool plugin that names its inputs, no silent fallback, full
  history in CI, append-only release history.
- [app-logging.md](app-logging.md) - MANDATORY for every shipped app: one given recorder,
  entries that are facts and never the person's content, every intent and state change
  logged, a Developer menu in Debug and Beta only, and a report the person chooses to send.
- [crash-and-state-reporting.md](crash-and-state-reporting.md) - MANDATORY with the log:
  MetricKit and StateReporting behind `canImport` and availability, the system's own crash
  reports as a second door, one crash seen twice is one, states joined to the log.
- [testing.md](testing.md) - Swift Testing, `@Test` / `#expect`, test isolation.
- [formatting-and-linting.md](formatting-and-linting.md) - SwiftFormat and
  SwiftLint, enforced by a pre-commit hook and again in CI.
- [documentation.md](documentation.md) - DocC catalogs and `///` requirements.
- [documentation-search.md](documentation-search.md) - verify API facts against an
  authoritative documentation index, not from memory: query it with keywords and
  read the results for Apple-API facts; it is a search engine, not an agent.
- [framework-policy.md](framework-policy.md) - stay inside Apple's own SDKs and the
  Swift-native ecosystem when selecting an Apple client/UI framework; portable
  libraries and servers follow the cross-platform rules.

## Packages

- [package-structure.md](package-structure.md) - workspace and package layout: one
  active `Package.swift`; root SPM packages use root `Sources/` and `Tests/`,
  project monorepos use `Packages/` plus `Apps/`.
- [package-architecture.md](package-architecture.md) - single-responsibility
  targets with unidirectional dependencies.
- [package-import-contract.md](package-import-contract.md) - per-target allowed
  imports; applies now, the engine and CLI are already two targets.
- [shared-protocols.md](shared-protocols.md) - the cross-target protocol seam.
- [openapi-generated.md](openapi-generated.md) - rules for code generated from an
  OpenAPI document and the hand-written code that surrounds it.

## ExtremePackaging

The granular packaging doctrine lives under [`exp/`](exp/): a monorepo split into
many single-responsibility SwiftPM targets in one active package, with explicit,
unidirectional dependencies for isolated compilation, parallel builds, and
per-target testability. The two
core files are loaded on every Swift session; the rest load on demand.

- [exp/critical-rules.md](exp/critical-rules.md) - core: the five rules that gate
  every target decision (single responsibility, explicit deps, granularity,
  naming, layer architecture).
- [exp/when-to-create.md](exp/when-to-create.md) - core: the decision tree and
  DO/DON'T list for when a new target is warranted.
- [exp/implementation-patterns.md](exp/implementation-patterns.md) - patterns for
  foundation, feature, middleware, API, component, and font targets, and for
  aggregators.
- [exp/dependency-management.md](exp/dependency-management.md) - cross-target and
  external-package dependencies, platform-conditional code, avoiding cycles.
- [exp/package-swift.md](exp/package-swift.md) - the closure-with-local-variables
  pattern for the `deps`, `allProducts`, and `targets` arrays.
- [exp/common-mistakes.md](exp/common-mistakes.md) - anti-patterns paired with the
  canonical fix, for code review of `Package.swift` changes.
- [exp/app-target.md](exp/app-target.md) - adding or modifying an app target
  (SwiftUI, UIKit, AppKit entry points).
- [exp/testing.md](exp/testing.md) - the per-source-target test target and
  cross-target test doubles (architecture angle; full rules in
  [testing.md](testing.md)).
- [exp/migration.md](exp/migration.md) - extracting code into a new target or
  splitting a large target.
- [exp/build-performance.md](exp/build-performance.md) - the build-time rationale
  behind the granularity.
- [exp/verification.md](exp/verification.md) - the final checklist before an
  ExtremePackaging change is considered done.

## Parsing and validation

- [parsing-rules.md](parsing-rules.md) - parse first, validate second; the
  OpenAPIKit parsing idiom over any structured input.
- [validation-rules.md](validation-rules.md) - composable `Validation<Subject>`
  values, never imperative if-trees; every public type is validated or excluded
  with a reason, enforced mechanically.

## UI

The UI rules live under [`ui/`](ui/). Any code with UI keeps the renderer thin over a framework-free model, and tests the flows from a shared scenario corpus.

- [ui/pre-ui-layer.md](ui/pre-ui-layer.md) - MANDATORY: all display state and behavior in a framework-free, value-typed model (Domain + Surface); one `perform(Intent)` write channel; renderers are the only UI import, gated mechanically.
- [ui/native-per-platform.md](ui/native-per-platform.md) - MANDATORY: optimize for the user via genuinely native UI per platform; per-device divergence is welcome; never trade the native experience for developer or test convenience or a write-once lowest-common-denominator. Governs and is superior to three-renderers.
- [ui/three-renderers.md](ui/three-renderers.md) - build the same UI in all three Apple SDKs (SwiftUI, UIKit, AppKit) over the one model: the architecture's payoff and a comparison instrument for which framework behaves best in a scenario. Subordinate to native-per-platform: applies only where the same UI is also the best native UI.
- [ui/swiftui-views.md](ui/swiftui-views.md) - the SwiftUI renderer: view architecture and identity.
- [ui/appuikit.md](ui/appuikit.md) - MANDATORY for AppKit and UIKit code: import `AppUIKit` and name its `AppUI*` types, never an `NS` or `UI` type or a direct SDK import; add a missing alias to the layer first.
- [ui/uikit-views.md](ui/uikit-views.md) - the UIKit renderer: `UIViewController`/`UIView` adapters, diffable data sources, re-pull on the change signal.
- [ui/appkit-views.md](ui/appkit-views.md) - the AppKit renderer: `NSViewController`/`NSView` adapters, `withObservationTracking`, programmatic menus.
- [ui/view-models.md](ui/view-models.md) - view-model responsibilities and patterns.
- [ui/components.md](ui/components.md) - the component system.
- [ui/colors.md](ui/colors.md) - the color system.
- [ui/fonts.md](ui/fonts.md) - font registration in SwiftPM targets.
- [ui/pom.md](ui/pom.md) - Page Object Model for UI tests: screens behind page objects, identifiers from one shared source.
- [ui/flowspec.md](ui/flowspec.md) - declarative UI scenarios driven by [FlowSpec](https://github.com/mihaelamj/FlowSpec): one flow, many renderers, replayed headless and on-device.

## License

Dual-licensed by content type, see [LICENSE](LICENSE): the prose (every `.md` rule document) under CC BY 4.0, any code under MIT.
