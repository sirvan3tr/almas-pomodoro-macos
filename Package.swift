// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AlmasPomodoro",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "almas-pomodoro", targets: ["AlmasPomodoro"])
    ],
    targets: [
        .executableTarget(
            name: "AlmasPomodoro",
            path: "Sources/AlmasPomodoro"
        ),
        .testTarget(
            name: "AlmasPomodoroTests",
            dependencies: ["AlmasPomodoro"],
            path: "Tests/AlmasPomodoroTests"
        )
    ]
)
