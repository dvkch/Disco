// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Disco",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12)
    ],
    products: [
        .library(name: "Disco", targets: ["Disco"]),
    ],
    dependencies: [
        .package(url: "https://github.com/samiyr/SwiftyPing", "1.2.1"..<"2.0.0")
    ],
    targets: [
        .target(name: "Disco", dependencies: ["SwiftyPing"]),
        .testTarget(name: "DiscoTests", dependencies: ["Disco", "SwiftyPing"]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
