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
- Text view helpers (`AppUITextView+Text.swift`): the text, the selection, the storage, a setup for editing code, the person's edits, and a scrolling text view (`appuiString`, `appuiSelectedRange`, `appuiTextStorage`, `appuiConfigureForCode(font:)`, `appuiObserveEdits(_:)`, `appuiMakeScrolling()`).
- Chrome helpers for code written once against the aliases: a control's primary action and tooltip
  (`appuiSetPrimaryAction(target:action:)`, `appuiToolTip`), a label's text and line limit (`appuiText`,
  `appuiMaximumLines`, `appuiConfigureAsLabel()`), a segmented control's segments and selection
  (`appuiSetSegments(_:)`, `appuiSelectedSegment`), a button's symbol and pressed state (`appuiSetSymbol(_:description:)`,
  `appuiIsSelected`, `appuiMakeToggle()`, `appuiMakeBorderless()`), an image view's tint (`appuiContentTintColor`), a
  view's opacity (`appuiAlpha`) and a stack's insets (`appuiEdgeInsets`).
- `isAppKit` / `isUIKit` platform flags.

## The canvas view

`AppUICanvas` is one layer-backed view that hosts a `CACanvas.Surface` (from the sibling CAControls package, which only displays) and reports what a person does to it: `samples`, one ordered stream of pointer samples (mouse, finger, pen; coalesced and predicted touches on UIKit, in that order), and `hit(at:)`, which answers a handle first and then the items under a point. The display scale follows the window and layout sizes the surface without animation. The article *The canvas view* in the DocC catalog has the rules and the limits.

## Drawing at runtime

The article *Drawing at runtime* in the DocC catalog (`Sources/AppUIKit/AppUIKit.docc/DrawingAtRuntime.md`) explains
how to draw content that changes live on AppKit and UIKit with this layer: turning off the implicit animations of
the layers you create, drawing from `draw(_:)` and not from an event handler, redrawing only the dirty rectangle,
flattening committed content, what costs a frame, keeping the main run loop free and scrolling through the scroll
view, and measuring. Each lesson names its source and whether it has been verified by a test here.

`import AppUIKit` also re-exports the platform UI framework and Core Graphics, so a consumer drawing in a
control reaches `CGContext` and the rest through `import AppUIKit` alone, with no second import.

## Installation

```swift
.package(url: "https://github.com/diyamantina/AppUIKit.git", from: "0.2.0"),
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
`third_party/rules-swift` (start at its `README.md`); the audit of this package against that
rule set is `docs/rules-swift-audit.md`. Formatting, linting, and
commit hygiene are enforced by `.githooks/` (install per clone with `scripts/install-hooks.sh`).

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

Proprietary. Copyright (c) 2026 Mihaela Mihaljevic. All rights reserved. The
source is published for reference and educational reading only. See
[LICENSE](LICENSE).
