# Testing Patterns (Architecture Angle)

ExtremePackaging-specific testing concerns: per-package test target, cross-package test doubles. Full Swift Testing rules live in `testing.md` (the top-level rule). Both files state the per-package-test-target rule, by deliberate cross-context dual-homing.

Full Swift Testing rules live in `testing.md`. Two ExtremePackaging-specific points:

**Per-package test target.** Every source target ships with a matching test target. Run a single package in isolation:

```bash
cd <active-package-root>
swift test --filter <PackageName>Tests
```

Folder layout: `Sources/<Package>/` and `Tests/<Package>Tests/` in package repos; `Packages/Sources/<Package>/` and `Packages/Tests/<Package>Tests/` in project monorepos.

**Cross-package test doubles.** Mocks live in the test target, not the source package. Public protocols can be defined in the source package; their mock implementations stay in `Tests/<Package>Tests/Mocks/` or `Packages/Tests/<Package>Tests/Mocks/`, matching repository shape. Never publish mocks from `Sources/` (they leak into production binaries).

```swift
// Sources/ApiClient/APIClientProtocol.swift
public protocol APIClientProtocol {
    func login(email: String, password: String) async throws -> User
}

// Tests/ApiClientTests/Mocks/MockAPIClient.swift
public struct MockAPIClient: APIClientProtocol { /* ... */ }
```
