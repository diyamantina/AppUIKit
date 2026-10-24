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

    /// Scrolls the view, up or down and sideways, so that the start of `range` is on screen, and the whole of it when it fits. The text is laid out as far as
    /// `range` first, because a text view lays out lazily and a request to scroll to text that is not laid out yet lands in the wrong place. With `centered` the
    /// range is put in the middle of the view, rows above and below it, which is where a person looking for it wants it; a range taller than the view
    /// starts at the top of it. On UIKit the text view keeps its
    /// content as wide as itself, so only the row can be scrolled to, not a column beyond the edge.
    func appuiScrollToVisible(_ range: AppUIRange, centered: Bool = false) {
        // The layout is lazy and does not lay out the lines before the range, so where the range is, before the view around it is laid out, is an estimate. The
        // view is scrolled to the estimate, the lines now in view are laid out, and where the range is is measured again, until it stops moving.
        var previous: CGFloat?
        for _ in 0 ..< 8 {
            let rect = appuiRect(of: range)
            appuiScroll(toRect: rect, centered: centered)
            appuiLayOutVisibleLines()
            let settled = abs(appuiRect(of: range).minY - rect.minY) < 1
            if settled || previous == rect.minY {
                return
            }
            previous = rect.minY
        }
    }

    /// Scrolls to `rect` once, as `appuiScrollToVisible` does.
    private func appuiScroll(toRect rect: CGRect, centered: Bool) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            guard let scroll = enclosingScrollView else {
                scrollToVisible(rect)
                return
            }
            let origin = Self.scrolledOrigin(to: rect, visible: scroll.documentVisibleRect, contentHeight: frame.height, centered: centered)
            scroll.contentView.scroll(to: origin)
            scroll.reflectScrolledClipView(scroll.contentView)
        #elseif canImport(UIKit)
            let visible = CGRect(origin: contentOffset, size: bounds.size)
            setContentOffset(Self.scrolledOrigin(to: rect, visible: visible, contentHeight: contentSize.height, centered: centered), animated: false)
        #endif
    }

    /// Lays out the lines that are in view now, so that where text is, near them, is no longer an estimate.
    func appuiLayOutVisibleLines() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            guard let layout = layoutManager, let container = textContainer else { return }
            layout.ensureLayout(forBoundingRect: appuiVisibleRect.offsetBy(dx: -textContainerOrigin.x, dy: -textContainerOrigin.y), in: container)
        #elseif canImport(UIKit)
            layoutManager.ensureLayout(forBoundingRect: appuiVisibleRect.offsetBy(dx: -textContainerInset.left, dy: -textContainerInset.top), in: textContainer)
        #endif
    }

    /// Where the visible part's origin has to move for `rect` to be seen: the rectangle's first line at the top when it is taller than the view, its middle in the
    /// middle of the view when `centered`, the least movement otherwise; sideways only when its start is out of view. Never past either end of the content.
    private static func scrolledOrigin(to rect: CGRect, visible: CGRect, contentHeight: CGFloat, centered: Bool) -> CGPoint {
        var origin = visible.origin
        if rect.height > visible.height {
            origin.y = rect.minY - 8
        } else if centered {
            origin.y = rect.midY - visible.height / 2
        } else if rect.minY < visible.minY {
            origin.y = rect.minY
        } else if rect.maxY > visible.maxY {
            origin.y = rect.maxY - visible.height
        }
        if rect.minX < visible.minX || rect.minX > visible.maxX - 24 {
            origin.x = max(0, rect.minX - 24)
        }
        origin.y = max(0, min(origin.y, max(0, contentHeight - visible.height)))
        return origin
    }

    /// The part of the text, in the text view's own coordinates, that can be seen now: the visible part of the scroll view that holds it on AppKit, the part of the
    /// content inside the bounds on UIKit.
    var appuiVisibleRect: CGRect {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return enclosingScrollView?.documentVisibleRect ?? visibleRect
        #elseif canImport(UIKit)
            return CGRect(origin: contentOffset, size: bounds.size)
        #endif
    }

    /// The rectangle `range` occupies in the view's own coordinates, with the text laid out as far as it.
    func appuiRect(of range: AppUIRange) -> CGRect {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            guard let layout = layoutManager, let container = textContainer else { return .zero }
            layout.ensureLayout(forCharacterRange: NSIntersectionRange(range, NSRange(location: 0, length: (string as NSString).length)))
            var rect = layout.boundingRect(forGlyphRange: layout.glyphRange(forCharacterRange: range, actualCharacterRange: nil), in: container)
            rect.origin.x += textContainerOrigin.x
            rect.origin.y += textContainerOrigin.y
            return rect
        #elseif canImport(UIKit)
            layoutManager.ensureLayout(forCharacterRange: NSIntersectionRange(range, NSRange(location: 0, length: (text ?? "").utf16.count)))
            var rect = layoutManager.boundingRect(forGlyphRange: layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil), in: textContainer)
            rect.origin.x += textContainerInset.left
            rect.origin.y += textContainerInset.top
            return rect
        #endif
    }

    /// The space between the edge of the view and the text, so that code does not touch the edge.
    private static var codeInset: CGFloat {
        12
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
            if #available(macOS 15, *) {
                writingToolsBehavior = .none
            }
            // Lay out what is seen and the little around it, not every line before it: a file of hundreds of thousands of lines takes seconds to lay out whole.
            layoutManager?.allowsNonContiguousLayout = true
            textContainerInset = NSSize(width: Self.codeInset, height: 8)
        #elseif canImport(UIKit)
            autocorrectionType = .no
            autocapitalizationType = .none
            smartQuotesType = .no
            smartDashesType = .no
            smartInsertDeleteType = .no
            spellCheckingType = .no
            if #available(iOS 18, *) {
                writingToolsBehavior = .none
            }
            layoutManager.allowsNonContiguousLayout = true
            textContainerInset = UIEdgeInsets(top: 8, left: Self.codeInset, bottom: 8, right: Self.codeInset)
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
