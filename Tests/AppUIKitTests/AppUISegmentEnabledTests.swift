import Testing
@testable import AppUIKit

/// The helper a shared persona bar is written against: one segment can be turned off on both frameworks, and reads back what it was told.
@MainActor
@Suite("AppUIKit segment enabled")
struct AppUISegmentEnabledTests {
    @Test func `a segment can be turned off and on again, the others keep their state, and an index outside the control does nothing`() {
        let control = AppUISegmentedControl()
        control.appuiSetSegments(["Draw", "Design", "Animate"])
        for index in 0 ..< 3 {
            #expect(control.appuiIsSegmentEnabled(at: index), "a new segment is on")
        }
        control.appuiSetSegmentEnabled(false, at: 2)
        #expect(control.appuiIsSegmentEnabled(at: 0) && control.appuiIsSegmentEnabled(at: 1) && !control.appuiIsSegmentEnabled(at: 2))
        control.appuiSetSegmentEnabled(true, at: 2)
        #expect(control.appuiIsSegmentEnabled(at: 2))
        control.appuiSetSegmentEnabled(false, at: 3)
        control.appuiSetSegmentEnabled(false, at: -1)
        #expect((0 ..< 3).allSatisfy { control.appuiIsSegmentEnabled(at: $0) } && !control.appuiIsSegmentEnabled(at: 3) && !control.appuiIsSegmentEnabled(at: -1))
    }
}
