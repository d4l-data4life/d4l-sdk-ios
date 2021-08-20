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
            checksum: "8a860d0a6fc5dea65eb6d1b8e4989d0696753b7b5efb68b680ac0f8f4e455118"
        ),
        .binaryTarget(
            name: "Data4LifeCrypto",
            url: "https://github.com/d4l-data4life/d4l-sdk-ios/releases/download/\(coreVersion)/Data4LifeCrypto-xcframework-\(cryptoVersion).zip",
            checksum: "e80d530bd7ac65483a87dd6bc13cccfdc800e08c868b0822b0f0cb5e4bed69ce"
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
