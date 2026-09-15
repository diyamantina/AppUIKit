//
//  AppUIInteractiveView.swift
//  AppUIKit
//

import CoreGraphics

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

/// A top-left view with a unified, cross-platform input surface. Subclasses
/// override the semantic callbacks (press / scroll / hover) instead of the
/// platform event methods, so subclass code carries no `#if`: AppKit's
/// mouseDown/mouseDragged/mouseUp/scrollWheel/mouseMoved and UIKit's
/// touchesBegan/Moved/Ended are funneled here. Points are in the view's own
/// top-left coordinates (see ``AppUITopLeftView``).
///
/// This is where the platform input fork lives, once, in the namespace layer,
/// rather than in every interactive view.
open class AppUIInteractiveView: AppUITopLeftView {
    /// A press began (mouse-down on AppKit, first touch-down on UIKit).
    open func pressBegan(at _: CGPoint) {}
    /// The press moved (mouse-drag / touch-move).
    open func pressMoved(at _: CGPoint) {}
    /// The press ended (mouse-up / touch-up).
    open func pressEnded(at _: CGPoint) {}
    /// A scroll or pan, as a content delta (positive y scrolls the content up,
    /// matching a natural wheel or two-finger drag).
    open func scrolled(by _: CGSize) {}
    /// The pointer moved with no button down. AppKit hover only; never called on
    /// UIKit, where there is no pointer.
    open func hoverMoved(at _: CGPoint) {}
    /// The pointer left this interactive surface. AppKit hover only; never called
    /// on UIKit, where there is no pointer.
    open func hoverExited() {
        AppUICursor.arrow.set()
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        override open func mouseDown(with event: NSEvent) {
            pressBegan(at: convert(event.locationInWindow, from: nil))
        }

        override open func mouseDragged(with event: NSEvent) {
            pressMoved(at: convert(event.locationInWindow, from: nil))
        }

        override open func mouseUp(with event: NSEvent) {
            pressEnded(at: convert(event.locationInWindow, from: nil))
        }

        override open func scrollWheel(with event: NSEvent) {
            scrolled(by: CGSize(width: -event.scrollingDeltaX, height: -event.scrollingDeltaY))
        }

        override open func updateTrackingAreas() {
            super.updateTrackingAreas()
            trackingAreas.forEach(removeTrackingArea)
            addTrackingArea(NSTrackingArea(
                rect: bounds,
                options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
                owner: self
            ))
        }

        override open func mouseMoved(with event: NSEvent) {
            hoverMoved(at: convert(event.locationInWindow, from: nil))
        }

        override open func mouseExited(with _: NSEvent) {
            hoverExited()
        }

    #elseif canImport(UIKit)
        override open func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
            if let point = touches.first?.location(in: self) {
                pressBegan(at: point)
            }
        }

        override open func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
            if let point = touches.first?.location(in: self) {
                pressMoved(at: point)
            }
        }

        override open func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) {
            if let point = touches.first?.location(in: self) {
                pressEnded(at: point)
            }
        }
    #endif
}
