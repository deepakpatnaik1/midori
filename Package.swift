// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "midori",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.7.7")
    ],
    targets: []
)
