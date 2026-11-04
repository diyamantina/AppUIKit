//
//  AppUICanvas.Navigation.swift
//  AppUIKit
//
import CoreGraphics
import Foundation

public extension AppUICanvas {
    /// One step of a change of view that a trackpad, a wheel or two fingers ask for, in the view's own points with the origin at the top left.
    ///
    /// The canvas reports the step and does no arithmetic with it: the host decides what a pan or a zoom is. Each case carries the pointer, so a
    /// zoom can keep that point where it is.
    enum Navigation: Sendable, Equatable {
        /// A scroll: `dx` and `dy` as the platform reports them for content that follows them (a trackpad in points, a wheel in lines when
        /// `precise` is false). `zooms` is true while Command or Option is held, which the host reads as a zoom and not a pan.
        case scroll(dx: CGFloat, dy: CGFloat, precise: Bool, zooms: Bool, at: CGPoint)
        /// A pinch step: the factor asked for relative to the step before it (1 means no change).
        case pinch(factor: CGFloat, at: CGPoint)
        /// A smart zoom (a two-finger double tap) at a point.
        case smartZoom(at: CGPoint)
        /// A twist step: the turn of this step as a unit vector (clockwise on the screen is positive), about the fingers' centre.
        case turn(cosine: CGFloat, sine: CGFloat, at: CGPoint)
        /// The fingers lifted after a twist: the host settles the turn (snaps it to a quarter turn when close).
        case settleTurn

        /// A scroll with `zooms` read from the modifier keys: Command or Option held.
        public static func scroll(dx: CGFloat, dy: CGFloat, precise: Bool, modifiers: Modifiers, at point: CGPoint) -> Navigation {
            .scroll(dx: dx, dy: dy, precise: precise, zooms: !modifiers.isDisjoint(with: [.command, .option]), at: point)
        }

        /// A twist step from a platform's angle, in radians, clockwise on the screen positive: the unit vector of the angle.
        public static func twist(radians: CGFloat, at point: CGPoint) -> Navigation {
            .turn(cosine: CGFloat(cos(Double(radians))), sine: CGFloat(sin(Double(radians))), at: point)
        }

        /// A pinch step from a platform's change of magnification since the last step: the factor is `1 + magnification`.
        public static func pinch(magnification: CGFloat, at point: CGPoint) -> Navigation {
            .pinch(factor: 1 + magnification, at: point)
        }
    }
}
