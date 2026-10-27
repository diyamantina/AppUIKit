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

    /// A text of many lines, the last long enough to need sideways scrolling, in a small view.
    private func tallAndWide() -> (textView: AppUITextView, container: AppUIView, text: String) {
        let (textView, container) = AppUITextView.appuiMakeScrolling()
        container.frame = CGRect(x: 0, y: 0, width: 300, height: 120)
        textView.appuiConfigureForCode(font: AppUIKit.Fonts.monospaced(ofSize: 13))
        let lines = (0 ..< 300).map { index in index == 250 ? String(repeating: "x", count: 400) + " target" : "line \(index)" }
        let text = lines.joined(separator: "\n")
        textView.appuiString = text
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            container.layoutSubtreeIfNeeded()
            textView.sizeToFit()
        #elseif canImport(UIKit)
            container.layoutIfNeeded()
        #endif
        return (textView, container, text)
    }

    /// The rectangle a range of the text occupies, and the part of the text view that can be seen.
    private func place(of range: AppUIRange, in textView: AppUITextView) -> (range: CGRect, visible: CGRect) {
        (textView.appuiRect(of: range), textView.appuiVisibleRect)
    }

    @Test func `scrolling to a range far down and far to the right puts it in view, both ways`() {
        let (textView, _, text) = tallAndWide()
        let target = (text as NSString).range(of: "target")
        textView.appuiScrollToVisible(target)
        var place = place(of: target, in: textView)
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            #expect(place.visible.intersects(place.range), "the range is in view: \(place.range) in \(place.visible)")
            #expect(place.visible.contains(CGPoint(x: place.range.minX + 1, y: place.range.midY)), "its start is in view, not only its edge")
        #elseif canImport(UIKit)
            // A UIKit text view keeps its content as wide as itself, so a line wider than the view cannot be scrolled sideways here; the row can be reached.
            #expect(place.visible.minY <= place.range.midY && place.range.midY <= place.visible.maxY, "its row is in view: \(place.range) in \(place.visible)")
        #endif
        // And back to the top, so the first line is in view again.
        let first = AppUIRange(location: 0, length: 6)
        textView.appuiScrollToVisible(first)
        place = self.place(of: first, in: textView)
        #expect(place.visible.minY <= place.range.midY && place.range.midY <= place.visible.maxY)
    }

    @Test func `centering puts the range in the middle of the view, rows above and below it`() {
        let (textView, _, text) = tallAndWide()
        let target = (text as NSString).range(of: "line 150")
        textView.appuiScrollToVisible(target, centered: true)
        let place = place(of: target, in: textView)
        #expect(abs(place.range.midY - place.visible.midY) < place.visible.height / 4, "centered: \(place.range) in \(place.visible)")
    }

    @Test func `centering on the first lines after a visit far down puts them in view, though the lines between were never laid out`() {
        let (textView, _, text) = tallAndWide()
        let far = (text as NSString).range(of: "line 190")
        textView.appuiScrollToVisible(far, centered: true)
        let first = AppUIRange(location: 0, length: 79)
        textView.appuiScrollToVisible(first, centered: true)
        let place = place(of: first, in: textView)
        #expect(place.visible.minY <= place.range.minY && place.range.minY <= place.visible.maxY, "the first lines are in view: \(place.range) in \(place.visible)")
    }

    @Test func `code keeps off the edge of the view and is not offered the system's writing tools`() {
        let (textView, _) = AppUITextView.appuiMakeScrolling()
        textView.appuiConfigureForCode(font: AppUIKit.Fonts.monospaced(ofSize: 13))
        textView.appuiString = "a: 1"
        let rect = textView.appuiRect(of: AppUIRange(location: 0, length: 1))
        #expect(rect.minX >= 12, "the first column starts \(rect.minX) from the edge")
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            if #available(macOS 15, *) {
                #expect(textView.writingToolsBehavior == .none)
            }
        #endif
    }

    @Test func `the column shows the numbers of the lines in view, and follows the scrolling`() {
        let (textView, _, text) = tallAndWide()
        textView.appuiShowsLineNumbers = true
        #expect(textView.appuiShowsLineNumbers)
        let first = textView.appuiVisibleLineLabels
        #expect(first.first?.number == 1, "the top of the text starts at line 1: \(first.map(\.number))")
        #expect(first.map(\.number) == Array(1 ... first.count), "consecutive from there")
        let target = (text as NSString).range(of: "line 150")
        textView.appuiScrollToVisible(target, centered: true)
        let later = textView.appuiVisibleLineLabels.map(\.number)
        #expect(later.contains(151), "line 150 is number 151: \(later)")
        for label in textView.appuiVisibleLineLabels {
            let start = AppUILineNumbers(text: text).starts[label.number - 1]
            let rect = textView.appuiRect(of: AppUIRange(location: start, length: 0))
            #expect(abs(rect.minY - label.fragment.minY) < 1, "the label of line \(label.number) is level with its text")
        }
        textView.appuiShowsLineNumbers = false
        #expect(!textView.appuiShowsLineNumbers)
    }

    @Test func `the column of line numbers is not an accessibility element of its own`() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let (textView, _, _) = tallAndWide()
            textView.appuiShowsLineNumbers = true
            #expect(textView.enclosingScrollView?.verticalRulerView?.isAccessibilityElement() == false)
        #endif
    }

    @Test func `the numbers follow an edit of the text`() {
        let (textView, container) = AppUITextView.appuiMakeScrolling()
        container.frame = CGRect(x: 0, y: 0, width: 300, height: 120)
        textView.appuiConfigureForCode(font: AppUIKit.Fonts.monospaced(ofSize: 13))
        textView.appuiShowsLineNumbers = true
        textView.appuiString = "a\nb"
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            container.layoutSubtreeIfNeeded()
        #elseif canImport(UIKit)
            container.layoutIfNeeded()
        #endif
        #expect(textView.appuiVisibleLineLabels.map(\.number) == [1, 2])
        textView.appuiString = "a\nb\nc\n"
        #expect(textView.appuiVisibleLineLabels.map(\.number) == [1, 2, 3, 4], "a text ending in a break has an empty last line")
        textView.appuiUpdateLineNumbers()
    }
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    extension AppUITextViewTextTests {
        /// The column, drawn into a bitmap after scrolling, has a number's ink level with every line in view, and none between lines.
        @Test func `scrolling draws the whole column again, so every line in view has its number`() throws {
            let (textView, container, _) = tallAndWide()
            textView.appuiShowsLineNumbers = true
            let scroll = try #require(textView.enclosingScrollView)
            let ruler = try #require(scroll.verticalRulerView)
            let window = NSWindow(contentRect: container.frame, styleMask: [.titled], backing: .buffered, defer: false)
            window.contentView = container
            for offset in [0.0, 1000.0, 2300.0] {
                scroll.contentView.scroll(to: NSPoint(x: 0, y: offset))
                scroll.reflectScrolledClipView(scroll.contentView)
                ruler.display()
                let bitmap = try #require(ruler.bitmapImageRepForCachingDisplay(in: ruler.bounds))
                ruler.cacheDisplay(in: ruler.bounds, to: bitmap)
                // A line cut by the top or bottom of the view shows part of its number, so only the lines wholly in view are held to it.
                let view = textView.appuiVisibleRect
                let whole = textView.appuiVisibleLineLabels.filter { $0.fragment.minY >= view.minY && $0.fragment.maxY <= view.maxY }
                for label in whole {
                    let scale = CGFloat(bitmap.pixelsHigh) / ruler.bounds.height
                    let y = Int(ruler.convert(NSPoint(x: 0, y: label.fragment.midY), from: textView).y * scale)
                    let background = bitmap.colorAt(x: 0, y: min(max(y, 0), bitmap.pixelsHigh - 1))
                    var ink = false
                    for x in 0 ..< bitmap.pixelsWide where y >= 0 && y < bitmap.pixelsHigh {
                        if let color = bitmap.colorAt(x: x, y: y), let background, abs(color.brightnessComponent - background.brightnessComponent) > 0.2 {
                            ink = true
                        }
                    }
                    #expect(ink, "line \(label.number) has no number drawn at \(y) after scrolling to \(offset)")
                }
            }
        }
    }
#endif

extension AppUITextViewTextTests {
    @Test func `a command-click tells the character under the pointer, and a plain click tells nothing`() throws {
        let (textView, container, text) = tallAndWide()
        var told: [Int] = []
        let observer = textView.appuiObserveCommandClick { told.append($0) }
        let target = (text as NSString).range(of: "line 7")
        // A person clicks on text that is in view, which is laid out; the layout is lazy, so the text is brought into view first.
        textView.appuiScrollToVisible(target)
        let rect = textView.appuiRect(of: target)
        let point = CGPoint(x: rect.minX + 2, y: rect.midY)
        observer.click(at: point, command: false)
        #expect(told.isEmpty)
        observer.click(at: point, command: true)
        #expect(told.count == 1)
        let index = try #require(told.first)
        #expect(abs(index - target.location) <= 1, "the click was on the first character of line 7: \(index) against \(target.location)")
        _ = container
    }

    @Test func `the pointer is a hand only with Command held over a link`() {
        let (textView, _, text) = tallAndWide()
        let link = (text as NSString).range(of: "line 7")
        let observer = textView.appuiObserveCommandClick(isLink: { link.contains($0) }, { _ in })
        textView.appuiScrollToVisible(link)
        let on = textView.appuiRect(of: AppUIRange(location: link.location + 1, length: 1))
        let off = textView.appuiRect(of: (text as NSString).range(of: "line 20"))
        #expect(observer.wantsPointer(at: CGPoint(x: on.midX, y: on.midY), command: true))
        #expect(!observer.wantsPointer(at: CGPoint(x: on.midX, y: on.midY), command: false))
        #expect(!observer.wantsPointer(at: CGPoint(x: off.minX + 2, y: off.midY), command: true))
    }
}
