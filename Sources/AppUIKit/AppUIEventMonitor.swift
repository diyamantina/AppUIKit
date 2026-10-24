//
//  AppUIEventMonitor.swift
//  AppUIKit
//
//  A local monitor of events that removes itself.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    /// A monitor of the events of the application that takes itself off when it is let go, so a view that holds one needs no deinit of its own.
    final class AppUIEventMonitor {
        private let token: Any?

        init(matching mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> NSEvent?) {
            token = NSEvent.addLocalMonitorForEvents(matching: mask, handler: handler)
        }

        deinit {
            if let token {
                NSEvent.removeMonitor(token)
            }
        }
    }
#endif
