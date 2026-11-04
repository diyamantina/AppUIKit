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
            let twist = AppUIRotationGestureRecognizer(target: self, action: #selector(twisted(_:)))
            let pan = AppUIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
            pan.minimumNumberOfTouches = 2
            pan.allowedScrollTypesMask = .all // an iPad trackpad's two-finger scroll and a mouse wheel pan too
            for recognizer in [pinch, twist, pan] as [AppUIGestureRecognizer] {
                recognizer.delegate = self
                addGestureRecognizer(recognizer)
            }
            // Two, three and four fingers tapping are commands, as in Procreate: undo, redo, the interface.
            for command in Command.allCases {
                let tap = AppUITapGestureRecognizer(target: self, action: #selector(multiTapped(_:)))
                tap.numberOfTouchesRequired = command.fingers
                tap.delegate = self
                addGestureRecognizer(tap)
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

        /// The first contact of a sequence draws; a second one cancels it and the gesture becomes a pinch or a pan, unless it is the pencil, which draws whatever fingers are down
        /// (see ``ContactTracker``).
        override func touchesBegan(_ touches: Set<AppUITouch>, with event: AppUIEvent?) {
            // With Space held (a hardware keyboard, and a pointer or a finger) a drag pans, as on the Mac.
            if isSpaceHeld, let touch = touches.first {
                panAnchor = touch.location(in: self)
                return
            }
            let down = event?.allTouches?.count ?? touches.count
            let pencil = touches.filter { $0.type == .pencil }
            let stylus = Set(pencil.map { ObjectIdentifier($0) })
            switch tracker.landed(touches.map { ObjectIdentifier($0) }, downCount: down, pencil: stylus) {
            case .begin:
                if let touch = pencil.first ?? touches.first {
                    report(.began, of: touch, event: event)
                }
            case .replace:
                // the pencil took over from a finger that was drawing: the finger's stroke was a resting hand
                cancelContactIfDown()
                if let touch = pencil.first {
                    report(.began, of: touch, event: event)
                }
            case .cancel:
                cancelContactIfDown()
            default:
                break
            }
        }

        override func touchesMoved(_ touches: Set<AppUITouch>, with event: AppUIEvent?) {
            if let anchor = panAnchor, let touch = touches.first {
                let here = touch.location(in: self)
                emit(navigation: .scroll(dx: here.x - anchor.x, dy: here.y - anchor.y, precise: true, zooms: false, at: here))
                panAnchor = here
                return
            }
            guard tracker.moved(touches.map { ObjectIdentifier($0) }) == .move, let touch = followed(in: touches) else { return }
            report(.moved, of: touch, event: event)
        }

        override func touchesEnded(_ touches: Set<AppUITouch>, with event: AppUIEvent?) {
            if panAnchor != nil {
                panAnchor = nil
                return
            }
            finish(touches, event: event, cancelled: false)
        }

        override func touchesCancelled(_ touches: Set<AppUITouch>, with event: AppUIEvent?) {
            panAnchor = nil
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

        /// A twist step: the recognizer's rotation (radians, clockwise positive on the screen) is reset to 0 after each, about the fingers' centre; the fingers lifting settles the
        /// turn.
        @objc private func twisted(_ recognizer: AppUIRotationGestureRecognizer) {
            switch recognizer.state {
            case .began, .changed:
                let angle = recognizer.rotation
                recognizer.rotation = 0
                emit(navigation: .twist(radians: angle, at: recognizer.location(in: self)))
            case .ended, .cancelled:
                emit(navigation: .settleTurn)
            default:
                break
            }
        }

        /// A two-finger pan, or an iPad trackpad's scroll: the translation since the last step, reset to zero after each.
        @objc private func panned(_ recognizer: AppUIPanGestureRecognizer) {
            guard recognizer.state == .began || recognizer.state == .changed else { return }
            let delta = recognizer.translation(in: self)
            recognizer.setTranslation(.zero, in: self)
            emit(navigation: .scroll(dx: delta.x, dy: delta.y, precise: true, zooms: false, at: recognizer.location(in: self)))
        }

        /// A tap with several fingers: the command of its count.
        @objc func multiTapped(_ recognizer: AppUITapGestureRecognizer) {
            guard recognizer.state == .ended, let command = Command(fingers: recognizer.numberOfTouchesRequired) else { return }
            commandContinuation.yield(command)
        }

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            reportKeys(presses, down: true)
            super.pressesBegan(presses, with: event)
        }

        override func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            reportKeys(presses, down: true)
            super.pressesChanged(presses, with: event)
        }

        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            reportKeys(presses, down: false)
            super.pressesEnded(presses, with: event)
        }

        override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            reportKeys(presses, down: false)
            super.pressesCancelled(presses, with: event)
        }

        /// The hardware keyboard: the modifier keys as they change, and the keys of the canvas (``Key``) by their HID usage, which does not change with the layout. Space is held
        /// until it comes up.
        private func reportKeys(_ presses: Set<UIPress>, down: Bool) {
            guard let key = presses.compactMap(\.key).first else { return }
            let modifiers = Self.modifiers(of: key.modifierFlags)
            emit(modifiers: modifiers, timestamp: ProcessInfo.processInfo.systemUptime)
            if key.keyCode == .keyboardX {
                // X is held like Space; Command or Control with it is the system's.
                if !down || modifiers.isDisjoint(with: [.command, .control]) {
                    holdMarquee(down, timestamp: ProcessInfo.processInfo.systemUptime)
                }
                return
            }
            guard let kind = Self.keyKind(forHIDUsage: key.keyCode) else { return }
            if kind == .space {
                isSpaceHeld = down
                if !down {
                    panAnchor = nil
                }
                keyContinuation.yield(Key(.space, modifiers: modifiers, isDown: down))
            } else if kind == .tilde {
                reportTilde(down: down, modifiers: modifiers)
            } else if down {
                keyContinuation.yield(Key(kind, modifiers: modifiers, isDown: true))
            }
        }

        /// The tilde key: held until it comes up, with Command or Control left to the system.
        private func reportTilde(down: Bool, modifiers: Modifiers) {
            guard modifiers.isDisjoint(with: [.command, .control]) || !down, down != isTildeHeld else { return }
            isTildeHeld = down
            keyContinuation.yield(Key(.tilde, modifiers: modifiers, isDown: down, location: down ? lastLocation : nil))
        }

        /// The canvas's key of a hardware key, by its HID usage.
        static func keyKind(forHIDUsage usage: UIKeyboardHIDUsage) -> KeyKind? {
            hidKeys[usage]
        }

        private static let hidKeys: [UIKeyboardHIDUsage: KeyKind] = [
            .keyboardLeftArrow: .arrow(.left), .keyboardRightArrow: .arrow(.right), .keyboardDownArrow: .arrow(.down), .keyboardUpArrow: .arrow(.up),
            .keyboardDeleteOrBackspace: .delete, .keyboardDeleteForward: .delete, .keyboardEscape: .escape, .keyboardTab: .tab,
            .keyboardReturnOrEnter: .return, .keypadEnter: .return, .keyboardSpacebar: .space, .keyboardGraveAccentAndTilde: .tilde,
        ]

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
                // a hardware key that came up while the canvas was away is never seen: X is let go with the window
                holdMarquee(false, timestamp: ProcessInfo.processInfo.systemUptime)
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

    extension AppUICanvas {
        /// A touch screen has no pointer shape.
        func platformCursorChanged() {}
    }

    extension AppUICanvas: AppUIGestureRecognizerDelegate {
        /// The pinch and the two-finger pan recognize together, so a pinch that moves pans as it zooms; the hover recognizer stands alone.
        public func gestureRecognizer(_ gestureRecognizer: AppUIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: AppUIGestureRecognizer) -> Bool {
            !(gestureRecognizer is AppUIHoverGestureRecognizer) && !(other is AppUIHoverGestureRecognizer)
        }
    }
#endif
