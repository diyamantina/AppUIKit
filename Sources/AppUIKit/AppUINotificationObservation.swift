//
//  AppUINotificationObservation.swift
//  AppUIKit
//
//  An observer of notifications that removes itself.
//

import Foundation

/// An observer of a notification that takes itself off when it is let go, so a view that holds one needs no deinit of its own, and no state of its own that a
/// deinit would have to reach from outside the main actor. The handler is called on the main queue.
final class AppUINotificationObservation {
    private let token: any NSObjectProtocol

    init(name: Notification.Name, object: Any?, handler: @escaping @Sendable (Notification) -> Void) {
        token = NotificationCenter.default.addObserver(forName: name, object: object, queue: .main, using: handler)
    }

    deinit {
        NotificationCenter.default.removeObserver(token)
    }
}
