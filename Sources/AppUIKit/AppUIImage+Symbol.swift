import Foundation

public extension AppUIImage {
    /// The SF Symbol `name`, on AppKit and on UIKit alike, or `nil` when the system has no such symbol.
    ///
    /// AppKit builds it with `NSImage(systemSymbolName:accessibilityDescription:)` and UIKit with `UIImage(systemName:)`; the description is what AppKit reads to VoiceOver and
    /// what UIKit leaves to the
    /// view's own accessibility label.
    static func appUISymbol(_ name: String, description: String? = nil) -> AppUIImage? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return NSImage(systemSymbolName: name, accessibilityDescription: description)
        #elseif canImport(UIKit)
            return UIImage(systemName: name)
        #else
            return nil
        #endif
    }
}
