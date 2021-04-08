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
        .package(name: "AppAuth",
                 url: "https://github.com/openid/AppAuth-iOS.git",
                 .upToNextMinor(from: "1.4.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .binaryTarget(
            name: "Data4LifeSDK",
            url: "https://github.com/d4l-data4life/d4l-sdk-ios/releases/download/1.13.0/Data4LifeSDK-xcframework-1.13.0.zip",
            checksum: "498c58323b8d752eac3b7184a0327fe8e7bdc5587bf3bc15de241500b599d991"
        ),
        .binaryTarget(
            name: "Data4LifeCrypto",
            url: "https://github.com/d4l-data4life/d4l-fhir-ios/releases/download/1.13.0/Data4LifeCrypto-xcframework-1.5.0.zip",
            checksum: "e97a5548952d616bbe8cf609ff767da108a2021586c7c05807d7886e770989a7"
        ),
        .target(name: "Data4LifeSDKFrameworks",
                dependencies: [
                    .product(name: "CryptoSwift",
                             package: "Data4LifeSDKUtils",
                             condition: .when(platforms: [.iOS])),
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
                    .byName(name: "AppAuth"),
                    .target(name: "Data4LifeSDK"),
                    .target(name: "Data4LifeCrypto")
                ],
                path: "SDKSPMFrameworks"),
        .testTarget(name: "Data4LifeSDKTests",
                    dependencies: ["Data4LifeSDKFrameworks"],
                    path: "SDK/Tests",
                    exclude: ["Info.plist","Data4LifeSDK-Version.plist"],
                    resources: [.process("Resources"),.process("BenchmarkClient/SubbedResponses")])
    ]
)
