// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "feather-mail",
    platforms: [
       .macOS(.v12),
    ],
    products: [
        .library(name: "FeatherMail", targets: ["FeatherMail"]),
        .library(name: "FeatherSESMail", targets: ["FeatherSESMail"]),
        .library(name: "FeatherSMTPMail", targets: ["FeatherSMTPMail"]),
        .library(name: "NIOSMTP", targets: ["NIOSMTP"]),
        .library(name: "SotoSESv2", targets: ["SotoSESv2"]),
        
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.51.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl", from: "2.24.0"),
        .package(url: "https://github.com/soto-project/soto-core", from: "6.5.0"),
        .package(url: "https://github.com/soto-project/soto-codegenerator", from: "0.8.0"),
    ],
    targets: [
        .target(name: "FeatherMail", dependencies: [
        ]),
        .target(name: "FeatherSESMail", dependencies: [
            .target(name: "FeatherMail"),
            .target(name: "SotoSESv2")
        ]),
        .target(name: "FeatherSMTPMail", dependencies: [
            .target(name: "NIOSMTP"),
            .target(name: "FeatherMail"),
        ]),
        .target(
            name: "SotoSESv2",
            dependencies: [
                .product(name: "SotoCore", package: "soto-core"),
            ],
            plugins: [
                .plugin(
                    name: "SotoCodeGeneratorPlugin",
                    package: "soto-codegenerator"
                ),
            ]
        ),
        .target(name: "NIOSMTP", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOSSL", package: "swift-nio-ssl"),
            .product(name: "Logging", package: "swift-log"),
        ]),
        
        .testTarget(name: "FeatherSMTPMailTests", dependencies: [
            .target(name: "FeatherSMTPMail"),
        ]),
        .testTarget(name: "FeatherSESMailTests", dependencies: [
            .target(name: "FeatherSESMail"),
        ]),
        
        // MARK: - feather tests
        
        .testTarget(name: "NIOSMTPTests", dependencies: [
            .target(name: "NIOSMTP"),
        ]),
    ]
)
