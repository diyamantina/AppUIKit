//
//  AppUICanvas.Cursor.swift
//  AppUIKit
//
//  The pointer shape over the canvas, set by the host from what is under the pointer.
//

public extension AppUICanvas {
    /// The shape of the pointer over the canvas. A touch screen has no pointer shape, so the UIKit half ignores it.
    enum Cursor: Sendable, Equatable, CaseIterable {
        /// The system arrow.
        case arrow
        /// The open hand: what is under the pointer can be picked up.
        case openHand
        /// The closed hand: it is being carried.
        case closedHand
    }
}
