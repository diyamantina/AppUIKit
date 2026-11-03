//
//  AppUICanvas.FrameDrag.swift
//  AppUIKit
//
//  The arithmetic of dragging the handles of a selection's frame, as Sketch does it.
//

import CoreGraphics
import Foundation

public extension AppUICanvas {
    /// The arithmetic of dragging the handles of a selection's frame, in points with the y axis down. Pure functions of the frame, the handle and two points, so each is proven
    /// against its closed form
    /// and the same numbers can drive a preview and the edit a host makes at the release.
    enum FrameDrag {
        /// The smallest and the largest size of a factor a drag asks for. A host whose scale has a narrower range clamps again.
        public static let factorRange = 0.001 ... 1000.0

        /// The scale that dragging `handle` of `frame` from `start` to `current` makes.
        ///
        /// The edge or corner of the handle follows the pointer and the opposite one stays, so the new extent along an axis the handle moves is the old one plus the pointer's
        /// travel along it (with the
        /// sign of the handle): a factor of `(extent + sign * delta) / extent`. A handle of a side moves one axis only. `.fromCentre` (Option) holds the centre instead and moves
        /// both edges, so the
        /// travel counts twice. `.proportional` (Shift) gives both axes one factor: for a corner the one that changed more, for a side the one it moves. A pointer that crosses the
        /// opposite edge
        /// makes the factor negative, as in Sketch: the shape is mirrored and goes on growing on the other side. A size is held within `factorRange`, and a drag that lands on the
        /// opposite edge itself
        /// holds the smallest size, never zero. `.keepsSide` holds a crossing at the smallest size instead of mirroring. An axis of no extent (a line) cannot be scaled along
        /// itself and keeps its
        /// factor 1, unless `.proportional` gives it the other axis's.
        public static func resize(frame: CGRect, handle: FrameHandle, from start: CGPoint, to current: CGPoint, constraint: FrameConstraint = []) -> FrameScaling {
            let proportional = constraint.contains(.proportional), fromCentre = constraint.contains(.fromCentre)
            let pivot = fromCentre ? CGPoint(x: frame.midX, y: frame.midY) : handle.opposite.point(in: frame)
            let gain = fromCentre ? 2.0 : 1.0
            func factor(extent: CGFloat, sign: Double, travel: CGFloat) -> Double? {
                guard sign != 0, extent > 0 else { return nil }
                return (Double(extent) + sign * Double(travel) * gain) / Double(extent)
            }
            var fx = factor(extent: frame.width, sign: handle.xSign, travel: current.x - start.x)
            var fy = factor(extent: frame.height, sign: handle.ySign, travel: current.y - start.y)
            if proportional {
                let common: Double? = switch (fx, fy) {
                case let (x?, y?): abs(x) >= abs(y) ? x : y
                case let (x?, nil): x
                case let (nil, y?): y
                case (nil, nil): nil
                }
                if let common {
                    fx = common
                    fy = common
                }
            }
            let mirrors = !constraint.contains(.keepsSide)
            func held(_ value: Double?) -> Double {
                guard let value else { return 1 }
                if value < 0, !mirrors {
                    return factorRange.lowerBound
                }
                let size = min(max(abs(value), factorRange.lowerBound), factorRange.upperBound)
                return value < 0 ? -size : size
            }
            return FrameScaling(sx: held(fx), sy: held(fy), pivot: pivot)
        }

        /// The angle in degrees, clockwise on the screen, that carries the direction from `centre` to `start` onto the direction from `centre` to `current`, in `(-180, 180]`.
        /// `step` (Shift) rounds it to a
        /// multiple, 15 degrees by the habit of every drawing app. A pointer on the centre has no direction: the angle is 0.
        public static func rotation(about centre: CGPoint, from start: CGPoint, to current: CGPoint, step: Double? = nil) -> Double {
            guard start != centre, current != centre else { return 0 }
            let from = atan2(Double(start.y - centre.y), Double(start.x - centre.x))
            let to = atan2(Double(current.y - centre.y), Double(current.x - centre.x))
            var degrees = (to - from) * 180 / .pi
            degrees -= 360 * (degrees / 360).rounded()
            if degrees <= -180 {
                degrees += 360
            }
            if let step, step > 0 {
                degrees = (degrees / step).rounded() * step
            }
            return degrees == 0 ? 0 : degrees
        }

        /// The map of the plane that turns by `degrees` about `centre`, clockwise on the screen: `(x, y) -> (cos x - sin y, sin x + cos y)` about the point.
        public static func turn(degrees: Double, about centre: CGPoint) -> CGAffineTransform {
            let radians = degrees * .pi / 180
            let cosine = CGFloat(cos(radians)), sine = CGFloat(sin(radians))
            return CGAffineTransform(
                a: cosine, b: sine, c: -sine, d: cosine,
                tx: centre.x - (cosine * centre.x - sine * centre.y), ty: centre.y - (sine * centre.x + cosine * centre.y)
            )
        }
    }
}
