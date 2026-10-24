import Foundation
import Testing
@testable import AppUIKit

/// The line of each offset held to a count of the breaks before it, made independently of the search.
struct AppUILineNumbersTests {
    /// The line of `offset` by counting the breaks that lie wholly before it, one character at a time: a line feed, a carriage return not followed by a line feed,
    /// and a carriage return with its line feed when both are before `offset`.
    private func slow(_ units: [UInt16], _ offset: Int) -> Int {
        var line = 1
        var index = 0
        while index < units.count {
            let next = index + 1 < units.count ? units[index + 1] : nil
            if units[index] == 0x0D, next == 0x0A {
                if index + 2 <= offset {
                    line += 1
                }
                index += 2
            } else {
                if units[index] == 0x0A || units[index] == 0x0D, index + 1 <= offset {
                    line += 1
                }
                index += 1
            }
        }
        return line
    }

    @Test func `an empty text is one line, and a text ending in a break has an empty last line`() {
        #expect(AppUILineNumbers(text: "").count == 1)
        #expect(AppUILineNumbers(text: "a").count == 1)
        #expect(AppUILineNumbers(text: "a\n").count == 2)
        #expect(AppUILineNumbers(text: "a\nb\n\n").count == 4)
    }

    @Test func `a carriage return and line feed together are one break`() {
        let lines = AppUILineNumbers(text: "a\r\nb\rc\nd")
        #expect(lines.starts == [0, 3, 5, 7])
        #expect(lines.count == 4)
    }

    @Test func `the line of each offset of a made-up text is the one counted by hand`() {
        let pieces = ["a", "bb", "\n", "\n", "\r", "\r\n", "é", "日本", "😀", " "]
        var state: UInt64 = 0x9E37_79B9_7F4A_7C15
        for _ in 0 ..< 200 {
            var text = ""
            for _ in 0 ..< 40 {
                state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                text += pieces[Int((state >> 33) % UInt64(pieces.count))]
            }
            let units = Array(text.utf16)
            let lines = AppUILineNumbers(text: text)
            for offset in 0 ... units.count {
                #expect(lines.line(at: offset) == slow(units, offset), "offset \(offset) of \(text.debugDescription)")
            }
        }
    }

    @Test func `a line starts exactly after a break, and the first line starts at 0`() {
        let lines = AppUILineNumbers(text: "ab\ncd\n")
        #expect(lines.startsLine(at: 0) && lines.startsLine(at: 3) && lines.startsLine(at: 6))
        #expect(!lines.startsLine(at: 1) && !lines.startsLine(at: 2) && !lines.startsLine(at: 4))
        #expect(lines.line(at: 99) == 3, "past the end is the last line")
    }

    @Test func `the width of the column is the digits of the last line number`() {
        #expect(AppUILineNumbers(text: "").digits == 1)
        #expect(AppUILineNumbers(text: String(repeating: "\n", count: 99)).digits == 3)
        #expect(AppUILineNumbers(text: String(repeating: "\n", count: 98)).digits == 2)
    }
}
