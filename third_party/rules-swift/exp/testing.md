# Testing Patterns (Architecture Angle)

ExtremePackaging-specific testing concerns: per-source-target test targets and
cross-target test doubles. Full Swift Testing rules live in `testing.md` (the
top-level rule). Both files state the source-target/test-target pairing rule by
deliberate cross-context dual-homing.

Full Swift Testing rules live in `testing.md`. Two ExtremePackaging-specific points:

**Per-source-target test target.** Every source target ships with a matching test
target. Run a single target's tests in isolation:

```bash
cd <active-package-root>
swift test --filter <PackageName>Tests
```

Folder layout: `Sources/<Package>/` and `Tests/<Package>Tests/` in package repos; `Packages/Sources/<Package>/` and `Packages/Tests/<Package>Tests/` in project monorepos.

**Cross-target test doubles.** Mocks live in the test target, not the source
target. Public protocols can be defined in the source target; their mock
implementations stay in `Tests/<Target>Tests/Mocks/` or
`Packages/Tests/<Target>Tests/Mocks/`, matching repository shape. Never publish
mocks from `Sources/` (they leak into production binaries), except in a declared
test-support target that the gate checks (`testing.md`, section "Exception: test-support
targets").

```swift
// Sources/ApiClient/APIClientProtocol.swift
public protocol APIClientProtocol {
    func login(email: String, password: String) async throws -> User
}

// Tests/ApiClientTests/Mocks/MockAPIClient.swift
public struct MockAPIClient: APIClientProtocol { /* ... */ }
```

## Acceptance check

Compare every source target in `Package.swift` with the test targets: each source
target MUST have exactly one `<SourceTarget>Tests` partner that depends on it. Grep
production `Sources/` for test-double names and confirm mocks live only under the
matching test target. Run each new target's filtered tests once, then run the full
suite and cite the total count.
