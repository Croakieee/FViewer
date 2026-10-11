// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "VfxRuntime",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "VfxCore", targets: ["VfxCore"]),
        .library(name: "VfxMetal", targets: ["VfxMetal"]),
    ],
    targets: [
        .target(name: "VfxCore"),
        .target(name: "VfxMetal", dependencies: ["VfxCore"]),
    ]
)
