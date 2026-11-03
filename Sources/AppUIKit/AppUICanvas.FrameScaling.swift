//
//  AppUICanvas.FrameScaling.swift
//  AppUIKit
//

import CoreGraphics

public extension AppUICanvas {
    /// A scale about a point: the factors along x and y, the point that stays, and the map of the plane they make.
    struct FrameScaling: Equatable, Sendable {
        /// The factor along x: its size within `FrameDrag.factorRange`, negative when the pointer has crossed the opposite edge and the shape is mirrored.
        public let sx: Double
        /// The factor along y, in the same terms.
        public let sy: Double
        /// The point that does not move.
        public let pivot: CGPoint

        public init(sx: Double, sy: Double, pivot: CGPoint) {
            self.sx = sx
            self.sy = sy
            self.pivot = pivot
        }

        /// The map of the plane: `p' = pivot + (sx (x - pivot.x), sy (y - pivot.y))`.
        public var matrix: CGAffineTransform {
            CGAffineTransform(a: CGFloat(sx), b: 0, c: 0, d: CGFloat(sy), tx: pivot.x - CGFloat(sx) * pivot.x, ty: pivot.y - CGFloat(sy) * pivot.y)
        }

        /// Whether the scale changes nothing.
        public var isIdentity: Bool {
            sx == 1 && sy == 1
        }

        /// Whether the shape is mirrored along x.
        public var flipsX: Bool {
            sx < 0
        }

        /// Whether the shape is mirrored along y.
        public var flipsY: Bool {
            sy < 0
        }

        /// How far the box must move after it was scaled by the sizes of the factors about the pivot and mirrored in place, to lie where the signed scale puts it: the mirror image
        /// of the scaled box
        /// across the pivot, so `2 pivot - low - high` along an axis that flips and 0 along one that does not.
        public func shift(of frame: CGRect) -> CGVector {
            func along(_ low: CGFloat, _ high: CGFloat, _ pivot: CGFloat, _ factor: Double) -> CGFloat {
                guard factor < 0 else { return 0 }
                let size = CGFloat(-factor)
                let a = pivot + size * (low - pivot), b = pivot + size * (high - pivot)
                return 2 * pivot - a - b
            }
            return CGVector(dx: along(frame.minX, frame.maxX, pivot.x, sx), dy: along(frame.minY, frame.maxY, pivot.y, sy))
        }
    }
}
