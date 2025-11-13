// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-async-testing",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "AsyncTesting",
            targets: ["AsyncTesting"]
        ),
    ],
    targets: [
        .target(
            name: "AsyncTesting"
        ),
        .testTarget(
            name: "AsyncTestingTests",
            dependencies: ["AsyncTesting"]
        ),
    ]
)
