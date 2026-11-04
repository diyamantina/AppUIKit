import CoreGraphics
import Foundation
import Testing
@testable import AppUIKit

/// The X key's state, which the AppKit and the UIKit views share (the key events that set it are AppKit's `AppUICanvasMarqueeKeyTests`; a UIKit `UIPress` cannot be made in a
/// test): holding it adds
/// `Modifiers.marquee` to every report, a change is one report at the pointer's last place, the same state again is none, and letting go takes the bit away again, whatever else is
/// held.
@MainActor
@Suite("AppUICanvas X key state")
struct AppUICanvasMarqueeStateTests {
    private func reports(_ canvas: AppUICanvas, count: Int) async -> [AppUICanvas.Sample] {
        var iterator = canvas.samples.makeAsyncIterator()
        var found: [AppUICanvas.Sample] = []
        for _ in 0 ..< count {
            if let sample = await iterator.next() {
                found.append(sample)
            }
        }
        return found
    }

    @Test(.timeLimit(.minutes(1)))
    func `a change of the key is one report at the pointer's place, the same state again is none, and a pointer report carries the bit while it is held`() async {
        let canvas = AppUICanvasFixtures.canvas()
        canvas.lastLocation = CGPoint(x: 9, y: 4)
        canvas.holdMarquee(true, timestamp: 1)
        canvas.holdMarquee(true, timestamp: 2)
        canvas.emit(.began, AppUICanvas.Contact(location: CGPoint(x: 20, y: 30), timestamp: 3, device: .mouse), modifiers: [.shift])
        canvas.holdMarquee(false, timestamp: 4)
        canvas.holdMarquee(false, timestamp: 5)
        canvas.emit(.ended, AppUICanvas.Contact(location: CGPoint(x: 20, y: 30), timestamp: 6, device: .mouse), modifiers: [.shift])
        let found = await reports(canvas, count: 4)
        #expect(found.map(\.phase) == [.modifiersChanged, .began, .modifiersChanged, .ended])
        #expect(found.map(\.modifiers) == [[.marquee], [.shift, .marquee], [.shift], [.shift]], "the bit is there only while the key is held, and Shift is kept beside it")
        #expect(found[0].location == CGPoint(x: 9, y: 4))
        #expect(!canvas.isMarqueeHeld)
    }
}
