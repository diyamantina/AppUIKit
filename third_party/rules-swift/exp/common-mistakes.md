# Common Mistakes to Avoid

Anti-patterns paired with the canonical fix. Mini-DOs are inline; full canonical forms live in `package-swift.md` (closure-with-locals), `testing.md` (test-target placement), and `implementation-patterns.md` (Pattern 6 for fonts).

### ❌ DON'T: Create God Targets

```swift
// WRONG: "Shared" target with everything
Packages/Sources/Shared/
├── Models/
├── Views/
├── Networking/
├── Database/
└── Utilities/
```

✅ **DO:** Split into focused targets
```
Packages/Sources/
├── SharedModels/
├── SharedViews/
├── NetworkClient/
├── DatabaseClient/
└── SharedUtilities/
```

### ❌ DON'T: Circular Dependencies

```swift
// WRONG
AuthFeature depends on AppFeature
AppFeature depends on AuthFeature
```

✅ **DO:** Extract shared code
```swift
AuthFeature depends on SharedAuthModels
AppFeature depends on SharedAuthModels
```

### ❌ DON'T: Inline `deps`, `allProducts`, or `targets` arrays

```swift
// WRONG: inline definitions
let deps: [Package.Dependency] = [
    .package(url: "...", from: "1.10.3"),
    .package(url: "...", from: "1.8.3"),
    // ... dozens more
]

let allProducts: [Product] = [
    .library(name: "ApiShared", targets: ["ApiShared"]),
    .library(name: "ApiClient", targets: ["ApiClient"]),
    // ... many more
]

let targets: [Target] = [
    Target.target(name: "SharedModels", dependencies: []),
    Target.testTarget(name: "SharedModelsTests", dependencies: ["SharedModels"]),
    // ... more inline
]
```

✅ **DO:** closure-with-local-variables pattern, grouped by purpose / layer / platform. Mini-shape for each array:

```swift
// deps
let deps: [Package.Dependency] = {
    // OpenAPI stack
    let openAPIRuntimeDep = Package.Dependency.package(url: "...", from: "1.8.3")
    // Vapor stack
    let vaporDep          = Package.Dependency.package(url: "...", from: "4.119.0")
    return [openAPIRuntimeDep, vaporDep]
}()

// allProducts
let allProducts: [Product] = {
    let apiSharedProduct = Product.singleTargetLibrary("ApiShared")
    let apiClientProduct = Product.singleTargetLibrary("ApiClient")
    return [apiSharedProduct, apiClientProduct]
}()

// targets
let targets: [Target] = {
    // foundation
    let sharedModelsTarget = Target.target(name: "SharedModels", dependencies: [])
    let foundationTargets  = [sharedModelsTarget]
    // api
    let apiClientTarget    = Target.target(name: "ApiClient", dependencies: ["SharedModels"])
    let apiTargets         = [apiClientTarget]
    return foundationTargets + apiTargets
}()
```

Full forms (with platform splits, helper extensions, every dep / product / target spelled out) in `package-swift.md` (Dependencies Definition, Product Definition, Target Organization).

### ❌ DON'T: Skip Test Targets

Every source target MUST ship with a matching `Target.testTarget(name:
"<name>Tests", dependencies: ["<name>"])`, grouped as a pair with the source
target in a named sub-array. See `testing.md > TEST TARGET PLACEMENT` for the
canonical form, folder layout, and the rule that mocks live in the test target
rather than the source target.

### ❌ DON'T: Transitive Dependencies

```swift
// WRONG: Relying on ApiClient importing SharedModels
import ApiClient
// Using User from SharedModels without importing it
```

✅ **DO:** Explicit imports
```swift
import ApiClient
import SharedModels  // Explicit dependency
```

### ❌ DON'T: Feature-to-Feature Dependencies

```swift
// WRONG: Features depending on each other
let appFeatureTarget = Target.target(
    name: "AppFeature",
    dependencies: [
        "AuthFeature",      // ❌ Feature depending on feature
        "ProfileFeature",   // ❌ Creates tight coupling
    ]
)
```

✅ **DO:** Coordinator pattern or shared protocols
```swift
// Extract navigation/coordination to AppFeature (parent)
// Child features (Auth, Profile) depend on parent's protocols
let authFeatureTarget = Target.target(
    name: "AuthFeature",
    dependencies: [
        "SharedModels",
        "AppCoordination",  // ✅ Protocol target
    ]
)
```

### ❌ DON'T: Use Info.plist for Font Registration in SwiftPM Targets

Three anti-patterns, all covered by `implementation-patterns.md > Pattern 6 (Font/Resource Target)`:

- `UIAppFonts` / `ATSApplicationFontsPath` in Info.plist: doesn't work for SwiftPM target resources
- `.copy("Fonts")` in `Package.swift` resources: breaks `Bundle.module` lookup
- `Bundle.main.urls(...)` inside the target: wrong bundle for SwiftPM resources

DO: `.process("Fonts")` in resources, `CTFontManagerRegisterFontsForURL` against `Bundle.module`, called from app init before any UI renders. Full implementation in `implementation-patterns.md > Pattern 6`.

## Acceptance check

Each anti-pattern above is mechanically checkable; the fixes are conforming when:

- **No inline top-level arrays.** The three top-level manifest arrays use the closure-with-local-variables form, never a bare array literal:

```bash
MANIFEST=Package.swift
[ -f "$MANIFEST" ] || MANIFEST=Packages/Package.swift
grep -nE 'let (deps|allProducts|targets)[^=]*=[[:space:]]*\[' "$MANIFEST"
```

  Output MUST be empty (each should read `let deps: [...] = {`), per the closure-with-locals fix.

- **No Info.plist font registration in SwiftPM targets.** Targets register fonts via CoreText, never the plist keys or `.copy("Fonts")`:

```bash
grep -rnE 'UIAppFonts|ATSApplicationFontsPath|\.copy\("Fonts"\)' Packages/
```

  Output MUST be empty (use `.process("Fonts")` + `CTFontManagerRegisterFontsForURL` against `Bundle.module`, Pattern 6).

- **Every source target has a matching test target.** For each `Target.target(name: "X")` there is a `Target.testTarget(name: "XTests")`. List the names and confirm no source target lacks its pair:

```bash
PACKAGE_ROOT=.
[ -f Package.swift ] || PACKAGE_ROOT=Packages
swift package --package-path "$PACKAGE_ROOT" describe --type json | jq -r '
  .targets as $targets
  | [$targets[] | select(.type == "test") | .name] as $tests
  | $targets[]
  | select(.type == "library" or .type == "executable")
  | . as $source
  | select(($tests | index($source.name + "Tests")) == null)
  | .name
'
```

  Output MUST be empty. Every source target name has a corresponding
  `<name>Tests` target.

  `swift package describe` names a library target `library`; the value `regular` belongs to
  `dump-package` and never occurs in this output, so a filter on it checks no library at all
  and passes whatever the package holds. To prove the command is not vacuous, count what it
  selects: the number of `library` and `executable` targets MUST equal the number of source
  targets the manifest declares.

- **Observable checklist** for the structural anti-patterns no grep settles, each a clear pass/fail: no "god target" mixing unrelated concerns (Models, Views, Networking, Database under one target); no circular dependency between two targets (the graph is a DAG); no feature target lists another feature target as a dependency (coordination goes through a parent/protocol target); and every cross-target symbol use has an explicit `import` of the module that declares it, never a reliance on a transitive import.
