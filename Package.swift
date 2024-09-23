// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "swift-trading-view",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_13),
        .watchOS(.v4),
        .tvOS(.v12),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "SwiftTradingView",
            targets: ["SwiftTradingView"]
        ),
        .library(
            name: "SwiftTA",
            targets: ["SwiftTA"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftTradingView",
            dependencies: [
                "SwiftTA"
            ],
            path: "Sources/SwiftTradingView"
        ),
        .target(
            name: "SwiftTA",
            dependencies: [
                "TALibFramework"
            ],
            path: "Sources/SwiftTA"
        ),
        .binaryTarget(
            name: "TALibFramework",
            path: "Sources/TALib/TALib.xcframework"
        ),
    ]
)
