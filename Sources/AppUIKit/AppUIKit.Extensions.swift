// AppUIKit - Cross-platform view and color extensions

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

    // MARK: - NSView Extensions

    public extension NSView {
        var appuiBackgroundColor: NSColor? {
            get { layer?.backgroundColor.flatMap { NSColor(cgColor: $0) } }
            set {
                wantsLayer = true
                layer?.backgroundColor = newValue?.cgColor
            }
        }

        var appuiCornerRadius: CGFloat {
            get { layer?.cornerRadius ?? 0 }
            set {
                wantsLayer = true
                layer?.cornerRadius = newValue
            }
        }

        var appuiClipsToBounds: Bool {
            get { layer?.masksToBounds ?? false }
            set {
                wantsLayer = true
                layer?.masksToBounds = newValue
            }
        }

        var appuiBorderWidth: CGFloat {
            get { layer?.borderWidth ?? 0 }
            set {
                wantsLayer = true
                layer?.borderWidth = newValue
            }
        }

        var appuiBorderColor: NSColor? {
            get { layer?.borderColor.flatMap { NSColor(cgColor: $0) } }
            set {
                wantsLayer = true
                layer?.borderColor = newValue?.cgColor
            }
        }

        func appuiResolvedColor(_ color: NSColor) -> NSColor {
            var resolved = color
            effectiveAppearance.performAsCurrentDrawingAppearance {
                resolved =
                    color.usingColorSpace(.deviceRGB) ?? color
            }
            return resolved
        }

        func appuiApplyLayerBackgroundColor(_ color: NSColor?) {
            wantsLayer = true
            layer?.backgroundColor = color.map(appuiResolvedColor)?.cgColor
        }

        func appuiApplyLayerBorderColor(_ color: NSColor?) {
            wantsLayer = true
            layer?.borderColor = color.map(appuiResolvedColor)?.cgColor
        }

        func appuiAddSubview(_ view: NSView) {
            addSubview(view)
        }

        func appuiRemoveFromSuperview() {
            removeFromSuperview()
        }
    }

    // MARK: - NSColor Extensions

    public extension NSColor {
        static var appuiLabel: NSColor {
            .labelColor
        }

        static var appuiSecondaryLabel: NSColor {
            .secondaryLabelColor
        }

        static var appuiTertiaryLabel: NSColor {
            .tertiaryLabelColor
        }

        static var appuiBackground: NSColor {
            .windowBackgroundColor
        }

        static var appuiSecondaryBackground: NSColor {
            .controlBackgroundColor
        }

        static var appuiSeparator: NSColor {
            .separatorColor
        }

        static var appuiAccent: NSColor {
            .controlAccentColor
        }

        convenience init(appuiRed red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        }
    }

    // MARK: - NSTextField Label Factory

    public extension NSTextField {
        static func appuiLabel(text: String) -> NSTextField {
            let label = NSTextField(labelWithString: text)
            label.isEditable = false
            label.isSelectable = false
            label.isBordered = false
            label.backgroundColor = .clear
            return label
        }
    }

    // MARK: - NSFont Extensions

    public extension NSFont {
        static func appuiSystem(size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
            .systemFont(ofSize: size, weight: weight)
        }

        static func appuiMonospaced(size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
            .monospacedSystemFont(ofSize: size, weight: weight)
        }
    }

    // MARK: - NSImage Extensions

    public extension NSImage {
        static func appuiSystemImage(named name: String) -> NSImage? {
            NSImage(systemSymbolName: name, accessibilityDescription: nil)
        }
    }

#elseif canImport(UIKit)

    // MARK: - UIView Extensions

    public extension UIView {
        var appuiBackgroundColor: UIColor? {
            get { backgroundColor }
            set { backgroundColor = newValue }
        }

        var appuiCornerRadius: CGFloat {
            get { layer.cornerRadius }
            set { layer.cornerRadius = newValue }
        }

        var appuiClipsToBounds: Bool {
            get { clipsToBounds }
            set { clipsToBounds = newValue }
        }

        var appuiBorderWidth: CGFloat {
            get { layer.borderWidth }
            set { layer.borderWidth = newValue }
        }

        var appuiBorderColor: UIColor? {
            get { layer.borderColor.flatMap { UIColor(cgColor: $0) } }
            set { layer.borderColor = newValue?.cgColor }
        }

        func appuiResolvedColor(_ color: UIColor) -> UIColor {
            color.resolvedColor(with: traitCollection)
        }

        func appuiApplyLayerBackgroundColor(_ color: UIColor?) {
            appuiBackgroundColor = color.map(appuiResolvedColor)
        }

        func appuiApplyLayerBorderColor(_ color: UIColor?) {
            appuiBorderColor = color.map(appuiResolvedColor)
        }

        func appuiAddSubview(_ view: UIView) {
            addSubview(view)
        }

        func appuiRemoveFromSuperview() {
            removeFromSuperview()
        }
    }

    // MARK: - UIColor Extensions

    public extension UIColor {
        static var appuiLabel: UIColor {
            .label
        }

        static var appuiSecondaryLabel: UIColor {
            .secondaryLabel
        }

        static var appuiTertiaryLabel: UIColor {
            .tertiaryLabel
        }

        static var appuiBackground: UIColor {
            .systemBackground
        }

        static var appuiSecondaryBackground: UIColor {
            .secondarySystemBackground
        }

        static var appuiSeparator: UIColor {
            .separator
        }

        static var appuiAccent: UIColor {
            .tintColor
        }

        convenience init(appuiRed red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        }
    }

    // MARK: - UILabel Factory

    public extension UILabel {
        static func appuiLabel(text: String) -> UILabel {
            let label = UILabel()
            label.text = text
            return label
        }
    }

    // MARK: - UIFont Extensions

    public extension UIFont {
        static func appuiSystem(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
            .systemFont(ofSize: size, weight: weight)
        }

        static func appuiMonospaced(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
            .monospacedSystemFont(ofSize: size, weight: weight)
        }
    }

    // MARK: - UIImage Extensions

    public extension UIImage {
        static func appuiSystemImage(named name: String) -> UIImage? {
            UIImage(systemName: name)
        }
    }

#endif
