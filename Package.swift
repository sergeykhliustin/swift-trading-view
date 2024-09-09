// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "swift-trading-view",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_13),
        .watchOS(.v4),
        .tvOS(.v12),
        .visionOS(.v1),
        .macCatalyst(.v13)
    ],
    products: [
        .library(
            name: "TradingView",
            targets: ["TradingView"]
        ),
        .library(
            name: "SwiftTA",
            targets: ["SwiftTA"]
        ),
    ],
    targets: [
        .target(
            name: "TradingView",
            dependencies: [
                "SwiftTA"
            ]
        ),
        .target(
            name: "SwiftTA",
            dependencies: [
                "TALibFramework"
            ],
            path: "Sources/TALib",
            sources: ["TALib.swift"]
        ),
        .binaryTarget(
            name: "TALibFramework",
            path: "Sources/TALib/TALib.xcframework"
        ),
    ]
)
