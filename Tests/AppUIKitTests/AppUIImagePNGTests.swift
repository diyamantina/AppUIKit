import Foundation
import Testing
@testable import AppUIKit

@MainActor
@Suite("AppUIKit image as PNG")
struct AppUIImagePNGTests {
    private static let signature = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

    private func image(width: Int, height: Int) -> AppUIImage {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let image = AppUIImage(size: NSSize(width: width, height: height))
            image.lockFocus()
            NSColor.red.setFill()
            NSRect(x: 0, y: 0, width: width, height: height).fill()
            image.unlockFocus()
            return image
        #else
            UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).image { context in
                UIColor.red.setFill()
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            }
        #endif
    }

    @Test func `an image with pixels is written as a PNG that reads back at its size`() throws {
        let data = try #require(image(width: 6, height: 4).appuiPNGData())
        #expect(data.prefix(8) == Self.signature)
        // The IHDR chunk holds the width and the height as big-endian integers at bytes 16 and 20.
        let width = data[16 ..< 20].reduce(0) { $0 << 8 | Int($1) }
        let height = data[20 ..< 24].reduce(0) { $0 << 8 | Int($1) }
        #expect(width >= 6 && height >= 4 && width % 6 == 0 && height % 4 == 0, "a scale factor may multiply the pixels, never change the shape: \(width) by \(height)")
        #expect(width * 4 == height * 6)
    }

    @Test func `an image with nothing to draw has no PNG`() {
        #expect(AppUIImage().appuiPNGData() == nil)
    }
}
