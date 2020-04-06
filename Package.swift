// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "CommonMark",
    products: [
        .library(name: "CommonMark", targets: ["CommonMark"]),
    ],
    dependencies: [],
    targets: [
		.target( // copied this approach from https://github.com/iwasrobbed/Down/
           name: "libcmark",
           dependencies: [],
           publicHeadersPath: "./"
        ), 
        .target(name: "CommonMark", dependencies: ["libcmark"]),
        .testTarget(name: "CommonMarkTests", dependencies: ["CommonMark", "libcmark"]),
    ]
)
