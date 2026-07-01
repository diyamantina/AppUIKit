// AppUIKit - Cross-platform view factory

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
#elseif canImport(UIKit)
#endif

// MARK: - View Factory

public extension AppUIKit {
    @MainActor
    enum ViewFactory {
        // MARK: - Labels

        public static func label(
            _ text: String,
            size: CGFloat = 13,
            weight: AppUIFont.Weight = .regular,
            color: AppUIColor = .appuiLabel,
            maxLines: Int = 1,
            truncate: Bool = true
        ) -> AppUILabel {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                let label = NSTextField(labelWithString: text)
                label.font = .systemFont(ofSize: size, weight: weight)
                label.textColor = color
                label.translatesAutoresizingMaskIntoConstraints = false
                label.maximumNumberOfLines = maxLines
                label.lineBreakMode = truncate ? .byTruncatingTail : .byWordWrapping
                label.cell?.truncatesLastVisibleLine = true
                return label
            #elseif canImport(UIKit)
                let label = UILabel()
                label.text = text
                label.font = .systemFont(ofSize: size, weight: weight)
                label.textColor = color
                label.translatesAutoresizingMaskIntoConstraints = false
                label.numberOfLines = maxLines
                label.lineBreakMode = truncate ? .byTruncatingTail : .byWordWrapping
                return label
            #endif
        }

        public static func monospacedLabel(
            _ text: String,
            size: CGFloat = 12,
            weight: AppUIFont.Weight = .regular,
            color: AppUIColor = .appuiLabel
        ) -> AppUILabel {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                let label = NSTextField(labelWithString: text)
                label.font = .monospacedSystemFont(ofSize: size, weight: weight)
                label.textColor = color
                label.translatesAutoresizingMaskIntoConstraints = false
                return label
            #elseif canImport(UIKit)
                let label = UILabel()
                label.text = text
                label.font = .monospacedSystemFont(ofSize: size, weight: weight)
                label.textColor = color
                label.translatesAutoresizingMaskIntoConstraints = false
                return label
            #endif
        }

        // MARK: - Buttons

        public static func button(
            title: String,
            action: Selector,
            target: AnyObject?
        ) -> AppUIButton {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                let button = NSButton(title: title, target: target, action: action)
                button.bezelStyle = .rounded
                button.translatesAutoresizingMaskIntoConstraints = false
                return button
            #elseif canImport(UIKit)
                let button = UIButton(type: .system)
                button.setTitle(title, for: .normal)
                if let target {
                    button.addTarget(target, action: action, for: .touchUpInside)
                }
                button.translatesAutoresizingMaskIntoConstraints = false
                return button
            #endif
        }

        public static func iconButton(
            systemName: String,
            action: Selector,
            target: AnyObject?,
            size: CGFloat = 16
        ) -> AppUIButton {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                let button = NSButton()
                button.image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)
                button.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: size, weight: .medium)
                button.bezelStyle = .recessed
                button.isBordered = false
                button.target = target
                button.action = action
                button.translatesAutoresizingMaskIntoConstraints = false
                return button
            #elseif canImport(UIKit)
                let button = UIButton(type: .system)
                let config = UIImage.SymbolConfiguration(pointSize: size, weight: .medium)
                button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
                if let target {
                    button.addTarget(target, action: action, for: .touchUpInside)
                }
                button.translatesAutoresizingMaskIntoConstraints = false
                return button
            #endif
        }

        public static func pillButton(
            title: String,
            color: AppUIColor,
            action: Selector,
            target: AnyObject?
        ) -> AppUIButton {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                let button = NSButton(title: title, target: target, action: action)
                button.bezelStyle = .rounded
                button.wantsLayer = true
                button.layer?.cornerRadius = 12
                button.layer?.backgroundColor = color.cgColor
                button.contentTintColor = .white
                button.translatesAutoresizingMaskIntoConstraints = false
                return button
            #elseif canImport(UIKit)
                let button = UIButton(type: .system)
                button.setTitle(title, for: .normal)
                button.backgroundColor = color
                button.setTitleColor(.white, for: .normal)
                button.layer.cornerRadius = 12
                if let target {
                    button.addTarget(target, action: action, for: .touchUpInside)
                }
                button.translatesAutoresizingMaskIntoConstraints = false
                return button
            #endif
        }

        // MARK: - Separators

        public static func separator(vertical: Bool = false) -> AppUIView {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                let box = NSBox()
                box.boxType = .separator
                box.translatesAutoresizingMaskIntoConstraints = false
                return box
            #elseif canImport(UIKit)
                let view = UIView()
                view.backgroundColor = .separator
                view.translatesAutoresizingMaskIntoConstraints = false
                if vertical {
                    view.widthAnchor.constraint(equalToConstant: 1).isActive = true
                } else {
                    view.heightAnchor.constraint(equalToConstant: 1).isActive = true
                }
                return view
            #endif
        }

        // MARK: - Containers

        public static func card(
            cornerRadius: CGFloat = 12,
            backgroundColor: AppUIColor = .appuiSecondaryBackground
        ) -> AppUIView {
            let view = AppUIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.appuiBackgroundColor = backgroundColor
            view.appuiCornerRadius = cornerRadius
            return view
        }

        public static func scrollView() -> AppUIScrollView {
            let scrollView = AppUIScrollView()
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                scrollView.hasVerticalScroller = true
                scrollView.hasHorizontalScroller = false
                scrollView.drawsBackground = false
            #elseif canImport(UIKit)
                scrollView.showsVerticalScrollIndicator = true
                scrollView.showsHorizontalScrollIndicator = false
            #endif
            return scrollView
        }

        public static func stackView(
            axis: StackAxis,
            spacing: CGFloat = 8,
            alignment: StackAlignment = .leading
        ) -> AppUIStackView {
            let stack = AppUIStackView()
            stack.translatesAutoresizingMaskIntoConstraints = false
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                stack.orientation = axis == .horizontal ? .horizontal : .vertical
                stack.spacing = spacing
                stack.alignment = appKitAlignment(alignment, axis: axis)
            #elseif canImport(UIKit)
                stack.axis = axis == .horizontal ? .horizontal : .vertical
                stack.spacing = spacing
                switch alignment {
                case .leading: stack.alignment = .leading
                case .center: stack.alignment = .center
                case .trailing: stack.alignment = .trailing
                case .fill: stack.alignment = .fill
                }
            #endif
            return stack
        }

        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            /// AppKit's stack alignment is a layout attribute whose axis flips with the stack's orientation:
            /// a vertical stack aligns its children horizontally (leading/centerX/trailing/width), a
            /// horizontal stack aligns them vertically (top/centerY/bottom/height).
            private static func appKitAlignment(_ alignment: StackAlignment, axis: StackAxis) -> NSLayoutConstraint.Attribute {
                switch (axis, alignment) {
                case (.vertical, .leading): .leading
                case (.vertical, .center): .centerX
                case (.vertical, .trailing): .trailing
                case (.vertical, .fill): .width
                case (.horizontal, .leading): .top
                case (.horizontal, .center): .centerY
                case (.horizontal, .trailing): .bottom
                case (.horizontal, .fill): .height
                }
            }
        #endif

        // MARK: - Image Views

        public static func imageView(
            systemName: String,
            size: CGFloat = 24,
            color: AppUIColor = .appuiLabel
        ) -> AppUIImageView {
            let imageView = AppUIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                imageView.image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)
                imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: size, weight: .medium)
                imageView.contentTintColor = color
            #elseif canImport(UIKit)
                let config = UIImage.SymbolConfiguration(pointSize: size, weight: .medium)
                imageView.image = UIImage(systemName: systemName, withConfiguration: config)
                imageView.tintColor = color
            #endif
            return imageView
        }
    }

    // MARK: - Types

    enum StackAxis {
        case horizontal
        case vertical
    }

    enum StackAlignment {
        case leading
        case center
        case trailing
        case fill
    }
}

// MARK: - Backwards Compatibility

public typealias ViewFactory = AppUIKit.ViewFactory
public typealias StackAxis = AppUIKit.StackAxis
public typealias StackAlignment = AppUIKit.StackAlignment
