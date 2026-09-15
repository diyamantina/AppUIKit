# AppUIKit

The cross-framework namespace layer for imperative AppKit and UIKit UI code.

AppUIKit is **not** a UI framework. It is a thin abstraction: one set of `AppUI*` type aliases plus a few
semantic helpers, so a single source file can target macOS and iOS without an `#if` at every type reference.
Reusable controls and editor surfaces are deliberately outside this package.

## What it provides

- The **full** `AppUI*` type-alias set: views, windows, view controllers, the
  control and gesture families, containers, tables/outlines/collections, images, color, font, bezier path,
  alerts, menus, toolbars, drag and drop, navigation, pasteboard, appearance/trait, attributed strings, and
  the delegate/data-source protocols (`AppUIView`, `AppUIViewController`, `AppUIColor`, `AppUIFont`,
  `AppUIPanGestureRecognizer`, …). Each resolves to the AppKit type on macOS and the UIKit type on iOS.
- `AppUIKit.currentCGContext()`: the current Core Graphics context inside a view's `draw(_:)`, the one place
  the two frameworks differ.
- `AppUIKit.Colors`: semantic colors (backgrounds, separators, labels, fills, plus `contentBackground`,
  `accent`, and `keyboardFocusIndicator`).
- `AppUIKit.Fonts`: `monospaced`, `monospacedPreferred`, and `monospacedDigit`.
- `AppUIKit.ViewFactory`: constructors for labels, buttons, icon/pill buttons, separators, cards, scroll
  views, stacks, and image views (with `StackAxis` / `StackAlignment`).
- `AppUIKit.Pasteboard`, `AppUIKit.VisualEffects`, `AppUIKit.LayoutDirection`, `AppUIKit.TooltipHelper`,
  `AppUIKit.KeyboardShortcuts`, and `appui*` view/color convenience extensions.
- `isAppKit` / `isUIKit` platform flags.

`import AppUIKit` also re-exports the platform UI framework and Core Graphics, so a consumer drawing in a
control reaches `CGContext` and the rest through `import AppUIKit` alone, with no second import.

## Installation

```swift
.package(url: "https://github.com/diyamantina/AppUIKit.git", from: "0.1.9"),
```

```swift
.target(name: "YourTarget", dependencies: ["AppUIKit"])
```

## Platforms

| Platform | Minimum |
|---|---|
| macOS | 14 |
| iOS | 17 |

## Rules

This package follows the canonical `rules-swift` rule set, vendored in snapshot mode under
`third_party/rules-swift`; see `AGENTS.md`. Formatting, linting, and
commit hygiene are enforced by `.githooks/` (install per clone with `scripts/install-hooks.sh`).

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

Proprietary. Copyright (c) 2026 Mihaela Mihaljevic. All rights reserved. The
source is published for reference and educational reading only. See
[LICENSE](LICENSE).
