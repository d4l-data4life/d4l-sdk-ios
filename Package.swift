// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Data4LifeSDK",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "Data4LifeSDK",
            targets: ["Data4LifeSDK","Data4LifeCrypto","Data4LifeSDKFrameworks"]),
        .library(
            name: "Data4LifeCrypto",
            targets: ["Data4LifeCrypto"]),
    ],
    dependencies: [
        .package(name: "Data4LifeSDKUtils",
                 url: "git@github.com:d4l-data4life/d4l-utils-ios.git",
                 .upToNextMinor(from: "0.5.0")),
        .package(name: "Data4LifeFHIR",
                 url: "git@github.com:d4l-data4life/d4l-fhir-ios.git",
                 .branch("feature/update-public-types")),
        .package(url: "https://github.com/Alamofire/Alamofire.git",
                 .upToNextMinor(from: "5.4.1")),
        .package(url: "https://github.com/freshOS/Then",
                 .upToNextMinor(from: "5.1.2")),
        .package(name: "AppAuth",
                 url: "https://github.com/openid/AppAuth-iOS.git",
                 .branch("master"))
    ],
    targets: [
        .binaryTarget(
            name: "Data4LifeSDK",
            url: "https://github.com/d4l-data4life/d4l-sdk-ios/releases/download/1.13.0/Data4LifeSDK-xcframework-1.13.0.zip",
            checksum: "5c9ebe9e69dc6ab280f1e6c6c150bb67dbbb0fe7ccbde2110c2549320d9fbb01"
        ),
        .binaryTarget(
            name: "Data4LifeCrypto",
            url: "https://github.com/d4l-data4life/d4l-sdk-ios/releases/download/1.13.0/Data4LifeCrypto-xcframework-1.5.0.zip",
            checksum: "a7097f3e78d632e1066b494b93fcac96a87d7f73827ea57b230f34c9aad6e7c9"
        ),
        .target(name: "Data4LifeSDKFrameworks",
                dependencies: [
                    .product(name: "Data4LifeSDKUtils",
                             package: "Data4LifeSDKUtils",
                             condition: .when(platforms: [.iOS])),
                             .product(name: "Data4LifeFHIRCore",
                                      package: "Data4LifeFHIR",
                                      condition: .when(platforms: [.iOS])),
                    .product(name: "Data4LifeFHIR",
                             package: "Data4LifeFHIR",
                             condition: .when(platforms: [.iOS])),
                    .product(name: "ModelsR4",
                             package: "Data4LifeFHIR",
                             condition: .when(platforms: [.iOS])),
                    .product(name: "Then",
                             package: "Then",
                             condition: .when(platforms: [.iOS])),
                    .product(name: "Alamofire",
                             package: "Alamofire",
                             condition: .when(platforms: [.iOS])),
                    .product(name: "AppAuth",
                             package: "AppAuth",
                             condition: .when(platforms: [.iOS])),
                ],
                path: "SDKSPMFrameworks"),
    ]
)
