import Foundation
import Testing

/// The rule that keeps events out of everything but the canvas view: the Surface and the files of the canvas that are not the input fork never
/// name an event, gesture or responder API, and the fork is in two files, one for each platform.
@Suite("AppUICanvas source")
struct AppUICanvasSourceTests {
    private static let sources: URL = .init(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Sources/AppUIKit")

    /// What only the input fork may name.
    private static let eventAPIs = [
        "NSEvent", "UIEvent", "UITouch", "AppUIEvent", "AppUITouch", "NSTrackingArea", "AppUITrackingArea", "GestureRecognizer",
        "mouseDown", "mouseUp", "mouseMoved", "mouseDragged", "touchesBegan", "touchesMoved", "touchesEnded", "touchesCancelled",
        "scrollWheel", "magnify(", "acceptsFirstResponder", "canBecomeFirstResponder",
    ]

    private static func canvasFiles() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: sources, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("AppUICanvas") && $0.pathExtension == "swift" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func isFork(_ file: URL) -> Bool {
        ["AppUICanvas+AppKit.swift", "AppUICanvas+UIKit.swift"].contains(file.lastPathComponent)
    }

    @Test
    func `only the two input fork files name an event API`() throws {
        let files = try Self.canvasFiles()
        #expect(files.count >= 9, "the canvas files were found")
        for file in files where !Self.isFork(file) {
            let text = try String(contentsOf: file, encoding: .utf8)
            // The header comment of the view names the rule in words; code is what is scanned.
            let code = text.split(separator: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }.joined(separator: "\n")
            for name in Self.eventAPIs {
                #expect(!code.contains(name), "\(file.lastPathComponent) names \(name); events belong to the input fork")
            }
        }
    }

    @Test
    func `no platform conditional outside the two fork files, and each fork is guarded whole`() throws {
        for file in try Self.canvasFiles() {
            let text = try String(contentsOf: file, encoding: .utf8)
            let conditionals = text.split(separator: "\n").filter { $0.contains("#if") }
            if Self.isFork(file) {
                #expect(conditionals.count == 1, "\(file.lastPathComponent) is one guarded block")
                #expect(text.split(separator: "\n").first { !$0.hasPrefix("//") && !$0.isEmpty }?.hasPrefix("#if") == true)
            } else {
                #expect(conditionals.isEmpty, "\(file.lastPathComponent) has a platform conditional")
            }
        }
    }

    @Test
    func `the display package is tracked by branch and nothing is pinned`() throws {
        let manifest = try String(contentsOf: Self.sources.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Package.swift"), encoding: .utf8)
        let line = try #require(manifest.split(separator: "\n").first { $0.contains("CAControls.git") })
        #expect(line.contains("branch: \"main\""))
        #expect(!line.contains("exact:") && !line.contains("revision:") && !line.contains("from:"))
    }
}
