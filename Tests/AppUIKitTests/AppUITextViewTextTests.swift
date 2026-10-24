import Foundation
import Testing
@testable import AppUIKit

/// The text view helpers a shared editor surface is written against: the text, the selection, the storage, the setup for code, and the person's edits.
@MainActor
@Suite("AppUIKit text view")
struct AppUITextViewTextTests {
    @Test func `the text reads back what was set, and an empty view holds an empty string`() {
        let (textView, _) = AppUITextView.appuiMakeScrolling()
        #expect(textView.appuiString == "")
        textView.appuiString = "a: 1\nb: é 日本語 😀"
        #expect(textView.appuiString == "a: 1\nb: é 日本語 😀")
    }

    @Test func `the selection reads back what was set, in UTF-16 units of the text`() {
        let (textView, _) = AppUITextView.appuiMakeScrolling()
        textView.appuiString = "😀 abc"
        textView.appuiSelectedRange = AppUIRange(location: 3, length: 3)
        #expect(textView.appuiSelectedRange == AppUIRange(location: 3, length: 3))
        textView.appuiScrollToVisible(AppUIRange(location: 3, length: 3))
    }

    @Test func `the text storage holds the same characters, and an attribute set on a range leaves them alone`() throws {
        let (textView, _) = AppUITextView.appuiMakeScrolling()
        textView.appuiString = "hello"
        let storage = try #require(textView.appuiTextStorage)
        #expect(storage.string == "hello")
        storage.addAttribute(.foregroundColor, value: AppUIColor.red, range: AppUIRange(location: 0, length: 2))
        #expect(textView.appuiString == "hello")
        #expect(storage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? AppUIColor == .red)
        // Outside the range the view's own default color stays; it is not the one set.
        #expect(storage.attribute(.foregroundColor, at: 3, effectiveRange: nil) as? AppUIColor != .red)
    }

    @Test func `a view set up for code takes the font and keeps undo where the framework has it`() {
        let (textView, _) = AppUITextView.appuiMakeScrolling()
        let font = AppUIKit.Fonts.monospaced(ofSize: 13)
        textView.appuiConfigureForCode(font: font)
        #expect(textView.font == font)
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            #expect(textView.allowsUndo && !textView.isRichText)
            #expect(!textView.isAutomaticQuoteSubstitutionEnabled && !textView.isAutomaticDashSubstitutionEnabled)
        #elseif canImport(UIKit)
            #expect(textView.autocorrectionType == .no && textView.smartQuotesType == .no)
        #endif
    }

    @Test func `the container is what goes in a window, and holds the text view`() {
        let (textView, container) = AppUITextView.appuiMakeScrolling()
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            #expect((container as? AppUIScrollView)?.documentView === textView)
        #elseif canImport(UIKit)
            #expect(container === textView)
        #endif
    }

    @Test func `an edit by the person calls the handler, and removing the token stops the calls`() {
        let (textView, _) = AppUITextView.appuiMakeScrolling()
        var calls = 0
        let token = textView.appuiObserveEdits { calls += 1 }
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            textView.didChangeText()
        #elseif canImport(UIKit)
            NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: textView)
        #endif
        #expect(calls == 1)
        NotificationCenter.default.removeObserver(token)
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            textView.didChangeText()
        #elseif canImport(UIKit)
            NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: textView)
        #endif
        #expect(calls == 1)
    }

    @Test func `setting the text from the program is not an edit by the person`() {
        let (textView, _) = AppUITextView.appuiMakeScrolling()
        var calls = 0
        let token = textView.appuiObserveEdits { calls += 1 }
        defer { NotificationCenter.default.removeObserver(token) }
        textView.appuiString = "set by the program"
        #expect(calls == 0)
    }
}
