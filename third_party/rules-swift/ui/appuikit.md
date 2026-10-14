# AppUIKit: imperative AppKit and UIKit code goes through the cross-framework layer

**Status: MANDATORY for every AppKit or UIKit renderer, feature, and app shell, in every app.** Imperative AppKit and UIKit code imports `AppUIKit` and names its `AppUI*` types. It never types an `NS` or `UI` UI type of its own and never imports `AppKit` or `UIKit` directly. When the layer lacks an alias or a helper the code needs, the component is added to the layer first, then used.

AppUIKit is the sibling package that is the cross-framework namespace for imperative AppKit and UIKit code: one `AppUI*` alias for each type both frameworks have (`AppUIView`, `AppUIViewController`, `AppUITableView`, `AppUISplitViewController`, `AppUIToolbar`, `AppUIApplicationDelegate`, ...), a few semantic helpers (colors, fonts, the current graphics context, accessibility identifiers, SF Symbols), and a re-export of the platform framework and Core Graphics, so `import AppUIKit` alone reaches both. It is a naming layer, not a UI framework.

## Why

- **One name, one place.** A type reference reads the same on macOS and iOS, so shared logic (a status line, a persona control, a tool palette, a layer row) is written once, and the `#if canImport` noise stays inside the layer instead of at every call site.
- **A missing piece is fixed once.** An alias or helper that one app lacks is added to the layer and every app gains it; the alternative is each app typing the platform name and drifting.
- **It does not change what is native.** This rule governs how types are *named*, not what the UI looks like. `native-per-platform.md` still decides the shape of the interface per device: a menu bar and split columns on the Mac, one-handed bars on the iPhone. The renderer for each SDK is still its own, over the same framework-free model (`pre-ui-layer.md`). SwiftUI code does not use the layer.

## Rules

1. **Import.** An AppKit or UIKit renderer, feature, or shell target imports `AppUIKit`. A direct `import AppKit` or `import UIKit` is a violation (the layer re-exports them).
2. **Names.** In those targets no `NS`-prefixed or `UI`-prefixed UI type is written. Use the alias: `AppUIView`, not `NSView` or `UIView`; `AppUIMenu`, not `NSMenu` or `UIMenu`; `AppUIApplicationDelegate`, not `NSApplicationDelegate` or `UIApplicationDelegate`. Use the layer's helper where one exists: `AppUIKit.currentCGContext()` for the drawing context, `AppUIImage.appUISymbol(_:description:)` for an SF Symbol, `setAXIdentifier(_:)` for an accessibility identifier.
3. **Foundation names are not UI types.** `NSObject`, `NSString`, `NSNumber`, `NSError`, `NSLock`, `NSNotification`, `NSData`, `NSURL`, `NSDate`, and the like are Foundation and are fine. A project keeps this list short and checked in with its gate.
4. **A missing component is added, not worked around.** If the layer has no alias or helper for what the code needs, add it to the layer (a one-line alias, with its test and changelog entry, on both frameworks where both have the type; on the one that has it where only one does), publish it, and then use it. Do not type the platform name "just this once", and do not write a private alias in the app.
5. **Where the two frameworks genuinely differ, the code differs.** A split view controller, a toolbar, a table's data source, and event handling are not the same API in AppKit and UIKit; the alias names the type, the code around it is platform code in its own target. The layer does not paper over that and this rule does not ask it to.
6. **Out of scope.** The strings of a property list or a project manifest (`UIApplicationSceneManifest`, `UISceneConfigurations`, and so on) are keys, not types, and stay as they are. The rule applies to Swift source of AppKit and UIKit targets, not to the layer itself, which is where the platform names live.

## Acceptance check

A gate, not a review. Run from the repository root, with `TARGETS` the directories of the AppKit and UIKit renderer, feature, and shell targets; both commands must print nothing:

```sh
# 1. no direct import of the platform framework
grep -rnE '^[[:space:]]*(@preconcurrency[[:space:]]+)?import (AppKit|UIKit)$' $TARGETS --include='*.swift'

# 2. no NS or UI type named (the tokens only; the framework name itself, Foundation names, and the module's own UIKit*/AppKit* names excepted)
grep -rnoE '\b(NS|UI)[A-Z][A-Za-z0-9]*' $TARGETS --include='*.swift' \
  | grep -vE ':(NSObject|NSObjectProtocol|NSString|NSNumber|NSError|NSLock|NSNotification|NSData|NSURL|NSDate|UIKit[A-Za-z0-9]*|AppKit[A-Za-z0-9]*)$'
```

A project promotes the second command to a build-failing script with a self-test (a fixture that names `UIView` after `import AppUIKit` must fail it; a fixture that names only `AppUIView` and `NSObject` must pass it), the same way `pre-ui-layer.md` requires the UI-import boundary to be mechanical. The check passes only when both are empty and every alias the code uses resolves to a type on both frameworks it is used on.

Cross-references: `pre-ui-layer.md` (the renderer is the only code that imports a UI framework; this rule says how it names the SDK), `native-per-platform.md` (what the interface is; this rule is only how it is spelled), `appkit-views.md`, `uikit-views.md`.
