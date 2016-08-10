import PackageDescription

let package = Package(
    name: "CommonMark",
    dependencies: [
        .Package(url: "../Ccmark", Version(0,24,1))
    ]
)
