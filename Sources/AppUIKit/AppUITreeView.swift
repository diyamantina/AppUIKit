//
//  AppUITreeView.swift
//  AppUIKit
//
//  A list of rows with their depth, symbol, title and detail that draws only the rows in view.
//

import CoreGraphics
import CoreText
import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

/// A tree as a list of rows, drawn from a source that is asked for the rows in view. The list of a system view enumerates all its rows to know what
/// they are, which a tree of millions of rows cannot afford; this one is as tall as its window, keeps its place as a `Double` of points, and asks for
/// nothing else. It selects a row by a click or the arrow keys, tells its owner to open or close one (by the chevron, a double click or the left and
/// right arrows), and scrolls by wheel, keys and a scroller of its own.
open class AppUITreeView: AppUIInteractiveView {
    public weak var source: (any AppUITreeSource)? {
        didSet { reload() }
    }

    public var font: AppUIFont = .systemFont(ofSize: 13, weight: .medium) {
        didSet { remeasure() }
    }

    public var detailFont: AppUIFont = AppUIKit.Fonts.monospaced(ofSize: 12) {
        didSet { redraw() }
    }

    public var textColor: AppUIColor = AppUIKit.Colors.label {
        didSet { redraw() }
    }

    public var secondaryColor: AppUIColor = AppUIKit.Colors.secondaryLabel {
        didSet { redraw() }
    }

    public var canvasColor: AppUIColor = AppUIKit.Colors.textBackground {
        didSet { redraw() }
    }

    public var selectionColor: AppUIColor = AppUIKit.Colors.dynamic(light: 0xCFE3FF, dark: 0x37506E) {
        didSet { redraw() }
    }

    /// Told of the row a person chose, by a click or the arrow keys.
    public var onSelect: ((Int) -> Void)?
    /// Told of the row a person asked to open or close.
    public var onToggle: ((Int) -> Void)?
    /// Told of the place the view is scrolled to when a person moves it.
    public var onPositionChange: ((Double) -> Void)?

    public internal(set) var rowCount = 0
    public internal(set) var rowHeight: CGFloat = 24
    public internal(set) var indentWidth: CGFloat = 14
    public var selectedRow: Int? {
        didSet { redraw() }
    }

    var cache: [Int: AppUITreeRow] = [:]
    var scrollerDrag: CGFloat?
    /// How many clicks the press in progress is the latest of: 2 for a double click. An owner sets it to drive a view by hand.
    public var pressCount = 1
    static let scrollerHitWidth: CGFloat = 14

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
        remeasure()
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            layerContentsRedrawPolicy = .onSetNeedsDisplay
            setAccessibilityRole(.outline)
            setAccessibilityElement(true)
        #elseif canImport(UIKit)
            isOpaque = true
            isAccessibilityElement = true
            addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panned(_:))))
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
        #endif
    }

    /// Takes the rows from the source again, as after one was opened or closed. The rows held are forgotten; the place and the selected row are kept.
    public func reload() {
        cache.removeAll()
        rowCount = source?.rowCount ?? 0
        position = min(position, maximumPosition)
        redraw()
    }

    func remeasure() {
        let measured: CTFont = font
        rowHeight = ceil(CTFontGetAscent(measured) + CTFontGetDescent(measured) + CTFontGetLeading(measured)) + 10
        indentWidth = ceil(font.pointSize * 1.1)
        cache.removeAll()
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
        cache.removeAll()
        redraw()
    }

    func row(_ index: Int) -> AppUITreeRow? {
        if let kept = cache[index] {
            return kept
        }
        guard let found = source?.row(at: index) else { return nil }
        if cache.count > 600 {
            cache.removeAll()
        }
        cache[index] = found
        return found
    }

    /// The titles and details of the rows in view, one to a line, which is what assistive technology and tests read.
    public var visibleText: String {
        visibleRows.compactMap { row($0) }.map { $0.detail.isEmpty ? $0.title : "\($0.title)\t\($0.detail)" }.joined(separator: "\n")
    }

    // MARK: Drawing

    override open func draw(_ dirtyRect: CGRect) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            guard let context = NSGraphicsContext.current?.cgContext else { return }
        #else
            guard let context = UIGraphicsGetCurrentContext() else { return }
        #endif
        context.setFillColor(canvasColor.cgColor)
        context.fill(dirtyRect)
        for number in visibleRows {
            let top = CGFloat(Double(number) * Double(rowHeight) - position)
            guard top + rowHeight > dirtyRect.minY, top < dirtyRect.maxY, let row = row(number) else { continue }
            drawRow(row, number: number, top: top, in: context)
        }
        drawScroller(in: context)
    }

    private func drawRow(_ row: AppUITreeRow, number: Int, top: CGFloat, in context: CGContext) {
        if number == selectedRow {
            context.setFillColor(selectionColor.cgColor)
            context.addPath(CGPath(
                roundedRect: CGRect(x: 4, y: top + 1, width: bounds.width - 8 - Self.scrollerHitWidth / 2, height: rowHeight - 2),
                cornerWidth: 5,
                cornerHeight: 5,
                transform: nil
            ))
            context.fillPath()
        }
        let size = font.pointSize
        var x = 10 + CGFloat(row.depth) * indentWidth
        let middle = top + rowHeight / 2
        if row.isLoading {
            drawSymbol("ellipsis", in: CGRect(x: x, y: middle - size / 2, width: indentWidth, height: size), color: secondaryColor, size: size * 0.8, in: context)
        } else if row.isExpandable {
            drawSymbol(
                row.isExpanded ? "chevron.down" : "chevron.right",
                in: CGRect(x: x, y: middle - size / 2, width: indentWidth, height: size),
                color: secondaryColor,
                size: size * 0.75,
                in: context
            )
        }
        x += indentWidth + 2
        if let symbol = row.symbol {
            drawSymbol(symbol, in: CGRect(x: x, y: middle - size / 2, width: size * 1.3, height: size), color: secondaryColor, size: size, in: context)
            x += size * 1.3 + 6
        }
        let right = bounds.width - Self.scrollerHitWidth - 4
        let detail = line(row.detail, font: detailFont, color: secondaryColor)
        let detailWidth = min(CGFloat(CTLineGetTypographicBounds(detail, nil, nil, nil)), max(0, (right - x) * 0.6))
        let title = line(row.title, font: font, color: textColor)
        draw(title, at: CGPoint(x: x, y: top), clippedTo: max(0, right - detailWidth - 10 - x), in: context)
        draw(detail, at: CGPoint(x: right - detailWidth, y: top), clippedTo: detailWidth, in: context, font: detailFont)
    }

    private func line(_ text: String, font: AppUIFont, color: AppUIColor) -> CTLine {
        CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [
            .font: font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color.cgColor,
        ]))
    }

    private func draw(_ line: CTLine, at origin: CGPoint, clippedTo width: CGFloat, in context: CGContext, font drawn: AppUIFont? = nil) {
        guard width > 0 else { return }
        let measured: CTFont = drawn ?? font
        let baseline = origin.y + (rowHeight - (CTFontGetAscent(measured) + CTFontGetDescent(measured))) / 2 + CTFontGetAscent(measured)
        context.saveGState()
        context.clip(to: CGRect(x: origin.x, y: origin.y, width: width, height: rowHeight))
        context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        context.textPosition = CGPoint(x: origin.x, y: baseline)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    /// A symbol of the system filled with `color` inside `rect`, as a template image is.
    private func drawSymbol(_ name: String, in rect: CGRect, color: AppUIColor, size: CGFloat, in context: CGContext) {
        guard let image = AppUIImage.appUISymbol(name) else { return }
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let configured = image.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: size, weight: .semibold)) ?? image
            var proposed = CGRect(origin: .zero, size: configured.size)
            guard let mask = configured.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else { return }
            let drawn = configured.size
        #else
            let configured = image.applyingSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: size, weight: .semibold)) ?? image
            guard let mask = configured.cgImage else { return }
            let drawn = configured.size
        #endif
        let target = CGRect(x: rect.minX + (rect.width - drawn.width) / 2, y: rect.midY - drawn.height / 2, width: drawn.width, height: drawn.height)
        context.saveGState()
        context.translateBy(x: target.minX, y: target.maxY)
        context.scaleBy(x: 1, y: -1)
        context.clip(to: CGRect(x: 0, y: 0, width: target.width, height: target.height), mask: mask)
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: target.width, height: target.height))
        context.restoreGState()
    }

    // MARK: Input

    override open func pressBegan(at point: CGPoint) {
        handlePressBegan(at: point)
    }

    override open func pressMoved(at point: CGPoint) {
        handlePressMoved(at: point)
    }

    override open func pressEnded(at _: CGPoint) {
        handlePressEnded()
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        override open var isOpaque: Bool {
            true
        }

        override open var acceptsFirstResponder: Bool {
            true
        }

        override open func mouseDown(with event: NSEvent) {
            pressCount = event.clickCount
            window?.makeFirstResponder(self)
            super.mouseDown(with: event)
        }

        override open func scrollWheel(with event: NSEvent) {
            scroll(byY: -event.scrollingDeltaY * (event.hasPreciseScrollingDeltas ? 1 : rowHeight * 3))
        }

        override open func keyDown(with event: NSEvent) {
            let page = max(1, Int(bounds.height / rowHeight) - 1)
            switch event.specialKey {
            case .upArrow: moveSelection(by: event.modifierFlags.contains(.command) ? -rowCount : -1)
            case .downArrow: moveSelection(by: event.modifierFlags.contains(.command) ? rowCount : 1)
            case .pageUp: moveSelection(by: -page)
            case .pageDown: moveSelection(by: page)
            case .home: moveSelection(by: -rowCount)
            case .end: moveSelection(by: rowCount)
            case .leftArrow: arrow(opening: false)
            case .rightArrow: arrow(opening: true)
            default: super.keyDown(with: event)
            }
        }

        override open func accessibilityValue() -> Any? {
            visibleText
        }
    #elseif canImport(UIKit)
        @objc private func panned(_ recognizer: UIPanGestureRecognizer) {
            let translation = recognizer.translation(in: self)
            recognizer.setTranslation(.zero, in: self)
            scroll(byY: -translation.y)
        }

        @objc private func tapped(_ recognizer: UITapGestureRecognizer) {
            pressCount = 1
            handlePressBegan(at: recognizer.location(in: self))
        }

        override open var accessibilityValue: String? {
            get { visibleText }
            set {}
        }
    #endif
}
