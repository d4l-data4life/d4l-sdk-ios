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
                 .upToNextMinor(from: "0.20.0")),
        .package(url: "https://github.com/Alamofire/Alamofire.git",
                 .upToNextMinor(from: "5.4.1")),
        .package(url: "https://github.com/freshOS/Then",
                 .upToNextMinor(from: "5.1.4")),
        .package(name: "AppAuth",
                 url: "https://github.com/openid/AppAuth-iOS.git",
                 .branch("master"))
    ],
    targets: [
        .binaryTarget(
            name: "Data4LifeSDK",
            url: "https://github.com/d4l-data4life/d4l-sdk-ios/releases/download/1.13.0/Data4LifeSDK-xcframework-1.13.0.zip",
            checksum: "54b1a117402e4844eabdd8a9db7fb3afd4fd32b5d83fedcdf640c8fbcb352aa5"
        ),
        .binaryTarget(
            name: "Data4LifeCrypto",
            url: "https://github.com/d4l-data4life/d4l-sdk-ios/releases/download/1.13.0/Data4LifeCrypto-xcframework-1.5.0.zip",
            checksum: "6b8d1d67ddada9ef8f5e1407522ef9edb40dbd05ff25b272e3c89af05d9a9cbc"
        ),
        .target(name: "Data4LifeSDKFrameworks",
                dependencies: [
                    .product(name: "Data4LifeSDKUtils",
                             package: "Data4LifeSDKUtils",
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
