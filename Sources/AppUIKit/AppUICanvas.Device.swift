//
//  AppUICanvas.Device.swift
//  AppUIKit
//

public extension AppUICanvas {
    /// What made a ``Sample``.
    ///
    /// AppKit and UIKit report a pointer without saying whether it is a mouse or a trackpad, so a pointer is ``mouse`` there. ``trackpad`` is
    /// what UIKit reports for an indirect touch that is not a pointer, and what the later scroll and magnify slices will report.
    enum Device: Sendable, Equatable, CaseIterable {
        /// A mouse, or a pointer that is not told apart from one.
        case mouse
        /// A trackpad touch.
        case trackpad
        /// A finger on the glass.
        case touch
        /// A pen: Apple Pencil on UIKit, a graphics tablet on AppKit.
        case pencil
    }
}
