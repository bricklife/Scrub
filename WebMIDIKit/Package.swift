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
            targets: ["WebMIDIKit"]),
    ],
    targets: [
        .target(
            name: "WebMIDIKit",
            exclude: [
                "WebMIDIAPIShimForiOS/WebMIDIAPIPolyfill/Base.lproj",
                "WebMIDIAPIShimForiOS/WebMIDIAPIPolyfill/en.lproj",
                "WebMIDIAPIShimForiOS/WebMIDIAPIPolyfill/AppDelegate.m",
                "WebMIDIAPIShimForiOS/WebMIDIAPIPolyfill/main.m",
                "WebMIDIAPIShimForiOS/WebMIDIAPIPolyfill/MIDIWebView.m",
                "WebMIDIAPIShimForiOS/WebMIDIAPIPolyfill/ViewController.m",
                "WebMIDIAPIShimForiOS/WebMIDIAPIPolyfillTests",
            ],
            resources: [
                .process("WebMIDIAPIShimForiOS/WebMIDIAPIPolyfill/WebMIDIAPIPolyfill.js"),
            ])
    ]
)
