// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WebMIDIKit",
    platforms: [
        .iOS("14.5")
    ],
    products: [
        .library(
            name: "WebMIDIKit",
            targets: ["WebMIDIKit"]
        ),
    ],
    targets: [
        .target(
            name: "WebMIDIKit",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
