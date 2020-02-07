// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "poloniex-portfolio",
    platforms: [
        .macOS(.v10_15),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "1.0.0")
    ],
    targets: [
              .target(name: "poloniex", dependencies:["Crypto"]),
              .target(name: "poloniex-portfolio", dependencies:["poloniex"])]
)
