import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    /// The column of line numbers beside a text view in a scroll view, drawn for the lines that can be seen and nothing else, so that a text of millions of
    /// lines costs no more than one of a screen.
    @MainActor
    final class AppUILineNumberRuler: NSRulerView {
        private weak var textView: NSTextView?
        private var lines: AppUILineNumbers?
        private nonisolated(unsafe) var editObserver: NSObjectProtocol?

        init(scrollView: NSScrollView, textView: NSTextView) {
            self.textView = textView
            super.init(scrollView: scrollView, orientation: .verticalRuler)
            clientView = textView
            if let storage = textView.textStorage {
                editObserver = NotificationCenter.default.addObserver(
                    forName: NSTextStorage.didProcessEditingNotification, object: storage, queue: .main
                ) { [weak self] note in
                    // Coloring edits attributes only, which moves no line; only a change of the characters does.
                    let changed = (note.object as? NSTextStorage)?.editedMask.contains(.editedCharacters) ?? true
                    MainActor.assumeIsolated {
                        guard changed else { return }
                        self?.lines = nil
                        self?.needsDisplay = true
                    }
                }
            }
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("AppUILineNumberRuler is made in code")
        }

        deinit {
            if let editObserver {
                NotificationCenter.default.removeObserver(editObserver)
            }
        }

        /// The lines of the text, found when first needed after a change of the characters.
        func currentLines() -> AppUILineNumbers {
            if let lines {
                return lines
            }
            let made = AppUILineNumbers(text: textView?.string ?? "")
            lines = made
            return made
        }

        /// Draws the numbers in a smaller size of the text's own font, and makes the column wide enough for the largest.
        private var numberAttributes: [NSAttributedString.Key: Any] {
            let base = textView?.font ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            return [.font: NSFont.monospacedDigitSystemFont(ofSize: base.pointSize * 0.85, weight: .regular), .foregroundColor: NSColor.secondaryLabelColor]
        }

        func fitThickness() {
            let width = ("0" as NSString).size(withAttributes: numberAttributes).width
            let wanted = ceil(width * CGFloat(max(currentLines().digits, 3))) + 20
            if abs(ruleThickness - wanted) > 0.5 {
                ruleThickness = wanted
            }
        }

        /// The numbers of the lines that can be seen, each with the rectangle of its first fragment in the text view's coordinates.
        func visibleLabels() -> [(number: Int, fragment: NSRect)] {
            guard let textView, let layout = textView.layoutManager, let container = textView.textContainer else { return [] }
            let lines = currentLines()
            let origin = textView.textContainerOrigin
            let visible = textView.visibleRect.offsetBy(dx: -origin.x, dy: -origin.y)
            var labels: [(number: Int, fragment: NSRect)] = []
            layout.enumerateLineFragments(forGlyphRange: layout.glyphRange(forBoundingRect: visible, in: container)) { fragment, _, _, glyphRange, _ in
                let characters = layout.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
                if lines.startsLine(at: characters.location) {
                    labels.append((lines.line(at: characters.location), fragment.offsetBy(dx: origin.x, dy: origin.y)))
                }
            }
            // A text that ends in a break has one more, empty line, which has no fragment of its own but the layout's extra one.
            let extra = layout.extraLineFragmentRect
            if !extra.isEmpty, extra.intersects(visible) {
                labels.append((lines.count, extra.offsetBy(dx: origin.x, dy: origin.y)))
            }
            return labels
        }

        override func drawHashMarksAndLabels(in _: NSRect) {
            guard let textView else { return }
            textView.backgroundColor.setFill()
            bounds.fill()
            fitThickness()
            let attributes = numberAttributes
            for label in visibleLabels() {
                let text = String(label.number) as NSString
                let size = text.size(withAttributes: attributes)
                let y = convert(NSPoint(x: 0, y: label.fragment.minY), from: textView).y + (label.fragment.height - size.height) / 2
                text.draw(at: NSPoint(x: bounds.width - size.width - 8, y: y), withAttributes: attributes)
            }
        }
    }
#elseif canImport(UIKit)
    import UIKit

    /// The column of line numbers over the left edge of a text view, as tall as the view and moved with its scrolling, drawn for the lines that can be seen only.
    @MainActor
    final class AppUILineNumberGutter: UIView {
        private weak var textView: UITextView?
        private var lines: AppUILineNumbers?
        private var scrollObservation: NSKeyValueObservation?
        private nonisolated(unsafe) var editObserver: NSObjectProtocol?

        init(textView: UITextView) {
            self.textView = textView
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            backgroundColor = textView.backgroundColor
            scrollObservation = textView.observe(\.contentOffset) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.follow() }
            }
            // Coloring edits attributes only, which moves no line; only a change of the characters does.
            editObserver = NotificationCenter.default.addObserver(
                forName: NSTextStorage.didProcessEditingNotification, object: textView.textStorage, queue: .main
            ) { [weak self] note in
                let changed = (note.object as? NSTextStorage)?.editedMask.contains(.editedCharacters) ?? true
                MainActor.assumeIsolated {
                    if changed {
                        self?.invalidate()
                    }
                }
            }
        }

        deinit {
            if let editObserver {
                NotificationCenter.default.removeObserver(editObserver)
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("AppUILineNumberGutter is made in code")
        }

        func invalidate() {
            lines = nil
            follow()
        }

        var thickness: CGFloat {
            guard let textView else { return 0 }
            let digits = max(currentLines().digits, 3)
            let width = ("0" as NSString).size(withAttributes: numberAttributes(for: textView)).width
            return ceil(width * CGFloat(digits)) + 20
        }

        private func currentLines() -> AppUILineNumbers {
            if let lines {
                return lines
            }
            let made = AppUILineNumbers(text: textView?.text ?? "")
            lines = made
            return made
        }

        private func numberAttributes(for textView: UITextView) -> [NSAttributedString.Key: Any] {
            let size = (textView.font?.pointSize ?? 13) * 0.85
            return [.font: UIFont.monospacedDigitSystemFont(ofSize: size, weight: .regular), .foregroundColor: UIColor.secondaryLabel]
        }

        /// Puts the column over the part of the text view that can be seen, and draws it again.
        func follow() {
            guard let textView else { return }
            frame = CGRect(x: textView.contentOffset.x, y: textView.contentOffset.y, width: thickness, height: textView.bounds.height)
            setNeedsDisplay()
        }

        /// The numbers of the lines that can be seen, each with the rectangle of its first fragment in the text view's coordinates.
        func visibleLabels() -> [(number: Int, fragment: CGRect)] {
            guard let textView else { return [] }
            let lines = currentLines()
            let layout = textView.layoutManager
            let inset = textView.textContainerInset
            let visible = CGRect(origin: textView.contentOffset, size: textView.bounds.size).offsetBy(dx: 0, dy: -inset.top)
            var labels: [(number: Int, fragment: CGRect)] = []
            layout.enumerateLineFragments(forGlyphRange: layout.glyphRange(forBoundingRect: visible, in: textView.textContainer)) { fragment, _, _, glyphRange, _ in
                let characters = layout.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
                if lines.startsLine(at: characters.location) {
                    labels.append((lines.line(at: characters.location), fragment.offsetBy(dx: inset.left, dy: inset.top)))
                }
            }
            let extra = layout.extraLineFragmentRect
            if !extra.isEmpty, extra.intersects(visible) {
                labels.append((lines.count, extra.offsetBy(dx: inset.left, dy: inset.top)))
            }
            return labels
        }

        override func draw(_: CGRect) {
            guard let textView else { return }
            let attributes = numberAttributes(for: textView)
            for label in visibleLabels() {
                let text = String(label.number) as NSString
                let size = text.size(withAttributes: attributes)
                let y = label.fragment.minY - textView.contentOffset.y + (label.fragment.height - size.height) / 2
                text.draw(at: CGPoint(x: bounds.width - size.width - 8, y: y), withAttributes: attributes)
            }
        }
    }
#endif

public extension AppUITextView {
    /// Whether a column of line numbers is shown beside the text. On AppKit it is the scroll view's vertical ruler; on UIKit a view over the left edge, with the
    /// text moved right of it. Setting it needs the text view to be in a scroll view made by `appuiMakeScrolling()` on AppKit.
    var appuiShowsLineNumbers: Bool {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return enclosingScrollView?.verticalRulerView is AppUILineNumberRuler && enclosingScrollView?.rulersVisible == true
            #elseif canImport(UIKit)
                return subviews.contains { $0 is AppUILineNumberGutter }
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                guard let scroll = enclosingScrollView else { return }
                if newValue {
                    if !(scroll.verticalRulerView is AppUILineNumberRuler) {
                        scroll.verticalRulerView = AppUILineNumberRuler(scrollView: scroll, textView: self)
                    }
                    scroll.hasVerticalRuler = true
                    scroll.rulersVisible = true
                    appuiUpdateLineNumbers()
                } else {
                    scroll.rulersVisible = false
                }
            #elseif canImport(UIKit)
                let gutter = subviews.compactMap { $0 as? AppUILineNumberGutter }.first
                if newValue, gutter == nil {
                    addSubview(AppUILineNumberGutter(textView: self))
                } else if !newValue, let gutter {
                    gutter.removeFromSuperview()
                }
                appuiUpdateLineNumbers()
            #endif
        }
    }

    /// Brings the column of line numbers up to date after the text or its font changed: the width for the largest number, and a new drawing.
    func appuiUpdateLineNumbers() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            guard let ruler = enclosingScrollView?.verticalRulerView as? AppUILineNumberRuler else { return }
            ruler.fitThickness()
            ruler.needsDisplay = true
        #elseif canImport(UIKit)
            guard let gutter = subviews.compactMap({ $0 as? AppUILineNumberGutter }).first else { return }
            gutter.invalidate()
            var inset = textContainerInset
            inset.left = 12 + gutter.thickness
            textContainerInset = inset
        #endif
    }
}

extension AppUITextView {
    /// The numbers of the lines the column shows now, top to bottom, with where each starts in the text view; empty when no column is shown.
    var appuiVisibleLineLabels: [(number: Int, fragment: CGRect)] {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            (enclosingScrollView?.verticalRulerView as? AppUILineNumberRuler)?.visibleLabels() ?? []
        #elseif canImport(UIKit)
            subviews.compactMap { $0 as? AppUILineNumberGutter }.first?.visibleLabels() ?? []
        #endif
    }
}
