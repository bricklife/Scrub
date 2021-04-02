// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScratchWebKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ScratchWebKit",
            targets: ["ScratchWebKit"]
        ),
        .library(
            name: "DummyModules",
            targets: ["PerfectHTTP", "PerfectWebSockets"]
        ),
    ],
    targets: [
        .target(
            name: "ScratchWebKit",
            dependencies: ["PerfectHTTP", "PerfectWebSockets"],
            exclude: [
                "scratch-link/Assets",
                "scratch-link/Certificates",
                "scratch-link/Documentation",
                "scratch-link/Windows",
                "scratch-link/LICENSE",
                "scratch-link/playground.html",
                "scratch-link/README.md",
                "scratch-link/TRADEMARK",
                "scratch-link/macOS/Packaging",
                "scratch-link/macOS/Makefile",
                "scratch-link/macOS/Package.resolved",
                "scratch-link/macOS/Package.swift",
                "scratch-link/macOS/Sources/scratch-link/main.swift",
                "scratch-link/macOS/Sources/scratch-link/BTSession.swift",
                "scratch-link/macOS/Sources/scratch-link/BundleInfo.swift",
                "scratch-link/macOS/Sources/scratch-link/SessionManager.swift",
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .target(name: "PerfectHTTP"),
        .target(name: "PerfectWebSockets"),
    ]
)
