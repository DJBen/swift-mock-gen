// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ExampleIntegration",
    products: [
        .library(
            name: "ExampleIntegration",
            targets: ["ExampleIntegration"]),
    ],
    targets: [
        .target(
            name: "ExampleIntegration"),
        .testTarget(
            name: "ExampleIntegrationTests",
            dependencies: ["ExampleIntegration"]),
    ]
)
