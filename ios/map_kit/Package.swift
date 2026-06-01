// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "map_kit",
    platforms: [
        .iOS("13.0") // Update this to match the minimum iOS version in your podspec
    ],
    products: [
        .library(name: "map_kit", targets: ["map_kit"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "map_kit",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy") // Explicitly include the privacy manifest
            ]
        )
    ]
)