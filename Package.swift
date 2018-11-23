import PackageDescription

let package = Package(
    name: "CommonMark",
    dependencies: [
        .Package(url: "https://github.com/chriseidhof/Ccmark.git", Version(0,28,2))
    ]
)
