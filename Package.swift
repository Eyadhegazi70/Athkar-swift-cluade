// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AthkarApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AthkarApp",
            targets: ["AthkarApp"]
        ),
    ],
    targets: [
        .target(
            name: "AthkarApp",
            path: "Sources",
            resources: [
                .copy("../Web")
            ]
        )
    ]
)
