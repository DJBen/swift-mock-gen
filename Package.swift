// swift-tools-version:5.7

import Foundation
import PackageDescription

let package = Package(
  name: "SwiftParserCLI",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .executable(name: "swift-parser-cli", targets: ["swift-parser-cli"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
    .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.2")
  ],
  targets: [
    .target(
      name: "InstructionCounter"
    ),

    .executableTarget(
      name: "swift-parser-cli",
      dependencies: [
        "InstructionCounter",
        .product(name: "SwiftBasicFormat", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
  ]
)
