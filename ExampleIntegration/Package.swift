// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ExampleIntegration",
    products: [
        .library(
            name: "Example",
            targets: ["Example"]),
        .library(
            name: "ExampleImpl",
            targets: ["ExampleImpl"]),
    ],
    targets: [
        .target(
            name: "Example"
        ),
        .target(
            name: "ExampleImpl"
        ),
        .testTarget(
            name: "ExampleImplTests",
            dependencies: ["Example", "ExampleImpl"]
        ),
    ]
)
