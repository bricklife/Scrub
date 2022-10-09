// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScratchWebKit",
    defaultLocalization: "en",
    platforms: [
        .iOS("14.5")
    ],
    products: [
        .library(
            name: "ScratchWebKit",
            targets: ["ScratchWebKit"]
        ),
    ],
    dependencies: [
        .package(path: "../ScratchLink")
    ],
    targets: [
        .target(
            name: "ScratchWebKit",
            dependencies: ["ScratchLink"],
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
