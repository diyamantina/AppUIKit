import Foundation
import Testing
@testable import AppUIKit

/// The caret keys in the words of no platform, so that what the Mac and the iPad do with them is held by the same tests.
@MainActor
struct AppUIRowViewCaretKeyTests {
    final class Lines: AppUIRowSource {
        let texts: [String]
        init(_ texts: [String]) {
            self.texts = texts
        }

        var rowCount: Int {
            texts.count
        }

        func rows(in range: Range<Int>) -> [AppUIRow] {
            (max(0, range.lowerBound) ..< min(texts.count, range.upperBound)).map { AppUIRow(text: texts[$0], gutter: "\($0 + 1)") }
        }
    }

    private func makeView(_ texts: [String]) -> (AppUIRowView, Lines) {
        let source = Lines(texts)
        let view = AppUIRowView(frame: CGRect(x: 0, y: 0, width: 480, height: 200))
        view.gutterDigits = 3
        view.source = source
        view.isEditable = true
        return (view, source)
    }

    private func press(_ key: AppUIRowCaretKey, shift: Bool = false, option: Bool = false, command: Bool = false, in view: AppUIRowView) {
        #expect(view.moved(by: key, extending: shift, option: option, command: command))
    }

    @Test func `the arrows move the caret over characters and rows, and home and end go to the ends of the row`() {
        let (view, source) = makeView(["abc", "", "e\u{301}f😀g"])
        defer { withExtendedLifetime(source) {} }
        view.setCaret(AppUIRowPosition(row: 0, column: 1))
        press(.right, in: view)
        #expect(view.caret == AppUIRowPosition(row: 0, column: 2))
        press(.down, in: view)
        #expect(view.caret == AppUIRowPosition(row: 1, column: 0), "a shorter row holds the caret at its end")
        press(.down, in: view)
        #expect(view.caret == AppUIRowPosition(row: 2, column: 0))
        press(.right, in: view)
        #expect(view.caret == AppUIRowPosition(row: 2, column: 2), "a letter with its accent is one character")
        press(.right, in: view)
        press(.right, in: view)
        #expect(view.caret == AppUIRowPosition(row: 2, column: 5), "so is an emoji of two UTF-16 units")
        press(.home, in: view)
        #expect(view.caret == AppUIRowPosition(row: 2, column: 0))
        press(.end, in: view)
        #expect(view.caret == AppUIRowPosition(row: 2, column: 6))
        press(.left, in: view)
        #expect(view.caret == AppUIRowPosition(row: 2, column: 5))
    }

    @Test func `with shift they select, option goes by words and command to the ends of the row and the document`() {
        let (view, source) = makeView(["one two  three", "", "four"])
        defer { withExtendedLifetime(source) {} }
        view.setCaret(AppUIRowPosition(row: 0, column: 0))
        press(.right, option: true, in: view)
        #expect(view.caret == AppUIRowPosition(row: 0, column: 3), "to the end of the first word")
        press(.left, option: true, in: view)
        #expect(view.caret == AppUIRowPosition(row: 0, column: 0))
        press(.right, shift: true, option: true, in: view)
        press(.right, shift: true, option: true, in: view)
        #expect(view.selectedText() == "one two")
        press(.left, shift: true, in: view)
        #expect(view.selectedText() == "one tw", "turned back, it shrinks")
        press(.down, command: true, in: view)
        #expect(view.caret == AppUIRowPosition(row: 2, column: 4))
        press(.up, shift: true, command: true, in: view)
        #expect(view.selection == AppUIRowPosition(row: 0, column: 0) ... AppUIRowPosition(row: 2, column: 4), "from here to the start of the document")
        press(.left, command: true, in: view)
        #expect(view.caret == AppUIRowPosition(row: 0, column: 0), "an arrow ends the selection at the end it points to")
    }

    @Test func `a key that is not a caret key is not taken`() {
        let (view, source) = makeView(["abc"])
        defer { withExtendedLifetime(source) {} }
        #expect(!view.moved(by: nil, extending: false, option: false, command: false))
    }
}
