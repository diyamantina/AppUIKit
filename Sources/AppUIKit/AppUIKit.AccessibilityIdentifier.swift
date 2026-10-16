// AppUIKit.AccessibilityIdentifier.swift
// AppUIKit
//
// Cross-framework accessibility-identifier setter so call sites do not need per-platform branches.

import Foundation

public extension AppUIView {
    /// Set the accessibility identifier uniformly across AppKit and UIKit.
    ///
    /// AppKit exposes `NSView.setAccessibilityIdentifier(_:)`; UIKit exposes the
    /// `UIView.accessibilityIdentifier` property. This wraps both so views can apply
    /// shared accessibility identifiers without `#if` at the call site.
    func setAXIdentifier(_ identifier: String) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            setAccessibilityIdentifier(identifier)
        #elseif canImport(UIKit)
            accessibilityIdentifier = identifier
        #endif
    }

    /// Set the accessibility label uniformly across AppKit and UIKit.
    ///
    /// AppKit exposes `NSView.setAccessibilityLabel(_:)`; UIKit exposes the
    /// `UIView.accessibilityLabel` property. This wraps both so views can apply
    /// shared accessibility labels without `#if` at the call site.
    func setAXLabel(_ label: String) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            setAccessibilityLabel(label)
        #elseif canImport(UIKit)
            accessibilityLabel = label
        #endif
    }

    /// Make a custom drawing view appear in the accessibility tree, so a UI test and an assistive technology find it by its identifier.
    ///
    /// An `NSView` that draws itself is not an accessibility element until it says so (`setAccessibilityElement(_:)`), and an element needs a role to be listed; the identifier
    /// alone
    /// leaves the view out of the tree on macOS. A `UIView` that is not an element still shows its identifier to a UI test, and making it one would hide its subviews from
    /// VoiceOver,
    /// so UIKit is left as it is.
    func setAXElement() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            setAccessibilityElement(true)
            setAccessibilityRole(.image)
        #endif
    }

    /// Make a table cell's content view the accessibility element of its row, so its identifier reaches a UI test.
    ///
    /// A view-based `NSTableView` lists a cell for each row, but an identifier set on the view that fills the cell is not carried to that cell unless the view is an element with
    /// the role of a cell.
    /// A `UITableViewCell` is already an element and carries its own identifier, so UIKit is left as it is.
    func setAXCell() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            setAccessibilityElement(true)
            setAccessibilityRole(.cell)
        #endif
    }
}
