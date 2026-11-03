//
//  AppUICanvas.FrameConstraint.swift
//  AppUIKit
//

public extension AppUICanvas {
    /// The constraints on a resize of a frame. A keyboard gives them by held keys (Shift, Option); a touch screen has no keys, so a host gives them from switches it shows, as
    /// Procreate's
    /// Magnetics and Uniform do.
    struct FrameConstraint: OptionSet, Sendable {
        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        /// Both axes take one factor (Shift).
        public static let proportional = FrameConstraint(rawValue: 1 << 0)
        /// The centre stays and both edges move (Option).
        public static let fromCentre = FrameConstraint(rawValue: 1 << 1)
        /// The shape does not pass the opposite edge: a drag past it holds the smallest size and does not mirror (a selection of several objects, which a host cannot mirror as
        /// one).
        public static let keepsSide = FrameConstraint(rawValue: 1 << 2)

        /// The constraints the modifier keys of a sample ask for: Shift proportional, Option from the centre.
        public init(modifiers: Modifiers) {
            var made: FrameConstraint = []
            if modifiers.contains(.shift) {
                made.insert(.proportional)
            }
            if modifiers.contains(.option) {
                made.insert(.fromCentre)
            }
            self = made
        }
    }
}
