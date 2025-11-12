// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftAsyncTest",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "SwiftAsyncTest",
            targets: ["SwiftAsyncTest"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftAsyncTest"
        ),
        .testTarget(
            name: "SwiftAsyncTestTests",
            dependencies: ["SwiftAsyncTest"]
        ),
    ]
)
