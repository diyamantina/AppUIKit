import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

/// Tells a closure the character under the pointer when a text view is Command-clicked (AppKit) or tapped (UIKit), written once for both. It is a gesture
/// recognizer on the text view, which sees the click and lets it through, so the caret still moves and the text is still selected. It must be kept: the
/// text view holds the recognizer, and the recognizer does not hold this.
@MainActor
public final class AppUITextViewClickObserver: NSObject {
    private let handler: @MainActor (Int) -> Void
    private weak var textView: AppUITextView?

    init(textView: AppUITextView, handler: @escaping @MainActor (Int) -> Void) {
        self.textView = textView
        self.handler = handler
        super.init()
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let recognizer = NSClickGestureRecognizer(target: self, action: #selector(clicked(_:)))
            recognizer.delaysPrimaryMouseButtonEvents = false
            textView.addGestureRecognizer(recognizer)
        #elseif canImport(UIKit)
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(clicked(_:)))
            recognizer.cancelsTouchesInView = false
            textView.addGestureRecognizer(recognizer)
        #endif
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
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

    /// A click at `point` of the text view, with or without Command held. Only a click with Command (or a tap, where there is no Command) is told.
    func click(at point: CGPoint, command: Bool) {
        guard command, let textView, let index = characterIndex(at: point, in: textView) else { return }
        handler(index)
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
    /// Command key. The click still reaches the text view. Keep the returned observer as long as the calls are wanted.
    func appuiObserveCommandClick(_ handler: @escaping @MainActor (Int) -> Void) -> AppUITextViewClickObserver {
        AppUITextViewClickObserver(textView: self, handler: handler)
    }
}
