// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Murmur",
    platforms: [.macOS("26.0")],
    targets: [
        .target(
            name: "MurmurCore",
            path: "Sources/MurmurCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "Murmur",
            dependencies: ["MurmurCore"],
            path: "Sources/Murmur",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "MurmurCoreTests",
            dependencies: ["MurmurCore"],
            path: "Tests/MurmurCoreTests"
        ),
    ]
)
