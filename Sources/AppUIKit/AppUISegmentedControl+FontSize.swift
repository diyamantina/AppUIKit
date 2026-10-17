import Foundation

public extension AppUISegmentedControl {
    /// Draws the titles of the segments in the system font at `pointSize` points: the font of an AppKit control, the title attributes of a UIKit control in its normal and selected
    /// states.
    func appuiSetFontSize(_ pointSize: Double) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let titleFont = NSFont.systemFont(ofSize: CGFloat(pointSize))
            font = titleFont
            // The rounded styles draw at a fixed height whatever the font, which cuts a larger title; the textured square style takes the height of the frame, so a control with a
            // larger title is
            // given a height that holds its line.
            let standardPointSize = NSFont.systemFontSize
            segmentStyle = CGFloat(pointSize) > standardPointSize ? .texturedSquare : .automatic
            let identifier = "appui.segmentedControlHeight"
            constraints.filter { $0.identifier == identifier }.forEach { $0.isActive = false }
            if CGFloat(pointSize) > standardPointSize {
                let height = (titleFont.ascender - titleFont.descender + titleFont.leading).rounded(.up) + 10
                let constraint = heightAnchor.constraint(equalToConstant: height)
                constraint.identifier = identifier
                constraint.isActive = true
            }
            invalidateIntrinsicContentSize()
        #elseif canImport(UIKit)
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: CGFloat(pointSize))]
            setTitleTextAttributes(attributes, for: .normal)
            setTitleTextAttributes(attributes, for: .selected)
        #endif
    }
}
