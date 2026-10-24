import Foundation

/// Tells a closure each time the selection or the caret of a text view moves, written once for AppKit and UIKit. It is the text view's delegate for as long as it
/// lives, so it must be kept (the text view holds its delegate weakly) and the text view must have no other delegate.
@MainActor
public final class AppUITextViewSelectionObserver: NSObject, AppUITextViewDelegate {
    private let handler: @MainActor (AppUIRange) -> Void

    init(handler: @escaping @MainActor (AppUIRange) -> Void) {
        self.handler = handler
        super.init()
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        public func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? AppUITextView else { return }
            handler(textView.selectedRange())
        }
    #elseif canImport(UIKit)
        public func textViewDidChangeSelection(_ textView: AppUITextView) {
            handler(textView.selectedRange)
        }
    #endif
}

public extension AppUITextView {
    /// Calls `handler` with the selected range each time the selection or the caret moves, whether the person moved it or the program did. Keep the returned
    /// observer as long as the calls are wanted; the text view has no other delegate while it is kept.
    func appuiObserveSelection(_ handler: @escaping @MainActor (AppUIRange) -> Void) -> AppUITextViewSelectionObserver {
        let observer = AppUITextViewSelectionObserver(handler: handler)
        delegate = observer
        return observer
    }
}
