// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UniversalSFSymbolsPicker",
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
            name: "UniversalSFSymbolsPicker"
        ),
        .testTarget(
            name: "UniversalSFSymbolsPickerTests",
            dependencies: ["UniversalSFSymbolsPicker"]
        ),
    ]
)
