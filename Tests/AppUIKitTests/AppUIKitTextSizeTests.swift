import Testing
@testable import AppUIKit

#if canImport(UIKit) && !os(macOS)
    import UIKit
#endif

@MainActor
struct AppUIKitTextSizeTests {
    @Test func `a size is the size given where there is no text size setting, and never smaller than it where there is`() {
        let scaled = appuiScaledFontSize(13)
        #if canImport(UIKit) && !os(macOS)
            #expect(scaled >= 13)
        #else
            #expect(scaled == 13)
        #endif
    }

    #if canImport(UIKit) && !os(macOS)
        @Test func `the largest accessibility text size more than doubles a size, and the smallest makes it smaller`() {
            #expect(AppUITextSize.scaled(13, for: .accessibilityExtraExtraExtraLarge) > 26)
            #expect(AppUITextSize.scaled(13, for: .extraSmall) < 13)
            #expect(AppUITextSize.scaled(13, for: .large) == 13, "large is the default, and leaves a size as it is")
        }

        @Test func `a change of text size is observed for as long as the observer is kept, and not after`() async {
            var calls = 0
            var observer = appuiObserveTextSizeChange { calls += 1 }
            NotificationCenter.default.post(name: UIContentSizeCategory.didChangeNotification, object: nil)
            await Task.yield()
            #expect(calls == 1)
            observer = nil
            NotificationCenter.default.post(name: UIContentSizeCategory.didChangeNotification, object: nil)
            await Task.yield()
            #expect(calls == 1)
            _ = observer
        }
    #endif
}
