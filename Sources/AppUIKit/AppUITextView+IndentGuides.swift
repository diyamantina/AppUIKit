//
//  AppUITextView+IndentGuides.swift
//  AppUIKit
//
//  The guides through the indentation of the lines of a text view.
//

import CoreGraphics
import Foundation

/// How deep the paragraph that holds a place of a text is, in spaces, and what a blank one is taken to be: shared by the view of each platform.
@MainActor
enum AppUIIndentGuideText {
    /// The depth of the paragraph of `text` at `range`, or nil when it is blank.
    static func depth(of text: NSString, paragraph range: NSRange, unit: Int) -> Int? {
        var depth = 0
        var position = range.location
        let end = NSMaxRange(range)
        while position < end {
            switch text.character(at: position) {
            case 0x20: depth += 1
            case 0x09: depth += unit
            case 0x0A, 0x0D: return nil
            default: return depth
            }
            position += 1
        }
        return nil
    }

    /// The depth a paragraph is drawn at: its own, or for a blank one the lesser of the nearest paragraphs with text above and below it.
    static func guideDepth(in text: NSString, paragraph range: NSRange, unit: Int) -> Int {
        if let own = depth(of: text, paragraph: range, unit: unit) {
            return own
        }
        func nearest(from start: Int, step: Int) -> Int? {
            var at = start
            var count = 0
            while at >= 0, at < text.length, count < 64 {
                let paragraph = text.paragraphRange(for: NSRange(location: at, length: 0))
                if let found = depth(of: text, paragraph: paragraph, unit: unit) {
                    return found
                }
                at = step < 0 ? paragraph.location - 1 : NSMaxRange(paragraph)
                count += 1
            }
            return nil
        }
        return AppUIIndentGuides.blankDepth(above: nearest(from: range.location - 1, step: -1), below: nearest(from: NSMaxRange(range), step: 1))
    }
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    /// A view laid over a text view that draws the guides through the indentation of the lines that can be seen, and takes no clicks.
    @MainActor
    final class AppUIIndentGuideView: NSView {
        private weak var textView: NSTextView?
        var unit: Int {
            didSet { needsDisplay = true }
        }

        private nonisolated(unsafe) var editObserver: NSObjectProtocol?

        init(textView: NSTextView, unit: Int) {
            self.textView = textView
            self.unit = unit
            super.init(frame: textView.bounds)
            autoresizingMask = [.width, .height]
            if let storage = textView.textStorage {
                editObserver = NotificationCenter.default.addObserver(
                    forName: NSTextStorage.didProcessEditingNotification, object: storage, queue: .main
                ) { [weak self] note in
                    // Coloring edits attributes only, which moves no line.
                    let changed = (note.object as? NSTextStorage)?.editedMask.contains(.editedCharacters) ?? true
                    MainActor.assumeIsolated {
                        if changed {
                            self?.needsDisplay = true
                        }
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
            fatalError("AppUIIndentGuideView is made in code")
        }

        override var isFlipped: Bool {
            true
        }

        override var isOpaque: Bool {
            false
        }

        override func hitTest(_: NSPoint) -> NSView? {
            nil
        }

        override func draw(_ dirtyRect: NSRect) {
            guard let textView, let layout = textView.layoutManager, let container = textView.textContainer, let context = NSGraphicsContext.current?.cgContext else { return }
            let text = textView.string as NSString
            let origin = textView.textContainerOrigin
            let font = textView.font ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            let characterWidth = (" " as NSString).size(withAttributes: [.font: font]).width
            let left = origin.x + container.lineFragmentPadding
            let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
            let dark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let visible = dirtyRect.offsetBy(dx: -origin.x, dy: -origin.y)
            layout.enumerateLineFragments(forGlyphRange: layout.glyphRange(forBoundingRect: visible, in: container)) { fragment, _, _, glyphRange, _ in
                let characters = layout.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
                let paragraph = text.paragraphRange(for: NSRange(location: min(characters.location, max(0, text.length - 1)), length: 0))
                let depth = AppUIIndentGuideText.guideDepth(in: text, paragraph: paragraph, unit: self.unit)
                let geometry = AppUIIndentGuides.Geometry(unit: self.unit, origin: left, characterWidth: characterWidth, scale: scale, dark: dark)
                AppUIIndentGuides.draw(
                    levels: AppUIIndentGuides.levels(depth: depth, unit: self.unit), top: fragment.minY + origin.y, bottom: fragment.maxY + origin.y,
                    geometry: geometry, in: context
                )
            }
        }
    }
#elseif canImport(UIKit)
    import UIKit

    /// A view over the part of a text view that can be seen, drawing the guides through the indentation of its lines, and taking no touches.
    @MainActor
    final class AppUIIndentGuideView: UIView {
        private weak var textView: UITextView?
        var unit: Int {
            didSet { setNeedsDisplay() }
        }

        private var offsetObservation: NSKeyValueObservation?
        private nonisolated(unsafe) var editObserver: NSObjectProtocol?

        init(textView: UITextView, unit: Int) {
            self.textView = textView
            self.unit = unit
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            isOpaque = false
            backgroundColor = .clear
            offsetObservation = textView.observe(\.contentOffset) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.follow() }
            }
            editObserver = NotificationCenter.default.addObserver(
                forName: NSTextStorage.didProcessEditingNotification, object: textView.textStorage, queue: .main
            ) { [weak self] note in
                let changed = (note.object as? NSTextStorage)?.editedMask.contains(.editedCharacters) ?? true
                MainActor.assumeIsolated {
                    if changed {
                        self?.setNeedsDisplay()
                    }
                }
            }
            follow()
        }

        deinit {
            if let editObserver {
                NotificationCenter.default.removeObserver(editObserver)
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("AppUIIndentGuideView is made in code")
        }

        /// Puts the view over the part of the text view that can be seen, and draws it again.
        func follow() {
            guard let textView else { return }
            frame = CGRect(origin: textView.contentOffset, size: textView.bounds.size)
            setNeedsDisplay()
        }

        override func draw(_: CGRect) {
            guard let textView, let context = UIGraphicsGetCurrentContext() else { return }
            let layout = textView.layoutManager
            let text = textView.text as NSString
            let inset = textView.textContainerInset
            let font = textView.font ?? UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            let characterWidth = (" " as NSString).size(withAttributes: [.font: font]).width
            let left = inset.left + textView.textContainer.lineFragmentPadding - textView.contentOffset.x
            let dark = traitCollection.userInterfaceStyle == .dark
            let visible = CGRect(origin: textView.contentOffset, size: textView.bounds.size).offsetBy(dx: 0, dy: -inset.top)
            layout.enumerateLineFragments(forGlyphRange: layout.glyphRange(forBoundingRect: visible, in: textView.textContainer)) { fragment, _, _, glyphRange, _ in
                let characters = layout.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
                let paragraph = text.paragraphRange(for: NSRange(location: min(characters.location, max(0, text.length - 1)), length: 0))
                let depth = AppUIIndentGuideText.guideDepth(in: text, paragraph: paragraph, unit: self.unit)
                let top = fragment.minY + inset.top - textView.contentOffset.y
                let geometry = AppUIIndentGuides.Geometry(
                    unit: self.unit, origin: left, characterWidth: characterWidth, scale: self.contentScaleFactor, dark: dark
                )
                AppUIIndentGuides.draw(
                    levels: AppUIIndentGuides.levels(depth: depth, unit: self.unit), top: top, bottom: top + fragment.height, geometry: geometry, in: context
                )
            }
        }
    }
#endif

public extension AppUITextView {
    /// The width of one level of indentation in spaces when the lines are drawn with a vertical guide through each level of their indentation (see
    /// ``AppUIIndentGuides``); nil draws none. Setting it puts a view that takes no clicks over the text.
    var appuiIndentGuideUnit: Int? {
        get { subviews.compactMap { $0 as? AppUIIndentGuideView }.first?.unit }
        set {
            let guides = subviews.compactMap { $0 as? AppUIIndentGuideView }.first
            if let newValue, newValue > 0 {
                if let guides {
                    guides.unit = newValue
                } else {
                    #if canImport(UIKit) && !canImport(AppKit)
                        insertSubview(AppUIIndentGuideView(textView: self, unit: newValue), at: 0)
                    #else
                        addSubview(AppUIIndentGuideView(textView: self, unit: newValue))
                    #endif
                }
            } else {
                guides?.removeFromSuperview()
            }
        }
    }
}
