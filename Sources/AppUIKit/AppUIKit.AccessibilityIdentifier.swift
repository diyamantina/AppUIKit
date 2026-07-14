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
}
