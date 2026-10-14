#if canImport(SwiftUI)
    import SwiftUI
    import Testing
    @testable import AppUIKit

    private struct Probe: AppUIRepresentable {
        func makeAppUIView(context _: Context) -> AppUIView {
            AppUIView()
        }

        func updateAppUIView(_: AppUIView, context _: Context) {}
    }

    @Suite("AppUIRepresentable")
    struct AppUIRepresentableTests {
        @MainActor
        @Test func `a conformer that writes only the AppUI requirements is a platform representable`() {
            func accepts(_: some AppUIViewRepresentable) {}
            accepts(Probe())
        }
    }
#endif
