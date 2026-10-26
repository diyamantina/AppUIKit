//
//  AppUIKit.TextSize.swift
//  AppUIKit
//
//  The text size a person chose in the system's settings, which a touch screen has and a Mac does not.
//

import Foundation

#if canImport(UIKit) && !os(macOS)
    import UIKit
#endif

/// A size in points made as large as the person chose text to be in the system's settings (Dynamic Type), for a view that sets its own sizes. A Mac has no such setting,
/// so it is the size given.
@MainActor
public func appuiScaledFontSize(_ size: Double) -> Double {
    #if canImport(UIKit) && !os(macOS)
        AppUITextSize.scaled(size, for: UIApplication.shared.preferredContentSizeCategory)
    #else
        size
    #endif
}

/// Calls `handler` when the person changes the text size in the system's settings, for as long as the returned object is kept; there is nothing to observe on a Mac, where it
/// returns nil.
@MainActor
public func appuiObserveTextSizeChange(_ handler: @escaping @MainActor () -> Void) -> AnyObject? {
    #if canImport(UIKit) && !os(macOS)
        AppUINotificationObservation(name: UIContentSizeCategory.didChangeNotification, object: nil) { _ in
            MainActor.assumeIsolated { handler() }
        }
    #else
        nil
    #endif
}

#if canImport(UIKit) && !os(macOS)
    /// The scaling, with the category given so that a test can ask for any.
    enum AppUITextSize {
        static func scaled(_ size: Double, for category: UIContentSizeCategory) -> Double {
            Double(UIFontMetrics.default.scaledValue(for: CGFloat(size), compatibleWith: UITraitCollection(preferredContentSizeCategory: category)))
        }
    }
#endif
