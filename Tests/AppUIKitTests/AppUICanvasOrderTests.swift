import CoreGraphics
import Testing
@testable import AppUIKit

/// The order in which the samples of one UIKit event reach the stream. UITouch cannot be made in a test, so the rule is held where it lives,
/// in the function both platforms call, with touches written as plain values.
@MainActor
@Suite("AppUICanvas sample order")
struct AppUICanvasOrderTests {
    private typealias Canvas = AppUICanvas

    private static func contact(_ x: CGFloat, at time: Double) -> Canvas.Contact {
        Canvas.Contact(location: CGPoint(x: x, y: 10), timestamp: time, device: .pencil, force: 0.5, altitude: 1, azimuth: 2)
    }

    private static func xs(_ samples: [Canvas.Sample]) -> [CGFloat] {
        samples.map(\.location.x)
    }

    @Test
    func `a moved event gives the folded touches, then its own, then the predicted ones`() {
        let folded = [Self.contact(1, at: 1), Self.contact(2, at: 2)]
        let samples = Canvas.samples(phase: .moved, folded: folded, own: Self.contact(3, at: 3), predicted: [Self.contact(4, at: 4), Self.contact(5, at: 5)], modifiers: [.shift])
        #expect(Self.xs(samples) == [1, 2, 3, 4, 5])
        #expect(samples.map(\.isCoalesced) == [true, true, false, false, false])
        #expect(samples.map(\.isPredicted) == [false, false, false, true, true])
        #expect(samples.map(\.phase) == [.moved, .moved, .moved, .moved, .moved])
        #expect(samples.allSatisfy { $0.modifiers == [.shift] })
    }

    @Test
    func `UIKit's folded list ends with the event's own touch, which is not given twice`() {
        let own = Self.contact(3, at: 3)
        let samples = Canvas.samples(phase: .moved, folded: [Self.contact(1, at: 1), Self.contact(2, at: 2), own], own: own, predicted: [], modifiers: [])
        #expect(Self.xs(samples) == [1, 2, 3])
        #expect(samples.map(\.isCoalesced) == [true, true, false])
    }

    @Test
    func `a touch that begins is alone, so no movement comes before the beginning`() {
        let own = Self.contact(3, at: 3)
        let samples = Canvas.samples(phase: .began, folded: [Self.contact(1, at: 1), own], own: own, predicted: [Self.contact(4, at: 4)], modifiers: [])
        #expect(samples.map(\.phase) == [.began])
        #expect(Self.xs(samples) == [3])
    }

    @Test
    func `a touch that lifts gives the folded movement first and then the lift, with no prediction`() {
        let own = Self.contact(3, at: 3)
        let samples = Canvas.samples(phase: .ended, folded: [Self.contact(2, at: 2), own], own: own, predicted: [Self.contact(4, at: 4)], modifiers: [])
        #expect(samples.map(\.phase) == [.moved, .ended])
        #expect(Self.xs(samples) == [2, 3])
        #expect(samples.last?.isPredicted == false)
    }

    @Test
    func `a folded list that does not hold the own touch keeps all of it`() {
        let samples = Canvas.samples(phase: .moved, folded: [Self.contact(1, at: 1), Self.contact(2, at: 2)], own: Self.contact(3, at: 3), predicted: [], modifiers: [])
        #expect(Self.xs(samples) == [1, 2, 3])
    }

    @Test
    func `the pen's force, altitude and azimuth ride with every sample`() {
        let samples = Canvas.samples(phase: .moved, folded: [Self.contact(1, at: 1)], own: Self.contact(3, at: 3), predicted: [Self.contact(4, at: 4)], modifiers: [])
        #expect(samples.allSatisfy { $0.force == 0.5 && $0.altitude == 1 && $0.azimuth == 2 && $0.device == .pencil })
    }

    @Test
    func `a canvas yields the samples of an event into its stream in that order`() async {
        let canvas = AppUICanvasFixtures.canvas()
        let own = Self.contact(3, at: 3)
        canvas.emit(phase: .moved, folded: [Self.contact(1, at: 1), own], own: own, predicted: [Self.contact(4, at: 4)], modifiers: [])
        let taken = await AppUICanvasFixtures.take(3, from: canvas.samples)
        #expect(Self.xs(taken) == [1, 3, 4])
    }
}
