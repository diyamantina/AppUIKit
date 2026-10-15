import Testing
@testable import AppUIKit

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

/// The diffable table aliases: the data source is the platform's own type, the snapshot is the same generic type on both frameworks, and a snapshot applied through the alias
/// reaches the table.
@Suite("AppUIKit diffable table data")
struct AppUIKitDiffableTests {
    private enum Section: Hashable, Sendable { case main }

    @Test func `the snapshot alias builds a keyed snapshot`() {
        var snapshot = AppUIDiffableSnapshot<Section, Int>()
        snapshot.appendSections([.main])
        snapshot.appendItems([10, 20, 30], toSection: .main)
        #expect(snapshot.itemIdentifiers == [10, 20, 30])
        #expect(snapshot.numberOfSections == 1)
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        @Test func `the data source alias is the AppKit type`() {
            #expect(AppUITableViewDiffableDataSource<Section, Int>.self == NSTableViewDiffableDataSource<Section, Int>.self)
        }

        @MainActor
        @Test func `a snapshot applied through the alias reaches the table`() async {
            let table = AppUITableView()
            table.addTableColumn(AppUITableColumn(identifier: AppUIUserInterfaceItemIdentifier("column")))
            let source = AppUITableViewDiffableDataSource<Section, Int>(tableView: table) { _, _, _, _ in AppUIView() }
            var snapshot = AppUIDiffableSnapshot<Section, Int>()
            snapshot.appendSections([.main])
            snapshot.appendItems([1, 2, 3], toSection: .main)
            await source.apply(snapshot, animatingDifferences: false)
            #expect(table.numberOfRows == 3)
            #expect(source.itemIdentifier(forRow: 1) == 2)
        }
    #elseif canImport(UIKit)
        @Test func `the data source alias is the UIKit type`() {
            #expect(AppUITableViewDiffableDataSource<Section, Int>.self == UITableViewDiffableDataSource<Section, Int>.self)
        }

        @MainActor
        @Test func `a snapshot applied through the alias reaches the table`() async {
            let table = AppUITableView()
            let source = AppUITableViewDiffableDataSource<Section, Int>(tableView: table) { _, _, _ in AppUITableViewCell() }
            var snapshot = AppUIDiffableSnapshot<Section, Int>()
            snapshot.appendSections([.main])
            snapshot.appendItems([1, 2, 3], toSection: .main)
            await source.apply(snapshot, animatingDifferences: false)
            #expect(table.numberOfRows(inSection: 0) == 3)
            #expect(source.itemIdentifier(for: IndexPath(row: 1, section: 0)) == 2)
        }
    #endif
}
