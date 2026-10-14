#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import SwiftUI
    import Testing
    @testable import AppUIKit

    @Suite("AppUIKit AppKit-only aliases")
    struct AppUIKitAppKitOnlyTests {
        @Test func `each alias is the AppKit type it names`() {
            #expect(AppUIText.self == NSText.self)
            #expect(AppUIRulerView.self == NSRulerView.self)
            #expect(AppUIBitmapImageRep.self == NSBitmapImageRep.self)
            #expect(AppUIValidatedUserInterfaceItem.self == NSValidatedUserInterfaceItem.self)
            #expect(AppUIWorkspace.self == NSWorkspace.self)
            #expect(AppUIHostingView<Color>.self == NSHostingView<Color>.self)
            #expect(AppUIHostingController<Color>.self == NSHostingController<Color>.self)
        }
    }
#endif
