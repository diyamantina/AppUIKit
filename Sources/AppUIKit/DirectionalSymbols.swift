// DirectionalSymbols.swift
// AppUIKit
//
// SF Symbol names that depend on layout direction, plus the set of symbols
// that must never flip.

import Foundation

/// Helpers for SF Symbols that need special RTL handling.
public enum DirectionalSymbols {
    /// Returns the appropriate SF Symbol name for a "forward" action.
    /// In LTR this points right, in RTL this points left.
    public static func forwardArrow(for direction: LayoutDirection) -> String {
        direction.isRTL ? "arrow.left" : "arrow.right"
    }

    /// Returns the appropriate SF Symbol name for a "backward" action.
    public static func backwardArrow(for direction: LayoutDirection) -> String {
        direction.isRTL ? "arrow.right" : "arrow.left"
    }

    /// Returns the appropriate SF Symbol name for "next" navigation.
    public static func nextChevron(for direction: LayoutDirection) -> String {
        direction.isRTL ? "chevron.left" : "chevron.right"
    }

    /// Returns the appropriate SF Symbol name for "previous" navigation.
    public static func previousChevron(for direction: LayoutDirection) -> String {
        direction.isRTL ? "chevron.right" : "chevron.left"
    }

    /// Returns the appropriate SF Symbol name for "expand" disclosure.
    public static func disclosureIndicator(for direction: LayoutDirection) -> String {
        direction.isRTL ? "chevron.left" : "chevron.right"
    }

    /// Returns the appropriate SF Symbol name for text alignment "leading".
    public static func alignLeading(for direction: LayoutDirection) -> String {
        direction.isRTL ? "text.alignright" : "text.alignleft"
    }

    /// Returns the appropriate SF Symbol name for text alignment "trailing".
    public static func alignTrailing(for direction: LayoutDirection) -> String {
        direction.isRTL ? "text.alignleft" : "text.alignright"
    }

    /// Symbols that should NEVER flip (playback, spatial meaning).
    public static let nonFlippingSymbols: Set<String> = [
        "play.fill",
        "pause.fill",
        "stop.fill",
        "backward.fill",
        "forward.fill",
        "gobackward",
        "goforward",
        "speaker.wave.1",
        "speaker.wave.2",
        "speaker.wave.3",
    ]
}
