import Foundation
import ObjectiveC

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    /// The keys the flag is kept under on the button: the address of a class made for the purpose, one address for the whole process.
    private final class OpensOnPressKey {}

    private var opensOnPressKey: UnsafeRawPointer {
        unsafeBitCast(OpensOnPressKey.self, to: UnsafeRawPointer.self)
    }
#elseif canImport(UIKit)
    import UIKit
#endif

public extension AppUIButton {
    /// Gives the button a menu whose sections are asked for each time it opens, so it shows the state of that moment. The menu opens from a secondary click on AppKit and from a
    /// long press or a
    /// secondary click on UIKit; with `opensOnPress` it also opens from a plain press (`appuiMenuOpensOnPress`).
    func appuiSetMenu(opensOnPress: Bool = false, sections: @escaping @MainActor () -> [[AppUIContextEntry]]) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            appuiSetContextMenu(sections: sections)
        #elseif canImport(UIKit)
            menu = UIMenu(children: [
                UIDeferredMenuElement.uncached { completion in
                    MainActor.assumeIsolated {
                        completion(sections().map { section in
                            UIMenu(options: .displayInline, children: section.map { entry in
                                UIAction(
                                    title: entry.title, image: entry.symbol.flatMap { UIImage(systemName: $0) }, attributes: entry.isEnabled ? [] : .disabled
                                ) { _ in MainActor.assumeIsolated { entry.action() } }
                            })
                        })
                    }
                },
            ])
        #endif
        appuiMenuOpensOnPress = opensOnPress
    }

    /// Whether a plain press opens the menu. On UIKit the button presents the menu itself and sends no primary action while this is on (`showsMenuAsPrimaryAction`); on AppKit the
    /// click's action
    /// must call `appuiPopUpMenu()` while this is on, so the flag is what the owner reads to decide between its own action and the menu.
    var appuiMenuOpensOnPress: Bool {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                (objc_getAssociatedObject(self, opensOnPressKey) as? NSNumber)?.boolValue ?? false
            #elseif canImport(UIKit)
                showsMenuAsPrimaryAction
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                objc_setAssociatedObject(self, opensOnPressKey, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            #elseif canImport(UIKit)
                showsMenuAsPrimaryAction = newValue
            #endif
        }
    }

    /// Opens the menu now, below the button. AppKit pops the menu up and returns when it is dismissed. On UIKit a button that opens its menu on a press presents it itself when
    /// pressed, and
    /// there is no public call that presents it from code, so this does nothing there.
    func appuiPopUpMenu() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            menu?.popUp(positioning: nil, at: NSPoint(x: 0, y: isFlipped ? bounds.height : 0), in: self)
        #endif
    }

    /// The colour of the button's image: `contentTintColor` on AppKit, `tintColor` on UIKit.
    var appuiContentTintColor: AppUIColor? {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                contentTintColor
            #elseif canImport(UIKit)
                tintColor
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                contentTintColor = newValue
            #elseif canImport(UIKit)
                tintColor = newValue
            #endif
        }
    }
}
