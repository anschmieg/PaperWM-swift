// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SocketHelper",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "SocketHelper",
            targets: ["SocketHelper"]),
    ],
    targets: [
        .target(
            name: "SocketHelper",
            dependencies: []),
        .testTarget(
            name: "SocketHelperTests",
            dependencies: ["SocketHelper"]),
    ]
)
