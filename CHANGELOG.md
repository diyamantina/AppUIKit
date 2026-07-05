# Changelog

All notable changes to AppUIKit are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- A DocC documentation catalog (`Sources/AppUIKit/AppUIKit.docc`) with a curated
  landing page for the library, built via the Swift-DocC plugin
  (`swift package generate-documentation`).

### Changed

- `LayoutDirectionManager`, `ConnectionPointCalculator`, and
  `DirectionalSymbols` moved out of `AppUIKit.LayoutDirection.swift` into their
  own files (one non-private type per file). No behavior change.
- The rules-swift CI lane now runs the full strict gate as a required step; the
  README and CONTRIBUTING rules sections point at the vendored
  `third_party/rules-swift` snapshot.

## [0.1.9] - 2026-07-01

### Added

- `AppUIKit.Colors.keyboardFocusIndicator`, a platform semantic color for focus
  rings.

### Changed

- README installation now points at the public Codeberg repository.

## [0.1.8] - 2026-06-27

### Changed

- Public package wording no longer refers to legacy replacement packages or
  SlayerMotion ownership, so the package reads as reusable by anyone.

## [0.1.7] - 2026-06-27

### Added

- Published an explicit source-available proprietary license.

### Changed

- Public README wording now keeps reusable controls and editor surfaces outside
  the package boundary.

## [0.1.6] - 2026-06-27

### Added

- `AppUITopLeftView`, a subclassable top-left container with a shared `didLayout()`
  hook, appearance-change hook, and `backingLayer` accessor.
- `AppUIInteractiveView` and `AppUICursor`, giving AppKit and UIKit controls one
  input seam for press, hover, scroll, and cursor behavior.
- `makeDisplayLink`, a cross-platform display-link helper for frame-following
  animation.
- `AppUIViewRepresentable`, a SwiftUI representable alias that resolves to the
  platform view representable when SwiftUI is available.
- Text sharing helpers with a pasteboard fallback for detached views.

### Changed

- Layer-backed view color helpers now resolve semantic colors against the view's
  current appearance before assigning layer colors.
- `AppUITopLeftView.didLayout()` is driven from AppKit frame-size changes as well
  as normal layout, matching UIKit's frame-driven behavior more closely.

## [0.1.3] - 2026-06-25

### Changed

- **Breaking:** the cross-platform alias prefix is now `AppUI*` (was `NSUI*`), so the
  names match the package: `AppUIView`, `AppUIColor`, `AppUIStepper`, and so on. The
  convenience extension members are likewise `appui*` (was `nsui*`). Pre-1.0, so no
  deprecation shims.

### Added

- AppUIKit re-exports Core Graphics, so a consumer reaches `CGContext`, `CGRect`, and
  the rest through `import AppUIKit` alone, with no second import and no platform `#if`.
- More shared-type aliases (each has a real counterpart on both frameworks):
  `AppUIStepper`, `AppUIDatePicker`, `AppUIProgressIndicator`, `AppUICollectionView`
  (and its delegate/data-source), `AppUIFontDescriptor`,
  `AppUIGestureRecognizerDelegate`, `AppUIRotationGestureRecognizer`, `AppUIStoryboard`,
  `AppUINib`, `AppUILayoutGuide`, `AppUIAccessibilityElement`.
- Community-health docs: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` (Contributor
  Covenant 2.1), and `SECURITY.md`.

### Removed

- The redundant `AppUIApp` accessor and `AppUIGraphicsGetCurrentContext()` free
  function (use `NSApp` directly, and `AppUIKit.currentCGContext()`).

## [0.1.2] - 2026-06-25

### Added

- The full helper surface under the `AppUIKit`/`NSUI*` scheme:
  `AppUIKit.ViewFactory` (label/button/icon/pill/separator/card/scroll/stack/
  image-view constructors, plus `StackAxis`/`StackAlignment`), `AppUIKit.Pasteboard`,
  `AppUIKit.VisualEffects`, `AppUIKit.LayoutDirection`, `AppUIKit.TooltipHelper`,
  `AppUIKit.KeyboardShortcuts`, and the `nsui*` view/color convenience extensions.
- `AppUIKit.Colors` expanded to the full set (backgrounds, separators, labels, fills),
  keeping `accent` and `contentBackground`. `AppUIKit.Fonts` gains `monospaced` and
  `monospacedPreferred` alongside `monospacedDigit`.

## [0.1.1] - 2026-06-25

### Added

- The **complete** `NSUI*` type-alias set under the `NSUI*` prefix: windows,
  panels, tables/outlines/collections, toolbars, menus,
  drag and drop, alerts, navigation, document picker, appearance/trait, tracking,
  clip view, attributed strings, the full control and gesture families, and the
  delegate/data-source protocol aliases, for both the AppKit and UIKit branches.
- `NSUIApp` (the shared application instance) and the free function
  `NSUIGraphicsGetCurrentContext()`.

## [0.1.0] - 2026-06-25

Initial release: the cross-framework namespace layer for imperative AppKit and
UIKit UI code.

### Added

- `NSUI*` type aliases for the common view, control, container, image, color, font,
  event, and gesture types, resolving to the AppKit type on macOS and the UIKit type
  on iOS.
- `AppUIKit.currentCGContext()` for the one place AppKit and UIKit differ inside
  `draw(_:)`.
- `AppUIKit.Colors` semantic colors (label, secondaryLabel, tertiaryLabel, separator,
  background, contentBackground, accent).
- `AppUIKit.Fonts.monospacedDigit` for numeric readouts.
- `isAppKit` / `isUIKit` platform flags, and a re-export of the platform UI framework.
- Adopted the `rules-swift` enforcement set (`.swiftformat`, `.swiftlint.yml`,
  `.githooks/`).
