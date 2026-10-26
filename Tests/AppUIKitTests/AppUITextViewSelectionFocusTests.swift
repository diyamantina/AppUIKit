import AppUIKit
import Testing

struct AppUITextViewSelectionFocusTests {
    @Test func `a Mac draws a selection without focus and a touch screen does not`() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            #expect(appuiShowsSelectionWithoutFocus() == true)
        #else
            #expect(appuiShowsSelectionWithoutFocus() == false)
        #endif
    }
}
