// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "CommonMark",
    products: [
        .library(name: "CommonMark", targets: ["CommonMark"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-cmark.git", .branch("master")),
    ],
    targets: [
        .target(name: "CommonMark", dependencies: ["cmark"]),
        .testTarget(name: "CommonMarkTests", dependencies: ["CommonMark"]),
    ]
)
