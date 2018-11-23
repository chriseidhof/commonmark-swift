// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "CommonMark",
    products: [
        .library(name: "CommonMark", targets: ["CommonMark"])
    ],
    dependencies: [
        .package(url: "https://github.com/objcio/Ccmark.git", .branch("master"))
    ],
    targets: [
        .target(name: "CommonMark")
    ]
)
