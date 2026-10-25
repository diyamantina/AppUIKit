#if canImport(UIKit) && !canImport(AppKit)
    import Foundation
    import Testing
    import UIKit
    @testable import AppUIKit

    /// Typing on an iPad: the text of the keyboard, the keys of an attached one, a tap that asks for the keyboard, and paste and cut.
    @MainActor
    struct AppUIRowViewTypingTests {
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

        /// A view in a window that is shown, which a view must be in to be the first responder.
        private func makeView(_ texts: [String], editable: Bool = true) -> (AppUIRowView, Lines, UIWindow) {
            let source = Lines(texts)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 600, height: 400))
            let view = AppUIRowView(frame: window.bounds)
            view.gutterDigits = 3
            view.source = source
            view.isEditable = editable
            window.addSubview(view)
            window.makeKeyAndVisible()
            return (view, source, window)
        }

        private func textPoint(_ view: AppUIRowView, row: Int, character: Int) -> CGPoint {
            CGPoint(x: view.gutterWidth + 6 + (Double(character) + 0.25) * view.characterWidth, y: view.top(ofRow: row) + view.rowHeight / 2)
        }

        @Test func `the text of the keyboard goes to the owner as what was typed, and return and tab are the keys they are`() {
            let (view, source, window) = makeView(["abc"])
            defer { withExtendedLifetime((source, window)) {} }
            var got: [AppUIRowEdit] = []
            view.onEdit = { got.append($0) }
            #expect(view.hasText, "or the delete key of the keyboard on the screen is dead")
            view.insertText("x")
            view.insertText("é")
            view.insertText("\n")
            view.insertText("\t")
            view.insertText("")
            view.deleteBackward()
            #expect(got == [.insert("x"), .insert("é"), .newline, .insert("  "), .deleteBackward])
        }

        @Test func `nothing is typed into rows that cannot be edited`() {
            let (view, source, window) = makeView(["abc"], editable: false)
            defer { withExtendedLifetime((source, window)) {} }
            var got: [AppUIRowEdit] = []
            view.onEdit = { got.append($0) }
            view.insertText("x")
            view.deleteBackward()
            view.pasteboardText = { "PASTED" }
            view.paste(nil)
            #expect(got.isEmpty)
            #expect(!view.handleKey(.keyboardDeleteForward, charactersIgnoringModifiers: "", modifiers: []))
            #expect(!view.canPerformAction(#selector(UIResponder.paste(_:)), withSender: nil))
            #expect(!view.canPerformAction(#selector(UIResponder.cut(_:)), withSender: nil))
        }

        @Test func `a tap in rows that can be edited puts the caret there and asks for the keyboard, and in others does neither`() {
            let (view, source, window) = makeView(["abcdef", "ghi"])
            defer { withExtendedLifetime((source, window)) {} }
            var activated: [AppUIRowPosition] = []
            view.onActivate = { place, _ in activated.append(place) }
            view.touchTap(at: textPoint(view, row: 0, character: 3))
            #expect(view.caret == AppUIRowPosition(row: 0, column: 3))
            #expect(view.isFirstResponder)
            #expect(activated == [AppUIRowPosition(row: 0, column: 3)], "the owner is told of the tap as before")
            view.isEditable = false
            #expect(!view.isFirstResponder, "the keyboard goes with the right to type")
            view.touchTap(at: textPoint(view, row: 1, character: 1))
            #expect(!view.isFirstResponder)
            #expect(activated.count == 2)
        }

        @Test func `the keys of an attached keyboard move the caret, delete forward, and undo and redo`() {
            let (view, source, window) = makeView(["one two", "three"])
            defer { withExtendedLifetime((source, window)) {} }
            var got: [String] = []
            view.onEdit = { got.append("\($0)") }
            view.onUndo = { got.append("undo") }
            view.onRedo = { got.append("redo") }
            view.setCaret(AppUIRowPosition(row: 0, column: 0))
            #expect(view.handleKey(.keyboardRightArrow, charactersIgnoringModifiers: "", modifiers: []))
            #expect(view.caret == AppUIRowPosition(row: 0, column: 1))
            #expect(view.handleKey(.keyboardRightArrow, charactersIgnoringModifiers: "", modifiers: [.alternate]))
            #expect(view.caret == AppUIRowPosition(row: 0, column: 3), "Option goes by a word")
            #expect(view.handleKey(.keyboardEnd, charactersIgnoringModifiers: "", modifiers: [.shift]))
            #expect(view.selectedText() == " two")
            #expect(view.handleKey(.keyboardDeleteForward, charactersIgnoringModifiers: "", modifiers: []))
            #expect(view.handleKey(.keyboardZ, charactersIgnoringModifiers: "z", modifiers: [.command]))
            #expect(view.handleKey(.keyboardZ, charactersIgnoringModifiers: "z", modifiers: [.command, .shift]))
            #expect(got == ["deleteForward", "undo", "redo"])
            #expect(!view.handleKey(.keyboardA, charactersIgnoringModifiers: "a", modifiers: []), "a letter is text, which the keyboard hands over as text")
            #expect(!view.handleKey(.keyboardZ, charactersIgnoringModifiers: "z", modifiers: []))
        }

        @Test func `paste puts the text of the pasteboard in, and cut takes the selection out after copying it`() {
            let (view, source, window) = makeView(["abcdef"])
            defer { withExtendedLifetime((source, window)) {} }
            var got: [AppUIRowEdit] = []
            view.onEdit = { got.append($0) }
            view.pasteboardText = { "PASTED" }
            view.paste(nil)
            #expect(got == [.insert("PASTED")])
            #expect(!view.canPerformAction(#selector(UIResponder.cut(_:)), withSender: nil), "nothing is selected")
            view.select(AppUIRowPosition(row: 0, column: 1) ... AppUIRowPosition(row: 0, column: 4))
            #expect(view.canPerformAction(#selector(UIResponder.cut(_:)), withSender: nil))
            #expect(view.selectedText() == "bcd")
            view.cut(nil)
            #expect(got.last == .deleteBackward, "the selection is taken out by the owner, as a delete takes it")
        }
    }
#endif
