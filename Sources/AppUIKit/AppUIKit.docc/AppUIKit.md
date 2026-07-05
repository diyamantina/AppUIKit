# ``AppUIKit``

The cross-framework namespace layer for imperative AppKit and UIKit UI code.

## Overview

AppUIKit is deliberately not a UI framework. It is a thin abstraction: one full set of
`AppUI*` type aliases plus a few semantic helpers, so a single source file can target
macOS and iOS without an `#if` at every type reference. Each alias resolves to the
AppKit type on macOS (`AppUIView` is `NSView`) and to the UIKit type on iOS
(`AppUIView` is `UIView`).

`import AppUIKit` also re-exports the platform UI framework and Core Graphics, so a
consumer drawing in a control reaches `CGContext` and the rest through a single import.
Reusable controls and editor surfaces live downstream, outside this package.

## Topics

### The namespace

- ``AppUIKit/AppUIKit``
- ``isAppKit``
- ``isUIKit``

### Core aliases

- ``AppUIView``
- ``AppUIViewController``
- ``AppUIColor``
- ``AppUIFont``
- ``AppUIImage``
- ``AppUIBezierPath``
- ``AppUIEdgeInsets``
- ``AppUILayoutConstraint``

### Views and cursors

- ``AppUITopLeftView``
- ``AppUIInteractiveView``
- ``AppUICursor``

### Layout direction

- ``AppUIKit/AppUIKit/LayoutDirection``
- ``LayoutDirectionManager``
- ``ConnectionPointCalculator``
- ``DirectionalSymbols``

### Tooltips

- ``TooltipFormatter``
