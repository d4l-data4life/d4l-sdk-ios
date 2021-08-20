// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let coreVersion = "1.15.0"
let cryptoVersion = "1.5.1"

let package = Package(
    name: "Data4LifeSDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_12)
    ],
    products: [
        .library(
            name: "Data4LifeSDK",
            targets: ["Data4LifeSDK", "Data4LifeDependencies"]),
        .library(
            name: "Data4LifeCrypto",
            targets: ["Data4LifeCrypto"]),
    ],
    dependencies: [
        .package(name: "Data4LifeSDKUtils",
                 url: "https://github.com/d4l-data4life/d4l-utils-ios.git",
                 .upToNextMinor(from: "0.6.0")),
        .package(name: "Data4LifeFHIR",
                 url: "https://github.com/d4l-data4life/d4l-fhir-ios.git",
                 .upToNextMinor(from: "0.22.0")),
        .package(url: "https://github.com/Alamofire/Alamofire.git",
                 .upToNextMinor(from: "5.4.1")),
        .package(name: "AppAuth",
                 url: "https://github.com/openid/AppAuth-iOS.git",
                 .upToNextMinor(from: "1.4.0")),
    ],
    targets: [
        .binaryTarget(
            name: "Data4LifeSDK",
            url: "https://github.com/d4l-data4life/d4l-sdk-ios/releases/download/\(coreVersion)/Data4LifeSDK-xcframework-\(coreVersion).zip",
            checksum: "0c4586049f319d10c93e07b6239876cab00a7b89700b1a54001841234811859e"
        ),
        .binaryTarget(
            name: "Data4LifeCrypto",
            url: "https://github.com/d4l-data4life/d4l-sdk-ios/releases/download/\(coreVersion)/Data4LifeCrypto-xcframework-\(cryptoVersion).zip",
            checksum: "c4724e0af0c0dda1c4b4902f541163d1e8ee1540e106a2a6d95ee4bb4463198d"
        ),
        .target(name: "Data4LifeDependencies",
                dependencies: [
                    .product(name: "Data4LifeFHIR",
                             package: "Data4LifeFHIR",
                             condition: .when(platforms: [.iOS])),
                    .product(name: "ModelsR4",
                             package: "Data4LifeFHIR",
                             condition: .when(platforms: [.iOS])),
                    .product(name: "Data4LifeFHIRCore",
                             package: "Data4LifeFHIR",
                             condition: .when(platforms: [.iOS])),
                    .product(name: "Data4LifeSDKUtils",
                             package: "Data4LifeSDKUtils",
                             condition: .when(platforms: [.iOS]))
                ],
                path: "Dummies/Data4LifeDependencies"),
        .target(name: "OtherDependencies",
                dependencies: [
                    .product(name: "Alamofire",
                             package: "Alamofire",
                             condition: .when(platforms: [.iOS])),
                    .product(name: "AppAuth",
                             package: "AppAuth",
                             condition: .when(platforms: [.iOS])),
                ],
                path: "Dummies/OtherDependencies"),
        .testTarget(name: "Data4LifeCryptoTests",
                    dependencies: ["Data4LifeCrypto"],
                    path: "Crypto/Tests",
                    exclude: ["Info.plist"],
                    resources: [.process("JSON Payloads")]),
    ]
)
