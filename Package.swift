// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "WorldClock",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "WorldClock",
            path: "Sources/WorldClock"
        )
    ]
)
