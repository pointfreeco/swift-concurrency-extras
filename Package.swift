// swift-tools-version: 5.6

import PackageDescription

let package = Package(
  name: "swift-concurrency-extras",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "ConcurrencyExtras",
      targets: ["ConcurrencyExtras"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "ConcurrencyExtras"
    ),
    .testTarget(
      name: "ConcurrencyExtrasTests",
      dependencies: [
        "ConcurrencyExtras"
      ]
    ),
  ]
)

//for target in package.targets {
//  target.swiftSettings = target.swiftSettings ?? []
//  target.swiftSettings?.append(
//    .unsafeFlags([
//      "-c", "release",
//      "-emit-module-interface", "-enable-library-evolution",
//      "-Xfrontend", "-warn-concurrency",
//      "-Xfrontend", "-enable-actor-data-race-checks",
//    ])
//  )
//}
