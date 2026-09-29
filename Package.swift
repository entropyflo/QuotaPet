// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QuotaPet",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "QuotaPet", targets: ["QuotaPet"]),
        .executable(name: "QuotaProbe", targets: ["QuotaProbe"])
    ],
    targets: [
        .executableTarget(
            name: "QuotaPet",
            dependencies: ["QuotaPetCore"],
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "QuotaProbe",
            dependencies: ["QuotaPetCore"]
        ),
        .target(name: "QuotaPetCore"),
        .testTarget(
            name: "QuotaPetCoreTests",
            dependencies: ["QuotaPetCore"]
        )
    ]
)
