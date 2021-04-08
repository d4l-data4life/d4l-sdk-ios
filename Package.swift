// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Data4LifeSDK",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "Data4LifeSDK",
            targets: ["Data4LifeSDKFrameworks"]),
        .library(
            name: "Data4LifeCrypto",
            targets: ["Data4LifeCrypto"]),
    ],
    dependencies: [
        .package(name: "Data4LifeSDKUtils",
                 url: "git@github.com:d4l-data4life/d4l-utils-ios.git",
                 .upToNextMinor(from: "0.4.0")),
        .package(name: "Data4LifeFHIR",
                 url: "git@github.com:d4l-data4life/d4l-fhir-ios.git",
                 .upToNextMinor(from: "0.19.0")),
        .package(url: "https://github.com/Alamofire/Alamofire.git",
                 .upToNextMinor(from: "5.4.1")),
        .package(url: "https://github.com/freshOS/Then",
                 .upToNextMinor(from: "5.1.4")),
        .package(url: "https://github.com/AppAuth/AppAuth-iOS.git",
                 .upToNextMinor(from: "1.4.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .binaryTarget(
            name: "Data4LifeSDK",
            url: "https://github.com/d4l-data4life/d4l-sdk-ios/releases/download/1.13.0/Data4LifeSDK-xcframework-1.13.0.zip",
            checksum: "287e39f125dd9559c55721e1ea6fb354a1a6f18808cf7ff929d9f1289bdc401c"
        ),
        .binaryTarget(
            name: "Data4LifeCrypto",
            url: "https://github.com/d4l-data4life/d4l-fhir-ios/releases/download/1.13.0/Data4LifeCrypto-xcframework-1.5.0.zip",
            checksum: "e650e60d9e1c2c929c31b363caf23f4e01526ec38173e36409b7adff5711caa3"
        ),
        .target(name: "Data4LifeSDKFrameworks",
                dependencies: [
                    .product(name: "Data4LifeSDK",
                             package: "Data4LifeSDK",
                             condition: .when(platforms: [.iOS])),
                    .product(name: "Data4LifeCrypto",
                             package: "Data4LifeCrypto",
                             condition: .when(platforms: [.iOS])),
                    .target(name: "Data4LifeSDK")
                ],
                path: "SDKSPMFrameworks"),
        .testTarget(name: "Data4LifeSDKTests",
                    dependencies: ["Data4LifeSDKFrameworks"],
                    path: "SDK/Tests",
                    exclude: ["Info.plist"],
                    resources: [.process("Resources")])
    ]
)
