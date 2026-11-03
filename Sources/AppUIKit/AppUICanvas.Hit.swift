//
//  AppUICanvas.Hit.swift
//  AppUIKit
//

public extension AppUICanvas {
    /// What lies under a point of the canvas, as ``AppUICanvas/hit(at:)`` answers it.
    enum Hit: Sendable, Equatable {
        /// A mark of the overlay (a handle). A handle beats the object under it.
        case mark(UInt64)
        /// The items under the point, topmost first. Never empty.
        case items([UInt64])
        /// Nothing: the backdrop.
        case none
    }
}
