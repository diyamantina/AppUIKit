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
        // What a UI test of an app built on AppUIKit waits with. It links XCTest, so only test targets depend on it.
        .library(name: "AppUITesting", targets: ["AppUITesting"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
        // The newer Apple UI APIs with a fallback below the OS that has them (reserved regions, the hinge): the cross-framework layer delegates to it.
        .package(url: "https://codeberg.org/Mihaela/Forwards.git", from: "0.1.0"),
        // The display layers of the canvas (one quiet host layer per object, keyed by id): AppUICanvas wraps them to take input. The branch is
        // tracked and nothing is pinned, so a change of the display lands here as it is pushed.
        .package(url: "git@git.aleahim.com:SlayerMotionHQ/CAControls.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "AppUIKit",
            dependencies: [
                .product(name: "ForwardsCore", package: "Forwards"),
                .product(name: "CACanvas", package: "CAControls"),
                .product(name: "ForwardsUIKit", package: "Forwards", condition: .when(platforms: [.iOS])),
            ]
        ),
        .target(name: "AppUITesting"),
        .testTarget(
            name: "AppUIKitTests",
            dependencies: [
                "AppUIKit",
                "AppUITesting",
                .product(name: "CAWitness", package: "CAControls"),
            ]
        ),
        .testTarget(name: "AppUITestingTests", dependencies: ["AppUITesting"]),
    ]
)
