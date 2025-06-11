// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EvaluateFile",
    platforms: [
        .macOS(.v13), .iOS(.v16)
    ],
    products: [
        .library(
            name: "Evaluate",
            targets: ["Evaluate"]
        ),
    ],
    targets: [
        .target(
            name: "Evaluate",
            dependencies: []
        )
    ]
)
