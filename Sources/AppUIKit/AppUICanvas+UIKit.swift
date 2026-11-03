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
            isMultipleTouchEnabled = true
            addGestureRecognizer(AppUIHoverGestureRecognizer(target: self, action: #selector(hovered(_:))))
            let pinch = AppUIPinchGestureRecognizer(target: self, action: #selector(pinched(_:)))
            let pan = AppUIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
            pan.minimumNumberOfTouches = 2
            pan.allowedScrollTypesMask = .all // an iPad trackpad's two-finger scroll and a mouse wheel pan too
            for recognizer in [pinch, pan] as [AppUIGestureRecognizer] {
                recognizer.delegate = self
                addGestureRecognizer(recognizer)
            }
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

        /// The first contact of a sequence draws; a second one cancels it and the gesture becomes a pinch or a pan (see ``ContactTracker``).
        override func touchesBegan(_ touches: Set<AppUITouch>, with event: AppUIEvent?) {
            let down = event?.allTouches?.count ?? touches.count
            switch tracker.landed(touches.map { ObjectIdentifier($0) }, downCount: down) {
            case .begin:
                if let touch = touches.first {
                    report(.began, of: touch, event: event)
                }
            case .cancel:
                cancelContactIfDown()
            default:
                break
            }
        }

        override func touchesMoved(_ touches: Set<AppUITouch>, with event: AppUIEvent?) {
            guard tracker.moved(touches.map { ObjectIdentifier($0) }) == .move, let touch = followed(in: touches) else { return }
            report(.moved, of: touch, event: event)
        }

        override func touchesEnded(_ touches: Set<AppUITouch>, with event: AppUIEvent?) {
            finish(touches, event: event, cancelled: false)
        }

        override func touchesCancelled(_ touches: Set<AppUITouch>, with event: AppUIEvent?) {
            finish(touches, event: event, cancelled: true)
        }

        private func finish(_ touches: Set<AppUITouch>, event: AppUIEvent?, cancelled: Bool) {
            let touch = followed(in: touches)
            let remaining = (event?.allTouches ?? []).filter { !touches.contains($0) && $0.phase != .ended && $0.phase != .cancelled }.count
            let action = tracker.lifted(touches.map { ObjectIdentifier($0) }, cancelled: cancelled, remaining: remaining)
            if let touch, action == .end {
                report(.ended, of: touch, event: event)
            } else if let touch, action == .system {
                report(.cancelled, of: touch, event: event)
            }
        }

        // MARK: Navigation and keys

        /// A pinch step: the recognizer's scale is reset to 1 after each, so each step's scale is its factor, about the fingers' centre.
        @objc private func pinched(_ recognizer: AppUIPinchGestureRecognizer) {
            guard recognizer.state == .began || recognizer.state == .changed else { return }
            let factor = recognizer.scale
            recognizer.scale = 1
            emit(navigation: .pinch(factor: factor, at: recognizer.location(in: self)))
        }

        /// A two-finger pan, or an iPad trackpad's scroll: the translation since the last step, reset to zero after each.
        @objc private func panned(_ recognizer: AppUIPanGestureRecognizer) {
            guard recognizer.state == .began || recognizer.state == .changed else { return }
            let delta = recognizer.translation(in: self)
            recognizer.setTranslation(.zero, in: self)
            emit(navigation: .scroll(dx: delta.x, dy: delta.y, precise: true, zooms: false, at: recognizer.location(in: self)))
        }

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            reportKeys(presses)
            super.pressesBegan(presses, with: event)
        }

        override func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            reportKeys(presses)
            super.pressesChanged(presses, with: event)
        }

        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            reportKeys(presses)
            super.pressesEnded(presses, with: event)
        }

        private func reportKeys(_ presses: Set<UIPress>) {
            guard let key = presses.compactMap(\.key).first else { return }
            emit(modifiers: Self.modifiers(of: key.modifierFlags), timestamp: ProcessInfo.processInfo.systemUptime)
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

        private func followed(in touches: Set<AppUITouch>) -> AppUITouch? {
            guard let token = tracker.current else { return nil }
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
                force: isPen ? Contact.normalizedForce(touch.force, maximum: touch.maximumPossibleForce) : nil,
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

    extension AppUICanvas: AppUIGestureRecognizerDelegate {
        /// The pinch and the two-finger pan recognize together, so a pinch that moves pans as it zooms; the hover recognizer stands alone.
        public func gestureRecognizer(_ gestureRecognizer: AppUIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: AppUIGestureRecognizer) -> Bool {
            !(gestureRecognizer is AppUIHoverGestureRecognizer) && !(other is AppUIHoverGestureRecognizer)
        }
    }
#endif
