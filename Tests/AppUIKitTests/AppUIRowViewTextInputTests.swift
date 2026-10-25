#if canImport(UIKit) && !canImport(AppKit)
    import Foundation
    import Testing
    import UIKit
    @testable import AppUIKit

    /// The keyboard of the iPad and its input methods: text composed at the caret is shown in the row and reaches the owner of the rows once, when it is settled,
    /// and the keyboard is answered from the row of the caret as it is shown.
    @MainActor
    struct AppUIRowViewTextInputTests {
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

        final class Spy: NSObject, UITextInputDelegate {
            var events: [String] = []
            func selectionWillChange(_: (any UITextInput)?) {
                events.append("selection will")
            }

            func selectionDidChange(_: (any UITextInput)?) {
                events.append("selection did")
            }

            func textWillChange(_: (any UITextInput)?) {
                events.append("text will")
            }

            func textDidChange(_: (any UITextInput)?) {
                events.append("text did")
            }

            @available(iOS 18.4, *)
            func conversationContext(_: UIConversationContext?, didChange _: (any UITextInput)?) {}
        }

        private func makeView(_ texts: [String]) -> (AppUIRowView, Lines, UIWindow) {
            let source = Lines(texts)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 600, height: 400))
            let view = AppUIRowView(frame: window.bounds)
            view.gutterDigits = 3
            view.source = source
            view.isEditable = true
            window.addSubview(view)
            window.makeKeyAndVisible()
            return (view, source, window)
        }

        private func range(_ view: AppUIRowView, _ first: Int, _ last: Int) -> UITextRange {
            view.textRange(from: AppUIRowTextPosition(first), to: AppUIRowTextPosition(last)) ?? AppUIRowTextRange(0, 0)
        }

        @Test func `text being composed is marked, shown in the row, and not given to the owner until it is settled`() {
            let (view, source, window) = makeView(["abcd"])
            defer { withExtendedLifetime((source, window)) {} }
            var got: [AppUIRowEdit] = []
            view.onEdit = { got.append($0) }
            view.setCaret(AppUIRowPosition(row: 0, column: 2))
            #expect(view.markedTextRange == nil)
            view.setMarkedText("にほ", selectedRange: NSRange(location: 2, length: 0))
            let marked = view.markedTextRange as? AppUIRowTextRange
            #expect(marked?.range == NSRange(location: 2, length: 2))
            #expect((view.selectedTextRange as? AppUIRowTextRange)?.range == NSRange(location: 4, length: 0))
            #expect(view.text(in: range(view, 0, 6)) == "abにほcd")
            #expect(got.isEmpty)
            view.setMarkedText("日本", selectedRange: NSRange(location: 2, length: 0))
            #expect(view.text(in: range(view, 0, 6)) == "ab日本cd")
            view.insertText("日本")
            #expect(got == [.insert("日本")] && view.markedTextRange == nil)
        }

        @Test func `unmarking settles the text as it stands, and no marked text takes the composition back`() {
            let (view, source, window) = makeView(["abcd"])
            defer { withExtendedLifetime((source, window)) {} }
            var got: [AppUIRowEdit] = []
            view.onEdit = { got.append($0) }
            view.setCaret(AppUIRowPosition(row: 0, column: 1))
            view.setMarkedText("é", selectedRange: NSRange(location: 1, length: 0))
            view.unmarkText()
            #expect(got == [.insert("é")] && view.markedTextRange == nil)
            view.setMarkedText("k", selectedRange: NSRange(location: 1, length: 0))
            view.setMarkedText(nil, selectedRange: NSRange(location: 0, length: 0))
            #expect(view.markedTextRange == nil && got == [.insert("é")])
        }

        @Test func `a selection is replaced when composing begins, and text replaced by range is put over the range`() {
            let (view, source, window) = makeView(["abcdef"])
            defer { withExtendedLifetime((source, window)) {} }
            var got: [AppUIRowEdit] = []
            view.onEdit = { edit in
                got.append(edit)
                if edit == .deleteBackward {
                    view.setCaret(AppUIRowPosition(row: 0, column: 1))
                }
            }
            view.setCaret(AppUIRowPosition(row: 0, column: 1))
            view.selectEverything()
            view.setMarkedText("n", selectedRange: NSRange(location: 1, length: 0))
            #expect(got == [.deleteBackward])
            view.unmarkText()
            got.removeAll()
            view.setCaret(AppUIRowPosition(row: 0, column: 3))
            view.replace(range(view, 2, 3), withText: "ç")
            #expect(got == [.insert("ç")])
            #expect(view.selection == AppUIRowPosition(row: 0, column: 2) ... AppUIRowPosition(row: 0, column: 3))
        }

        @Test func `the keyboard moves the selection and finds places and ranges in the row of the caret`() {
            let (view, source, window) = makeView(["abcd", "efgh"])
            defer { withExtendedLifetime((source, window)) {} }
            view.setCaret(AppUIRowPosition(row: 1, column: 1))
            view.selectedTextRange = range(view, 1, 3)
            #expect(view.selection == AppUIRowPosition(row: 1, column: 1) ... AppUIRowPosition(row: 1, column: 3))
            view.selectedTextRange = range(view, 2, 2)
            #expect(view.caret == AppUIRowPosition(row: 1, column: 2) && view.selection == nil)
            let end = view.endOfDocument
            #expect(view.offset(from: view.beginningOfDocument, to: end) == 4)
            #expect(view.position(from: end, offset: 1) == nil && view.position(from: end, offset: -1) != nil)
            #expect(view.compare(view.beginningOfDocument, to: end) == .orderedAscending)
            #expect(view.text(in: range(view, 1, 3)) == "fg")
            let first = view.firstRect(for: range(view, 1, 3))
            let caret = view.caretRect(for: AppUIRowTextPosition(2))
            #expect(first.width > view.characterWidth && caret.height == view.rowHeight && caret.minX > view.gutterWidth)
            let point = CGPoint(x: view.gutterWidth + 6 + 2.25 * view.characterWidth, y: view.top(ofRow: 1) + view.rowHeight / 2)
            #expect((view.closestPosition(to: point) as? AppUIRowTextPosition)?.offset == 2)
            #expect(view.closestPosition(to: CGPoint(x: point.x, y: view.top(ofRow: 0) + 2)) == nil, "another row is not the keyboard's business")
        }

        @Test func `the keyboard is told that the text is about to change and has changed around a composition`() {
            let (view, source, window) = makeView(["abcd"])
            defer { withExtendedLifetime((source, window)) {} }
            let spy = Spy()
            view.inputDelegate = spy
            view.setCaret(AppUIRowPosition(row: 0, column: 1))
            view.setMarkedText("k", selectedRange: NSRange(location: 1, length: 0))
            view.unmarkText()
            #expect(spy.events == ["text will", "text did", "text will", "text did"])
        }
    }
#endif
