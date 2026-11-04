import Testing
@testable import AppUIKit

/// Palm rejection by pencil priority (`ContactTracker`): a resting hand does not cancel a pencil stroke, and a pencil takes over from a hand that was drawing. A touch cannot be
/// made in a test, so the rule is held on plain values.
@Suite("AppUICanvas palm rejection")
struct AppUICanvasPalmTests {
    typealias Tracker = AppUICanvas.ContactTracker<Int>

    @Test
    func `a palm that lands while the pencil draws cancels nothing and is not a pinch`() {
        var tracker = Tracker()
        #expect(tracker.landed([1], downCount: 1, pencil: [1]) == .begin)
        #expect(tracker.landed([2], downCount: 2) == .ignore, "the hand lands")
        #expect(tracker.current == 1, "the pencil is still the contact followed")
        #expect(tracker.moved([2]) == .ignore && tracker.moved([1]) == .move)
        #expect(tracker.landed([3], downCount: 3) == .ignore, "and so does a second finger of the hand")
        #expect(tracker.lifted([2], cancelled: false, remaining: 2) == .ignore, "the palm lifting is nothing")
        #expect(tracker.lifted([1], cancelled: false, remaining: 1) == .end, "the pencil lifting ends the stroke")
        #expect(tracker.landed([4], downCount: 2) == .ignore, "a finger landing while the hand is still down does not draw")
        #expect(tracker.lifted([3, 4], cancelled: false, remaining: 0) == .ignore)
        #expect(tracker.landed([5], downCount: 1) == .begin, "all up: the next contact draws again")
    }

    @Test
    func `a pencil that lands while a finger draws takes over from it`() {
        var tracker = Tracker()
        #expect(tracker.landed([1], downCount: 1) == .begin, "the palm lands first and is followed")
        #expect(tracker.landed([2], downCount: 2, pencil: [2]) == .replace, "the pencil lands: the palm's stroke is cancelled and the pencil begins")
        #expect(tracker.current == 2)
        #expect(tracker.moved([2]) == .move && tracker.moved([1]) == .ignore)
        #expect(tracker.lifted([2], cancelled: false, remaining: 1) == .end)
        #expect(tracker.moved([1]) == .ignore, "the palm does not draw once the pencil has lifted")
    }

    @Test
    func `a pencil draws even when several fingers were already down`() {
        var tracker = Tracker()
        #expect(tracker.landed([1, 2], downCount: 2) == .ignore, "two fingers land together: nothing draws")
        #expect(tracker.landed([3], downCount: 3, pencil: [3]) == .begin, "the pencil still does")
        #expect(tracker.current == 3)
        #expect(tracker.lifted([3], cancelled: true, remaining: 2) == .system)
        #expect(tracker.landed([4], downCount: 3) == .ignore, "the fingers stay out of the way")
    }

    @Test
    func `without a pencil the rule is the one it was`() {
        var tracker = Tracker()
        #expect(tracker.landed([1], downCount: 1) == .begin)
        #expect(tracker.landed([2], downCount: 2) == .cancel, "a second finger still turns the gesture into a pinch")
    }
}
