// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "liquid_glass_ios_widgets",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "liquid-glass-ios-widgets", targets: ["liquid_glass_ios_widgets"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "liquid_glass_ios_widgets",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
