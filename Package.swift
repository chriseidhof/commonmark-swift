// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "CommonMark",
    products: [
        .library(name: "CommonMark", targets: ["CommonMark"]),
        .library(name: "Ccmark", targets: ["Ccmark"]),

    ],
    dependencies: [],
    targets: [
        .target(name: "CommonMark", dependencies: ["Ccmark"]),
        .systemLibrary(
          name: "Ccmark",
          pkgConfig: "libcmark",
          providers: [
            .brew(["commonmark"])
          ]),
        .testTarget(name: "CommonMarkTests", dependencies: ["CommonMark"]),
    ]
)
