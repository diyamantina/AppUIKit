import CoreGraphics
import Foundation
import Testing
@testable import AppUIKit

/// The modifiers a host holds for the person (`AppUICanvas.heldModifiers`, a touch screen's Uniform and From centre switches): every report carries them beside the keys of the
/// event, a change is one report at the pointer's place,
/// the same value again is none, and letting go takes them away again whatever else is held.
@MainActor
@Suite("AppUICanvas held modifiers")
struct AppUICanvasHeldModifierTests {
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
    func `a held key is one report at the pointer's place, is carried by the pointer, and goes with the switch`() async {
        let canvas = AppUICanvasFixtures.canvas()
        canvas.lastLocation = CGPoint(x: 9, y: 4)
        canvas.heldModifiers = [.shift]
        canvas.heldModifiers = [.shift] // the same value: nothing
        canvas.emit(.began, AppUICanvas.Contact(location: CGPoint(x: 20, y: 30), timestamp: 3, device: .touch), modifiers: [])
        canvas.heldModifiers = [.shift, .option]
        canvas.emit(.moved, AppUICanvas.Contact(location: CGPoint(x: 22, y: 30), timestamp: 4, device: .touch), modifiers: [.command])
        canvas.heldModifiers = []
        canvas.emit(.ended, AppUICanvas.Contact(location: CGPoint(x: 22, y: 30), timestamp: 5, device: .touch), modifiers: [])
        let found = await reports(canvas, count: 6)
        #expect(found.map(\.phase) == [.modifiersChanged, .began, .modifiersChanged, .moved, .modifiersChanged, .ended])
        #expect(
            found.map(\.modifiers) == [[.shift], [.shift], [.shift, .option], [.shift, .option, .command], [.command], []],
            "held keys beside the event's own, and gone with the switch"
        )
        #expect(found[0].location == CGPoint(x: 9, y: 4))
    }

    @Test(.timeLimit(.minutes(1)))
    func `a held key that the keyboard also holds is not lost when the switch goes`() async {
        let canvas = AppUICanvasFixtures.canvas()
        canvas.heldModifiers = [.shift]
        canvas.emit(modifiers: [.shift], timestamp: 1) // the keyboard's Shift as well: no change of what is carried
        canvas.heldModifiers = []
        canvas.emit(modifiers: [], timestamp: 2) // the keyboard's Shift comes up
        let found = await reports(canvas, count: 2)
        #expect(
            found.map(\.modifiers) == [[.shift], []],
            "the switch made one report; letting go of it changed nothing while the keyboard held Shift, and the keyboard's release was the next report"
        )
        #expect(found[1].timestamp == 2, "the second report is the keyboard's, not the switch's")
    }
}
