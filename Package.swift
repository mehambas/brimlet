// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Brimlet",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Brimlet", targets: ["Brimlet"]), .library(name: "BrimletIPC", targets: ["BrimletIPC"])],
    targets: [
        .target(name: "BrimletCore"),
        .target(name: "BrimletIPC", dependencies: ["BrimletCore"]),
        .executableTarget(name: "BrimletIPCProbe", dependencies: ["BrimletIPC"], path: "Tests/IPCProbe", exclude: ["Sandbox.entitlements", "Info.plist"]),
        .executableTarget(name: "Brimlet", dependencies: ["BrimletCore", "BrimletIPC"]),
        .testTarget(name: "BrimletCoreTests", dependencies: ["BrimletCore", "BrimletIPC"]),
        .testTarget(name: "BrimletTests", dependencies: ["Brimlet"])
    ]
)
