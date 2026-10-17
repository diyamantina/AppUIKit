import Foundation

public extension AppUISegmentedControl {
    /// Draws the titles of the segments in the system font at `pointSize` points: the font of an AppKit control, the title attributes of a UIKit control in its normal and selected
    /// states.
    func appuiSetFontSize(_ pointSize: Double) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            font = NSFont.systemFont(ofSize: CGFloat(pointSize))
        #elseif canImport(UIKit)
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: CGFloat(pointSize))]
            setTitleTextAttributes(attributes, for: .normal)
            setTitleTextAttributes(attributes, for: .selected)
        #endif
    }
}
