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

    @Test func `a view set up for code does not wrap a long line, it keeps it whole to scroll sideways`() throws {
        let (textView, container) = AppUITextView.appuiMakeScrolling()
        container.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        textView.appuiConfigureForCode(font: AppUIKit.Fonts.monospaced(ofSize: 13))
        textView.appuiString = "key: " + String(repeating: "word ", count: 80)
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            container.layoutSubtreeIfNeeded()
            let layout = try #require(textView.layoutManager)
            let textContainer = try #require(textView.textContainer)
            layout.ensureLayout(for: textContainer)
            #expect(!textContainer.widthTracksTextView)
            #expect(layout.usedRect(for: textContainer).width > 200, "the line is wider than the view, so it was not wrapped")
            #expect(layout.usedRect(for: textContainer).height < 40, "and it is one line")
        #elseif canImport(UIKit)
            container.layoutIfNeeded()
            textView.layoutManager.ensureLayout(for: textView.textContainer)
            #expect(!textView.textContainer.widthTracksTextView)
            let used = textView.layoutManager.usedRect(for: textView.textContainer)
            #expect(used.width > 200, "the line is wider than the view, so it was not wrapped (used \(used), content \(textView.contentSize))")
            #expect(used.height < 40, "and it is one line")
        #endif
    }

    @Test func `a view set up for code with wrapping asked for wraps at the edge`() throws {
        let (textView, container) = AppUITextView.appuiMakeScrolling()
        container.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        textView.appuiConfigureForCode(font: AppUIKit.Fonts.monospaced(ofSize: 13), wrapsLines: true)
        textView.appuiString = "key: " + String(repeating: "word ", count: 80)
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            container.layoutSubtreeIfNeeded()
            let layout = try #require(textView.layoutManager)
            let textContainer = try #require(textView.textContainer)
            layout.ensureLayout(for: textContainer)
            #expect(textContainer.widthTracksTextView)
            #expect(layout.usedRect(for: textContainer).width <= 200)
        #elseif canImport(UIKit)
            container.layoutIfNeeded()
            #expect(textView.textContainer.widthTracksTextView)
            #expect(textView.contentSize.width <= 200)
        #endif
    }

    @Test func `the selection observer is told where the caret or the selection goes, by the program too`() {
        let (textView, _) = AppUITextView.appuiMakeScrolling()
        textView.appuiString = "hello world"
        var seen: [AppUIRange] = []
        let observer = textView.appuiObserveSelection { seen.append($0) }
        textView.appuiSelectedRange = AppUIRange(location: 6, length: 5)
        textView.appuiSelectedRange = AppUIRange(location: 2, length: 0)
        #expect(seen.last == AppUIRange(location: 2, length: 0))
        #expect(seen.contains(AppUIRange(location: 6, length: 5)))
        withExtendedLifetime(observer) {}
    }
}
