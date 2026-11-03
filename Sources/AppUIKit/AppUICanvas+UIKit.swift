//
//  AppUICanvas+UIKit.swift
//  AppUIKit
//
//  The UIKit half of the canvas's input: touches (with the folded and predicted ones of an event) and the hovering pointer become samples; the
//  trait collection's display scale becomes the Surface's. The AppKit half is AppUICanvas+AppKit.swift. Nothing in the shared files names
//  either platform.
//

#if !(canImport(AppKit) && !targetEnvironment(macCatalyst)) && canImport(UIKit)
    import UIKit

    public extension AppUICanvas {
        // MARK: Platform hooks

        internal func installPlatformInput() {
            isMultipleTouchEnabled = false
            addGestureRecognizer(AppUIHoverGestureRecognizer(target: self, action: #selector(hovered(_:))))
        }

        internal func platformDisplayScale() -> CGFloat {
            let scale = traitCollection.displayScale
            return scale > 0 ? scale : (window?.screen.scale ?? 1)
        }

        // MARK: Focus

        override var canBecomeFirstResponder: Bool {
            true
        }

        // MARK: Events

        override func touchesBegan(_ touches: Set<AppUITouch>, with event: AppUIEvent?) {
            guard contactToken == nil, let touch = touches.first else { return }
            contactToken = ObjectIdentifier(touch)
            report(.began, of: touch, event: event)
        }

        override func touchesMoved(_ touches: Set<AppUITouch>, with event: AppUIEvent?) {
            guard let touch = ours(in: touches) else { return }
            report(.moved, of: touch, event: event)
        }

        override func touchesEnded(_ touches: Set<AppUITouch>, with event: AppUIEvent?) {
            guard let touch = ours(in: touches) else { return }
            report(.ended, of: touch, event: event)
        }

        override func touchesCancelled(_ touches: Set<AppUITouch>, with event: AppUIEvent?) {
            guard let touch = ours(in: touches) else { return }
            report(.cancelled, of: touch, event: event)
        }

        @objc private func hovered(_ recognizer: AppUIHoverGestureRecognizer) {
            guard recognizer.state == .changed || recognizer.state == .began else { return }
            let contact = Contact(location: recognizer.location(in: self), timestamp: ProcessInfo.processInfo.systemUptime, device: .mouse)
            emit(.hovered, contact, modifiers: Self.modifiers(of: recognizer.modifierFlags))
        }

        // MARK: Window and scale

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window == nil {
                cancelContactIfDown()
            }
            refreshDisplayScale()
        }

        // MARK: Reading a touch

        private func ours(in touches: Set<AppUITouch>) -> AppUITouch? {
            guard let token = contactToken else { return nil }
            return touches.first { ObjectIdentifier($0) == token }
        }

        /// Gives the touch of an event to the stream: the folded touches, the touch itself, the predicted ones, in that order.
        private func report(_ phase: Phase, of touch: AppUITouch, event: AppUIEvent?) {
            emit(
                phase: phase,
                folded: (event?.coalescedTouches(for: touch) ?? []).map(contact(of:)),
                own: contact(of: touch),
                predicted: (event?.predictedTouches(for: touch) ?? []).map(contact(of:)),
                modifiers: Self.modifiers(of: event?.modifierFlags ?? [])
            )
        }

        private func contact(of touch: AppUITouch) -> Contact {
            let device: Device = switch touch.type {
            case .direct:
                .touch
            case .pencil:
                .pencil
            case .indirectPointer:
                .mouse
            case .indirect:
                .trackpad
            @unknown default:
                .touch
            }
            let isPen = device == .pencil
            return Contact(
                location: touch.location(in: self),
                timestamp: touch.timestamp,
                device: device,
                force: isPen ? touch.force : nil,
                altitude: isPen ? touch.altitudeAngle : nil,
                azimuth: isPen ? touch.azimuthAngle(in: self) : nil
            )
        }

        internal static func modifiers(of flags: UIKeyModifierFlags) -> Modifiers {
            var result: Modifiers = []
            if flags.contains(.alphaShift) {
                result.insert(.capsLock)
            }
            if flags.contains(.shift) {
                result.insert(.shift)
            }
            if flags.contains(.control) {
                result.insert(.control)
            }
            if flags.contains(.alternate) {
                result.insert(.option)
            }
            if flags.contains(.command) {
                result.insert(.command)
            }
            if flags.contains(.numericPad) {
                result.insert(.numericPad)
            }
            return result
        }
    }
#endif
