import AppUIKit
import Testing

struct AppUIKitLinkActivationTests {
    @Test func `a plain click follows a link where there is a touch screen and not where there is a pointer`() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            #expect(appuiPlainClickFollowsLinks() == false)
        #else
            #expect(appuiPlainClickFollowsLinks() == true)
        #endif
    }
}
