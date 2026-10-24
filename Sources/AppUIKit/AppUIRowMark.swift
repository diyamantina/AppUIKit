/// A place along the whole length of the rows of an `AppUIRowView`, drawn on its scroller.
public struct AppUIRowMark: Equatable, Sendable {
    public var row: Int
    /// Drawn larger and in the accent color: the match chosen, the node chosen.
    public var emphasized: Bool

    public init(row: Int, emphasized: Bool = false) {
        self.row = row
        self.emphasized = emphasized
    }
}
