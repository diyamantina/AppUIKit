import Foundation
import ObjectiveC

/// One item of a context menu: a title, an optional SF Symbol, whether it is on, and what it does. The same description makes an `NSMenuItem` on AppKit and a `UIAction` on UIKit.
public struct AppUIContextEntry {
    /// The words of the item.
    public let title: String
    /// The SF Symbol of the item, or `nil` for none.
    public let symbol: String?
    /// Whether the item can be chosen; an off item is shown dimmed.
    public let isEnabled: Bool
    /// What the item does.
    public let action: @MainActor () -> Void

    /// An item with `title`, `symbol` and `action`, on unless `isEnabled` says not.
    public init(title: String, symbol: String? = nil, isEnabled: Bool = true, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.symbol = symbol
        self.isEnabled = isEnabled
        self.action = action
    }
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    @MainActor
    private final class ContextMenuHandler: NSObject, NSMenuDelegate {
        let sections: @MainActor () -> [[AppUIContextEntry]]
        private var actions: [@MainActor () -> Void] = []

        init(sections: @escaping @MainActor () -> [[AppUIContextEntry]]) {
            self.sections = sections
        }

        func menuNeedsUpdate(_ menu: NSMenu) {
            menu.removeAllItems()
            actions = []
            for (index, section) in sections().enumerated() {
                if index > 0 {
                    menu.addItem(.separator())
                }
                for entry in section {
                    let item = NSMenuItem(title: entry.title, action: #selector(chosen(_:)), keyEquivalent: "")
                    item.target = self
                    item.tag = actions.count
                    item.isEnabled = entry.isEnabled
                    if let symbol = entry.symbol {
                        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: entry.title)
                    }
                    actions.append(entry.action)
                    menu.addItem(item)
                }
            }
        }

        @objc private func chosen(_ item: NSMenuItem) {
            if actions.indices.contains(item.tag) {
                actions[item.tag]()
            }
        }
    }

    /// The key the handler is kept under on the view: the address of a class made for the purpose, which is one address for the whole process and is no variable.
    private final class HandlerKey {}

    private var handlerKey: UnsafeRawPointer {
        unsafeBitCast(HandlerKey.self, to: UnsafeRawPointer.self)
    }

    public extension AppUIView {
        /// Gives the view a context menu (a secondary click) whose sections are asked for each time it opens, so it shows the state of that moment: AppKit's menu, built from the
        /// entries, with a separator between sections.
        func appuiSetContextMenu(sections: @escaping @MainActor () -> [[AppUIContextEntry]]) {
            let handler = ContextMenuHandler(sections: sections)
            objc_setAssociatedObject(self, handlerKey, handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            let menu = NSMenu()
            menu.delegate = handler
            self.menu = menu
        }
    }
#elseif canImport(UIKit)
    import UIKit

    @MainActor
    private final class ContextMenuHandler: NSObject, UIContextMenuInteractionDelegate {
        let sections: @MainActor () -> [[AppUIContextEntry]]

        init(sections: @escaping @MainActor () -> [[AppUIContextEntry]]) {
            self.sections = sections
        }

        nonisolated func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
            UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                MainActor.assumeIsolated {
                    UIMenu(children: self.sections().map { section in
                        UIMenu(options: .displayInline, children: section.map { entry in
                            UIAction(
                                title: entry.title, image: entry.symbol.flatMap { UIImage(systemName: $0) }, attributes: entry.isEnabled ? [] : .disabled
                            ) { _ in MainActor.assumeIsolated { entry.action() } }
                        })
                    })
                }
            }
        }
    }

    /// The key the handler is kept under on the view: the address of a class made for the purpose, which is one address for the whole process and is no variable.
    private final class HandlerKey {}

    private var handlerKey: UnsafeRawPointer {
        unsafeBitCast(HandlerKey.self, to: UnsafeRawPointer.self)
    }

    public extension AppUIView {
        /// Gives the view a context menu (a secondary click, a long press) whose sections are asked for each time it opens, so it shows the state of that moment: a `UIMenu` of
        /// inline sections of actions.
        func appuiSetContextMenu(sections: @escaping @MainActor () -> [[AppUIContextEntry]]) {
            let handler = ContextMenuHandler(sections: sections)
            objc_setAssociatedObject(self, handlerKey, handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            addInteraction(UIContextMenuInteraction(delegate: handler))
        }
    }
#endif
