//
//  AppUIRowView.swift
//  AppUIKit
//
//  A view that shows rows of fixed height from a source, drawing only the rows in view.
//

import CoreGraphics
import CoreText
import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

/// Shows the rows of an ``AppUIRowSource``, however many, by drawing only the rows that are in view with Core Text. It is as tall as its window and not as
/// tall as its rows: the place it is scrolled to is a `Double` of points from the top of all the rows, so a file of thirty-seven million rows is placed
/// exactly, and nothing it holds grows with the number of rows but a small cache of the rows lately drawn. It scrolls by the wheel, by the keys and by a
/// scroller of its own, selects and copies text, and tells its owner of the places clicked, so an owner can make words into links.
open class AppUIRowView: AppUIInteractiveView {
    /// A row with its line laid out, kept while it is near the window.
    struct CachedRow {
        var row: AppUIRow
        var line: CTLine
        var width: CGFloat
        var gutter: CTLine?
        var gutterWidth: CGFloat
    }

    public weak var source: (any AppUIRowSource)? {
        didSet { reload() }
    }

    public var font: AppUIFont = AppUIKit.Fonts.monospaced(ofSize: 12) {
        didSet { fontChanged() }
    }

    public var textColor: AppUIColor = AppUIKit.Colors.label {
        didSet { invalidateLines() }
    }

    public var gutterColor: AppUIColor = AppUIKit.Colors.secondaryLabel {
        didSet { invalidateLines() }
    }

    public var canvasColor: AppUIColor = AppUIKit.Colors.textBackground {
        didSet { redraw() }
    }

    /// The color behind selected text: a blue that reads on both appearances.
    public var selectionColor: AppUIColor = AppUIKit.Colors.dynamic(light: 0xB3D7FF, dark: 0x264F78) {
        didSet { redraw() }
    }

    /// How many digits the gutter has room for; the owner sets it from the number of lines. Zero draws no gutter.
    public var gutterDigits = 0 {
        didSet { invalidateLines() }
    }

    /// Told of the place the view is scrolled to, in points from the top of all the rows, when a person moves it.
    public var onPositionChange: ((Double) -> Void)?
    /// Told when the selection changes.
    public var onSelectionChange: (() -> Void)?
    /// Told of a click or a tap that was not a drag; `command` is true when Command was held.
    public var onActivate: ((AppUIRowPosition, Bool) -> Void)?
    /// Asked whether the place is a link, to show the pointing hand over it while Command is held.
    public var isLink: ((AppUIRowPosition) -> Bool)?

    public internal(set) var rowCount = 0
    public internal(set) var rowHeight: CGFloat = 16
    public internal(set) var ascent: CGFloat = 12
    public internal(set) var characterWidth: CGFloat = 7
    public internal(set) var selection: ClosedRange<AppUIRowPosition>?
    var selectionAnchor: AppUIRowPosition?
    var cache: [Int: CachedRow] = [:]
    var horizontalOffset: CGFloat = 0
    var widestRow: CGFloat = 0
    var scrollerDrag: CGFloat?
    var pressedWithCommand = false
    var pressMoved = false
    var pressCount = 1
    var showsLinkCursor = false
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        var monitor: AppUIEventMonitor?
    #endif

    /// Points between the top of the first row and the top edge of the view.
    public var position: Double = 0 {
        didSet {
            let clamped = min(maximumPosition, max(0, position))
            if clamped != position {
                position = clamped
                return
            }
            redraw()
        }
    }

    public var maximumPosition: Double {
        max(0, Double(rowCount) * Double(rowHeight) - Double(bounds.height))
    }

    /// The rows that have any part in the view.
    public var visibleRows: Range<Int> {
        guard rowCount > 0, bounds.height > 0 else { return 0 ..< 0 }
        let first = min(rowCount - 1, max(0, Int(position / Double(rowHeight))))
        let last = min(rowCount, Int(((position + Double(bounds.height)) / Double(rowHeight)).rounded(.up)))
        return first ..< max(first + 1, last)
    }

    override public init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        fontChanged()
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            layerContentsRedrawPolicy = .onSetNeedsDisplay
            setAccessibilityRole(.textArea)
            setAccessibilityElement(true)
        #elseif canImport(UIKit)
            isOpaque = true
            isAccessibilityElement = true
            installGestures()
        #endif
    }

    // MARK: Rows

    /// Asks the source for its rows again, as after the file was read or changed.
    public func reload() {
        cache.removeAll()
        selection = nil
        selectionAnchor = nil
        rowCount = source?.rowCount ?? 0
        widestRow = 0
        position = min(position, maximumPosition)
        redraw()
    }

    func fontChanged() {
        // The font is a Core Text font already; making one again from its name would not find a system font, whose name is private.
        let measured: CTFont = font
        ascent = ceil(CTFontGetAscent(measured))
        rowHeight = ceil(CTFontGetAscent(measured) + CTFontGetDescent(measured) + CTFontGetLeading(measured)) + 2
        var glyph = CTFontGetGlyphWithName(measured, "zero" as CFString)
        var advance = CGSize.zero
        CTFontGetAdvancesForGlyphs(measured, .horizontal, &glyph, &advance, 1)
        characterWidth = max(1, advance.width)
        invalidateLines()
    }

    func invalidateLines() {
        cache.removeAll()
        widestRow = 0
        redraw()
    }

    func redraw() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            needsDisplay = true
        #else
            setNeedsDisplay()
        #endif
    }

    override open func didLayout() {
        position = min(position, maximumPosition)
        redraw()
    }

    override open func didChangeAppearance() {
        invalidateLines()
    }

    // MARK: Laying out lines

    var gutterWidth: CGFloat {
        gutterDigits > 0 ? ceil(CGFloat(gutterDigits) * characterWidth) + 16 : 0
    }

    private func attributed(_ row: AppUIRow) -> NSAttributedString {
        let text = NSMutableAttributedString(string: row.text, attributes: [
            .font: font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): textColor.cgColor,
        ])
        let length = (row.text as NSString).length
        for run in row.runs where run.range.lowerBound >= 0 && run.range.upperBound <= length && !run.range.isEmpty {
            let range = NSRange(location: run.range.lowerBound, length: run.range.count)
            text.addAttribute(NSAttributedString.Key(kCTForegroundColorAttributeName as String), value: run.color.cgColor, range: range)
            if run.underline {
                text.addAttribute(.underlineStyle, value: 1, range: range)
            }
        }
        return text
    }

    func layout(_ row: AppUIRow) -> CachedRow {
        let line = CTLineCreateWithAttributedString(attributed(row))
        let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        var gutterLine: CTLine?
        var gutterWidth: CGFloat = 0
        if let label = row.gutter, gutterDigits > 0 {
            let text = NSAttributedString(string: label, attributes: [
                .font: font,
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): gutterColor.cgColor,
            ])
            let made = CTLineCreateWithAttributedString(text)
            gutterLine = made
            gutterWidth = CGFloat(CTLineGetTypographicBounds(made, nil, nil, nil))
        }
        return CachedRow(row: row, line: line, width: width, gutter: gutterLine, gutterWidth: gutterWidth)
    }

    /// Makes sure the rows of `range` and some beyond are laid out, asking the source once for those that are not.
    func prepare(_ range: Range<Int>) {
        guard let source, !range.isEmpty else { return }
        let margin = 48
        let wanted = max(0, range.lowerBound - margin) ..< min(rowCount, range.upperBound + margin)
        guard let firstMissing = wanted.first(where: { cache[$0] == nil }), let lastMissing = wanted.last(where: { cache[$0] == nil }) else { return }
        // A window far from the cache replaces it; one beside it adds to it.
        if cache.count > 1200 {
            cache = cache.filter { abs($0.key - range.lowerBound) < 600 }
        }
        let fetched = source.rows(in: firstMissing ..< lastMissing + 1)
        for (offset, row) in fetched.enumerated() {
            let laid = layout(row)
            cache[firstMissing + offset] = laid
            widestRow = max(widestRow, laid.width)
        }
    }

    // MARK: Drawing

    var currentContext: CGContext? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            NSGraphicsContext.current?.cgContext
        #else
            UIGraphicsGetCurrentContext()
        #endif
    }

    override open func draw(_ dirtyRect: CGRect) {
        guard let context = currentContext else { return }
        context.setFillColor(canvasColor.cgColor)
        context.fill(dirtyRect)
        let visible = visibleRows
        prepare(visible)
        let textLeft = gutterWidth
        let first = visible.lowerBound
        for number in visible {
            guard let cached = cache[number] else { continue }
            let top = CGFloat(Double(number) * Double(rowHeight) - position)
            guard top + rowHeight > dirtyRect.minY, top < dirtyRect.maxY else { continue }
            drawSelection(of: number, cached: cached, top: top, textLeft: textLeft, in: context)
            context.saveGState()
            context.clip(to: CGRect(x: textLeft, y: top, width: max(0, bounds.width - textLeft), height: rowHeight))
            context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
            context.textPosition = CGPoint(x: textLeft + 6 - horizontalOffset, y: top + ascent + 1)
            CTLineDraw(cached.line, context)
            context.restoreGState()
            if let gutter = cached.gutter {
                context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
                context.textPosition = CGPoint(x: textLeft - 8 - cached.gutterWidth, y: top + ascent + 1)
                CTLineDraw(gutter, context)
            }
            _ = first
        }
        drawScroller(in: context)
    }

    private func drawSelection(of number: Int, cached: CachedRow, top: CGFloat, textLeft: CGFloat, in context: CGContext) {
        guard let selection, number >= selection.lowerBound.row, number <= selection.upperBound.row else { return }
        let length = (cached.row.text as NSString).length
        let start = number == selection.lowerBound.row ? min(length, selection.lowerBound.column) : 0
        let end = number == selection.upperBound.row ? min(length, selection.upperBound.column) : length
        let left = CTLineGetOffsetForStringIndex(cached.line, start, nil)
        var right = CTLineGetOffsetForStringIndex(cached.line, end, nil)
        // A row that is selected through its end shows its line break as one more space.
        if number < selection.upperBound.row {
            right += characterWidth
        }
        guard right > left else { return }
        context.setFillColor(selectionColor.cgColor)
        context.fill(CGRect(x: textLeft + 6 - horizontalOffset + left, y: top, width: right - left, height: rowHeight))
    }

    // MARK: Input

    override open func pressBegan(at point: CGPoint) {
        handlePressBegan(at: point)
    }

    override open func pressMoved(at point: CGPoint) {
        handlePressMoved(at: point)
    }

    override open func pressEnded(at point: CGPoint) {
        handlePressEnded(at: point)
    }

    // MARK: The platform's input

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        override open var isOpaque: Bool {
            true
        }

        override open var acceptsFirstResponder: Bool {
            true
        }

        override open func mouseDown(with event: NSEvent) {
            pressedWithCommand = event.modifierFlags.contains(.command)
            pressCount = event.clickCount
            window?.makeFirstResponder(self)
            super.mouseDown(with: event)
        }

        override open func scrollWheel(with event: NSEvent) {
            // A wheel that reports lines is turned into points; a trackpad reports points.
            let scale: CGFloat = event.hasPreciseScrollingDeltas ? 1 : rowHeight * 3
            scroll(byY: -event.scrollingDeltaY * scale, x: -event.scrollingDeltaX * scale)
        }

        override open func keyDown(with event: NSEvent) {
            let page = bounds.height - rowHeight
            let command = event.modifierFlags.contains(.command)
            switch event.specialKey {
            case .upArrow where command: scroll(byY: -.greatestFiniteMagnitude)
            case .downArrow where command: scroll(byY: .greatestFiniteMagnitude)
            case .upArrow: scroll(byY: -rowHeight)
            case .downArrow: scroll(byY: rowHeight)
            case .pageUp: scroll(byY: -page)
            case .pageDown: scroll(byY: page)
            case .home: scroll(byY: -.greatestFiniteMagnitude)
            case .end: scroll(byY: .greatestFiniteMagnitude)
            default: super.keyDown(with: event)
            }
        }

        @objc open func copy(_: Any?) {
            copySelection()
        }

        override open func selectAll(_: Any?) {
            selectEverything()
        }

        /// Copy is on when there is a selection; select all is always on.
        @objc open func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
            item.action == #selector(copy(_:)) ? selection != nil : true
        }

        override open func resetCursorRects() {
            addCursorRect(CGRect(x: 0, y: 0, width: max(0, bounds.width - Self.scrollerHitWidth), height: bounds.height), cursor: .iBeam)
        }

        override open func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            monitor = nil
            guard window != nil else { return }
            // Pressing or letting go of Command with the pointer still decides the cursor, and no event reaches the view for it.
            monitor = AppUIEventMonitor(matching: [.mouseMoved, .flagsChanged]) { [weak self] event in
                let command = event.modifierFlags.contains(.command)
                MainActor.assumeIsolated { self?.updateLinkCursor(command: command) }
                return event
            }
        }

        private func updateLinkCursor(command: Bool) {
            guard let window else { return }
            let point = convert(window.mouseLocationOutsideOfEventStream, from: nil)
            let inside = bounds.contains(point) && point.x < bounds.width - Self.scrollerHitWidth
            let overLink = inside && command && (rowPosition(at: point).map { isLink?($0) ?? false } ?? false)
            if overLink {
                NSCursor.pointingHand.set()
                showsLinkCursor = true
            } else if showsLinkCursor {
                showsLinkCursor = false
                (inside ? NSCursor.iBeam : NSCursor.arrow).set()
            }
        }

        override open func accessibilityValue() -> Any? {
            visibleText
        }

        override open func accessibilityNumberOfCharacters() -> Int {
            (visibleText as NSString).length
        }
    #elseif canImport(UIKit)
        private func installGestures() {
            addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panned(_:))))
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
        }

        @objc private func panned(_ recognizer: UIPanGestureRecognizer) {
            let translation = recognizer.translation(in: self)
            recognizer.setTranslation(.zero, in: self)
            scroll(byY: -translation.y, x: -translation.x)
        }

        @objc private func tapped(_ recognizer: UITapGestureRecognizer) {
            let point = recognizer.location(in: self)
            if let place = rowPosition(at: point) {
                onActivate?(place, false)
            }
        }

        override open var accessibilityValue: String? {
            get { visibleText }
            set {}
        }
    #endif
}
