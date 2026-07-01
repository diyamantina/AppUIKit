# Package and Repository Structure

Choose the repository shape before adding targets. A Swift package repository is
an SPM-consumable package at the repository root. A project repository is a
monorepo that hosts one package plus one or more app projects. Do not mix the two
shapes casually.

## What this covers

This rule covers two allowed shapes:

- **Package repository:** a reusable package or CLI that another project can add
  as a SwiftPM dependency by pointing at the repository URL. It has a root
  `Package.swift`, root `Sources/`, root `Tests/`, and no `Apps/` or
  `.xcworkspace`.
- **Project monorepo:** an app/product repository that needs Xcode app projects,
  workspace settings, signing, entitlements, or multiple app targets. It has
  `Main.xcworkspace`, `Packages/Package.swift`, `Packages/Sources/`,
  `Packages/Tests/`, and `Apps/`.

Both shapes use one manifest for all library, executable, and test targets in
that repository. Add targets when a responsibility becomes separable, reuse
appears, isolated compilation matters, or a second front door appears.

## Core Rules

### Rule 1: Pick exactly one repository shape

Use package repository shape for reusable libraries, reusable CLIs, compilers,
parsers, semantic engines, validators, and other code products meant to be
consumed by SwiftPM.

Use project monorepo shape for shipping GUI apps or product repositories that
need Xcode project settings a plain SwiftPM executable target cannot express.

Do not leave a package repo half-converted: no root `Package.swift` plus nested
`Packages/Package.swift`, no orphaned `Main.xcworkspace`, and no empty `Apps/`.

### Rule 2: Package repository root structure

Package repositories use this top-level structure:

- `Package.swift` for all products and targets
- `Sources/` for all library and executable targets
- `Tests/` for all test targets
- `docs/` for documentation
- `scripts/` for local validation helpers, when needed

Forbidden in package repositories:

- `Main.xcworkspace`
- `Apps/`
- `Packages/Package.swift`
- `Packages/Sources/` or `Packages/Tests/` as the primary source tree

### Rule 3: Project monorepo root structure

Project monorepos use this top-level structure:

- `Main.xcworkspace` containing all projects
- `Packages/` for the single SPM package with all library and CLI targets
- `Apps/` for app targets that ship a UI
- `docs/` for documentation
- `scripts/` for local validation helpers, when needed

The workspace hosts `Packages/Package.swift` and any `Apps/*/*.xcodeproj`. CLI
executable targets stay inside the single `Package.swift`; `Apps/` is for app
targets that need Xcode project settings.

### Rule 4: Single Package.swift

Use one active `Package.swift` for all Swift targets in the repository:

- In a package repo, it is `Package.swift` at the repository root.
- In a project monorepo, it is `Packages/Package.swift`.
- It contains all library targets and products.
- It contains CLI executable targets.
- It contains all test targets.
- It uses `#if os()` for platform-specific manifest branches.

Do not split the targets into one manifest per library. A single manifest keeps
the dependency graph in one readable place.

### Rule 5: Apps as separate projects in project monorepos

App targets are separate Xcode projects in `Apps/`:

- Each app has its own `.xcodeproj`.
- Apps import the package as a local SwiftPM dependency.
- This enables signing, entitlements, asset catalogs, and app configurations.
- It supports multiple platforms per app.

The CLI executable target stays inside the single `Package.swift`. Use `Apps/`
only for app targets that need Xcode project settings.

### Rule 6: Workspace references for project monorepos

Add every project to the workspace: the `Packages/` SPM package, each
`Apps/*/*.xcodeproj`, and the docs/README files.

### Rule 7: No storyboards or XIBs

For any UI you add, do not use Interface Builder artifacts:

- NO `.storyboard` files.
- NO `.xib` files.
- ALL UI is created in code (SwiftUI or programmatic UIKit/AppKit).
- Delete any auto-generated storyboards from Xcode templates.

### Rule 8: UI code lives in packages

Keep views and view controllers in package targets, not in app targets:

- SwiftUI views in feature packages.
- UIKit/AppKit views in a dedicated UI package.
- App targets contain ONLY entry points (`AppDelegate`, `SceneDelegate`, `@main`).

## Package Repository Layout

```
PackageRepo/
├── Package.swift                  # All products and targets
├── Package.resolved               # Tracked when dependencies are resolved
├── Sources/
│   ├── PackageCore/
│   ├── PackageCLI/
│   └── ...
├── Tests/
│   ├── PackageCoreTests/
│   └── ...
├── docs/
├── scripts/
└── README.md
```

## Project Monorepo Layout

```
ProjectRoot/
├── Main.xcworkspace/              # Hosts the package and Apps/ projects
│   └── contents.xcworkspacedata
├── Packages/
│   ├── Package.swift              # All package products and targets
│   ├── Package.resolved
│   ├── Sources/
│   │   ├── ProjectCore/
│   │   ├── ProjectCLI/
│   │   └── ...
│   └── Tests/
│       ├── ProjectCoreTests/
│       └── ...
├── Apps/
│   └── ProjectApp/
│       ├── ProjectApp.xcodeproj/
│       └── ProjectApp/
├── docs/
├── scripts/
└── README.md
```

## Package.swift structure (many targets in one package)

Use helper-driven, grouped target declarations rather than one giant inline array.

### Platform-specific products

```swift
// swift-tools-version: 6.2
import PackageDescription

// ---------- Base Products (All Platforms) ----------
let baseProducts: [Product] = [
    .singleTargetLibrary("TileKit"),
    .singleTargetLibrary("TileCore"),
    .executable(name: "tile-down", targets: ["TileDownCLI"]),
]

// ---------- Apple-Only Products ----------
#if os(iOS) || os(macOS)
let appleOnlyProducts: [Product] = [
    .singleTargetLibrary("TileUI"),
]
#else
let appleOnlyProducts: [Product] = []
#endif

let allProducts = baseProducts + appleOnlyProducts

extension Product {
    static func singleTargetLibrary(_ name: String) -> Product {
        .library(name: name, targets: [name])
    }
}
```

### Target organization pattern

```swift
let targets: [Target] = {
    // ---------- Foundation Layer ----------
    let tileCoreTarget = Target.target(
        name: "TileCore",
        dependencies: []
    )
    let tileCoreTestsTarget = Target.testTarget(
        name: "TileCoreTests",
        dependencies: ["TileCore"]
    )
    let foundationTargets = [tileCoreTarget, tileCoreTestsTarget]

    // ---------- Library Layer ----------
    let tileKitTarget = Target.target(
        name: "TileKit",
        dependencies: ["TileCore"]
    )
    let libraryTargets = [tileKitTarget]

    return foundationTargets + libraryTargets
}()
```

## App configuration (only if a GUI app is added)

### Removing storyboard references

When you create a new Xcode app project, remove all storyboard configuration.

iOS (UIKit):

1. Delete `Main.storyboard` and `LaunchScreen.storyboard`.
2. Remove the `UIMainStoryboardFile` and `UILaunchStoryboardName` keys from `Info.plist`.
3. Configure the scene manifest with a `UISceneDelegateClassName` and no `UISceneStoryboardFile` key.
4. Provide a launch screen via the `UILaunchScreen` plist dictionary instead of a storyboard.
5. Clear the storyboard build-setting fields.

macOS (AppKit):

1. Delete `Main.storyboard` / `MainMenu.xib`.
2. Remove `NSMainStoryboardFile` and `NSMainNibFile` from `Info.plist`.
3. Set `NSPrincipalClass` to `NSApplication`.
4. Clear the Main Interface build setting.
5. Provide a `main.swift` (AppKit without a storyboard needs an explicit entry point, no `@main`):

```swift
import Cocoa

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
```

macOS (SwiftUI):

1. Delete any `.storyboard` / `.xib` files.
2. Use a `@main` `App` struct. No storyboard keys are needed.

### Build menus in code

For AppKit apps, build the `NSMenu` programmatically in the app delegate rather than using `MainMenu.xib`.

## Native UI patterns (AppKit / UIKit)

If you add a UIKit/AppKit UI package, use platform typealiases and factory entry points so the app target stays minimal:

```swift
#if os(macOS)
import AppKit
public typealias PlatformViewController = NSViewController
public typealias PlatformView = NSView
public typealias PlatformColor = NSColor
#elseif os(iOS)
import UIKit
public typealias PlatformViewController = UIViewController
public typealias PlatformView = UIView
public typealias PlatformColor = UIColor
#endif
```

```swift
public enum NativeUI {
    #if os(macOS)
    @MainActor
    public static func createWindowController() -> NSWindowController {
        NativeWindowController()
    }
    #endif
}
```

The app target then just wires the factory:

```swift
// SceneDelegate (iOS)
window = NativeUI.createMainWindow(for: windowScene)  // all UI from the package
```

## When to create a new app target

Create a new app target when:

- A different backend endpoint is needed (local, staging, production).
- A different platform is targeted (iOS, macOS).
- A different app variant ships (lite, pro).
- A different testing mode is needed (offline, mock data).

Do NOT create a new app target when:

- You only need Debug vs Release (use build configurations).
- You only need a different bundle ID (use build settings).
- You only have a feature-flag difference (use runtime flags).

## Common mistakes

- Do NOT leave `Packages/Package.swift` in a package repository. The manifest lives at the repository root.
- Do NOT leave `Main.xcworkspace` or `Apps/` in a package repository. Those are project monorepo artifacts.
- Do NOT put app executable targets for shipping GUI apps in `Package.swift` when they need real Xcode project settings. A plain CLI executable target is fine in `Package.swift`.
- Do NOT create multiple active `Package.swift` files, one per library. Use a single manifest.
- Do NOT put business logic, view models, services, or models in an app target. They belong in package targets under the active source tree.
- Do NOT keep `.storyboard` or `.xib` files anywhere.
- Do NOT keep view controllers in the app target. Move them into a package.

## Checklist

Before changing repo structure:

- [ ] Repository shape is explicitly package repo or project monorepo
- [ ] Package repo has root `Package.swift`, root `Sources/`, root `Tests/`
- [ ] Package repo has no `Main.xcworkspace`, no `Apps/`, no nested `Packages/Package.swift`
- [ ] Project monorepo has `Main.xcworkspace`, `Packages/Package.swift`, `Packages/Sources/`, `Packages/Tests/`
- [ ] Project monorepo GUI apps, if any, are separate `.xcodeproj` projects in `Apps/`
- [ ] Apps import the package via a local dependency
- [ ] Single active SPM package manifest for all targets
- [ ] Platform-specific targets use `#if os()`
- [ ] App targets contain entry points only
- [ ] Business logic stays in packages, not apps
- [ ] No `.storyboard` or `.xib` files anywhere
- [ ] macOS AppKit apps have `main.swift` (not `@main`)
- [ ] SwiftUI apps use a `@main` `App` struct

## Related rules

- [package-architecture.md](package-architecture.md): single-responsibility packages, layers, and the when-to-create decision tree
- [package-import-contract.md](package-import-contract.md): what each target may import
- [shared-protocols.md](shared-protocols.md): the cross-target protocol-seam package
