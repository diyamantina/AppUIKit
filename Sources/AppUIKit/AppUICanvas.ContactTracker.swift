///
///  AppUICanvas.ContactTracker.swift
///  AppUIKit
///
public extension AppUICanvas {
    /// What the canvas does with a report.
    enum ContactAction: Equatable {
        /// Nothing is reported.
        case ignore
        /// The followed contact begins.
        case begin
        /// The followed contact is cancelled because another landed.
        case cancel
        /// The followed contact is cancelled and the contact that landed begins: a pencil landed while a finger was drawing.
        case replace
        /// The followed contact moves.
        case move
        /// The followed contact lifts.
        case end
        /// The system cancelled the followed contact.
        case system
    }

    /// The rule that one contact at a time draws and a second one turns the gesture into a pinch or a pan, with the pencil first: a pencil contact is always the one followed, a
    /// finger that lands while it is followed is a resting
    /// hand and neither cancels it nor turns the sequence into a pinch, and a pencil that lands while a finger is followed takes over from it.
    ///
    /// The first contact of a sequence is followed. A second contact that lands while it is down cancels it, and no contact of that sequence
    /// draws again until every one is up. Written on plain values so the rule is held by tests: a touch cannot be made in a test.
    struct ContactTracker<ID: Hashable> {
        private var followed: ID?
        private var followedIsPencil = false
        private var isMulti = false

        /// A tracker with no contact down.
        public init() {}

        /// The contact being followed, if any.
        public var current: ID? {
            followed
        }

        /// Contacts landed. `downCount` is how many contacts are down now, those included. `pencil` are those of `ids` that are the pencil.
        public mutating func landed(_ ids: [ID], downCount: Int, pencil: Set<ID> = []) -> ContactAction {
            if let stylus = ids.first(where: { pencil.contains($0) }) {
                let replacing = followed != nil && followed != stylus
                followed = stylus
                followedIsPencil = true
                isMulti = isMulti || downCount > 1
                return replacing ? .replace : .begin
            }
            if followedIsPencil, followed != nil {
                return .ignore // a finger while the pencil draws is a resting hand: it cancels nothing and is not a pinch
            }
            if let followed, !ids.contains(followed) {
                self.followed = nil
                isMulti = true
                return .cancel
            }
            guard !isMulti, downCount == 1, let first = ids.first, followed == nil else {
                isMulti = true
                return .ignore
            }
            followed = first
            return .begin
        }

        /// Contacts moved.
        public func moved(_ ids: [ID]) -> ContactAction {
            guard let followed, ids.contains(followed) else { return .ignore }
            return .move
        }

        /// Contacts lifted (`cancelled` false) or were cancelled by the system. `remaining` is how many contacts stay down.
        public mutating func lifted(_ ids: [ID], cancelled: Bool, remaining: Int) -> ContactAction {
            var action = ContactAction.ignore
            if let followed, ids.contains(followed) {
                self.followed = nil
                followedIsPencil = false
                action = cancelled ? .system : .end
            }
            if remaining == 0 {
                isMulti = false
            }
            return action
        }
    }
}
