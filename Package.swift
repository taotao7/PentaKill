// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PentaKill",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PentaKill", targets: ["PentaKill"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "PentaKill",
            dependencies: [],
            path: ".",
            sources: [
                "PortManagerApp.swift",
                "ContentView.swift",
                "Models/PortInfo.swift",
                "Models/ProcessInfo.swift",
                "Views/ProcessGroupView.swift",
                "Services/PortScanner.swift",
                "Services/ProcessManager.swift"
            ]
        ),
        .testTarget(
            name: "PentaKillTests",
            dependencies: ["PentaKill"],
            path: "Tests"
        )
    ]
)