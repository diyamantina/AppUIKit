import Foundation
import Testing
@testable import AppUITesting

/// Waiting for a condition by looking again: answered at once when it holds, answered when something that has to happen on the run loop has happened, and
/// answered no when the time is up, with a last look at the end.
@MainActor
struct AppUIWaitTests {
    /// A flag that another thread sets and this one reads.
    final class Flag: @unchecked Sendable {
        private let lock = NSLock()
        private var isSet = false

        func set() {
            lock.withLock { isSet = true }
        }

        var value: Bool {
            lock.withLock { isSet }
        }
    }

    @Test func `a condition that holds is answered at once, without waiting`() {
        let start = Date()
        #expect(AppUIWait.until(timeout: 5) { true })
        #expect(Date().timeIntervalSince(start) < 1)
    }

    @Test func `a condition that holds only when another thread has made it so, as the app under test does, is waited for`() {
        let happened = Flag()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { happened.set() }
        let start = Date()
        #expect(AppUIWait.until(timeout: 5) { happened.value })
        let took = Date().timeIntervalSince(start)
        #expect(took >= 0.09 && took < 2, "it took \(took) seconds")
    }

    @Test func `a timer of this thread fires while it waits`() {
        var fired = false
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in fired = true }
        defer { timer.invalidate() }
        #expect(AppUIWait.until(timeout: 5) { fired })
    }

    @Test func `a condition that never holds is answered no when the time is up, and not before`() {
        let start = Date()
        #expect(!AppUIWait.until(timeout: 0.3, interval: 0.02) { false })
        let took = Date().timeIntervalSince(start)
        #expect(took >= 0.3 && took < 1.5, "it took \(took) seconds")
    }

    @Test func `the condition is looked at once more at the end, so that what became true at the last moment counts, and with no time it is looked at once`() {
        var looks = 0
        #expect(!AppUIWait.until(timeout: 0) {
            looks += 1
            return false
        })
        #expect(looks == 2, "once to begin and once at the end")
        #expect(AppUIWait.until(timeout: 0) { true })
        // True only at the second look, which the end of the time makes.
        var count = 0
        #expect(AppUIWait.until(timeout: 0) {
            count += 1
            return count >= 2
        })
    }

    @Test func `how often it looks is the interval and not more often`() {
        var looks = 0
        _ = AppUIWait.until(timeout: 0.5, interval: 0.1) {
            looks += 1
            return false
        }
        #expect(looks >= 3 && looks <= 12, "looked \(looks) times")
    }

    @Test func `a value that stops changing is given when it has been still for as long as was asked, and one that never does is not`() {
        // It changes for a while, then stays.
        let start = Date()
        let settled = AppUIWait
            .settled(quiet: 0.2, timeout: 5, interval: 0.02) { Int(Date().timeIntervalSince(start) / 0.3) < 2 ? Int(Date().timeIntervalSince(start) / 0.05) : 999 }
        #expect(settled == 999)
        #expect(Date().timeIntervalSince(start) >= 0.8, "it was still only after 0.6 seconds, and for 0.2 more")
        // It never stops.
        var counter = 0
        #expect(AppUIWait.settled(quiet: 0.3, timeout: 0.6, interval: 0.02) {
            counter += 1
            return counter
        } == nil)
    }
}
