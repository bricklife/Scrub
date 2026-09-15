// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "WebBluetoothKit",
    defaultLocalization: "en",
    platforms: [
        .iOS("14.5")
    ],
    products: [
        .library(
            name: "WebBluetoothKit",
            targets: ["WebBluetoothKit"]
        ),
    ],
    targets: [
        .target(
            name: "WebBluetoothKit",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
