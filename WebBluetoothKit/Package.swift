// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "WebBluetoothKit",
    defaultLocalization: "en",
    platforms: [
        .iOS("14.5"),
        .macOS("12.0")
    ],
    products: [
        .library(
            name: "WebBluetoothKit",
            targets: ["WebBluetoothKit"]
        ),
        .library(
            name: "WebBluetoothCore",
            targets: ["WebBluetoothCore"]
        ),
    ],
    targets: [
        .target(
            name: "WebBluetoothCore",
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "WebBluetoothKit",
            dependencies: ["WebBluetoothCore"],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "WebBluetoothKitTests",
            dependencies: ["WebBluetoothCore"]
        ),
    ]
)
