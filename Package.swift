// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AppUIKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "AppUIKit", targets: ["AppUIKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
    ],
    targets: [
        .target(name: "AppUIKit"),
        .testTarget(name: "AppUIKitTests", dependencies: ["AppUIKit"]),
    ]
)
