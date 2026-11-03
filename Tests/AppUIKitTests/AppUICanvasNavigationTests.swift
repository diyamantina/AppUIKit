import CoreGraphics
import Testing
@testable import AppUIKit

/// The rules of the canvas's input that do not depend on a platform event, held on plain values: a touch or a scroll cannot be made in a test.
@MainActor
@Suite("AppUICanvas navigation and contacts")
struct AppUICanvasNavigationTests {
    private typealias Canvas = AppUICanvas

    private static func take(_ count: Int, from stream: AsyncStream<Canvas.Navigation>) async -> [Canvas.Navigation] {
        var taken: [Canvas.Navigation] = []
        var iterator = stream.makeAsyncIterator()
        while taken.count < count, let next = await iterator.next() {
            taken.append(next)
        }
        return taken
    }

    // MARK: Navigation values

    @Test
    func `a scroll zooms exactly when Command or Option is held`() {
        let at = CGPoint(x: 5, y: 6)
        let cases: [(Canvas.Modifiers, Bool)] = [([], false), ([.shift], false), ([.control], false), ([.command], true), ([.option], true), ([.command, .shift], true)]
        for (modifiers, zooms) in cases {
            #expect(Canvas.Navigation.scroll(dx: 1, dy: 2, precise: true, modifiers: modifiers, at: at) == .scroll(dx: 1, dy: 2, precise: true, zooms: zooms, at: at))
        }
    }

    @Test
    func `a pinch step is one plus the magnification`() {
        #expect(Canvas.Navigation.pinch(magnification: 0.25, at: .zero) == .pinch(factor: 1.25, at: .zero))
        #expect(Canvas.Navigation.pinch(magnification: 0, at: .zero) == .pinch(factor: 1, at: .zero))
        #expect(Canvas.Navigation.pinch(magnification: -0.5, at: .zero) == .pinch(factor: 0.5, at: .zero))
    }

    @Test(.timeLimit(.minutes(1)))
    func `the navigation stream carries the steps in the order they were reported`() async {
        let canvas = AppUICanvasFixtures.canvas()
        canvas.emit(navigation: .pinch(factor: 2, at: .zero))
        canvas.emit(navigation: .scroll(dx: 1, dy: 1, precise: false, zooms: false, at: .zero))
        canvas.emit(navigation: .smartZoom(at: CGPoint(x: 3, y: 4)))
        let steps = await Self.take(3, from: canvas.navigation)
        #expect(steps == [.pinch(factor: 2, at: .zero), .scroll(dx: 1, dy: 1, precise: false, zooms: false, at: .zero), .smartZoom(at: CGPoint(x: 3, y: 4))])
    }

    // MARK: Pen force

    @Test
    func `a force is a fraction of the most the glass reports, held between 0 and 1`() {
        #expect(Canvas.Contact.normalizedForce(1, maximum: 4) == 0.25)
        #expect(Canvas.Contact.normalizedForce(0, maximum: 4) == 0)
        #expect(Canvas.Contact.normalizedForce(4, maximum: 4) == 1)
        #expect(Canvas.Contact.normalizedForce(9, maximum: 4) == 1)
        #expect(Canvas.Contact.normalizedForce(-1, maximum: 4) == 0)
    }

    @Test
    func `a glass that reports no maximum, or a force that is not a number, gives no force`() {
        #expect(Canvas.Contact.normalizedForce(1, maximum: 0) == nil)
        #expect(Canvas.Contact.normalizedForce(1, maximum: -1) == nil)
        #expect(Canvas.Contact.normalizedForce(.nan, maximum: 4) == nil)
        #expect(Canvas.Contact.normalizedForce(.infinity, maximum: 4) == nil)
    }

    // MARK: One contact draws, a second one navigates

    @Test
    func `the first contact begins, moves and ends`() {
        var tracker = Canvas.ContactTracker<Int>()
        #expect(tracker.landed([1], downCount: 1) == .begin)
        #expect(tracker.current == 1)
        #expect(tracker.moved([1]) == .move)
        #expect(tracker.lifted([1], cancelled: false, remaining: 0) == .end)
        #expect(tracker.current == nil)
    }

    @Test
    func `a second contact cancels the first and nothing draws until all are up`() {
        var tracker = Canvas.ContactTracker<Int>()
        #expect(tracker.landed([1], downCount: 1) == .begin)
        #expect(tracker.landed([2], downCount: 2) == .cancel)
        #expect(tracker.current == nil)
        #expect(tracker.moved([1]) == .ignore)
        // the first finger lifts while the second is still down: the sequence is not over
        #expect(tracker.lifted([1], cancelled: false, remaining: 1) == .ignore)
        #expect(tracker.landed([3], downCount: 2) == .ignore)
        #expect(tracker.lifted([2, 3], cancelled: false, remaining: 0) == .ignore)
        // all up: the next contact draws again
        #expect(tracker.landed([4], downCount: 1) == .begin)
    }

    @Test
    func `two contacts that land together never draw`() {
        var tracker = Canvas.ContactTracker<Int>()
        #expect(tracker.landed([1, 2], downCount: 2) == .ignore)
        #expect(tracker.current == nil)
        #expect(tracker.lifted([1, 2], cancelled: false, remaining: 0) == .ignore)
        #expect(tracker.landed([5], downCount: 1) == .begin)
    }

    @Test
    func `the system cancelling the followed contact is reported as such`() {
        var tracker = Canvas.ContactTracker<Int>()
        _ = tracker.landed([1], downCount: 1)
        #expect(tracker.lifted([1], cancelled: true, remaining: 0) == .system)
        #expect(tracker.current == nil)
    }

    @Test
    func `a contact that is not followed is not reported when it lifts`() {
        var tracker = Canvas.ContactTracker<Int>()
        _ = tracker.landed([1], downCount: 1)
        #expect(tracker.lifted([9], cancelled: false, remaining: 1) == .ignore)
        #expect(tracker.current == 1)
    }

    // MARK: Modifier keys

    @Test(.timeLimit(.minutes(1)))
    func `a change of modifier keys arrives in the pointer's stream at the pointer's last place, and only a change`() async {
        let canvas = AppUICanvasFixtures.canvas()
        canvas.emit(.began, Canvas.Contact(location: CGPoint(x: 7, y: 8), timestamp: 1, device: .mouse), modifiers: [])
        canvas.emit(modifiers: [], timestamp: 2) // no change: nothing
        canvas.emit(modifiers: [.shift], timestamp: 3)
        canvas.emit(modifiers: [.shift], timestamp: 4) // no change: nothing
        canvas.emit(.moved, Canvas.Contact(location: CGPoint(x: 9, y: 9), timestamp: 5, device: .mouse), modifiers: [.shift])
        canvas.emit(modifiers: [], timestamp: 6)
        let samples = await AppUICanvasFixtures.take(4, from: canvas.samples)
        #expect(samples.map(\.phase) == [.began, .modifiersChanged, .moved, .modifiersChanged])
        #expect(samples.map(\.modifiers) == [[], [.shift], [.shift], []])
        #expect(samples[1].location == CGPoint(x: 7, y: 8))
        #expect(samples[3].location == CGPoint(x: 9, y: 9))
    }
}

/// The navigation stream's first steps, for the tests that send a platform event.
enum AppUICanvasNavigationFixtures {
    @MainActor
    static func take(_ count: Int, from stream: AsyncStream<AppUICanvas.Navigation>) async -> [AppUICanvas.Navigation] {
        var taken: [AppUICanvas.Navigation] = []
        var iterator = stream.makeAsyncIterator()
        while taken.count < count, let next = await iterator.next() {
            taken.append(next)
        }
        return taken
    }
}
