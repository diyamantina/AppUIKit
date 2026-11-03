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

        init(
            location: CGPoint,
            timestamp: TimeInterval,
            device: Device,
            force: CGFloat? = nil,
            altitude: CGFloat? = nil,
            azimuth: CGFloat? = nil
        ) {
            self.location = location
            self.timestamp = timestamp
            self.device = device
            self.force = force
            self.altitude = altitude
            self.azimuth = azimuth
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
                modifiers: modifiers,
                isCoalesced: isCoalesced,
                isPredicted: isPredicted
            )
        }
    }
}
