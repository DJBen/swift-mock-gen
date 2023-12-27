// swift-tools-version:5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "SwiftMockGen",
  platforms: [
    .macOS(.v13),
    .iOS(.v13),
  ],
  products: [
    .executable(name: "swift-mock-gen", targets: ["swift-mock-gen"]),
    .library(name: "SwiftMockGen", targets: ["SwiftMockGen"]),
    .library(name: "MockSupport", targets: ["MockSupport"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
    .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.2")
  ],
  targets: [
    .macro(
        name: "SwiftMockGenMacro",
        dependencies: [
            "CodeGenerationFactories",
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
        ]
    ),

    .target(
      name: "SwiftMockGen",
      dependencies: [
        "SwiftMockGenMacro"
      ]
    ),

    .target(
      name: "MockSupport"
    ),

    .target(
        name: "CLIUtils",
        dependencies: [
            .product(name: "SwiftParser", package: "swift-syntax"),
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        ]
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

    .testTarget(
        name: "SwiftMockGenMacroTests",
        dependencies: [
            "SwiftMockGenMacro",
            "CodeGenerationFactories",
            .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
        ]
    ),

    .testTarget(
        name: "CLIUtilsTests",
        dependencies: [
            "CLIUtils",
            .product(name: "SwiftParser", package: "swift-syntax"),
            .product(name: "SwiftSyntax", package: "swift-syntax"),
        ]
    ),

    .executableTarget(
      name: "swift-mock-gen",
      dependencies: [
        "CLIUtils",
        "CodeGenerationFactories",
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
