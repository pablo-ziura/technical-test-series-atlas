// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SeriesAtlasNetwork",
    platforms: [
        .iOS("18.6"),
        .macOS(.v15)
    ],
    products: [
        .library(name: "SeriesAtlasNetwork", targets: ["SeriesAtlasNetwork"])
    ],
    targets: [
        .target(
            name: "SeriesAtlasNetwork",
            swiftSettings: [.defaultIsolation(nil)]
        ),
        .testTarget(
            name: "SeriesAtlasNetworkTests",
            dependencies: ["SeriesAtlasNetwork"],
            swiftSettings: [.defaultIsolation(nil)]
        )
    ],
    swiftLanguageModes: [.v6]
)
