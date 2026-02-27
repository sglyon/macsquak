// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MacSquak",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MacSquak", targets: ["MacSquak"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.3.0")
    ],
    targets: [
        .executableTarget(
            name: "MacSquak",
            dependencies: ["KeyboardShortcuts"],
            path: "Sources"
        ),
        .testTarget(
            name: "MacSquakTests",
            dependencies: ["MacSquak"],
            path: "Tests"
        )
    ]
)
