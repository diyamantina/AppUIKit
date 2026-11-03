//
//  AppUICanvas+AppKit.swift
//  AppUIKit
//
//  The AppKit half of the canvas's input: mouse, tablet and hover events become samples; the window's backing scale becomes the Surface's
//  display scale. The UIKit half is AppUICanvas+UIKit.swift. Nothing in the shared files names either platform.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    public extension AppUICanvas {
        // MARK: Platform hooks

        internal func installPlatformInput() {
            // Hover needs a tracking area; it is made in updateTrackingAreas, which AppKit calls when the area is first needed.
        }

        internal func platformCursorChanged() {
            window?.invalidateCursorRects(for: self)
        }

        override func resetCursorRects() {
            super.resetCursorRects()
            if let native = Self.nativeCursor(cursor) {
                addCursorRect(bounds, cursor: native)
            }
        }

        /// The system cursor of a shape; `nil` for the arrow, which is what no rectangle gives. The diagonal arrows are the system's frame resize cursors (macOS 15 and later);
        /// before
        /// that the crosshair stands in, because the system had no public diagonal arrow.
        internal static func nativeCursor(_ cursor: Cursor) -> NSCursor? {
            switch cursor {
            case .arrow: nil
            case .openHand: .openHand
            case .closedHand: .closedHand
            case .resizeHorizontal: .resizeLeftRight
            case .resizeVertical: .resizeUpDown
            case .resizeDiagonalDown:
                if #available(macOS 15.0, *) {
                    NSCursor.frameResize(position: .topLeft, directions: .all)
                } else {
                    .crosshair
                }
            case .resizeDiagonalUp:
                if #available(macOS 15.0, *) {
                    NSCursor.frameResize(position: .topRight, directions: .all)
                } else {
                    .crosshair
                }
            case .rotate: rotateCursor
            }
        }

        /// A turn arrow, made once from a system symbol, with its hot spot at its centre.
        private static let rotateCursor: NSCursor = {
            let configuration = NSImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
            guard let symbol = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil)?.withSymbolConfiguration(configuration)
            else { return .crosshair }
            let size = NSSize(width: 22, height: 22)
            let image = NSImage(size: size, flipped: false) { rect in
                // A white ring under a black glyph keeps it visible on any colour.
                let tinted: (NSColor) -> NSImage = { colour in
                    NSImage(size: symbol.size, flipped: false) { box in
                        symbol.draw(in: box)
                        colour.set()
                        box.fill(using: .sourceAtop)
                        return true
                    }
                }
                let target = NSRect(x: (rect.width - symbol.size.width) / 2, y: (rect.height - symbol.size.height) / 2, width: symbol.size.width, height: symbol.size.height)
                for step in [(-1.0, 0.0), (1.0, 0.0), (0.0, -1.0), (0.0, 1.0)] {
                    tinted(.white).draw(in: target.offsetBy(dx: step.0, dy: step.1))
                }
                tinted(.black).draw(in: target)
                return true
            }
            return NSCursor(image: image, hotSpot: NSPoint(x: size.width / 2, y: size.height / 2))
        }()

        internal func platformDisplayScale() -> CGFloat {
            window?.backingScaleFactor ?? 1
        }

        // MARK: Focus

        override var acceptsFirstResponder: Bool {
            true
        }

        /// A click that brings the window forward is also the first stroke.
        override func acceptsFirstMouse(for _: AppUIEvent?) -> Bool {
            true
        }

        // MARK: Events

        override func mouseDown(with event: AppUIEvent) {
            emit(.began, contact(of: event), modifiers: Self.modifiers(of: event))
        }

        override func mouseDragged(with event: AppUIEvent) {
            emit(.moved, contact(of: event), modifiers: Self.modifiers(of: event))
        }

        override func mouseUp(with event: AppUIEvent) {
            emit(.ended, contact(of: event), modifiers: Self.modifiers(of: event))
        }

        override func mouseMoved(with event: AppUIEvent) {
            emit(.hovered, contact(of: event), modifiers: Self.modifiers(of: event))
        }

        /// A two-finger scroll, its momentum, or a wheel: one step each, momentum included, because the system sends the momentum.
        override func scrollWheel(with event: AppUIEvent) {
            emit(navigation: .scroll(
                dx: event.scrollingDeltaX, dy: event.scrollingDeltaY, precise: event.hasPreciseScrollingDeltas,
                modifiers: Self.modifiers(of: event), at: convert(event.locationInWindow, from: nil)
            ))
        }

        /// A pinch step: `magnification` is the change since the last event.
        override func magnify(with event: AppUIEvent) {
            emit(navigation: .pinch(magnification: event.magnification, at: convert(event.locationInWindow, from: nil)))
        }

        /// A two-finger double tap.
        override func smartMagnify(with event: AppUIEvent) {
            emit(navigation: .smartZoom(at: convert(event.locationInWindow, from: nil)))
        }

        /// A modifier key went down or up: reported in the pointer's stream, so Shift pressed in the middle of a drag arrives in its order.
        override func flagsChanged(with event: AppUIEvent) {
            emit(modifiers: Self.modifiers(of: event), timestamp: event.timestamp)
            super.flagsChanged(with: event)
        }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            for area in trackingAreas where area.owner === self {
                removeTrackingArea(area)
            }
            addTrackingArea(AppUITrackingArea(rect: bounds, options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect], owner: self))
        }

        // MARK: Window

        override func viewWillMove(toWindow newWindow: AppUIWindow?) {
            if newWindow == nil {
                cancelContactIfDown()
            }
            super.viewWillMove(toWindow: newWindow)
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            refreshDisplayScale()
        }

        override func viewDidChangeBackingProperties() {
            super.viewDidChangeBackingProperties()
            refreshDisplayScale()
        }

        // MARK: Reading an event

        /// What a mouse or tablet event says: where (converted to the view's top-left points), when, by what, and how hard for a pen.
        private func contact(of event: AppUIEvent) -> Contact {
            let device: Device = switch event.subtype {
            case .tabletPoint:
                .pencil
            case .touch:
                .touch
            default:
                .mouse
            }
            return Contact(
                location: convert(event.locationInWindow, from: nil),
                timestamp: event.timestamp,
                device: device,
                force: device == .pencil ? CGFloat(event.pressure) : nil,
                tilt: device == .pencil ? event.tilt : nil
            )
        }

        internal static func modifiers(of event: AppUIEvent) -> Modifiers {
            var result: Modifiers = []
            let flags = event.modifierFlags
            if flags.contains(.capsLock) {
                result.insert(.capsLock)
            }
            if flags.contains(.shift) {
                result.insert(.shift)
            }
            if flags.contains(.control) {
                result.insert(.control)
            }
            if flags.contains(.option) {
                result.insert(.option)
            }
            if flags.contains(.command) {
                result.insert(.command)
            }
            if flags.contains(.numericPad) {
                result.insert(.numericPad)
            }
            if flags.contains(.function) {
                result.insert(.function)
            }
            return result
        }
    }
#endif
