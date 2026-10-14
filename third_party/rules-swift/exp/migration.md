# Migration Patterns

Extracting code into a new target; splitting a large target.

### Extracting Code to New Target

```bash
# 1. Create new target structure
mkdir -p Sources/NewPackage
mkdir -p Tests/NewPackageTests

# 2. Move files
git mv OldPackage/SomeFeature.swift NewPackage/

# 3. Update Package.swift
# Add new target and product

# 4. Update imports in dependent files
# Change: import OldPackage
# To: import NewPackage

# 5. Rebuild
swift build

# 6. Run tests
swift test --filter NewPackageTests
```

### Splitting Large Package

```swift
// Before: Large "Features" target
Features/
├── Auth/
├── Profile/
└── Settings/

// After: Separate feature targets
AuthFeature/
ProfileFeature/
SettingsFeature/
```

## Acceptance check

A target extraction or split conforms when the manifest declares every new source
and matching test target, old imports and paths grep to zero, dependency edges
remain unidirectional, each new target passes its portability or lift-out check,
and both `swift build` and the full `swift test` suite pass. Run the repository's
format, lint, package-purity, and documentation gates before calling the migration
complete.
