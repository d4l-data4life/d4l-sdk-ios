#!/usr/bin/env swift

import Foundation

func log(_ input: String, prefix: String = "✅", separator: String = " ") {
    print([prefix, input].joined(separator: separator))
}

func error(_ input: String) {
    log(input, prefix: "❌")
}

let licenseText = """
    //  Copyright (c) 2021 D4L data4life gGmbH
    //  All rights reserved.
    //
    //  D4L owns all legal rights, title and interest in and to the Software Development Kit (SDK),
    //  including any intellectual property rights that subsist in the SDK.
    //
    //  The SDK and its documentation may be accessed and used for viewing/review purposes only.
    //  Any usage of the SDK for other purposes, including usage for the development of
    //  applications/third-party applications shall require the conclusion of a license agreement
    //  between you and D4L.
    //
    //  If you are interested in licensing the SDK for your own applications/third-party
    //  applications and/or if you’d like to contribute to the development of the SDK, please
    //  contact D4L by email to help@data4life.care.
    //
    """

func makeXcconfig(
    clientIdentifier: String,
    clientSecret: String,
    redirectScheme: String,
    environment: String,
    platform: String,
    licenseText: String = licenseText
) -> String {
    """
    \(licenseText)

    D4L_PLATFORM = \(platform)
    D4L_ID = \(clientIdentifier)
    D4L_SECRET = \(clientSecret)
    D4L_REDIRECT_SCHEME = \(redirectScheme)
    D4L_ENVIRONMENT = \(environment)
    
    """
}

func generateFile(
    content: String,
    outputDirectoryPath: String,
    filename: String,
    fileManager: FileManager = .default
) {
    do {
        if fileManager.fileExists(atPath: outputDirectoryPath) {
            log("removing existing files @ \(outputDirectoryPath)")
            try fileManager.removeItem(atPath: outputDirectoryPath)
        }
        
        log("creating output directory @ \(outputDirectoryPath)")
        try fileManager.createDirectory(
            atPath: outputDirectoryPath,
            withIntermediateDirectories: false,
            attributes: nil
        )
        
        let url = URL(string: "file://" + outputDirectoryPath + "/\(filename)")!
        try content.data(using: .utf8)?.write(to: url)

        log("created file @ \(url.relativePath)")
    } catch {
        log("generating files failed due to \(String(describing: error))")
    }
}

struct Configuration: Codable {
    let id: String
    let secret: String
    let redirectScheme: String
}

enum Environment: String, Codable, CaseIterable {
    case local
    case development
    case staging
    case sandbox
    case production
    
    var name: String { return rawValue.uppercased() }
}

enum Platform: String, Codable, CaseIterable {
    case d4l
    case s4h

    var name: String { return rawValue.uppercased() }
}


struct EnvironmentConfigurations: Codable {
    let platform: String?
    let configs: [String: Configuration]
}

func parseEnvConfiguration(
    atPath path: String,
    fileManager: FileManager = .default,
    jsonDecoder: JSONDecoder = JSONDecoder()
) -> EnvironmentConfigurations? {
    guard let data = fileManager.contents(atPath: path) else { return nil}
    return try? jsonDecoder.decode(EnvironmentConfigurations.self, from: data)
}

func main() {
    guard CommandLine.arguments.count == 3 else {
        error("usage: config-generator.swift target-platform [d4l|s4h] target-environment [development|staging|production|sandbox]")
        exit(EXIT_FAILURE)
    }

    let targetPlatformName = CommandLine.arguments[1]
    guard let targetPlatform = Platform(rawValue: targetPlatformName) else {
        error("could not find `\(targetPlatformName)` platform")
        error("supported platform: \(Platform.allCases.map(\.rawValue).joined(separator: ", "))")
        exit(EXIT_FAILURE)
    }

    let targetEnvironmentName = CommandLine.arguments[2]
    guard let targetEnvironment = Environment(rawValue: targetEnvironmentName) else {
        error("could not find `\(targetEnvironmentName)` environment")
        error("supported envs: \(Environment.allCases.map(\.rawValue).joined(separator: ", "))")
        exit(EXIT_FAILURE)
    }

    let fileManager = FileManager.default
    let configurationJsonFilePath = fileManager.currentDirectoryPath.appending("/\(targetPlatform.rawValue)-example-app-config.json")
    let environments = parseEnvConfiguration(atPath: configurationJsonFilePath)

    guard let config = environments?.configs[targetEnvironment.name] else {
        error("could not find target environment \(targetEnvironment)")
        exit(EXIT_FAILURE)
    }

    let xcconfig = makeXcconfig(
        clientIdentifier: config.id,
        clientSecret: config.secret,
        redirectScheme: config.redirectScheme,
        environment: targetEnvironment.name,
        platform: targetPlatform.name
    )
    
    generateFile(
        content: xcconfig,
        outputDirectoryPath: fileManager.currentDirectoryPath.appending("/generated"),
        filename: "d4l-example.xcconfig"
    )
}

main()
exit(EXIT_SUCCESS)
