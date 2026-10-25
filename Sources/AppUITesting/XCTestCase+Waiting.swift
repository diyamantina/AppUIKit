//
//  XCTestCase+Waiting.swift
//  AppUITesting
//
//  The waits of a UI test, said in terms of what an element shows. Each fails the test at the line that asked, with what was waited for and what was there.
//

import XCTest

public extension XCUIElement {
    /// What the element says: its value when it has one, else its label, which is where the system puts the words of some static texts.
    var words: String {
        (value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? label
    }
}

@MainActor
public extension XCTestCase {
    /// Waits until `condition` holds, and fails the test, saying `what` was waited for, when it does not within `timeout` seconds.
    func waitUntil(
        _ what: @autoclosure () -> String, timeout: TimeInterval = AppUIWait.defaultTimeout, file: StaticString = #filePath, line: UInt = #line,
        _ condition: () -> Bool
    ) {
        if !AppUIWait.until(timeout: timeout, condition) {
            XCTFail("Waited \(Int(timeout)) seconds for \(what())", file: file, line: line)
        }
    }

    /// Waits until the words of `element` are such that `matches` holds of them; on failure says what they were.
    func waitForWords(
        of element: XCUIElement, _ what: @autoclosure () -> String, timeout: TimeInterval = AppUIWait.defaultTimeout, file: StaticString = #filePath,
        line: UInt = #line, matching matches: (String) -> Bool
    ) {
        if !AppUIWait.until(timeout: timeout, { element.exists && matches(element.words) }) {
            let said = element.exists ? String(element.words.prefix(200)).debugDescription : "nothing: it is not there"
            XCTFail("Waited \(Int(timeout)) seconds for \(what()); the element said \(said)", file: file, line: line)
        }
    }

    func waitForWords(
        of element: XCUIElement, hasPrefix prefix: String, timeout: TimeInterval = AppUIWait.defaultTimeout, file: StaticString = #filePath, line: UInt = #line
    ) {
        waitForWords(of: element, "words that begin \(prefix.debugDescription)", timeout: timeout, file: file, line: line) { $0.hasPrefix(prefix) }
    }

    func waitForWords(
        of element: XCUIElement, contains text: String, timeout: TimeInterval = AppUIWait.defaultTimeout, file: StaticString = #filePath, line: UInt = #line
    ) {
        waitForWords(of: element, "words that hold \(text.debugDescription)", timeout: timeout, file: file, line: line) { $0.contains(text) }
    }

    func waitForWords(
        of element: XCUIElement, doesNotContain text: String, timeout: TimeInterval = AppUIWait.defaultTimeout, file: StaticString = #filePath, line: UInt = #line
    ) {
        waitForWords(of: element, "words that do not hold \(text.debugDescription)", timeout: timeout, file: file, line: line) { !$0.contains(text) }
    }

    func waitForWords(
        of element: XCUIElement, equal text: String, timeout: TimeInterval = AppUIWait.defaultTimeout, file: StaticString = #filePath, line: UInt = #line
    ) {
        waitForWords(of: element, "the words \(text.debugDescription)", timeout: timeout, file: file, line: line) { $0 == text }
    }

    /// Waits until the element is not there.
    func waitUntilGone(_ element: XCUIElement, timeout: TimeInterval = AppUIWait.defaultTimeout, file: StaticString = #filePath, line: UInt = #line) {
        waitUntil("\(element) to go", timeout: timeout, file: file, line: line) { !element.exists }
    }

    /// Waits until the element is there, and fails the test when it is not.
    func waitUntilThere(_ element: XCUIElement, timeout: TimeInterval = AppUIWait.defaultTimeout, file: StaticString = #filePath, line: UInt = #line) {
        waitUntil("\(element) to appear", timeout: timeout, file: file, line: line) { element.exists }
    }

    /// Waits until the element can be clicked: it is there and on the screen. A person cannot click what they cannot see, and neither can a test.
    func waitUntilClickable(_ element: XCUIElement, timeout: TimeInterval = AppUIWait.defaultTimeout, file: StaticString = #filePath, line: UInt = #line) {
        waitUntil("\(element) to be clickable", timeout: timeout, file: file, line: line) { element.exists && element.isHittable }
    }

    /// Waits until the words of some element of `query` are such that `matches` holds of them: for finding a static text by what it says when it has no
    /// name of its own to be found by.
    func waitForAnyWords(
        in query: XCUIElementQuery, _ what: @autoclosure () -> String, timeout: TimeInterval = AppUIWait.defaultTimeout, file: StaticString = #filePath,
        line: UInt = #line, matching matches: (String) -> Bool
    ) {
        waitUntil(what(), timeout: timeout, file: file, line: line) { query.allElementsBoundByIndex.contains { matches($0.words) } }
    }

    /// Waits until the words of `element` have stopped changing for `quiet` seconds, and gives them; fails the test when they never do.
    @discardableResult
    func waitUntilStill(
        _ element: XCUIElement, for quiet: TimeInterval = 1, timeout: TimeInterval = AppUIWait.defaultTimeout, file: StaticString = #filePath, line: UInt = #line
    ) -> String {
        guard let settled = AppUIWait.settled(quiet: quiet, timeout: timeout, { element.exists ? element.words : "" }) else {
            XCTFail("Waited \(Int(timeout)) seconds for \(element) to stop changing", file: file, line: line)
            return ""
        }
        return settled
    }
}
