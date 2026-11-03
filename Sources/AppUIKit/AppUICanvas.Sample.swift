//
//  AppUICanvas.Sample.swift
//  AppUIKit
//

import CoreGraphics
import Foundation

public extension AppUICanvas {
    /// One report of a contact or of a hovering pointer, in the order it happened.
    struct Sample: Sendable, Equatable {
        /// Where the sample lies in the life of its contact.
        public var phase: Phase
        /// The place in the view's own points, origin at the top left, y downward, the same on AppKit and UIKit.
        public var location: CGPoint
        /// When it happened, in seconds on the system's event clock (the clock of `NSEvent.timestamp` and `UITouch.timestamp`).
        public var timestamp: TimeInterval
        /// What made it.
        public var device: Device
        /// How hard it pressed, for a pen only (0 to 1 on AppKit, `UITouch.force` on UIKit); nil for a mouse and a finger.
        public var force: CGFloat?
        /// The pen's angle from the glass in radians (0 flat, pi/2 upright), UIKit pen only; nil otherwise.
        public var altitude: CGFloat?
        /// The direction the pen leans, in radians in the view's own coordinates, UIKit pen only; nil otherwise.
        public var azimuth: CGFloat?
        /// The modifier keys held.
        public var modifiers: Modifiers
        /// True for a sample UIKit folded into an event: the movements since the previous event, which a stroke wants for its shape.
        public var isCoalesced: Bool
        /// True for a sample UIKit guessed for the next frame. It is never a fact: draw it, never commit it.
        public var isPredicted: Bool

        /// Creates a sample.
        public init(
            phase: Phase,
            location: CGPoint,
            timestamp: TimeInterval,
            device: Device,
            force: CGFloat? = nil,
            altitude: CGFloat? = nil,
            azimuth: CGFloat? = nil,
            modifiers: Modifiers = [],
            isCoalesced: Bool = false,
            isPredicted: Bool = false
        ) {
            self.phase = phase
            self.location = location
            self.timestamp = timestamp
            self.device = device
            self.force = force
            self.altitude = altitude
            self.azimuth = azimuth
            self.modifiers = modifiers
            self.isCoalesced = isCoalesced
            self.isPredicted = isPredicted
        }
    }
}
