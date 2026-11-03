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
                force: device == .pencil ? CGFloat(event.pressure) : nil
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
