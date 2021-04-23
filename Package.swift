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
            targets: ["Data4LifeSDK", "Data4LifeCrypto", "Data4LifeSDKUtilsDependency", "OtherDependencies"]),
        .library(
            name: "Data4LifeCrypto",
            targets: ["Data4LifeCrypto"]),
    ],
    dependencies: [
        .package(name: "Data4LifeSDKUtils",
                 url: "git@github.com:d4l-data4life/d4l-utils-ios.git",
                 .branch("remove-symbols")),
        .package(name: "Data4LifeFHIR",
                 url: "git@github.com:d4l-data4life/d4l-fhir-ios.git",
                 .branch("bugfix/fix-nested-framework")),
        .package(url: "https://github.com/Alamofire/Alamofire.git",
                 .upToNextMinor(from: "5.4.1")),
        .package(url: "https://github.com/freshOS/Then",
                 .upToNextMinor(from: "5.1.2")),
        .package(name: "AppAuth",
                 url: "git@github.com:d4l-data4life/AppAuth-iOS.git",
                 .branch("master"))
    ],
    targets: [
        .binaryTarget(
            name: "Data4LifeSDK",
            url: "https://github.com/d4l-data4life/d4l-sdk-ios/releases/download/1.13.0/Data4LifeSDK-xcframework-1.13.0.zip",
            checksum: "47cbabde2b571adf4a3ff937a4add2e4f0c1c1e1cf2ea4cab88b891635847f6e"
        ),
        .binaryTarget(
            name: "Data4LifeCrypto",
            url: "https://github.com/d4l-data4life/d4l-sdk-ios/releases/download/1.13.0/Data4LifeCrypto-xcframework-1.5.0.zip",
            checksum: "a98aef1a5f3138f520ffc693052d8cc64a3a02aae1d20707d5b617ef254a59d0"
        ),
        .target(name: "Data4LifeSDKUtilsDependency",
                dependencies: [
                    .product(name: "Data4LifeSDKUtils",
                             package: "Data4LifeSDKUtils",
                             condition: .when(platforms: [.iOS]))
                ],
                path: "SwiftPMDummyTargets/SDKUtilsDependency"),
        .target(name: "OtherDependencies",
                dependencies: [
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
                path: "SwiftPMDummyTargets/OtherDependencies"),
    ]
)
