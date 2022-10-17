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
        .library(
            name: "MIDI",
            targets: ["MIDI"]
        ),
    ],
    targets: [
        .target(
            name: "WebMIDIKit",
            dependencies: ["MIDI"],
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "MIDI"
        ),
    ]
)
