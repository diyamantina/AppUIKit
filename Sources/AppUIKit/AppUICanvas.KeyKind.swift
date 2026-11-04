//
//  AppUICanvas.KeyKind.swift
//  AppUIKit
//

public extension AppUICanvas {
    /// Which of the canvas's keys.
    enum KeyKind: Sendable, Equatable {
        case arrow(ArrowDirection)
        /// Delete (backspace) or the forward delete key.
        case delete
        case escape
        case tab
        /// Return or Enter.
        case `return`
        /// The space bar.
        case space
        /// The grave accent and tilde key, held: Sketch shows the canvas at 100% while it is down.
        case tilde
    }
}
