import Testing
@testable import AppUIKit

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

/// A made color is the light number in the light appearance and the dark number in the dark one.
@MainActor
@Suite("AppUIColor dynamic")
struct AppUIColorDynamicTests {
    /// The sRGB numbers of `color` as `0xRRGGBB` in the appearance named.
    private func rgb(of color: AppUIColor, dark: Bool) throws -> UInt32 {
        var result: UInt32?
        func read(_ color: AppUIColor) throws {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                let srgb = try #require(color.usingColorSpace(.sRGB))
                let (red, green, blue) = (srgb.redComponent, srgb.greenComponent, srgb.blueComponent)
            #else
                let (red, green, blue) = (color.redComponent, color.greenComponent, color.blueComponent)
            #endif
            result = (UInt32((red * 255).rounded()) << 16) | (UInt32((green * 255).rounded()) << 8) | UInt32((blue * 255).rounded())
        }
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let appearance = try #require(NSAppearance(named: dark ? .darkAqua : .aqua))
            var failure: (any Error)?
            appearance.performAsCurrentDrawingAppearance {
                do { try read(color) } catch { failure = error }
            }
            if let failure {
                throw failure
            }
        #else
            try read(color.resolvedColor(with: UITraitCollection(userInterfaceStyle: dark ? .dark : .light)))
        #endif
        return try #require(result)
    }

    @Test(arguments: [(0xA31515 as UInt32, 0xCE9178 as UInt32), (0x000000, 0xFFFFFF), (0x0B5394, 0x9CDCFE)])
    func `a made color is the light number in the light appearance and the dark number in the dark one`(light: UInt32, dark: UInt32) throws {
        let color = AppUIKit.Colors.dynamic(light: light, dark: dark)
        #expect(try rgb(of: color, dark: false) == light)
        #expect(try rgb(of: color, dark: true) == dark)
    }
}
