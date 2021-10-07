// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "AffirmSDK",
    platforms: [
        .iOS(.v9), .macOS(.v10_15)
    ],
    products: [
        .library(name: "AffirmSDK", targets: ["AffirmSDK"]),
    ],
    targets: [
        .target(name: "AffirmSDK",
                path: "SPM",
                resources: [
                    .process("AffirmCardInfoViewController.xib"),
                    .process("AffirmEligibilityViewController.xib"),
                    .process("AffirmHowToViewController.xib"),
                    .process("AffirmSDK.bundle")
                ])
    ]
)
