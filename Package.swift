// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PaperWM",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "deskpadctl",
            targets: ["deskpadctl"]
        ),
        .library(
            name: "PaperWM",
            targets: ["PaperWM"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "PaperWM",
            dependencies: [],
            exclude: [
                "DeskPadAppExample.swift",
                "INTEGRATION.md"
            ]
        ),
        .executableTarget(
            name: "deskpadctl",
            dependencies: [],
            path: "Sources/deskpadctl"
        ),
        .testTarget(
            name: "PaperWMTests",
            dependencies: ["PaperWM"]
        )
    ]
)
