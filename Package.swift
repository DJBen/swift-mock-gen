// swift-tools-version:5.7

import Foundation
import PackageDescription

let package = Package(
  name: "SwiftMockGen",
  platforms: [
    .macOS(.v12),
  ],
  products: [
    .executable(name: "swift-mock-gen", targets: ["swift-mock-gen"]),
    .library(name: "MockTestSupport", targets: ["MockTestSupport"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
    .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.2")
  ],
  targets: [
    .target(
      name: "InstructionCounter"
    ),

    .target(
      name: "MockTestSupport"
    ),

    .target(
      name: "CodeGenTesting",
      dependencies: [
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),

    .target(
        name: "CodeGenerationFactories",
        dependencies: [
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        ]
    ),

    .testTarget(
        name: "CodeGenerationFactoriesTests",
        dependencies: [
            "CodeGenerationFactories",
            "CodeGenTesting",
        ]
    ),

    .executableTarget(
      name: "swift-mock-gen",
      dependencies: [
        "InstructionCounter",
        "CodeGenerationFactories",
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
