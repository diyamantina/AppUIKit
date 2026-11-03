//
//  AppUICanvas.Contact.swift
//  AppUIKit
//

import CoreGraphics
import Foundation

extension AppUICanvas {
    /// What one platform event says of a contact, before the canvas gives it a phase: the part of a ``Sample`` that does not depend on how the
    /// event is delivered. Each platform file reads its own events into this, so the ordering rules live once, in `AppUICanvas.samples(...)`.
    struct Contact: Equatable {
        var location: CGPoint
        var timestamp: TimeInterval
        var device: Device
        var force: CGFloat?
        var altitude: CGFloat?
        var azimuth: CGFloat?
        var tilt: CGPoint?

        init(
            location: CGPoint,
            timestamp: TimeInterval,
            device: Device,
            force: CGFloat? = nil,
            altitude: CGFloat? = nil,
            azimuth: CGFloat? = nil,
            tilt: CGPoint? = nil
        ) {
            self.location = location
            self.timestamp = timestamp
            self.device = device
            self.force = force
            self.altitude = altitude
            self.azimuth = azimuth
            self.tilt = tilt
        }

        /// A force as a fraction from 0 to 1 of the most the glass can report, or nil when the glass reports none (a maximum of 0 or less).
        static func normalizedForce(_ force: CGFloat, maximum: CGFloat) -> CGFloat? {
            guard maximum > 0, force.isFinite else { return nil }
            return min(max(force / maximum, 0), 1)
        }

        /// The sample this contact makes.
        func sample(_ phase: Phase, modifiers: Modifiers, isCoalesced: Bool = false, isPredicted: Bool = false) -> Sample {
            Sample(
                phase: phase,
                location: location,
                timestamp: timestamp,
                device: device,
                force: force,
                altitude: altitude,
                azimuth: azimuth,
                tilt: tilt,
                modifiers: modifiers,
                isCoalesced: isCoalesced,
                isPredicted: isPredicted
            )
        }
    }
}
