import Testing
@testable import AppUIKit

#if canImport(UIKit) && !os(macOS)
    import UIKit

    /// The bar over the keyboard types its keys through the text view, and is taken away when it has no keys.
    @MainActor
    @Suite("AppUITextView keyboard bar")
    struct AppUITextViewKeyboardBarTests {
        private static let keys = [
            AppUIKeyboardKey(title: "-", accessibilityLabel: "Dash", action: .insert("- ")),
            AppUIKeyboardKey(title: ":", accessibilityLabel: "Colon", action: .insert(": ")),
            AppUIKeyboardKey(title: "", systemImage: "keyboard.chevron.compact.down", accessibilityLabel: "Done", action: .dismiss),
        ]

        @Test("a bar has a button for each key, in order, labeled for VoiceOver")
        func buttons() throws {
            let view = UITextView()
            view.appuiSetKeyboardBar(Self.keys)
            let bar = try #require(view.inputAccessoryView as? AppUIKeyboardBar)
            #expect(bar.keyButtons.map(\.accessibilityLabel) == ["Dash", "Colon", "Done"])
        }

        @Test("a key that inserts types its text at the caret, as the keyboard does, and a second key types after it")
        func inserts() throws {
            let view = UITextView()
            view.text = "ab"
            view.selectedRange = NSRange(location: 1, length: 0)
            view.appuiSetKeyboardBar(Self.keys)
            let bar = try #require(view.inputAccessoryView as? AppUIKeyboardBar)
            bar.perform(.insert("- "))
            #expect(view.text == "a- b")
            bar.perform(.insert(": "))
            #expect(view.text == "a- : b")
        }

        @Test("a bar with no keys is no bar")
        func removed() {
            let view = UITextView()
            view.appuiSetKeyboardBar(Self.keys)
            view.appuiSetKeyboardBar([])
            #expect(view.inputAccessoryView == nil)
        }
    }
#endif
