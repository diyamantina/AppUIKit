//
//  AppUIReservedRegionsTests.swift
//  AppUIKitTests
//

import Testing
@testable import AppUIKit

@Suite("AppUIKit reserved regions and the hinge")
@MainActor
struct AppUIReservedRegionsTests {
    @Test("Whatever the platform reports, each region is of the kind asked for and has a finite frame, and asking for the inactive ones never gives fewer")
    func regions() {
        let view = AppUIView(frame: .init(x: 0, y: 0, width: 400, height: 800))
        for kind in AppUIRegionKind.allCases {
            let active = view.appuiReservedRegions(kind: kind)
            let all = view.appuiReservedRegions(kind: kind, includeInactive: true)
            #expect(all.count >= active.count)
            for region in all {
                #expect(region.kind == kind)
                #expect(region.frame.width.isFinite && region.frame.height.isFinite)
            }
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                #expect(all.isEmpty, "AppKit has no reserved regions of a view")
            #endif
        }
    }

    @Test("A hinge observer can be made, switched and removed, and where there is no hinge it never reports")
    func hingeObserver() {
        let view = AppUIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
        var reported = 0
        let observer = AppUIHingeObserver(view: view) { _ in reported += 1 }
        observer.isEnabled = false
        #expect(!observer.isEnabled)
        observer.invalidate()
        #expect(!observer.isEnabled)
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            #expect(reported == 0)
        #endif
        _ = reported
    }
}
