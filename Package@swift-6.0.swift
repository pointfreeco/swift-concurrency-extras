// swift-tools-version: 6.0

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
  ],
  swiftLanguageModes: [.v6]
)

#if !os(Windows)
  // Add the documentation compiler plugin if possible
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif
