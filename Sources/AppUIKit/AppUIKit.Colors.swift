// AppUIKit.Colors.swift
// AppUIKit
//
// Native platform color constants using AppKit/UIKit.

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

public extension AppUIKit {
    /// Native platform color accessors.
    ///
    /// Use these when you need the actual NSColor/UIColor rather than SwiftUI Color.
    /// Access via `AppUIKit.Colors.label`, `AppUIKit.Colors.background`, etc.
    enum Colors {
        // MARK: - Backgrounds

        /// Background color for control elements.
        public static var controlBackground: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .controlBackgroundColor
            #else
                .systemBackground
            #endif
        }

        /// Background color for text areas.
        public static var textBackground: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .textBackgroundColor
            #else
                .secondarySystemBackground
            #endif
        }

        /// Primary window/view background.
        public static var background: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .windowBackgroundColor
            #else
                .systemBackground
            #endif
        }

        /// Secondary background.
        public static var secondaryBackground: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .underPageBackgroundColor
            #else
                .secondarySystemBackground
            #endif
        }

        /// Tertiary background.
        public static var tertiaryBackground: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .controlBackgroundColor
            #else
                .tertiarySystemBackground
            #endif
        }

        // MARK: - Separators

        /// Separator line color.
        public static var separator: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .separatorColor
            #else
                .separator
            #endif
        }

        // MARK: - Labels

        /// Primary label color.
        public static var label: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .labelColor
            #else
                .label
            #endif
        }

        /// Secondary label color.
        public static var secondaryLabel: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .secondaryLabelColor
            #else
                .secondaryLabel
            #endif
        }

        /// Tertiary label color.
        public static var tertiaryLabel: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .tertiaryLabelColor
            #else
                .tertiaryLabel
            #endif
        }

        // MARK: - Fill

        /// Primary fill color.
        public static var fill: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .systemFill
            #else
                .systemFill
            #endif
        }

        /// Secondary fill color.
        public static var secondaryFill: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .secondarySystemFill
            #else
                .secondarySystemFill
            #endif
        }

        /// Tertiary fill color.
        public static var tertiaryFill: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .tertiarySystemFill
            #else
                .tertiarySystemFill
            #endif
        }

        /// Quaternary fill color.
        public static var quaternaryFill: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .quaternarySystemFill
            #else
                .quaternarySystemFill
            #endif
        }

        /// The background for text/content areas (the editor stage, code panels).
        public static var contentBackground: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .textBackgroundColor
            #else
                .secondarySystemBackground
            #endif
        }

        /// The system accent (the default tint for a control). UIKit has no first-class accent color, so it
        /// resolves to system blue there, matching AppKit's default control accent on a fresh install.
        public static var accent: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .controlAccentColor
            #else
                .systemBlue
            #endif
        }

        /// The platform focus-ring color. On macOS this is the same dynamic color AppKit uses for keyboard
        /// focus indicators; UIKit falls back to system blue.
        public static var keyboardFocusIndicator: AppUIColor {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .keyboardFocusIndicatorColor
            #else
                .systemBlue
            #endif
        }
    }
}
