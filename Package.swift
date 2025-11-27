// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SugarRecord",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SugarRecord", targets: ["SugarRecord"])
    ],
    targets: [
        .target(
            name: "SugarRecord"
        ),
        .testTarget(
            name: "SugarRecordTests",
            dependencies: ["SugarRecord"]
        )
    ]
)
