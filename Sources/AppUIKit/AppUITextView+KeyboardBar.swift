//
//  AppUITextView+KeyboardBar.swift
//  AppUIKit
//
//  A row of keys over the keyboard of a touch screen, for the characters a text of data needs and the keyboard hides behind other layers.
//

import Foundation

/// One key of the bar over the keyboard: what it shows, and what it does.
public struct AppUIKeyboardKey: Sendable {
    public enum Action: Sendable {
        /// Types this text at the caret.
        case insert(String)
        case undo
        case redo
        /// Puts the keyboard away.
        case dismiss
    }

    public var title: String
    public var systemImage: String?
    public var accessibilityLabel: String
    public var action: Action

    public init(title: String, systemImage: String? = nil, accessibilityLabel: String, action: Action) {
        self.title = title
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
}

#if canImport(UIKit) && !os(macOS)
    import UIKit

    public extension UITextView {
        /// Puts a bar of keys over the keyboard of this text view, in a scrolling row, or takes the bar away when `keys` is empty. The keys type their text through the
        /// text view, as the keyboard does, so what the view observes of edits it observes of these.
        func appuiSetKeyboardBar(_ keys: [AppUIKeyboardKey]) {
            guard !keys.isEmpty else {
                inputAccessoryView = nil
                return
            }
            inputAccessoryView = AppUIKeyboardBar(keys: keys, textView: self)
        }
    }

    /// The bar: a row of keys in a horizontal scroll view over the blur of the system's bars.
    @MainActor
    final class AppUIKeyboardBar: UIInputView {
        private weak var textView: UITextView?

        init(keys: [AppUIKeyboardKey], textView: UITextView) {
            self.textView = textView
            super.init(frame: CGRect(x: 0, y: 0, width: 320, height: 44), inputViewStyle: .keyboard)
            allowsSelfSizing = true
            let scroll = UIScrollView()
            scroll.showsHorizontalScrollIndicator = false
            scroll.translatesAutoresizingMaskIntoConstraints = false
            addSubview(scroll)
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 6
            row.translatesAutoresizingMaskIntoConstraints = false
            scroll.addSubview(row)
            NSLayoutConstraint.activate([
                heightAnchor.constraint(equalToConstant: 44),
                scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
                scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
                scroll.topAnchor.constraint(equalTo: topAnchor),
                scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
                row.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 8),
                row.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -8),
                row.centerYAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerYAnchor),
            ])
            for key in keys {
                row.addArrangedSubview(button(for: key))
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("AppUIKeyboardBar is made in code")
        }

        /// The keys the bar has, in order, for a test.
        var keyButtons: [UIButton] {
            subviews.compactMap { $0 as? UIScrollView }.first?.subviews.compactMap { $0 as? UIStackView }.first?.arrangedSubviews.compactMap { $0 as? UIButton } ?? []
        }

        private func button(for key: AppUIKeyboardKey) -> UIButton {
            var configuration = UIButton.Configuration.gray()
            configuration.cornerStyle = .medium
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            if let image = key.systemImage {
                configuration.image = UIImage(systemName: image)
            } else {
                configuration.title = key.title
                configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                    var attributes = attributes
                    attributes.font = .monospacedSystemFont(ofSize: 17, weight: .medium)
                    return attributes
                }
            }
            let button = UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in self?.perform(key.action) })
            button.accessibilityLabel = key.accessibilityLabel
            return button
        }

        func perform(_ action: AppUIKeyboardKey.Action) {
            guard let textView else { return }
            switch action {
            case let .insert(text): textView.insertText(text)
            case .undo: textView.undoManager?.undo()
            case .redo: textView.undoManager?.redo()
            case .dismiss: textView.resignFirstResponder()
            }
        }
    }
#else
    #if canImport(AppKit)
        import AppKit

        public extension NSTextView {
            /// A Mac has a keyboard of its own with every key, so there is no bar over it; this is here so that one source file asks for the bar on every platform.
            func appuiSetKeyboardBar(_: [AppUIKeyboardKey]) {}
        }
    #endif
#endif
