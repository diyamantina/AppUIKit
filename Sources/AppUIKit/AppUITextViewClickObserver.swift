import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

/// Tells a closure the character under the pointer when a text view is Command-clicked (AppKit) or tapped (UIKit), written once for both. It is a gesture
/// recognizer on the text view, which sees the click and lets it through, so the caret still moves and the text is still selected. On AppKit it also shows
/// the pointing hand while Command is held over a character that `isLink` accepts, as the editors of the system's own tools do. It must be kept: the text
/// view holds the recognizer, and the recognizer does not hold this.
@MainActor
public final class AppUITextViewClickObserver: NSObject {
    private let handler: @MainActor (Int) -> Void
    private let isLink: @MainActor (Int) -> Bool
    private weak var textView: AppUITextView?
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        private nonisolated(unsafe) var monitor: Any?
    #endif

    init(textView: AppUITextView, isLink: @escaping @MainActor (Int) -> Bool, handler: @escaping @MainActor (Int) -> Void) {
        self.textView = textView
        self.isLink = isLink
        self.handler = handler
        super.init()
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let recognizer = NSClickGestureRecognizer(target: self, action: #selector(clicked(_:)))
            recognizer.delaysPrimaryMouseButtonEvents = false
            textView.addGestureRecognizer(recognizer)
            // Moving the pointer, and pressing or letting go of Command with the pointer still, both decide the cursor.
            textView.addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect], owner: self, userInfo: nil))
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .flagsChanged]) { [weak self] event in
                MainActor.assumeIsolated { self?.updateCursor(command: event.modifierFlags.contains(.command)) }
                return event
            }
        #elseif canImport(UIKit)
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(clicked(_:)))
            recognizer.cancelsTouchesInView = false
            textView.addGestureRecognizer(recognizer)
        #endif
    }

    deinit {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
        #endif
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        /// Needed so that the tracking area, whose owner this is, may ask for the events it follows.
        @objc private func mouseMoved(with _: NSEvent) {}

        /// Shows the pointing hand when Command is held and the pointer is over a link; the text view puts the text cursor back as soon as the pointer moves
        /// away, or Command is let go.
        private func updateCursor(command: Bool) {
            guard let textView, let window = textView.window else { return }
            let point = textView.convert(window.mouseLocationOutsideOfEventStream, from: nil)
            guard textView.visibleRect.contains(point), wantsPointer(at: point, command: command) else { return }
            // The text view sets its own cursor as the event is delivered, after this; setting ours on the next turn of the run loop leaves ours.
            DispatchQueue.main.async { NSCursor.pointingHand.set() }
        }

        @objc private func clicked(_ recognizer: NSClickGestureRecognizer) {
            guard let textView else { return }
            click(at: recognizer.location(in: textView), command: NSEvent.modifierFlags.contains(.command))
        }
    #elseif canImport(UIKit)
        @objc private func clicked(_ recognizer: UITapGestureRecognizer) {
            guard let textView else { return }
            click(at: recognizer.location(in: textView), command: true)
        }
    #endif

    /// A click at `point` of the text view, with or without Command held, as the recognizer tells it. Only a click with Command (or a tap, where there is no
    /// Command) is told; a host that replays a flow without a window makes the click this way.
    public func click(at point: CGPoint, command: Bool) {
        guard command, let textView, let index = characterIndex(at: point, in: textView) else { return }
        handler(index)
    }

    /// Whether the pointer at `point` should be a pointing hand: Command is held and the character under it is a link.
    public func wantsPointer(at point: CGPoint, command: Bool) -> Bool {
        guard command, let textView, let index = characterIndex(at: point, in: textView) else { return false }
        return isLink(index)
    }

    private func characterIndex(at point: CGPoint, in textView: AppUITextView) -> Int? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return textView.characterIndexForInsertion(at: point)
        #elseif canImport(UIKit)
            return textView.closestPosition(to: point).map { textView.offset(from: textView.beginningOfDocument, to: $0) }
        #endif
    }
}

public extension AppUITextView {
    /// Calls `handler` with the UTF-16 index of the character under the pointer when the view is Command-clicked on AppKit, or tapped on UIKit, which has no
    /// Command key. The click still reaches the text view. With Command held on AppKit the pointer becomes a pointing hand over the characters `isLink` says
    /// are links. Keep the returned observer as long as the calls are wanted.
    func appuiObserveCommandClick(
        isLink: @escaping @MainActor (Int) -> Bool = { _ in true }, _ handler: @escaping @MainActor (Int) -> Void
    ) -> AppUITextViewClickObserver {
        AppUITextViewClickObserver(textView: self, isLink: isLink, handler: handler)
    }
}
