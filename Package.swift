// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UniversalSFSymbolsPicker",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "UniversalSFSymbolsPicker",
            targets: ["UniversalSFSymbolsPicker"]
        ),
    ],
    targets: [
        .target(
            name: "UniversalSFSymbolsPicker",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "UniversalSFSymbolsPickerTests",
            dependencies: ["UniversalSFSymbolsPicker"]
        ),
    ]
)
