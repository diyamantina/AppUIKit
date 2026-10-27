//  AppUIKit.ReduceMotion.swift
//  AppUIKit
//
//  The system's Reduce Motion setting, read the same way on AppKit and UIKit.

import Foundation

public extension AppUIKit {
    /// Whether the person has asked the system to reduce motion (Settings, Accessibility, Motion on iOS; System Settings, Accessibility, Display on the Mac). A view
    /// that springs, slides or zooms reads it and switches to a fade or no animation.
    @MainActor
    static var reducesMotion: Bool {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #elseif canImport(UIKit)
            UIAccessibility.isReduceMotionEnabled
        #else
            false
        #endif
    }
}
