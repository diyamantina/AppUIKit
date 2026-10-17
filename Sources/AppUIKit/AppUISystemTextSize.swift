import Foundation

/// The text size the platform's accessibility settings ask for, as a percentage of the standard one.
///
/// UIKit has Dynamic Type: the body font's point size at the person's content size category, against 17 points at the default category (Apple's Human Interface Guidelines table),
/// is the percentage.
/// AppKit has no such setting, so it asks for nothing and the percentage is 100.
@MainActor
public enum AppUISystemTextSize {
    /// The body font's point size at the default content size category.
    public static let standardBodyPointSize = 17.0

    /// The percentage now, rounded to a whole number: 100 when the platform asks for nothing.
    public static var percent: Int {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return 100
        #elseif canImport(UIKit)
            let body = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
            return Int((body / standardBodyPointSize * 100).rounded())
        #else
            return 100
        #endif
    }

    /// Calls `handler` with the new percentage each time the person changes the size in the system's settings. Keep the returned token for as long as the calls are wanted.
    public static func observe(_ handler: @escaping @MainActor (Int) -> Void) -> any NSObjectProtocol {
        #if canImport(UIKit) && !(canImport(AppKit) && !targetEnvironment(macCatalyst))
            return NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { handler(percent) }
            }
        #else
            return NSObject()
        #endif
    }
}
