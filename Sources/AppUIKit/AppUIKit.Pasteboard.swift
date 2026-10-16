//
//  AppUIKit.Pasteboard.swift
//  AppUIKit
//
//  Platform-adaptive pasteboard operations for macOS and iOS.
//

import Foundation

#if os(macOS)
#else
#endif

public extension AppUIKit {
    /// Platform-adaptive pasteboard operations.
    ///
    /// Access via `AppUIKit.Pasteboard.copy(...)`, `AppUIKit.Pasteboard.paste()`.
    enum Pasteboard {
        /// Copy text to the system pasteboard.
        ///
        /// - Parameter text: The text to copy.
        public static func copy(_ text: String) {
            #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            #else
                UIPasteboard.general.string = text
            #endif
        }

        /// Copy an image to a pasteboard, the system's by default.
        ///
        /// - Parameters:
        ///   - image: The image to copy.
        ///   - pasteboard: Where the image goes; a test gives its own so the person's clipboard is not touched.
        public static func copy(_ image: AppUIImage, to pasteboard: AppUIPasteboard = .general) {
            #if os(macOS)
                pasteboard.clearContents()
                pasteboard.writeObjects([image])
            #else
                pasteboard.image = image
            #endif
        }

        /// Get text from the system pasteboard.
        ///
        /// - Returns: The text from the pasteboard, or nil if unavailable.
        public static func paste() -> String? {
            #if os(macOS)
                NSPasteboard.general.string(forType: .string)
            #else
                UIPasteboard.general.string
            #endif
        }
    }
}
