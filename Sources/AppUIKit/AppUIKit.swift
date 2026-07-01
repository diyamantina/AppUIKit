//  AppUIKit.swift
//  AppUIKit
//
//  The cross-framework namespace layer for imperative AppKit and UIKit UI code. It vends one
//  full set of `AppUI*` type aliases plus platform-detection and graphics-context helpers, so a single source
//  file can target macOS and iOS without `#if` noise at every type reference. It is deliberately a thin
//  abstraction, names and a few helpers, not a UI framework; the reusable controls live in the AppUIControls
//  package, which depends on this one.

import Foundation

// Re-export the platform UI framework so a consumer only needs `import AppUIKit` to reach NSView/UIView and
// the rest. `@_exported` makes those types visible to any file that imports AppUIKit.
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @_exported import AppKit
#elseif canImport(UIKit)
    @_exported import UIKit
#endif

#if canImport(SwiftUI)
    @_exported import SwiftUI
#endif

// Re-export Core Graphics too, so a consumer drawing in a control reaches `CGContext`, `CGRect`, and the
// rest through `import AppUIKit` alone, with no second import and no platform `#if` of their own.
@_exported import CoreGraphics

/// The root namespace for AppUIKit. Holds the package version and the platform helpers; the cross-framework
/// type aliases are vended at the top level (e.g. `AppUIView`) so call sites read like ordinary type names.
public enum AppUIKit {
    /// The package version.
    public static let version = "0.1.9"

    /// The current Core Graphics context inside a view's `draw(_:)`, the one place AppKit and UIKit differ in
    /// how the context is reached. A control's drawing code calls this once and then draws identically on
    /// both platforms.
    public static func currentCGContext() -> CGContext? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return NSGraphicsContext.current?.cgContext
        #elseif canImport(UIKit)
            return UIGraphicsGetCurrentContext()
        #else
            return nil
        #endif
    }
}

// MARK: - Platform flags

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    /// True when compiled against AppKit (macOS).
    public let isAppKit = true
    /// True when compiled against UIKit (iOS / iPadOS).
    public let isUIKit = false
#elseif canImport(UIKit)
    public let isAppKit = false
    public let isUIKit = true
#endif

// MARK: - Type aliases (AppUI*)

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

    // View types.
    public typealias AppUIView = NSView
    public typealias AppUIViewController = NSViewController
    public typealias AppUIWindow = NSWindow
    public typealias AppUIWindowController = NSWindowController
    public typealias AppUIApplication = NSApplication
    public typealias AppUIScreen = NSScreen
    public typealias AppUIResponder = NSResponder

    // Controls.
    public typealias AppUIControl = NSControl
    public typealias AppUIButton = NSButton
    public typealias AppUILabel = NSTextField
    public typealias AppUITextField = NSTextField
    public typealias AppUITextView = NSTextView
    public typealias AppUISearchField = NSSearchField
    public typealias AppUISegmentedControl = NSSegmentedControl
    public typealias AppUISwitch = NSSwitch
    public typealias AppUISlider = NSSlider
    public typealias AppUIPopUpButton = NSPopUpButton
    public typealias AppUIColorWell = NSColorWell

    // Container views.
    public typealias AppUIScrollView = NSScrollView
    public typealias AppUIStackView = NSStackView
    public typealias AppUISplitView = NSSplitView
    public typealias AppUISplitViewController = NSSplitViewController
    public typealias AppUISplitViewItem = NSSplitViewItem
    public typealias AppUITabViewController = NSTabViewController
    public typealias AppUITabView = NSTabView
    public typealias AppUITabViewItem = NSTabViewItem
    public typealias AppUIBox = NSBox

    // Table / outline views.
    public typealias AppUITableView = NSTableView
    public typealias AppUITableColumn = NSTableColumn
    public typealias AppUITableCellView = NSTableCellView
    public typealias AppUIOutlineView = NSOutlineView

    // Images and graphics.
    public typealias AppUIImage = NSImage
    public typealias AppUIImageView = NSImageView
    public typealias AppUIColor = NSColor
    public typealias AppUIFont = NSFont
    public typealias AppUIBezierPath = NSBezierPath
    public typealias AppUIGraphicsContext = NSGraphicsContext

    // Alerts and panels.
    public typealias AppUIAlert = NSAlert
    public typealias AppUIPanel = NSPanel
    public typealias AppUIOpenPanel = NSOpenPanel
    public typealias AppUISavePanel = NSSavePanel

    // Events and gestures.
    public typealias AppUIEvent = NSEvent
    public typealias AppUIGestureRecognizer = NSGestureRecognizer
    public typealias AppUIPanGestureRecognizer = NSPanGestureRecognizer
    public typealias AppUIClickGestureRecognizer = NSClickGestureRecognizer
    public typealias AppUIPressGestureRecognizer = NSPressGestureRecognizer
    public typealias AppUIMagnificationGestureRecognizer = NSMagnificationGestureRecognizer

    // Drag and drop.
    public typealias AppUIDraggingInfo = NSDraggingInfo
    public typealias AppUIDraggingSession = NSDraggingSession
    public typealias AppUIDraggingSource = NSDraggingSource
    public typealias AppUIDragOperation = NSDragOperation
    public typealias AppUIDraggingItem = NSDraggingItem
    public typealias AppUIDraggingContext = NSDraggingContext

    // Menu.
    public typealias AppUIMenu = NSMenu
    public typealias AppUIMenuItem = NSMenuItem

    // Toolbar.
    public typealias AppUIToolbar = NSToolbar
    public typealias AppUIToolbarItem = NSToolbarItem
    public typealias AppUIToolbarDelegate = NSToolbarDelegate
    public typealias AppUIToolbarItemIdentifier = NSToolbarItem.Identifier

    // Layout and geometry.
    public typealias AppUIEdgeInsets = NSEdgeInsets
    public typealias AppUIRect = NSRect
    public typealias AppUISize = NSSize
    public typealias AppUIPoint = NSPoint
    public typealias AppUILayoutConstraint = NSLayoutConstraint

    // Pasteboard.
    public typealias AppUIPasteboard = NSPasteboard
    public typealias AppUIPasteboardItem = NSPasteboardItem

    /// Visual effects.
    public typealias AppUIVisualEffectView = NSVisualEffectView

    // Animation, appearance, tracking, clip view.
    public typealias AppUIAnimationContext = NSAnimationContext
    public typealias AppUIAppearance = NSAppearance
    public typealias AppUITrackingArea = NSTrackingArea
    public typealias AppUIClipView = NSClipView

    // Protocols (as aliases for consistency).
    public typealias AppUIOutlineViewDataSource = NSOutlineViewDataSource
    public typealias AppUIOutlineViewDelegate = NSOutlineViewDelegate
    public typealias AppUITableViewDataSource = NSTableViewDataSource
    public typealias AppUITableViewDelegate = NSTableViewDelegate
    public typealias AppUITextViewDelegate = NSTextViewDelegate
    public typealias AppUITextFieldDelegate = NSTextFieldDelegate
    public typealias AppUISearchFieldDelegate = NSSearchFieldDelegate

    // Attributed strings.
    public typealias AppUIMutableAttributedString = NSMutableAttributedString
    public typealias AppUIAttributedString = NSAttributedString

    // Other.
    public typealias AppUICoder = NSCoder
    public typealias AppUIUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier
    public typealias AppUIRegularExpression = NSRegularExpression
    public typealias AppUIRange = NSRange
    public typealias AppUIUnderlineStyle = NSUnderlineStyle

    // Further shared types (each has a real counterpart on both frameworks).
    public typealias AppUIStepper = NSStepper
    public typealias AppUIDatePicker = NSDatePicker
    public typealias AppUIProgressIndicator = NSProgressIndicator
    public typealias AppUICollectionView = NSCollectionView
    public typealias AppUICollectionViewDelegate = NSCollectionViewDelegate
    public typealias AppUICollectionViewDataSource = NSCollectionViewDataSource
    public typealias AppUIFontDescriptor = NSFontDescriptor
    public typealias AppUIGestureRecognizerDelegate = NSGestureRecognizerDelegate
    public typealias AppUIRotationGestureRecognizer = NSRotationGestureRecognizer
    public typealias AppUIStoryboard = NSStoryboard
    public typealias AppUINib = NSNib
    public typealias AppUILayoutGuide = NSLayoutGuide
    public typealias AppUIAccessibilityElement = NSAccessibilityElement
    #if canImport(SwiftUI)
        public typealias AppUIViewRepresentable = NSViewRepresentable
    #endif

#elseif canImport(UIKit)

    // View types.
    public typealias AppUIView = UIView
    public typealias AppUIViewController = UIViewController
    public typealias AppUIWindow = UIWindow
    public typealias AppUIWindowScene = UIWindowScene
    public typealias AppUIApplication = UIApplication
    public typealias AppUIScreen = UIScreen
    public typealias AppUIResponder = UIResponder

    // Controls.
    public typealias AppUIControl = UIControl
    public typealias AppUIButton = UIButton
    public typealias AppUILabel = UILabel
    public typealias AppUITextField = UITextField
    public typealias AppUITextView = UITextView
    public typealias AppUISearchBar = UISearchBar
    public typealias AppUISearchController = UISearchController
    public typealias AppUISegmentedControl = UISegmentedControl
    public typealias AppUISwitch = UISwitch
    public typealias AppUISlider = UISlider
    public typealias AppUIColorWell = UIColorWell

    // Container views.
    public typealias AppUIScrollView = UIScrollView
    public typealias AppUIStackView = UIStackView
    public typealias AppUISplitView = UISplitViewController
    public typealias AppUISplitViewController = UISplitViewController
    public typealias AppUITabBarController = UITabBarController

    // Table / collection views.
    public typealias AppUITableView = UITableView
    public typealias AppUITableViewCell = UITableViewCell
    public typealias AppUITableViewController = UITableViewController
    public typealias AppUICollectionView = UICollectionView
    public typealias AppUICollectionViewCell = UICollectionViewCell

    // Images and graphics.
    public typealias AppUIImage = UIImage
    public typealias AppUIImageView = UIImageView
    public typealias AppUIColor = UIColor
    public typealias AppUIFont = UIFont
    public typealias AppUIBezierPath = UIBezierPath
    public typealias AppUIGraphicsContext = UIGraphicsImageRenderer

    // Alerts.
    public typealias AppUIAlertController = UIAlertController
    public typealias AppUIAlertAction = UIAlertAction

    // Events and gestures.
    public typealias AppUIEvent = UIEvent
    public typealias AppUIGestureRecognizer = UIGestureRecognizer
    public typealias AppUIPanGestureRecognizer = UIPanGestureRecognizer
    public typealias AppUITapGestureRecognizer = UITapGestureRecognizer
    public typealias AppUILongPressGestureRecognizer = UILongPressGestureRecognizer
    public typealias AppUIPinchGestureRecognizer = UIPinchGestureRecognizer

    // Drag and drop.
    public typealias AppUIDragInteraction = UIDragInteraction
    public typealias AppUIDropInteraction = UIDropInteraction
    public typealias AppUIDropInteractionDelegate = UIDropInteractionDelegate
    public typealias AppUIDropSession = UIDropSession
    public typealias AppUIDropProposal = UIDropProposal

    // Menu.
    public typealias AppUIMenu = UIMenu
    public typealias AppUIAction = UIAction
    public typealias AppUIContextMenuInteraction = UIContextMenuInteraction
    public typealias AppUIContextMenuConfiguration = UIContextMenuConfiguration

    // Navigation and toolbar.
    public typealias AppUINavigationController = UINavigationController
    public typealias AppUIBarButtonItem = UIBarButtonItem

    // Layout and geometry.
    public typealias AppUIEdgeInsets = UIEdgeInsets
    public typealias AppUILayoutConstraint = NSLayoutConstraint

    /// Pasteboard.
    public typealias AppUIPasteboard = UIPasteboard

    // Visual effects.
    public typealias AppUIVisualEffectView = UIVisualEffectView
    public typealias AppUIBlurEffect = UIBlurEffect

    // Appearance.
    public typealias AppUIUserInterfaceStyle = UIUserInterfaceStyle
    public typealias AppUITraitCollection = UITraitCollection

    /// Tab bar.
    public typealias AppUITabBarItem = UITabBarItem

    // Protocols.
    public typealias AppUITableViewDataSource = UITableViewDataSource
    public typealias AppUITableViewDelegate = UITableViewDelegate
    public typealias AppUITextViewDelegate = UITextViewDelegate
    public typealias AppUITextFieldDelegate = UITextFieldDelegate
    public typealias AppUISearchBarDelegate = UISearchBarDelegate
    public typealias AppUISearchResultsUpdating = UISearchResultsUpdating
    public typealias AppUIDocumentPickerDelegate = UIDocumentPickerDelegate

    /// Document picker.
    public typealias AppUIDocumentPickerViewController = UIDocumentPickerViewController

    // Attributed strings.
    public typealias AppUIMutableAttributedString = NSMutableAttributedString
    public typealias AppUIAttributedString = NSAttributedString

    // Other.
    public typealias AppUICoder = NSCoder
    public typealias AppUIRegularExpression = NSRegularExpression
    public typealias AppUIRange = NSRange
    public typealias AppUIUnderlineStyle = NSUnderlineStyle

    // Further shared types (each has a real counterpart on both frameworks).
    public typealias AppUIStepper = UIStepper
    public typealias AppUIDatePicker = UIDatePicker
    public typealias AppUIProgressIndicator = UIProgressView
    public typealias AppUICollectionViewDelegate = UICollectionViewDelegate
    public typealias AppUICollectionViewDataSource = UICollectionViewDataSource
    public typealias AppUIFontDescriptor = UIFontDescriptor
    public typealias AppUIGestureRecognizerDelegate = UIGestureRecognizerDelegate
    public typealias AppUIRotationGestureRecognizer = UIRotationGestureRecognizer
    public typealias AppUIStoryboard = UIStoryboard
    public typealias AppUINib = UINib
    public typealias AppUILayoutGuide = UILayoutGuide
    public typealias AppUIAccessibilityElement = UIAccessibilityElement
    #if canImport(SwiftUI)
        public typealias AppUIViewRepresentable = UIViewRepresentable
    #endif

#endif
