// LayoutDirectionManager.swift
// AppUIKit
//
// Detects the effective layout direction: for the application, for a specific
// view, and (thread-safe) for a locale or language code.

import Foundation

/// Utilities for detecting and working with layout direction.
@MainActor
public enum LayoutDirectionManager {
    /// Returns the current application layout direction based on the user's locale.
    public static var currentDirection: LayoutDirection {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return NSApp?.userInterfaceLayoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
        #elseif canImport(UIKit)
            return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
        #endif
    }

    /// Returns true if the current layout direction is RTL.
    public static var isRTL: Bool {
        currentDirection.isRTL
    }

    /// Returns true if the current layout direction is LTR.
    public static var isLTR: Bool {
        currentDirection.isLTR
    }

    // Returns the layout direction for a specific view.
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        public static func direction(for view: NSView) -> LayoutDirection {
            view.userInterfaceLayoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
        }

    #elseif canImport(UIKit)
        public static func direction(for view: UIView) -> LayoutDirection {
            UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft ? .rightToLeft : .leftToRight
        }
    #endif

    /// Returns the layout direction for the given locale (thread-safe, no MainActor required).
    public nonisolated static func direction(for locale: Locale) -> LayoutDirection {
        guard let languageCode = locale.language.languageCode?.identifier else {
            return .leftToRight
        }
        return Locale.Language(identifier: languageCode).characterDirection == .rightToLeft ? .rightToLeft : .leftToRight
    }

    /// Returns true if the given language code is RTL (thread-safe, no MainActor required).
    public nonisolated static func isRTL(languageCode: String) -> Bool {
        // Common RTL language codes
        let rtlLanguages: Set = [
            "ar", // Arabic
            "he", // Hebrew
            "fa", // Farsi/Persian
            "ur", // Urdu
            "yi", // Yiddish
            "ps", // Pashto
            "sd", // Sindhi
            "ug", // Uyghur
            "ku", // Kurdish (Arabic script)
            "dv", // Divehi
            "ckb", // Central Kurdish
        ]
        return rtlLanguages.contains(languageCode.lowercased())
    }
}
