import Foundation

public extension AppUIImage {
    /// The image as the bytes of a PNG file, or `nil` when it has no pixels to write (an image of no size, or one with no representation). AppKit goes through the
    /// image's bitmap representation; UIKit through its own PNG writer.
    func appuiPNGData() -> Data? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            guard let tiff = tiffRepresentation, let bitmap = AppUIBitmapImageRep(data: tiff) else { return nil }
            return bitmap.representation(using: .png, properties: [:])
        #elseif canImport(UIKit)
            return pngData()
        #endif
    }
}
