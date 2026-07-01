// AppUIKit.Fonts.swift
// AppUIKit
//
// Native platform font helpers for AppKit/UIKit.

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

public extension AppUIKit {
    /// Native platform font utilities.
    ///
    /// Access via `AppUIKit.Fonts.monospaced(...)`, `AppUIKit.Fonts.monospacedPreferred(...)`.
    enum Fonts {
        /// Monospaced system font with explicit size.
        public static func monospaced(ofSize size: CGFloat, weight: AppUIFont.Weight = .regular) -> AppUIFont {
            .monospacedSystemFont(ofSize: size, weight: weight)
        }

        /// Preferred monospaced font for the given text style, respecting Dynamic Type.
        public static func monospacedPreferred(forTextStyle style: AppUIFont.TextStyle, weight: AppUIFont.Weight = .regular) -> AppUIFont {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                let preferred = NSFont.preferredFont(forTextStyle: style)
            #else
                let preferred = UIFont.preferredFont(forTextStyle: style)
            #endif
            return monospaced(ofSize: preferred.pointSize, weight: weight)
        }

        /// A monospaced-digit system font, so a changing number does not shift a readout's width.
        public static func monospacedDigit(size: CGFloat, weight: AppUIFont.Weight = .semibold) -> AppUIFont {
            AppUIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
        }
    }
}
