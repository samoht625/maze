// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MazeCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MazeCore", targets: ["MazeCore"])
    ],
    targets: [
        .target(
            name: "MazeCore",
            path: "MazeScreensaver",
            exclude: [
                "MazeScreensaverView.swift", "MazeRenderer.swift", "MazeSettings.swift",
                "Info.plist", "install.sh"
            ],
            sources: ["MazeModel.swift", "MazePlayback.swift"]
        ),
        .testTarget(name: "MazeCoreTests", dependencies: ["MazeCore"])
    ],
    swiftLanguageVersions: [.v5]
)
