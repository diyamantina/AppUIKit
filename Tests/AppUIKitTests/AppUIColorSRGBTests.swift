import Testing
@testable import AppUIKit

/// A color made from sRGB numbers reads back as the same numbers on either framework, which is what lets a palette be written once.
@MainActor
@Suite("AppUIColor sRGB")
struct AppUIColorSRGBTests {
    @Test(arguments: [(0.0, 0.0, 0.0, 1.0), (1.0, 1.0, 1.0, 1.0), (0.98, 0.56, 0.12, 0.55), (0.075, 0.085, 0.11, 0.0)])
    func `an sRGB color reads back its numbers`(red: Double, green: Double, blue: Double, alpha: Double) throws {
        let color = AppUIColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let srgb = try #require(color.usingColorSpace(.sRGB))
            let read = (srgb.redComponent, srgb.greenComponent, srgb.blueComponent, srgb.alphaComponent)
        #else
            let read = (color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent)
        #endif
        #expect(abs(read.0 - red) < 1e-6 && abs(read.1 - green) < 1e-6 && abs(read.2 - blue) < 1e-6 && abs(read.3 - alpha) < 1e-6)
    }

    @Test func `two different colors do not read the same`() {
        let one = AppUIColor(srgbRed: 0.2, green: 0.4, blue: 0.6, alpha: 1)
        let other = AppUIColor(srgbRed: 0.2, green: 0.4, blue: 0.7, alpha: 1)
        #expect(one != other)
    }
}
