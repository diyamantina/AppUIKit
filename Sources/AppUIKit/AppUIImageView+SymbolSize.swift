import Foundation

public extension AppUIImageView {
    /// Draws the symbol of the image view at `pointSize` points: the symbol configuration of an AppKit image view, the preferred symbol configuration of a UIKit one.
    func appuiSetSymbolSize(_ pointSize: Double) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            symbolConfiguration = NSImage.SymbolConfiguration(pointSize: CGFloat(pointSize), weight: .regular)
        #elseif canImport(UIKit)
            preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: CGFloat(pointSize), weight: .regular)
        #endif
    }
}
