import Foundation

public extension AppUILabel {
    /// The text the label shows: `stringValue` of the text field AppKit uses for a label, `text` of UIKit's label (empty when it has none).
    var appuiText: String {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return stringValue
            #elseif canImport(UIKit)
                return text ?? ""
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                stringValue = newValue
            #elseif canImport(UIKit)
                text = newValue
            #endif
        }
    }

    /// How many lines the label wraps to at most; 0 is no limit on both frameworks (`maximumNumberOfLines` on AppKit, `numberOfLines` on UIKit).
    var appuiMaximumLines: Int {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return maximumNumberOfLines
            #elseif canImport(UIKit)
                return numberOfLines
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                maximumNumberOfLines = newValue
            #elseif canImport(UIKit)
                numberOfLines = newValue
            #endif
        }
    }

    /// Whether the text is centred in the label (`alignment` of AppKit's text field, `textAlignment` of UIKit's label); the other is the natural alignment of the language.
    var appuiCentersText: Bool {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return alignment == .center
            #elseif canImport(UIKit)
                return textAlignment == .center
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                alignment = newValue ? .center : .natural
            #elseif canImport(UIKit)
                textAlignment = newValue ? .center : .natural
            #endif
        }
    }

    /// Makes the view a read-only label. AppKit's `AppUILabel` is a text field, editable, selectable, bordered and drawn on a background until told otherwise; UIKit's is a label
    /// already, and here it is told to follow the person's text size.
    func appuiConfigureAsLabel() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            isEditable = false
            isSelectable = false
            isBordered = false
            drawsBackground = false
        #elseif canImport(UIKit)
            adjustsFontForContentSizeCategory = true
        #endif
    }
}
