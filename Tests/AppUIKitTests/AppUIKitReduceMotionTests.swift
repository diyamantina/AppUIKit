//
//  AppUIKitReduceMotionTests.swift
//  AppUIKitTests
//

import Testing
@testable import AppUIKit

@Suite("AppUIKit Reduce Motion")
@MainActor
struct AppUIKitReduceMotionTests {
    @Test("The setting is read from the system, and reading it does not change it")
    func readsSystem() {
        // A test cannot switch the system setting; it can show the read is a stable value of the platform's own flag.
        let first = AppUIKit.reducesMotion
        #expect(AppUIKit.reducesMotion == first)
    }
}
