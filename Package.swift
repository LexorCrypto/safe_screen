// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SafeScreen",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SafeScreenCore",
            targets: ["SafeScreenCore"]
        ),
        .executable(
            name: "SafeScreenApp",
            targets: ["SafeScreenApp"]
        )
    ],
    targets: [
        .target(
            name: "SafeScreenCore"
        ),
        .executableTarget(
            name: "SafeScreenApp",
            dependencies: ["SafeScreenCore"]
        ),
        .testTarget(
            name: "SafeScreenCoreTests",
            dependencies: ["SafeScreenCore"]
        )
    ]
)
