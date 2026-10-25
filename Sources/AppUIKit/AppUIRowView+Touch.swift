//
//  AppUIRowView+Touch.swift
//  AppUIKit
//
//  What a finger does to a row view on an iPad: the gestures that scroll it, flick it, select with it and tap in it, and the text input of the keyboard
//  that the typing of an editable view is made of.
//

#if !(canImport(AppKit) && !targetEnvironment(macCatalyst)) && canImport(UIKit)
    import UIKit

    extension AppUIRowView {
        func installGestures() {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
            pan.maximumNumberOfTouches = 1
            addGestureRecognizer(pan)
            let press = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
            press.minimumPressDuration = 0.35
            addGestureRecognizer(press)
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
            addInteraction(UIEditMenuInteraction(delegate: self))
        }

        /// A finger is wider than a pointer: it takes hold of the scroller from this far in.
        static let touchScrollerWidth: CGFloat = 32

        @objc fileprivate func panned(_ recognizer: UIPanGestureRecognizer) {
            let point = recognizer.location(in: self)
            switch recognizer.state {
            case .began:
                // The recognizer begins after the finger has moved a little; the place it went down is that far back.
                let moved = recognizer.translation(in: self)
                touchPanBegan(at: CGPoint(x: point.x - moved.x, y: point.y - moved.y))
                touchPanChanged(by: moved, at: point)
            case .changed:
                touchPanChanged(by: recognizer.translation(in: self), at: point)
            case .ended:
                touchPanEnded(velocity: recognizer.velocity(in: self), at: point)
            default:
                touchPanEnded(velocity: .zero, at: point)
            }
            if recognizer.state == .began || recognizer.state == .changed {
                recognizer.setTranslation(.zero, in: self)
            }
        }

        // MARK: What a touch does

        /// A finger went down: a flick still moving the rows stops, and a finger on the scroller takes hold of it.
        func touchPanBegan(at point: CGPoint) {
            stopMomentum()
            touchOnScroller = knobRect != nil && point.x >= bounds.width - Self.touchScrollerWidth
            if touchOnScroller {
                handlePressBegan(at: point, scrollerWidth: Self.touchScrollerWidth)
            }
        }

        /// The finger moved by `delta` since it last did, and is now at `point`.
        func touchPanChanged(by delta: CGPoint, at point: CGPoint) {
            if touchOnScroller {
                handlePressMoved(at: point)
            } else {
                scroll(byY: -delta.y, x: -delta.x)
            }
        }

        /// The finger lifted at a speed: the rows go on moving and slow down, as a system scroll view's do.
        func touchPanEnded(velocity: CGPoint, at point: CGPoint) {
            if touchOnScroller {
                handlePressEnded(at: point)
                touchOnScroller = false
                return
            }
            startMomentum(velocity: -Double(velocity.y))
        }

        func startMomentum(velocity: Double) {
            stopMomentum()
            let flick = AppUIRowMomentum(velocity: velocity)
            guard flick.isMoving else { return }
            momentum = flick
            let link = CADisplayLink(target: self, selector: #selector(momentumFrame(_:)))
            link.add(to: .main, forMode: .common)
            momentumLink = link
        }

        func stopMomentum() {
            (momentumLink as? CADisplayLink)?.invalidate()
            momentumLink = nil
            momentum = nil
        }

        @objc fileprivate func momentumFrame(_ link: CADisplayLink) {
            advanceMomentum(by: link.targetTimestamp - link.timestamp)
        }

        /// Moves the rows as far as the flick goes in `seconds` more, and ends it when it has slowed to a stop or reached an end of the rows.
        func advanceMomentum(by seconds: Double) {
            guard var flick = momentum else { return }
            let before = position
            scroll(byY: CGFloat(flick.advance(by: seconds)))
            momentum = flick
            if !flick.isMoving || position == before {
                stopMomentum()
            }
        }

        /// A finger held down: the word under it is selected, and moving the finger takes the selection with it. Lifting leaves a menu to copy it.
        func touchLongPress(_ state: UIGestureRecognizer.State, at point: CGPoint) {
            switch state {
            case .began:
                stopMomentum()
                pressCount = 2
                handlePressBegan(at: point)
            case .changed:
                handlePressMoved(at: point)
            case .ended, .cancelled, .failed:
                handlePressEnded(at: point)
                pressCount = 1
                if state == .ended, selection != nil {
                    let configuration = UIEditMenuConfiguration(identifier: nil, sourcePoint: point)
                    (interactions.compactMap { $0 as? UIEditMenuInteraction }).first?.presentEditMenu(with: configuration)
                }
            default:
                break
            }
        }

        @objc fileprivate func longPressed(_ recognizer: UILongPressGestureRecognizer) {
            touchLongPress(recognizer.state, at: recognizer.location(in: self))
        }

        @objc fileprivate func tapped(_ recognizer: UITapGestureRecognizer) {
            touchTap(at: recognizer.location(in: self))
        }

        /// A tap: a flick stops, the place is told to the owner, and in rows that can be edited the caret goes there and the keyboard is asked for.
        func touchTap(at point: CGPoint) {
            stopMomentum()
            guard let place = rowPosition(at: point) else { return }
            if isEditable {
                setCaret(place)
                _ = becomeFirstResponder()
            }
            onActivate?(place, false)
        }
    }

    /// The text of the keyboard, the one on the screen and one that is attached, goes to the owner of the rows as what was typed.
    extension AppUIRowView: @MainActor UIKeyInput {
        public var hasText: Bool {
            // The delete key of the keyboard on the screen is dead when this is false; what there is to delete is for the owner to say.
            true
        }

        public func insertText(_ text: String) {
            guard isEditable, !text.isEmpty else { return }
            switch text {
            case "\n": onEdit?(.newline)
            case "\t": onEdit?(.insert("  "))
            default: onEdit?(.insert(text))
            }
        }

        public func deleteBackward() {
            guard isEditable else { return }
            onEdit?(.deleteBackward)
        }
    }

    extension AppUIRowView: @MainActor UIEditMenuInteractionDelegate {
        public func editMenuInteraction(_: UIEditMenuInteraction, menuFor _: UIEditMenuConfiguration, suggestedActions _: [UIMenuElement]) -> UIMenu? {
            var actions = [UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in self?.copySelection() }]
            if isEditable {
                actions.append(UIAction(title: "Cut", image: UIImage(systemName: "scissors")) { [weak self] _ in self?.cut(nil) })
                actions.append(UIAction(title: "Paste", image: UIImage(systemName: "doc.on.clipboard")) { [weak self] _ in self?.paste(nil) })
            }
            return UIMenu(children: actions)
        }
    }
#endif
