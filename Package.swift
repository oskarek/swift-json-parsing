// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "swift-json-parsing",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "JSONParsing",
      targets: ["JSONParsing"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.13.0"),
    .package(url: "https://github.com/google/swift-benchmark", from: "0.1.2"),
  ],
  targets: [
    .target(
      name: "JSONParsing",
      dependencies: [
        .product(name: "Parsing", package: "swift-parsing"),
      ]
    ),
    .testTarget(
      name: "JSONParsingTests",
      dependencies: [
        "JSONParsing",
      ]
    ),
    .executableTarget(
      name: "swift-json-parsing-benchmark",
      dependencies: [
        "JSONParsing",
        .product(name: "Benchmark", package: "swift-benchmark"),
        .product(name: "Parsing", package: "swift-parsing"),
      ],
      resources: [.process("Samples")]
    ),
  ]
)
