// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SugarRecord",
    platforms: [
        .iOS(.v15),
        .tvOS(.v13),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "SugarRecord",
            targets: ["SugarRecord"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SugarRecord",
            dependencies: [],
            path: "SugarRecord"
        ),
        .testTarget(
            name: "SugarRecordTests",
            dependencies: ["SugarRecord"]
        )
    ]
)
