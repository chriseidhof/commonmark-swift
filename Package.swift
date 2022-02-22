// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "CommonMark",
    products: [
        .library(name: "CommonMark", targets: ["CommonMark"]),
        .library(name: "libcmark", targets: ["libcmark"]),
    ],
    dependencies: [],
    targets: [
		.target( // copied this approach from https://github.com/iwasrobbed/Down/
           name: "libcmark",
           dependencies: [],
           exclude: ["include"],
           publicHeadersPath: "./"
        ), 
        .target(name: "CommonMark", dependencies: ["libcmark"]),
        .testTarget(name: "CommonMarkTests", dependencies: ["CommonMark", "libcmark"]),
    ]
)
