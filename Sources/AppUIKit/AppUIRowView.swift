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
    /// Whether the rows can be typed in: a caret is shown, keys move it, and what is typed is given to `onEdit` for its owner to put in the text.
    public var isEditable = false {
        didSet {
            if oldValue != isEditable {
                composition = nil
                redraw()
                #if !(canImport(AppKit) && !targetEnvironment(macCatalyst)) && canImport(UIKit)
                    if !isEditable {
                        // The keyboard is put away with the right to type.
                        _ = resignFirstResponder()
                    }
                #endif
            }
        }
    }

    /// Where typed text goes when nothing is selected, or nil while nothing is. Set by a click, the arrow keys, and `setCaret`.
    public internal(set) var caret: AppUIRowPosition? {
        didSet {
            if oldValue != caret {
                redraw()
            }
        }
    }

    /// Text an input method is composing at the caret (the kana before they are turned into characters, the accent waiting for its letter): drawn where it
    /// will be, underlined, and not in the text of the owner until it is committed, as one `AppUIRowEdit.insert`.
    public internal(set) var composition: AppUIRowComposition? {
        didSet {
            if oldValue != composition {
                redraw()
            }
        }
    }

    /// Told what was typed. The owner changes its text and then shows the rows again and puts the caret where it belongs.
    public var onEdit: ((AppUIRowEdit) -> Void)?
    /// Told that Undo or Redo was chosen, and asked whether each can be done, for the menu.
    public var onUndo: (() -> Void)?
    public var onRedo: (() -> Void)?
    public var canUndoRedo: (() -> (undo: Bool, redo: Bool))?
    /// What a touch is doing: a flick still moving the rows, the display link that moves it, and whether the finger went down on the scroller.
    var momentum: AppUIRowMomentum?
    var momentumLink: AnyObject?
    var touchOnScroller = false
    /// Places along the whole length of the rows to show on the scroller, as a map of where in the file things are (matches, the node chosen), so a person
    /// sees them without scrolling. Each is a row; the rows of a file of any length are laid along the height of the view.
    public var marks: [AppUIRowMark] = [] {
        didSet {
            if oldValue != marks {
                redraw()
            }
        }
    }

    var pressedWithCommand = false
    var pressMoved = false
    /// How many clicks the press in progress is the latest of: 2 for a double click. An owner sets it to drive a view by hand.
    public var pressCount = 1
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
        if let composition, composition.row >= rowCount {
            self.composition = nil
        }
        widestRow = 0
        position = min(position, maximumPosition)
        redraw()
    }

    /// Asks the source for the text and the runs of the rows again, as when it has found more to say of them (the links in the rows in view), and draws them.
    /// The rows, the selection and the place are kept, which `reload()` does not.
    public func restyle() {
        invalidateLines()
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

    func attributed(_ row: AppUIRow) -> NSAttributedString {
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
            CTLineDraw(composedLine(of: cached, row: number) ?? cached.line, context)
            context.restoreGState()
            if let gutter = cached.gutter {
                context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
                context.textPosition = CGPoint(x: textLeft - 8 - cached.gutterWidth, y: top + ascent + 1)
                CTLineDraw(gutter, context)
            }
            _ = first
        }
        drawCaret(in: context)
        drawScroller(in: context)
    }

    /// The insertion point: a line the height of the row at the caret, when the rows can be edited and nothing is selected; inside the text being composed
    /// at the place the input method says, while there is some.
    private func drawCaret(in context: CGContext) {
        guard isEditable, selection == nil, let caret, visibleRows.contains(caret.row), let cached = cache[caret.row] else { return }
        let x: CGFloat
        if let composition, composition.row == caret.row, let line = composedLine(of: cached, row: caret.row) {
            x = gutterWidth + 6 - horizontalOffset + CTLineGetOffsetForStringIndex(line, composition.column + composition.selected.location, nil)
        } else {
            let length = (cached.row.text as NSString).length
            x = gutterWidth + 6 - horizontalOffset + CTLineGetOffsetForStringIndex(cached.line, min(length, caret.column), nil)
        }
        let top = CGFloat(Double(caret.row) * Double(rowHeight) - position)
        context.setFillColor(textColor.cgColor)
        context.fill(CGRect(x: x, y: top + 1, width: 1.5, height: rowHeight - 2))
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

        override open func resignFirstResponder() -> Bool {
            endComposition(commit: true)
            inputContext?.discardMarkedText()
            return super.resignFirstResponder()
        }

        override open func mouseDown(with event: NSEvent) {
            // What is being composed is settled where it is before the caret moves.
            endComposition(commit: true)
            inputContext?.discardMarkedText()
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
            if isEditable, !event.modifierFlags.contains(.control), handledByInputSystemOrAsTyped(event) {
                return
            }
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

        /// Text goes through the input system first, so that accents, kana and the rest are made into the text they stand for; a view with no window has none,
        /// and then the keys are what they say. True when the key was dealt with.
        private func handledByInputSystemOrAsTyped(_ event: NSEvent) -> Bool {
            if belongsToInputSystem(event), inputContext?.handleEvent(event) == true {
                return true
            }
            return typed(event)
        }

        /// What a key does to a view that can be edited: moves the caret, or is given to the owner as what was typed. True when it was one of those.
        private func typed(_ event: NSEvent) -> Bool {
            let flags = event.modifierFlags
            if moved(by: AppUIRowCaretKey(event.specialKey), extending: flags.contains(.shift), option: flags.contains(.option), command: flags.contains(.command)) {
                return true
            }
            guard !flags.contains(.command) else { return false }
            switch event.specialKey {
            case .delete: onEdit?(.deleteBackward)
            case .deleteForward: onEdit?(.deleteForward)
            case .carriageReturn, .newline, .enter: onEdit?(.newline)
            case .tab: onEdit?(.insert("  "))
            case nil:
                guard let characters = event.characters, Self.isTypedText(characters) else { return false }
                onEdit?(.insert(characters))
            default: return false
            }
            return true
        }

        @objc open func copy(_: Any?) {
            copySelection()
        }

        @objc open func paste(_: Any?) {
            guard isEditable, let text = AppUIKit.Pasteboard.paste(), !text.isEmpty else { return }
            onEdit?(.insert(text))
        }

        @objc open func cut(_: Any?) {
            guard isEditable, selection != nil else { return }
            copySelection()
            onEdit?(.deleteBackward)
        }

        @objc open func undo(_: Any?) {
            onUndo?()
        }

        @objc open func redo(_: Any?) {
            onRedo?()
        }

        override open func selectAll(_: Any?) {
            selectEverything()
        }

        /// Copy is on when there is a selection; select all is always on.
        @objc open func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
            switch item.action {
            case #selector(copy(_:)): selection != nil
            case #selector(paste(_:)): isEditable
            case #selector(cut(_:)): isEditable && selection != nil
            case #selector(undo(_:)): isEditable && (canUndoRedo?().undo ?? false)
            case #selector(redo(_:)): isEditable && (canUndoRedo?().redo ?? false)
            default: true
            }
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
        override open var canBecomeFirstResponder: Bool {
            true
        }

        override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            switch action {
            case #selector(copy(_:)): selection != nil
            case #selector(cut(_:)): isEditable && selection != nil
            case #selector(paste(_:)): isEditable && UIPasteboard.general.hasStrings
            case #selector(selectAll(_:)): rowCount > 0
            default: super.canPerformAction(action, withSender: sender)
            }
        }

        override open func copy(_: Any?) {
            copySelection()
        }

        override open func cut(_: Any?) {
            guard isEditable, selection != nil else { return }
            copySelection()
            onEdit?(.deleteBackward)
        }

        override open func paste(_: Any?) {
            guard isEditable, let text = pasteboardText(), !text.isEmpty else { return }
            onEdit?(.insert(text))
        }

        override open func selectAll(_: Any?) {
            selectEverything()
        }

        // MARK: Typing

        /// Where paste reads the text from: the pasteboard of the system, which is not open to every process (a test run of the simulator is refused it).
        var pasteboardText: () -> String? = { AppUIKit.Pasteboard.paste() }

        /// Told by this view when the text or the selection changes under the keyboard, as the keyboard tells it to follow.
        public weak var inputDelegate: (any UITextInputDelegate)?
        /// How the keyboard asks marked text to look; the view underlines it itself.
        public var composedStyle: [NSAttributedString.Key: Any]?

        // What is typed is the person's own: nothing is corrected, capitalized, completed or turned into a typographer's mark.
        public var autocorrectionType: UITextAutocorrectionType = .no
        public var autocapitalizationType: UITextAutocapitalizationType = .none
        public var spellCheckingType: UITextSpellCheckingType = .no
        public var smartQuotesType: UITextSmartQuotesType = .no
        public var smartDashesType: UITextSmartDashesType = .no
        public var smartInsertDeleteType: UITextSmartInsertDeleteType = .no

        /// What a key of a hardware keyboard that is not text does: the caret keys (with Shift, Option, Command), forward delete, and Command-Z with and
        /// without Shift for undo and redo. True when it was one of these, so that it is not passed on.
        func handleKey(_ usage: UIKeyboardHIDUsage, charactersIgnoringModifiers characters: String, modifiers: UIKeyModifierFlags) -> Bool {
            guard isEditable else { return false }
            if let key = AppUIRowCaretKey(usage) {
                return moved(by: key, extending: modifiers.contains(.shift), option: modifiers.contains(.alternate), command: modifiers.contains(.command))
            }
            if usage == .keyboardDeleteForward {
                onEdit?(.deleteForward)
                return true
            }
            if modifiers.contains(.command), characters.lowercased() == "z" {
                if modifiers.contains(.shift) {
                    onRedo?()
                } else {
                    onUndo?()
                }
                return true
            }
            return false
        }

        override open func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            let rest = presses.filter { press in
                guard let key = press.key else { return true }
                return !handleKey(key.keyCode, charactersIgnoringModifiers: key.charactersIgnoringModifiers, modifiers: key.modifierFlags)
            }
            if !rest.isEmpty {
                super.pressesBegan(rest, with: event)
            }
        }

        override open var accessibilityValue: String? {
            get { visibleText }
            set {}
        }
    #endif
}
