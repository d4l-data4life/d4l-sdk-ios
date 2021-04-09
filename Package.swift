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
            targets: ["Data4LifeCryptoFrameworks"]),
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
        .target(name: "Data4LifeCryptoFrameworks",
                dependencies: [
                    .target(name: "Data4LifeCrypto"),
                    .product(name: "CryptoSwift",
                             package: "Data4LifeSDKUtils",
                             condition: .when(platforms: [.iOS]))
                ],
                path: "CryptoSPMFrameworks"),
        .target(name: "Data4LifeSDKFrameworks",
                dependencies: [
                    .target(name: "Data4LifeSDK"),
                    .target(name: "Data4LifeCrypto"),
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
                    .byName(name: "AppAuth")
                ],
                path: "SDKSPMFrameworks"), 
        .binaryTarget(
            name: "Data4LifeSDK",
            url: "https://github.com/d4l-data4life/d4l-sdk-ios/releases/download/1.13.0/Data4LifeSDK-xcframework-1.13.0.zip",
            checksum: "a3a43e6031057bbb87bbff94b6a18cf1314b0419c0823333a4b87c1e37653a9a"
        ),
        .binaryTarget(
            name: "Data4LifeCrypto",
            url: "https://github.com/d4l-data4life/d4l-fhir-ios/releases/download/1.13.0/Data4LifeCrypto-xcframework-1.5.0.zip",
            checksum: "970a999a9ab63991f4ac59c90e260658decc14e41f62bae15bfe6afcdd4421cb"
        ),
        .testTarget(name: "Data4LifeSDKTests",
                    dependencies: ["Data4LifeSDKFrameworks","Data4LifeCryptoFrameworks"],
                    path: "SDK/Tests",
                    exclude: ["Info.plist","Data4LifeSDK-Version.plist"],
                    resources: [.process("Resources"),.process("BenchmarkClient/SubbedResponses")])
    ]
)
