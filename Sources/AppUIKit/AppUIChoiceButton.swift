import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    /// A button that opens a menu of titles and shows the one chosen, the same on both frameworks: an `NSPopUpButton` on AppKit, a `UIButton` whose menu is its primary action on
    /// UIKit. It tells its owner the index
    /// the person chose through `onChoose`, and `selectedIndex` reads and sets which title shows (setting it does not call `onChoose`).
    @MainActor
    public final class AppUIChoiceButton: NSPopUpButton {
        /// Called with the index of the title the person chose.
        public var onChoose: (@MainActor (Int) -> Void)?

        /// A button listing `titles`, `selected` showing.
        public convenience init(titles: [String], selected: Int) {
            self.init(frame: .zero, pullsDown: false)
            translatesAutoresizingMaskIntoConstraints = false
            target = self
            action = #selector(chosen)
            appuiSetTitles(titles, selected: selected)
        }

        /// Replaces the titles and shows the one at `selected` (none when it is out of range).
        public func appuiSetTitles(_ titles: [String], selected: Int) {
            removeAllItems()
            addItems(withTitles: titles)
            selectedIndex = selected
        }

        /// The index of the title shown, or -1 for none.
        public var selectedIndex: Int {
            get { indexOfSelectedItem }
            set {
                if (0 ..< numberOfItems).contains(newValue) {
                    selectItem(at: newValue)
                } else {
                    select(nil)
                }
            }
        }

        @objc private func chosen() {
            onChoose?(indexOfSelectedItem)
        }
    }
#elseif canImport(UIKit)
    import UIKit

    /// A button that opens a menu of titles and shows the one chosen, the same on both frameworks: an `NSPopUpButton` on AppKit, a `UIButton` whose menu is its primary action on
    /// UIKit. It tells its owner the index
    /// the person chose through `onChoose`, and `selectedIndex` reads and sets which title shows (setting it does not call `onChoose`).
    @MainActor
    public final class AppUIChoiceButton: UIButton {
        /// Called with the index of the title the person chose.
        public var onChoose: (@MainActor (Int) -> Void)?

        private var titles: [String] = []
        /// The index of the title shown, or -1 for none.
        public private(set) var selectedIndex = -1

        /// A button listing `titles`, `selected` showing.
        public convenience init(titles: [String], selected: Int) {
            self.init(type: .system)
            translatesAutoresizingMaskIntoConstraints = false
            showsMenuAsPrimaryAction = true
            appuiSetTitles(titles, selected: selected)
        }

        /// Replaces the titles and shows the one at `selected` (none when it is out of range).
        public func appuiSetTitles(_ titles: [String], selected: Int) {
            self.titles = titles
            show(selected)
        }

        /// Shows the title at `index` without calling `onChoose`.
        public func show(_ index: Int) {
            selectedIndex = titles.indices.contains(index) ? index : -1
            setTitle(titles.indices.contains(index) ? titles[index] : "", for: .normal)
            menu = UIMenu(children: titles.enumerated().map { position, title in
                UIAction(title: title, state: position == selectedIndex ? .on : .off) { [weak self] _ in
                    MainActor.assumeIsolated {
                        self?.show(position)
                        self?.onChoose?(position)
                    }
                }
            })
        }
    }
#endif
