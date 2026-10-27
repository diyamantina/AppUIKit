# Changelog

All notable changes to this rule set are documented here. This project follows Semantic Versioning.

## [Unreleased]

## [2.8.0] - 2026-10-28

### Changed

- `accessibility.md`: the Mac is audited too, and what it found is in the rules (a divider with no role is a slider on the Mac and an adjustable action on iOS; a list, an outline and a placeholder-only text field are named; a ruler beside text is hidden). A finding is checked against the pixels of the picture before it is listed, and one the pixels contradict is recorded as a false positive with its measured ratio. The ledger may name element kinds, a finding with no element is let pass only by an entry with no label, and the macOS SDK's missing audit types are named by their raw values. Rule 14 now has a built answer (pages instead of columns at accessibility sizes, decided by a tested pure function) and says for which screens it was looked at.

## [2.7.0] - 2026-10-27

### Added

- `accessibility.md`: text through text styles (Dynamic Type) with the app's own zoom applied as a shift of it,
  every control named by what it does and never by its symbol's default name, 28 point tap targets, an
  alternative for every gesture (named actions, adjustable elements), the name and actions on the element a
  person reaches and not on a container, contrast as arithmetic (4.5 to 1, Light, Dark, Increase Contrast),
  announcements, Reduce Motion, layer-drawn UI exposed element by element, and a UI framework's core that
  describes while each surface must declare that it realizes it. The audit
  (`performAccessibilityAudit`) runs in UI tests and fails for a finding that is not on a ledger of known
  findings, each with its reason. Written from the Cupertino corpus (the Human Interface Guidelines pages
  Accessibility and VoiceOver, Performing accessibility testing, the audit's documentation) and from what the
  audit measured on an iPad app: 300 findings on five screens, 118 of them hit areas, 69 Dynamic Type, 59
  contrast. States what is not established: the layout at the largest accessibility size, VoiceOver on a
  device, and the audit on the Mac.

## [2.6.0] - 2026-10-27

### Added

- `help.md`: an app's help is written once, in one JSON file, and every platform's help is made from it. The
  Mac carries an Apple Help Book (the two Info.plist keys, the book's structure and indexes, generated and
  checked against the file) and leaves the Help menu to the system; an iPad and an iPhone have an in-app
  help sheet in a Help menu of the toolbar and in the menu bar of an iPad, and the version in the Settings
  app through a Settings bundle; tips (TipKit) point at the first thing to do and go when it is done. Each
  platform is told in its own words. Ships a build-checked acceptance list and tests; what was observed on a
  built app is stated as observed, and the Help Book format, which the Cupertino corpus does not hold, is
  marked as such.

### Changed

- `versioning.md` rule 14: the stamp phase names the built `Info.plist` as an input file, so that it runs
  after the system writes the plist; observed on a clean build, where the stamp was lost without it.

## [2.5.0] - 2026-10-18

### Added

- `app-logging.md`: every shipped app has one given recorder, entries that are facts and never the
  person's content, every intent and state change logged, a Developer menu in Debug and Beta builds
  only, and a report (log window, snapshot, optional content) made on the person's request and
  sent only by their choice. Ships a build-checked acceptance list and tests.
- `crash-and-state-reporting.md`: MetricKit and StateReporting used behind `canImport` and
  availability, the system's crash reports as a second door, one crash seen through both doors
  kept once, the call stack never in the log, states joined to the log. Claims about delivery and
  the return of states are stated at the strength they were shown.
- `versioning.md` rule 14: the stamp in an Xcode app target is a post-build script phase.

## [2.4.0] - 2026-10-17

### Added

- `versioning.md`: the version is written once, in a `VERSION` file, and read as Semantic
  Versioning 2.0.0 (a value outside the grammar stops the build); the store's short version is
  the core only; the build number is the first-parent commit count of the release branch, which
  grows by one per commit, never restarts, and names one commit; both reach the code through a
  generated file from a build-tool plugin whose command names its inputs (`VERSION` and the
  git `HEAD` files); a shallow clone or a missing history is refused, never defaulted to `1`;
  CI fetches full history; release history is append-only; a store build comes from the release
  branch with a clean tree; a second upload of one commit needs its own number (the dotted
  form is stated as not established until one upload orders it). Each rule names its basis as
  documented, observed, or design. Ships six acceptance commands and the tests, including a
  regeneration check in a throwaway clone.

## [2.3.0] - 2026-10-14

### Added

- `app-intents.md`: App Intents live in one adapter target; an intent in a package is
  declared by an `AppIntentsPackage` that each app and extension includes; dependencies are
  registered, not passed; every string a person sees is a localized resource that names the
  package bundle and is handed to the system unresolved, so Siri and Shortcuts resolve it in
  their own language; an interpolated sentence keeps its plural forms (one and other in
  English and German, one, few and other in Croatian); a sentence is one key, not translated
  fragments. Each rule names its basis as documented or observed. Ships five acceptance
  commands, a test recipe for the languages (set `locale` on a copy of the resource, because
  `String(localized:bundle:locale:)` reads the process's language), and the statement that a
  unit test does not prove Shortcuts lists the intent in each language.

## [2.2.0] - 2026-10-14

### Added

- `ui/appuikit.md`: imperative AppKit and UIKit renderers, features, and app shells import
  the cross-framework layer and name its `AppUI*` types, never an `NS` or `UI` type or a
  direct SDK import; a missing alias or helper is added to the layer first. Ships an
  acceptance check (two greps to promote to a self-tested gate). `appkit-views.md` and
  `uikit-views.md` point to it.

## [2.1.1] - 2026-10-11

### Fixed

- `exp/common-mistakes.md`: the test-target pairing command filtered `swift package
  describe` output on the target type `regular`, which that output never uses (it says
  `library`), so the command checked no library target and passed vacuously. It now selects
  `library` and `executable`, and the rule says how to confirm the command selects
  something.

## [2.1.0] - 2026-10-11

### Added

- `testing.md`: an exception to "mocks live in the test target" for test-support
  targets that several test targets share, because SwiftPM does not let a test target
  depend on another. It names four conditions (declared in a checked-in table, not
  published, not shipped except by a named allowlist, mechanically checked) and ships a
  runnable acceptance check.

## [2.0.0] - 2026-07-11

### Added

- A complete local repository gate covering leak, namespacing, filenames,
  relative links, rule structure, changelog, version bumps, and fault injection.
- A checked-in five-label tracker manifest plus scheduled issue-body and label-drift
  auditing against Codeberg.
- An exact vendored core license, allowing the upstream README and every changed
  core rule to remain byte-identical after synchronization.
- A byte-for-byte core-sync gate with a planted divergent-vendor negative control.
- Negative controls for commit-message rejection, breaking-change notation,
  missing Markdown links, leaked prose, namespacing violations, missing rule proof
  sections, missing changelog/version bumps, stale issue bodies, label drift, and
  consumer freshness.
- Acceptance checks for the remaining binding parsing, namespacing, planning,
  design, dependency-injection, migration, and package-testing rules.

### Changed

- **Breaking:** Renamed the non-conventional `CONVENTIONS.md` overview to
  `conventions.md`; inbound repository links now use the lowercase path.
- **Breaking:** Reconciled the target graph, DI seams, namespace exception,
  protocol-creation threshold, test-framework scope, and dependency direction
  into one non-contradictory architecture. Consumers must review these rules
  before updating their freshness marker.

### Fixed

- Made forbidden-byte matching portable across POSIX shells so Linux `sh` does
  not treat hexadecimal escape text inside the gates as a leak.
- Replaced the unavailable hosted priority-label action with a repository-owned
  Forgejo API script and deterministic add, remove, and no-op fixtures.
- Renamed the consumer workflow from conformance to freshness so its name matches
  its actual proof: it compares the shared-rules version marker and does not claim
  semantic conformance.
- Strengthened the commit hook to enforce Conventional Commit types, the 72-column
  limit, automated-author attribution prohibitions, and the em-dash rule.
- Made missing SwiftFormat or SwiftLint fail instead of silently weakening a commit
  that contains Swift files.
- Repaired stale repository-relative links and narrowed the shared-path exception
  in the folder-grouping rule so it no longer contradicts the default mandate.
- Scoped the Apple framework policy to Apple client/UI targets so it no longer
  contradicts the Swift Linux, Windows, WASM, and server rules.
- Normalized ExtremePackaging terminology and examples to the repository's
  one-package/many-targets architecture, removing impossible nested manifests.
- Classified the repository's `VERSION` marker as a conventional root filename and
  repaired the file-naming rule's non-Conventional commit example.
- Removed the dead GitHub workflow badge and documented the Forgejo fallback and
  local source of verification evidence.
- Moved the shell-only consumer freshness job from an unproven `macos` label to
  the repository's demonstrated `ubuntu-latest` Forgejo runner label.
- Flattened the sole consumer workflow template from the one-file `templates/`
  directory to `rules-freshness.yml` at the repository root.

## [1.1.2]

- **scripts/leak-gate.sh (.build exclusion):** all three scans and the file count now
  exclude `.build/` directories. Fetched dependency checkouts carry their own vendor
  names, absolute-path examples, and em dashes in documentation the repo does not own
  and git does not track; scanning them made the gate permanently red on any consumer
  with resolved dependencies, which trains readers to ignore it. Found by a rule-canon
  audit on 2026-07-04 where the gate failed consumers solely on `.build/checkouts/`
  markdown.

## [1.1.1]

- **scripts/leak-gate.sh (charter-file exception):** the vendor-name scan now excludes the
  two agent charter files at the repository ROOT, where the filename is the tool's
  addressing interface (function, not attribution). Root only; the same name in any nested
  file still fails, and the exception is fault-injection tested downstream. A permanently
  red gate trains readers to ignore it, which is worse than no gate.

## [1.1.0]

- **documentation.md Rule 0 (DocC scope):** DocC is packages-only (never apps), and only
  for packages that are public OR heavily used. Non-qualifying packages skip the DocC
  catalog entirely. Narrows the former "every project" framing.

A conformance pass brought the repository closer to agreement with its own rules.

### Added

- Vendored `core/oracle-first.md` from the engineering-discipline upstream: build the answer key (Oracle, comparison law, failure report, unsupported-case classification, parity gate) before any system or new correctness surface, including the "a codified expectation is a witness, not a verdict" guidance. Indexed in `core/README.md` and the README core-spine list.
- Acceptance check sections for the rule files that lacked one (per `core/rules.md`): `core/first-principles-analysis`, `core/systematic-debugging`, `concurrency`, `linux-server`, `ui/native-per-platform`, and the ExtremePackaging set (`exp/build-performance`, `exp/common-mistakes`, `exp/critical-rules`, `exp/dependency-management`, `exp/implementation-patterns`, `exp/package-swift`).
- Namespacing gate `scripts/check-namespacing.sh` (one non-private top-level type per file, per `code-style.md`), wired into the `pre-commit` hook and the gates CI workflow.
- GitHub issue forms (feature, bug) with required status/priority/complexity fields, a pull-request template, and an issue-priority labeler workflow, per `core/git-discipline.md`.
- README CI and license badges, and a License section.

### Fixed

- Broken cross-reference links in `CONVENTIONS.md` and `code-style.md`.

### Changed

- Label set trimmed to the brutal-minimum per `core/git-discipline.md` (added `epic` and `priority: high`; removed the decorative stock labels), with the Rule 2.3 semantic color palette.
- Synced the vendored core spine to the engineering-discipline upstream: `core/systematic-debugging.md` gains "Rule 6: Debugging against a differential or parity oracle" and two anti-patterns; `core/verification.md` and `core/git-discipline.md` gain the GitHub-hosted vs self-hosted CI runner escalation rule; `core/testing-discipline.md` gains the hosted-first runner note; `core/proof-discipline.md` and `core/no-shortcuts-first-principles.md` gain `oracle-first.md` cross-references. The local acceptance-check sections in `core/first-principles-analysis.md` and `core/systematic-debugging.md` are preserved.

## [1.0.0] - 2026-06-15

Initial public release of the Swift domain rules, built on the engineering-discipline core spine (vendored in `core/`).

### Added

- Where an app starts: `business-rules-and-constraints` (MANDATORY first artifact: business rules as explicit checkable statements, plus the constraints that bound them, which REST services, what compliance, which auth model) and `domain-first` (MANDATORY: start at the domain and business rules, framework-free and headless-provable; the UI framework is the last, reversible, and plural choice).
- Swift craft: `code-style`, `namespacing`, `dependency-injection`, `concurrency`, `cross-platform`, `linux-server`, `testing`, `formatting-and-linting`, `documentation`, `documentation-search`, `package-structure`, `package-architecture`, `package-import-contract`, `shared-protocols`.
- UI (`ui/`): `pre-ui-layer` (the display-less model seam, MANDATORY: Domain + Surface, one `perform(Intent)` channel, renderers the only UI import; one model drives the SwiftUI, AppKit, and UIKit renderers at once, both the architecture's payoff and a comparison instrument), `pom` (Page Object Model for UI tests), `flowspec` (declarative UI scenarios via the [FlowSpec](https://github.com/mihaelamj/FlowSpec) package), plus three renderers over the one model (`swiftui-views`, `uikit-views`, `appkit-views`), `view-models`, `components`, `colors`, `fonts`.
- Parsing and validation: `parsing-rules` and `validation-rules` (the OpenAPIKit idiom). Validation requires every public type to be validated or excluded with a reason, enforced mechanically.
- Apple-platform stance: `framework-policy` (Apple-only mandate), `openapi-generated`.
- Drop-in kit: `.gitignore`, `.swiftformat`, `.swiftlint.yml`, `.pre-commit-config.yaml`, and `.githooks/` (a `pre-commit` format-and-lint hook and a `commit-msg` attribution/em-dash check).
- Vendored `core/` spine: the cross-cutting engineering-discipline rules (incl. `round-trip-transformation`).
- Dual license: prose under CC BY 4.0, code under MIT.
