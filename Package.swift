// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "unsplash-swift",
    platforms: [.iOS(.v12)], 
    products: [
        .library(name: "unsplash-swift", targets: ["unsplash-swift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jlainog/Codable-Utils.git", from: "0.0.2")
    ],
    targets: [
        .target(
            name: "unsplash-swift",
            dependencies: ["Codable-Utils"],
            path: "Source"
        ),
        .testTarget(
            name: "unsplash-swiftTests",
            dependencies: ["unsplash-swift"],
            path: "Tests"
        ),
    ]
//    swiftLanguageVersions: [.version("5.1")]
)
