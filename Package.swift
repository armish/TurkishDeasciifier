// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TurkishDeasciifier",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "TurkishDeasciifier",
            targets: ["TurkishDeasciifier"]
        )
    ],
    targets: [
        .executableTarget(
            name: "TurkishDeasciifier",
            dependencies: [],
            resources: [
                .copy("turkish_patterns.json")
            ]
        )
    ]
)