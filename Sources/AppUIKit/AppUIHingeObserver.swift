// AppUIHingeObserver.swift
// AppUIKit
//
// The hinge of a foldable device, uniformly across AppKit and UIKit.

import ForwardsCore
#if canImport(UIKit) && !targetEnvironment(macCatalyst)
    import ForwardsUIKit
#endif

/// Reports the hinge state of the view hierarchy a view is in, for live effects and interactions (use reserved regions for layout).
///
/// On UIKit this is `UIHingeInteraction` from iOS 27.1 (through Forwards): the handler is called with the hinge as it is when the observer starts and on each change, and
/// with nil in a hierarchy that has no hinge. Before 27.1, and on AppKit, which has no hinge, the handler is never called. Call ``invalidate()`` when done.
@MainActor
public final class AppUIHingeObserver {
    #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        private let observer: ForwardsHingeObserver

        public init(view: AppUIView, isEnabled: Bool = true, handler: @escaping @MainActor (AppUIHinge?) -> Void) {
            observer = ForwardsHingeObserver(view: view, isEnabled: isEnabled, handler: handler)
        }

        /// Whether the observer is calling its handler. False where there is no hinge to observe.
        public var isEnabled: Bool {
            get { observer.isEnabled }
            set { observer.isEnabled = newValue }
        }

        /// Stops observing.
        public func invalidate() {
            observer.invalidate()
        }
    #else
        public init(view _: AppUIView, isEnabled _: Bool = true, handler _: @escaping @MainActor (AppUIHinge?) -> Void) {}

        /// Always false: AppKit has no hinge to observe.
        public var isEnabled: Bool {
            get { false }
            set { _ = newValue } // nothing to switch: there is no hinge
        }

        public func invalidate() {}
    #endif
}
