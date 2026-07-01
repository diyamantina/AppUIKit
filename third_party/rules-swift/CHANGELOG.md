# Changelog

All notable changes to this rule set are documented here. This project follows Semantic Versioning.

## [Unreleased]

A conformance pass bringing the repository into agreement with its own rules.

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
