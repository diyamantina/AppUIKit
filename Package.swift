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
    targets: [
        .target(name: "AppUIKit"),
        .testTarget(name: "AppUIKitTests", dependencies: ["AppUIKit"]),
    ]
)
