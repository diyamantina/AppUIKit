import Foundation

public extension AppUIButton {
    /// Draws the symbol of the button at `pointSize` points: the symbol configuration of an AppKit button, the preferred symbol configuration of the image of a UIKit button's
    /// configuration (or of its normal state).
    func appuiSetSymbolSize(_ pointSize: Double) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            symbolConfiguration = NSImage.SymbolConfiguration(pointSize: CGFloat(pointSize), weight: .regular)
        #elseif canImport(UIKit)
            let symbol = UIImage.SymbolConfiguration(pointSize: CGFloat(pointSize), weight: .regular)
            if configuration != nil {
                configuration?.preferredSymbolConfigurationForImage = symbol
            } else {
                setPreferredSymbolConfiguration(symbol, forImageIn: .normal)
            }
        #endif
    }

    /// Takes the padding out of the button, so a small image sits in a small frame: the configuration of a UIKit button has insets of its own; an AppKit borderless button has
    /// none.
    func appuiRemoveContentInsets() {
        #if canImport(UIKit) && !(canImport(AppKit) && !targetEnvironment(macCatalyst))
            configuration?.contentInsets = .zero
        #endif
    }
}
