import Foundation
import Testing
@testable import AppUIKit

struct AppUIRowMomentumTests {
    @Test func `the distance gone does not depend on how the time is cut into frames`() {
        for velocity in [-9000.0, -800, 30, 450, 6000] {
            var whole = AppUIRowMomentum(velocity: velocity)
            let once = whole.advance(by: 1.2)
            for frame in [1.0 / 120, 1.0 / 60, 1.0 / 30, 0.0173] {
                var cut = AppUIRowMomentum(velocity: velocity)
                var total = 0.0
                var elapsed = 0.0
                while elapsed + frame <= 1.2 + 1e-12 {
                    total += cut.advance(by: frame)
                    elapsed += frame
                }
                total += cut.advance(by: 1.2 - elapsed)
                // The only difference allowed is what is left under the speed at which it is called still, which cut into frames is not gone.
                #expect(abs(total - once) < AppUIRowMomentum.reach(of: AppUIRowMomentum.stopsBelow) + 0.01, "velocity \(velocity) frame \(frame): \(total) against \(once)")
            }
        }
    }

    @Test func `a flick goes the distance its speed gives in the end, and keeps its direction`() {
        for velocity in [-5000.0, 1200, 20000] {
            var flick = AppUIRowMomentum(velocity: velocity)
            var total = 0.0
            var frames = 0
            while flick.isMoving, frames < 100_000 {
                total += flick.advance(by: 1.0 / 60)
                frames += 1
            }
            #expect(frames < 100_000, "it stops")
            let reach = AppUIRowMomentum.reach(of: velocity)
            // What is left when it is called still is the speed at the stop over the rate of decay.
            let left = AppUIRowMomentum.reach(of: velocity.sign == .minus ? -AppUIRowMomentum.stopsBelow : AppUIRowMomentum.stopsBelow)
            #expect(abs(total - (reach - left)) < 1, "velocity \(velocity): \(total) against \(reach - left)")
            #expect(total.sign == velocity.sign)
        }
    }

    @Test func `a speed under the stop does not move, and time that does not pass does not either`() {
        var slow = AppUIRowMomentum(velocity: 5)
        #expect(!slow.isMoving && slow.advance(by: 1) == 0)
        var fast = AppUIRowMomentum(velocity: 3000)
        #expect(fast.advance(by: 0) == 0 && fast.advance(by: -1) == 0 && fast.velocity == 3000)
    }
}
