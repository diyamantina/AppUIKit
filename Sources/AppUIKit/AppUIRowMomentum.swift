import Foundation

/// How a flick keeps moving after the finger leaves: the speed falls by the same share in the same time, so after `t` seconds it is
/// `velocity * rate^(1000 t)` and the distance gone is the area under that, which is found exactly and not by adding up frames. A device that draws a
/// frame late goes just as far as one that draws on time.
struct AppUIRowMomentum: Equatable, Sendable {
    /// The share of the speed kept after a thousandth of a second; the rate of a system scroll view's normal deceleration.
    static let rate = 0.998
    /// Under this speed, in points a second, it has stopped.
    static let stopsBelow = 8.0

    /// Points a second, signed.
    private(set) var velocity: Double

    var isMoving: Bool {
        abs(velocity) >= Self.stopsBelow
    }

    /// The distance the flick goes in `seconds` more, and the speed after it.
    mutating func advance(by seconds: Double) -> Double {
        guard isMoving, seconds > 0 else { return 0 }
        let decay = pow(Self.rate, seconds * 1000)
        let distance = velocity * (decay - 1) / (1000 * log(Self.rate))
        velocity *= decay
        return distance
    }

    /// The whole distance a flick of `velocity` goes before it stops by itself, ignoring the stop below which it is called still.
    static func reach(of velocity: Double) -> Double {
        velocity / (-1000 * log(rate))
    }
}
