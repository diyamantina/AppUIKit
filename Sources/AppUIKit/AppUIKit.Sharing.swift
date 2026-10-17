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

        /// Shares an image from `anchor`: the system's sharing menu, or when the anchor is not in a presentable window hierarchy the image is copied instead, so
        /// the action is never inert.
        ///
        /// - Parameters:
        ///   - image: The image to share.
        ///   - anchor: The view the menu comes out of.
        ///   - fallback: Where the image is copied when nothing can be presented; the system pasteboard by default.
        @MainActor
        public static func share(image: AppUIImage, from anchor: AppUIView, fallback: AppUIPasteboard = .general) {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                guard anchor.window != nil else {
                    AppUIKit.Pasteboard.copy(image, to: fallback)
                    return
                }
                let picker = NSSharingServicePicker(items: [image])
                let sourceRect = anchor.bounds.isEmpty ? CGRect(x: 0, y: 0, width: 1, height: 1) : anchor.bounds
                picker.show(relativeTo: sourceRect, of: anchor, preferredEdge: .minY)
            #elseif canImport(UIKit)
                guard let presenter = presenter(for: anchor) else {
                    AppUIKit.Pasteboard.copy(image, to: fallback)
                    return
                }
                let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                controller.popoverPresentationController?.sourceView = anchor
                controller.popoverPresentationController?.sourceRect = anchor.bounds.isEmpty ? CGRect(x: 0, y: 0, width: 1, height: 1) : anchor.bounds
                presenter.present(controller, animated: true)
            #endif
        }

        /// Shares the file at `url` from `anchor`: the system's sharing menu with the file as the item, or when the anchor is not in a presentable window hierarchy the
        /// file's path is copied instead, so the action is never inert.
        @MainActor
        public static func share(fileURL url: URL, from anchor: AppUIView) {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                guard anchor.window != nil else {
                    AppUIKit.Pasteboard.copy(url.path)
                    return
                }
                let picker = NSSharingServicePicker(items: [url])
                let sourceRect = anchor.bounds.isEmpty ? CGRect(x: 0, y: 0, width: 1, height: 1) : anchor.bounds
                picker.show(relativeTo: sourceRect, of: anchor, preferredEdge: .minY)
            #elseif canImport(UIKit)
                guard let presenter = presenter(for: anchor) else {
                    AppUIKit.Pasteboard.copy(url.path)
                    return
                }
                let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
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
