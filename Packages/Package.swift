// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MathTypeset",
    products: [
        .library(
            name: "MathTypeset",
            targets: ["MathTypeset"],
        ),
    ],
    targets: [
        .target(
            name: "MathTypeset",
        ),
        .testTarget(
            name: "MathTypesetTests",
            dependencies: ["MathTypeset"],
        ),
    ],
)
