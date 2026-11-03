//
//  AppUICanvas.FrameReach.swift
//  AppUIKit
//

import CoreGraphics

public extension AppUICanvas {
    /// How near a press has to be, in view points, for each part. A mouse is exact, a pencil nearly, a fingertip is a thumb-sized blur, so the targets grow with the device: the
    /// touch reach is the
    /// 44 point target of Apple's guidelines (a radius of 22).
    struct FrameReach: Equatable, Sendable {
        /// The radius of a handle's target.
        public var handle: CGFloat
        /// How far outside a corner a press still rotates.
        public var rotate: CGFloat
        /// How far either side of an edge a press still takes the edge (less on a frame too thin to hold the band twice).
        public var edge: CGFloat

        public init(handle: CGFloat, rotate: CGFloat, edge: CGFloat) {
            self.handle = handle
            self.rotate = rotate
            self.edge = edge
        }

        /// The reach of a device.
        public static func of(_ device: Device) -> FrameReach {
            switch device {
            case .mouse, .trackpad: FrameReach(handle: 7, rotate: 22, edge: 6)
            case .pencil: FrameReach(handle: 11, rotate: 28, edge: 8)
            case .touch: FrameReach(handle: 22, rotate: 44, edge: 16)
            }
        }
    }
}
