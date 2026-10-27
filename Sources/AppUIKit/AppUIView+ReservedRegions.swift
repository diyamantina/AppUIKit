// AppUIView+ReservedRegions.swift
// AppUIKit
//
// Reserved regions of a view, uniformly across AppKit and UIKit.

import ForwardsCore
#if canImport(UIKit) && !targetEnvironment(macCatalyst)
    import ForwardsUIKit
#endif

public extension AppUIView {
    /// The reserved regions of `kind` that overlap the view, with frames in the view's coordinate space.
    ///
    /// On UIKit this is `UIView.reservedRegions(kind:options:)` from iOS 27.1 (through Forwards), and empty before it. AppKit has no reserved regions of a view, so it
    /// answers with an empty list: lay the view out as if nothing were reserved. A region is active while it takes effect; by default only the active ones come back.
    @MainActor
    func appuiReservedRegions(kind: AppUIRegionKind, includeInactive: Bool = false) -> [AppUIReservedRegion] {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
            return forwards.reservedRegions(kind: kind, includeInactive: includeInactive)
        #else
            return []
        #endif
    }
}
