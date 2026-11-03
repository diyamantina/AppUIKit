//
//  AppUICanvas.Phase.swift
//  AppUIKit
//

public extension AppUICanvas {
    /// Where a ``Sample`` lies in the life of a contact (a pressed button or a finger or pen on the glass).
    enum Phase: Sendable, Equatable, CaseIterable {
        /// The contact went down.
        case began
        /// The contact moved while down.
        case moved
        /// The contact lifted.
        case ended
        /// The system took the contact away (a call, a window that closed, a gesture that won). Nothing was committed by the person.
        case cancelled
        /// The pointer moved over the view with no contact down. Only a pointer hovers; a finger does not.
        case hovered
    }
}
