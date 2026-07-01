//  AppUIKit.Sharing.swift
//  AppUIKit
//
//  Platform-adaptive text sharing for AppKit and UIKit.

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

public extension AppUIKit {
    /// Platform-adaptive text sharing.
    ///
    /// Access via `AppUIKit.Sharing.share(text:from:)`. If the anchor is not in a
    /// presentable window hierarchy, the text is copied instead so the action is
    /// never inert.
    enum Sharing {
        @MainActor
        public static func share(text: String, from anchor: AppUIView) {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                guard anchor.window != nil else {
                    AppUIKit.Pasteboard.copy(text)
                    return
                }
                let picker = NSSharingServicePicker(items: [text])
                let sourceRect = anchor.bounds.isEmpty ? CGRect(x: 0, y: 0, width: 1, height: 1) : anchor.bounds
                picker.show(relativeTo: sourceRect, of: anchor, preferredEdge: .minY)
            #elseif canImport(UIKit)
                guard let presenter = presenter(for: anchor) else {
                    AppUIKit.Pasteboard.copy(text)
                    return
                }
                let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                controller.popoverPresentationController?.sourceView = anchor
                controller.popoverPresentationController?.sourceRect = anchor.bounds.isEmpty ? CGRect(x: 0, y: 0, width: 1, height: 1) : anchor.bounds
                presenter.present(controller, animated: true)
            #endif
        }

        #if canImport(UIKit)
            private static func presenter(for view: AppUIView) -> UIViewController? {
                var responder: UIResponder? = view
                while let current = responder {
                    if let controller = current as? UIViewController {
                        return controller
                    }
                    responder = current.next
                }
                return nil
            }
        #endif
    }
}
