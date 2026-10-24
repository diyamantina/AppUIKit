# Changelog

All notable changes to AppUIKit are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- A text view of a very large file stalled for seconds: it laid out every line before showing or scrolling to one (4.6 s to open and 4.7 s to jump to the end of a 13 MB description of 357,000 lines). `appuiConfigureForCode` now allows non-contiguous layout, and `appuiScrollToVisible` scrolls to where the range is estimated to be, lays out the lines then in view and measures again until the range stops moving (0.7 s to open, 11 ms to jump to the end; jumps checked at 50%, 90% and 100% of the file).
- On AppKit a Command-click on a link did nothing: a text view runs its own loop from the mouse-down to the mouse-up, in which a gesture recognizer sees nothing. It is now taken at the mouse-down by a monitor of the window's events, and only when the character is a link, so any other click reaches the text view. Found by sending real mouse events to the real view in a window.

### Added
- Moving by words and to the ends in an `AppUIRowView` that can be edited: Option with left or right goes to the end or the start of the next word, over the end of a row to the next row; Command with left or right goes to the edge of the row, and Command with up or down to the start or the end of the document. All of them extend the selection with Shift. Command with a letter is still left to the responder chain (copy, paste, undo).
- Selecting with the keyboard in an `AppUIRowView` that can be edited: Shift with the arrows, Home and End extends the selection from where it began, a character or a row at a time, shrinks it when turned back, and runs the other way past the place it began; an arrow without Shift ends it at the end it points to. What is typed then goes to `onEdit` to replace it.
- `AppUIRowView` can be edited (Mac): with `isEditable` it shows a caret (a line at `caret`, set by a click or `setCaret`), the arrow keys move it over characters (a letter with its accent, an emoji, are one), over the ends of rows and between rows, Home and End go to the edges of the row, and an arrow with a selection goes to the end of it that it points to. What is typed is not put in anything by the view: it is given to `onEdit` as `AppUIRowEdit` (text typed or pasted, the two delete keys, return, and tab as two spaces) for the owner of the rows, who changes its text, shows the rows again with `reload()` and puts the caret with `setCaret`. Paste and Cut are responder actions that give the same, and Undo and Redo give `onUndo` and `onRedo`, validated by `canUndoRedo`. Keys that are not text (escape, the function keys) are not given. Held by tests that send the view real key events.
- Touch in `AppUIRowView` on iPad and iPhone: a flick goes on moving the rows and slows to a stop (the distance is found exactly from the speed, so a late frame goes as far as an early one; held to its closed form), a finger on the right edge takes hold of the scroller from 32 points in, holding a finger selects the word under it and moving it extends the selection, and lifting offers Copy. A finger put down stops a flick. Held by tests on an iPad simulator; two existing tests of other views (`sharing from a detached view falls back to pasteboard`, `the content is as wide as the scroll view...`) fail there on the commit before this too.
- `AppUIRowView.marks`: places along the whole length of the rows (`AppUIRowMark`, a row and whether it is emphasized) drawn on the scroller, as a map of where things are in a file of any length. Marks that fall on one line of pixels are drawn once, so a hundred thousand cost a few hundred strokes.
- `AppUIRowView.restyle()` asks the source for the rows again and draws them, keeping the selection and the place, which `reload()` does not. For a source that has found more to say of its rows (links) after they were first drawn.

- `AppUITreeView`, with `AppUITreeSource` and `AppUITreeRow`: a tree as a list of rows (depth, SF Symbol, title, detail, chevron) that draws only the rows in view and asks its source for those alone. A system list enumerates the identifiers of all its rows to know what they are, which stopped an application for minutes on a tree of 1.77 million rows; this one is placed to the row at any size, selects by click and arrow keys, opens and closes by the chevron, a double click and the left and right arrows, and scrolls by wheel, keys and a scroller of its own. AppKit and UIKit.
- `AppUIRowView.select(_:)`: an owner chooses the range of text that is selected (or none), as when a node of an outline is chosen and its whole text should show selected.
- `AppUIRowView`, with `AppUIRowSource`, `AppUIRow`, `AppUIRowRun` and `AppUIRowPosition`: a view that shows the rows of a source of any size by drawing only the rows in view with Core Text, on AppKit and UIKit. It is as tall as its window; the place it is scrolled to is a `Double` of points, so thirty-seven million rows are placed to the row. It scrolls by wheel, trackpad, keys and a scroller of its own, selects (drag, double click for a word, triple click for a row) and copies, shows a gutter, tells its owner of a click or a tap and shows the pointing hand over a link while Command is held (AppKit). Measured in a window on a Mac: 0.9 ms to redraw 60 rows and 1.6 ms for 200, against 3 to 10 ms for a pool of row layers.
- `AppUIKit.Colors.dynamic(light:dark:)`: a color made from two `0xRRGGBB` numbers that is the first in the light appearance and the second in the dark one, on AppKit and UIKit.
- `appuiObserveCommandClick`: tells the UTF-16 index of the character under the pointer when a text view is Command-clicked (AppKit) or tapped (UIKit), through a gesture recognizer that lets the click through, so the caret and selection still work.
- `appuiShowsLineNumbers`: a column of line numbers beside a text view, the scroll view's ruler on AppKit and a view over the left edge on UIKit, drawn for the lines in view only. `AppUILineNumbers` finds the line of an offset by search; `appuiUpdateLineNumbers()` refits the column after the font changes.
- `appuiConfigureForCode` keeps the text 12 points from the edge of the view and turns the system's writing tools off, which put an Apple Intelligence popup over selected code.
- `appuiScrollToVisible(_:centered:)` lays the text out as far as the range before scrolling, scrolls up, down and sideways (AppKit; UIKit only to the row), and can put the range in the middle of the view. `appuiRect(of:)` and `appuiVisibleRect` say where a range is and what can be seen.
- `appuiObserveSelection(_:)` and `AppUITextViewSelectionObserver`: a closure told each time the selection or the caret of a text view moves, on AppKit and UIKit.
- `appuiConfigureForCode(font:wrapsLines:)` keeps each line whole and scrolls sideways unless asked to wrap, and `appuiSetWrapsLines(_:)` changes it later; a wrapped line of code restarts at the left edge, under none of its indentation.
- Text view helpers: `appuiString`, `appuiSelectedRange`, `appuiTextStorage`, `appuiScrollToVisible(_:)`, `appuiConfigureForCode(font:)`, `appuiObserveEdits(_:)` and `AppUITextView.appuiMakeScrolling()`, so an editor surface is written once for AppKit and UIKit.

### Added

- UIKit-only `AppUIActivityIndicatorView` (`UIActivityIndicatorView`), the spinner `AppUIProgressIndicator` is on AppKit.
- `AppUILayoutManager`, `AppUITextContainer` and `AppUITextStorage` (`NSLayoutManager`, `NSTextContainer`, `NSTextStorage`) on both frameworks, so a text editor that paints behind its glyphs names them through AppUIKit.
- UIKit-only `UIColor(srgbRed:green:blue:alpha:)` and `redComponent`, `greenComponent`, `blueComponent` and `alphaComponent`, so a palette written against `NSColor`'s names builds the same on UIKit.
- `AppUIKit.Sharing.share(image:from:fallback:)` and `AppUIKit.Pasteboard.copy(_:to:)` for an image: the system sharing menu from a view, or when the view is in no window the image is copied to the pasteboard given (the system's by default), so sharing is never inert.
- `AppUIParagraphStyle` and `AppUIMutableParagraphStyle` on both frameworks, so a line spacing or an indent on attributed text is written without naming `NSParagraphStyle`.
- `AppUIApplicationDelegate` on both frameworks; AppKit-only `AppUIMenuItemValidation` and `AppUIImageSymbolConfiguration`; UIKit-only `AppUIRect`, `AppUISize`, `AppUIPoint`, `AppUIWindowSceneDelegate`, `AppUITouch`, `AppUIKeyCommand`, `AppUIHoverGestureRecognizer`, `AppUIMenuElement`, `AppUIDeferredMenuElement`, `AppUIToolbar`, `AppUIImageSymbolConfiguration`, `AppUIScene`, `AppUISceneSession`, `AppUISceneConfiguration`, `AppUICommand`.
- Documents: `AppUIDocument` (`NSDocument`, `UIDocument`), `AppUIDocumentController` (AppKit), `AppUIWindowDelegate` (AppKit), `AppUIDocumentBrowserViewController` and `AppUIDocumentBrowserDelegate` (UIKit).
- `AppUIOpenURLContext` (UIKit).
- `AppUIHostingController` on both frameworks; AppKit-only `AppUIWorkspace` and `AppUIHostingView`.
- `AppUIRepresentable`, a SwiftUI view hosting a platform view with `makeAppUIView` and `updateAppUIView` on both frameworks.
- AppKit-only `AppUIValidatedUserInterfaceItem`, `AppUIText`, `AppUIRulerView` and `AppUIBitmapImageRep`.
- `AppUIImage.appUISymbol(_:description:)`, an SF Symbol on AppKit and UIKit alike.
- Chrome helpers, so a status line, a segmented control, a palette button and a list row are written once: `AppUIControl.appuiSetPrimaryAction(target:action:)` and `appuiToolTip`; `AppUILabel.appuiText`, `appuiMaximumLines` and `appuiConfigureAsLabel()`; `AppUISegmentedControl.appuiSetSegments(_:)`, `appuiSegmentCount`, `appuiSegmentTitle(at:)` and `appuiSelectedSegment`; `AppUIButton.appuiSetSymbol(_:description:)`, `appuiSymbolImage`, `appuiIsSelected`, `appuiMakeToggle()` and `appuiMakeBorderless()`; `AppUIImageView.appuiContentTintColor`; `AppUIView.appuiAlpha`; `AppUIStackView.appuiEdgeInsets`.

- Text entry, written once: `AppUITextField.appuiString`, `appuiPlaceholder` and `appuiSetCommitAction(target:action:)` (Return and loss of focus), and `AppUIViewController.appuiPromptForText(title:message:placeholder:initialText:confirmTitle:cancelTitle:fieldIdentifier:completion:)`, an alert with one text field (a sheet with an accessory field on AppKit, an alert controller on UIKit) that answers the text or `nil`.

- `AppUIView.setAXElement()` and `setAXCell(...)`: a custom drawing view or a table cell appears in the accessibility tree on AppKit (an `NSView` that draws itself is not an element until it says so), and `AppUIButton.appuiIsSelected` now sets the selected accessibility state on AppKit, so a UI test and VoiceOver find and read them as on UIKit.

- `AppUITableViewDiffableDataSource` (`NSTableViewDiffableDataSource`, `UITableViewDiffableDataSource`) and `AppUIDiffableSnapshot` (`NSDiffableDataSourceSnapshot`), so a table keyed by stable identifiers is driven by snapshots on AppKit and UIKit alike.

## [0.2.0] - 2026-09-16

### Added

- A DocC documentation catalog (`Sources/AppUIKit/AppUIKit.docc`) with a curated
  landing page for the library, built via the Swift-DocC plugin
  (`swift package generate-documentation`). The plugin is declared as a package
  dependency.
- `AppUIView.setAXLabel(_:)`, the accessibility-label twin of
  `setAXIdentifier(_:)`, wrapping `NSView.setAccessibilityLabel(_:)` on AppKit and
  `UIView.accessibilityLabel` on UIKit.

### Changed

- `LayoutDirectionManager`, `ConnectionPointCalculator`, and
  `DirectionalSymbols` moved out of `AppUIKit.LayoutDirection.swift` into their
  own files (one non-private type per file). No behavior change.
- README installation now points at the public GitHub mirror
  (`github.com/diyamantina/AppUIKit`), which is read-only.
- The rules-swift CI lane now runs the full strict gate as a required step; the
  README and CONTRIBUTING rules sections point at the vendored
  `third_party/rules-swift` snapshot.

### Fixed

- `NSImage.flippedHorizontally()` returns the original image unchanged for a
  zero-size, non-finite, or implausibly large image instead of crashing in
  `lockFocus()`.
- `ConnectionPointCalculator.bezierControlPoints(from:to:)` clamps the control
  offset to its floor instead of leaking NaN when an endpoint is infinite.

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
