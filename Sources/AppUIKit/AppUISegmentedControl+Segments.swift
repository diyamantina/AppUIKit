import Foundation

public extension AppUISegmentedControl {
    /// Replaces every segment with one for each title, in order, none selected. AppKit sets the count and labels each segment (its width left to the label); UIKit removes
    /// the segments and inserts the new ones.
    func appuiSetSegments(_ titles: [String]) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            segmentCount = titles.count
            for (index, title) in titles.enumerated() {
                setLabel(title, forSegment: index)
                setWidth(0, forSegment: index)
            }
        #elseif canImport(UIKit)
            removeAllSegments()
            for (index, title) in titles.enumerated() {
                insertSegment(withTitle: title, at: index, animated: false)
            }
        #endif
    }

    /// Turns the segment at `index` on or off: an off segment is drawn dimmed and cannot be chosen (`setEnabled(_:forSegment:)` on AppKit, `setEnabled(_:forSegmentAt:)` on UIKit).
    /// An index outside the control
    /// does nothing.
    func appuiSetSegmentEnabled(_ enabled: Bool, at index: Int) {
        guard (0 ..< appuiSegmentCount).contains(index) else { return }
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            setEnabled(enabled, forSegment: index)
        #elseif canImport(UIKit)
            setEnabled(enabled, forSegmentAt: index)
        #endif
    }

    /// Whether the segment at `index` is on; `false` for an index outside the control.
    func appuiIsSegmentEnabled(at index: Int) -> Bool {
        guard (0 ..< appuiSegmentCount).contains(index) else { return false }
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return isEnabled(forSegment: index)
        #elseif canImport(UIKit)
            return isEnabledForSegment(at: index)
        #endif
    }

    /// How many segments the control has.
    var appuiSegmentCount: Int {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            segmentCount
        #elseif canImport(UIKit)
            numberOfSegments
        #endif
    }

    /// The title of the segment at `index`, or `nil` for a segment that has none.
    func appuiSegmentTitle(at index: Int) -> String? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            label(forSegment: index)
        #elseif canImport(UIKit)
            titleForSegment(at: index)
        #endif
    }

    /// The index of the selected segment, or -1 when none is selected (`selectedSegment` on AppKit, `selectedSegmentIndex` on UIKit, both of which use -1 for none).
    var appuiSelectedSegment: Int {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return selectedSegment
            #elseif canImport(UIKit)
                return selectedSegmentIndex
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                selectedSegment = newValue
            #elseif canImport(UIKit)
                selectedSegmentIndex = newValue
            #endif
        }
    }
}
