// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "map_kit",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "map-kit", targets: ["map_kit"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        // Official Neshan build: includes MLNApiKey authentication. Do not replace
        // it with the upstream MapLibre binary, which lacks Neshan's key handling.
        .binaryTarget(
            name: "MapLibre",
            url: "https://static.neshan.org/sdk/maplibre/ios/MapLibre-6.28.0.zip",
            checksum: "d93047723546fa76a8936095dda76b5b405ae8262c8cb7eb4d7b339ca9617845"
        ),
        .target(
            name: "map_kit",
            dependencies: [
                "MapLibre",
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
