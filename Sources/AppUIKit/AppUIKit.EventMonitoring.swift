// AppUIKit.EventMonitoring.swift
// AppUIKit
//
// Small cross-platform entry points for non-consuming local event observation.

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @preconcurrency import AppKit
#endif

public extension AppUIKit {
    /// Installs a macOS local left-mouse-down monitor and returns its token.
    ///
    /// The handler must return the event to keep normal AppKit delivery intact. UIKit returns `nil` because
    /// touch events do not have an equivalent local monitor.
    @MainActor
    static func addLocalLeftMouseDownMonitor(
        _ handler: @escaping @MainActor (AppUIEvent) -> AppUIEvent?
    ) -> AnyObject? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            AppUIKitLocalLeftMouseDownMonitor(handler: handler)
        #else
            nil
        #endif
    }

    /// Removes an event-monitor token returned by ``addLocalLeftMouseDownMonitor(_:)``.
    static func removeEventMonitor(_ monitor: AnyObject) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            (monitor as? AppUIKitLocalLeftMouseDownMonitor)?.invalidate()
        #endif
    }
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    private final class AppUIKitLocalLeftMouseDownMonitor {
        private var monitor: AnyObject?
        private let handler: @MainActor (AppUIEvent) -> AppUIEvent?

        @MainActor
        init(handler: @escaping @MainActor (AppUIEvent) -> AppUIEvent?) {
            self.handler = handler
            monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
                self?.handle(event) ?? event
            } as AnyObject?
        }

        func invalidate() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
        }

        deinit {
            invalidate()
        }

        @preconcurrency @MainActor
        private func handle(_ event: AppUIEvent) -> AppUIEvent? {
            handler(event)
        }
    }
#endif
