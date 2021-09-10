// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let coreVersion = "1.15.0"

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
    ],
    dependencies: [
        .package(name: "Data4LifeSDKUtils",
                 url: "https://github.com/d4l-data4life/d4l-utils-ios.git",
                 .upToNextMinor(from: "0.6.0")),
        .package(name: "Data4LifeFHIR",
                 url: "https://github.com/d4l-data4life/d4l-fhir-ios.git",
                 .upToNextMinor(from: "0.22.0")),
        .package(name: "Data4LifeCrypto",
                 url: "https://github.com/d4l-data4life/d4l-crypto-ios.git",
                 .upToNextMinor(from: "1.7.0")),
        .package(url: "https://github.com/Alamofire/Alamofire.git",
                 .upToNextMinor(from: "5.4.1")),
        .package(name: "AppAuth",
                 url: "https://github.com/openid/AppAuth-iOS.git",
                 .upToNextMinor(from: "1.4.0")),
    ],
    targets: [
        .binaryTarget(
            name: "Data4LifeSDK",
            url: "https://d4l-ios-artifact-repository.s3.eu-central-1.amazonaws.com/d4l-data4life/d4l-sdk-ios/Data4LifeSDK-xcframework-v1.16.0.zip",
            checksum: "988ea5a1402197e2243d28ce4ee881ca38034d97483ea57601be47f2edd1e18e"
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
                             condition: .when(platforms: [.iOS])),
                    .product(name: "Data4LifeCrypto",
                             package: "Data4LifeCrypto",
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
                path: "Dummies/OtherDependencies")
    ]
)
