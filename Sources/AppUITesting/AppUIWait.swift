//
//  AppUIWait.swift
//  AppUITesting
//
//  Waiting for a UI to be what a test expects, by looking again until it is or the time is up. A test says what it is waiting for in words and a condition;
//  it does not build a predicate, and it does not sleep: a sleep is a guess at how long a thing takes, and a wait is the thing itself.
//

import Foundation

/// Looks again at a condition until it holds or the time is up.
public enum AppUIWait {
    /// How long a wait is, when a test does not say: long enough for a large file to be read, short enough that a test that cannot pass ends.
    public static let defaultTimeout: TimeInterval = 30

    /// Whether `condition` held within `timeout` seconds, looked at every `interval`. Between looks the run loop runs, so that what a timer or a source of the
    /// test's own process has to do gets done, and the rest of the interval is waited out, so that the UI is looked at as often as is asked and no oftener.
    ///
    /// - Parameters:
    ///   - timeout: How long to look, in seconds. A condition that holds at once is answered at once; one that does not is looked at once more at the end.
    ///   - interval: How long between looks.
    ///   - condition: What is waited for.
    @MainActor
    public static func until(timeout: TimeInterval = defaultTimeout, interval: TimeInterval = 0.05, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            let remaining = deadline.timeIntervalSinceNow
            guard remaining > 0 else { return condition() }
            let until = Date().addingTimeInterval(min(max(0.001, interval), remaining))
            RunLoop.current.run(mode: .default, before: until)
            // The run loop returns at once when it has nothing to run; the rest of the interval is not spent looking.
            let rest = until.timeIntervalSinceNow
            if rest > 0 {
                Thread.sleep(forTimeInterval: rest)
            }
        }
        return true
    }

    /// Whether `value` stayed as it was, for `quiet` seconds in a row, within `timeout`: for what a screen does after something was asked of it, when
    /// nothing says it is done but its not changing any more.
    ///
    /// - Returns: The value it settled at, or nil when it kept changing until the time was up.
    @MainActor
    public static func settled<Value: Equatable>(
        quiet: TimeInterval = 1, timeout: TimeInterval = defaultTimeout, interval: TimeInterval = 0.05, _ read: () -> Value
    ) -> Value? {
        var last = read()
        var since = Date()
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            _ = until(timeout: min(interval, max(0.001, deadline.timeIntervalSinceNow)), interval: interval) { false }
            let now = read()
            if now != last {
                last = now
                since = Date()
            } else if Date().timeIntervalSince(since) >= quiet {
                return now
            }
        }
        return nil
    }
}
