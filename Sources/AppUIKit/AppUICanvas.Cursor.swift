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
        /// A double arrow left and right: a side handle that moves an edge across.
        case resizeHorizontal
        /// A double arrow up and down: a side handle that moves an edge up or down.
        case resizeVertical
        /// A double arrow along the diagonal from the top left to the bottom right: those two corner handles.
        case resizeDiagonalDown
        /// A double arrow along the diagonal from the bottom left to the top right: those two corner handles.
        case resizeDiagonalUp
        /// A turn: just outside a corner of the selection, where a press rotates it.
        case rotate
    }
}
