// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "midori",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "./FluidAudio-Local")
    ],
    targets: []
)
