// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "SugarRecord",
  platforms: [
    .iOS(.v14), .macOS(.v12), .watchOS(.v8), .tvOS(.v15)
  ],
  products: [
    .library(name: "SugarRecord", targets: ["SugarRecord"])
  ],
  targets: [
    .target(
      name: "SugarRecord",
      swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
    ),
    .testTarget(
      name: "SugarRecordTests",
      dependencies: ["SugarRecord"]
    )
  ]
)
