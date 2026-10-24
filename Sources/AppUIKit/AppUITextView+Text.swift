import Foundation

public extension AppUITextView {
    /// The text the view holds: `string` on AppKit, `text` on UIKit (empty when it has none).
    var appuiString: String {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return string
            #elseif canImport(UIKit)
                return text ?? ""
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                string = newValue
            #elseif canImport(UIKit)
                text = newValue
            #endif
        }
    }

    /// The characters that are selected, or where the caret is when the length is zero: `selectedRange()` on AppKit, `selectedRange` on UIKit.
    var appuiSelectedRange: AppUIRange {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return selectedRange()
            #elseif canImport(UIKit)
                return selectedRange
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                setSelectedRange(newValue)
            #elseif canImport(UIKit)
                selectedRange = newValue
            #endif
        }
    }

    /// The storage behind the text, to change the attributes of ranges without touching the characters: it is optional on AppKit and not on UIKit, and nil here means the view has
    /// none.
    var appuiTextStorage: AppUITextStorage? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return textStorage
        #elseif canImport(UIKit)
            return textStorage
        #endif
    }

    /// Scrolls the view so that `range` is on screen.
    func appuiScrollToVisible(_ range: AppUIRange) {
        scrollRangeToVisible(range)
    }

    /// Sets the view up for editing code and data, where the system's help changes what was typed: no smart quotes or dashes, no autocorrection, spelling or text replacement,
    /// plain text, and undo kept.
    /// `font` is the font of the text and of what is typed next. A line is kept whole and the view scrolls sideways unless `wrapsLines` is true, because a wrapped line of code
    /// restarts at the left edge, under none of its indentation, and the structure of the text is lost.
    func appuiConfigureForCode(font: AppUIFont, wrapsLines: Bool = false) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            isRichText = false
            allowsUndo = true
            isAutomaticQuoteSubstitutionEnabled = false
            isAutomaticDashSubstitutionEnabled = false
            isAutomaticSpellingCorrectionEnabled = false
            isAutomaticTextReplacementEnabled = false
            isAutomaticTextCompletionEnabled = false
        #elseif canImport(UIKit)
            autocorrectionType = .no
            autocapitalizationType = .none
            smartQuotesType = .no
            smartDashesType = .no
            smartInsertDeleteType = .no
            spellCheckingType = .no
        #endif
        self.font = font
        appuiSetWrapsLines(wrapsLines)
    }

    /// Wraps long lines at the edge of the view, or keeps each whole and lets the view scroll sideways.
    func appuiSetWrapsLines(_ wraps: Bool) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            if wraps {
                isHorizontallyResizable = false
                textContainer?.widthTracksTextView = true
                textContainer?.containerSize = NSSize(width: enclosingScrollView?.contentSize.width ?? frame.width, height: CGFloat.greatestFiniteMagnitude)
                enclosingScrollView?.hasHorizontalScroller = false
            } else {
                isHorizontallyResizable = true
                maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                textContainer?.widthTracksTextView = false
                textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                enclosingScrollView?.hasHorizontalScroller = true
            }
        #elseif canImport(UIKit)
            // Reading the layout manager makes the view use the text system that has one, which builds a new text container; set up the container after it, not before.
            _ = layoutManager
            textContainer.widthTracksTextView = wraps
            textContainer.size = CGSize(width: wraps ? bounds.width : Self.unwrappedWidth, height: CGFloat.greatestFiniteMagnitude)
            textContainer.lineBreakMode = wraps ? .byWordWrapping : .byClipping
            alwaysBounceHorizontal = !wraps
        #endif
    }

    /// Calls `handler` each time the person changes the text (typing, pasting, undo), not when the program sets it. Keep the returned token as long as the calls are wanted and
    /// pass it to `NotificationCenter.removeObserver(_:)` to stop them.
    func appuiObserveEdits(_ handler: @escaping @MainActor () -> Void) -> NSObjectProtocol {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let name = NSText.didChangeNotification
        #elseif canImport(UIKit)
            let name = UITextView.textDidChangeNotification
        #endif
        return NotificationCenter.default.addObserver(forName: name, object: self, queue: .main) { _ in
            MainActor.assumeIsolated { handler() }
        }
    }

    /// A text view and the view to put in a window to show it with scrolling: a scroll view that holds the text view on AppKit, the text view itself on UIKit, where it scrolls on
    /// its own.
    static func appuiMakeScrolling() -> (textView: AppUITextView, container: AppUIView) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let scroll = AppUITextView.scrollableTextView()
            let textView = (scroll.documentView as? AppUITextView) ?? AppUITextView()
            return (textView, scroll)
        #elseif canImport(UIKit)
            let textView = AppUITextView()
            return (textView, textView)
        #endif
    }

    #if canImport(UIKit) && !canImport(AppKit)
        /// The width given to the text container of a view that does not wrap: wider than any line of code.
        private static var unwrappedWidth: CGFloat {
            100_000
        }
    #endif
}
