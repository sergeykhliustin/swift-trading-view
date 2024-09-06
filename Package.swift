// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SwiftTradingView",
    platforms: [
        .iOS(.v15)
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
