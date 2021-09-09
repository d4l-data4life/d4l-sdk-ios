//  Copyright (c) 2021 D4L data4life gGmbH
//  All rights reserved.
//  
//  D4L owns all legal rights, title and interest in and to the Software Development Kit ("SDK"),
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

import Foundation

protocol InfoServiceType {
    func fetchSDKVersion() -> String
}

struct InfoService: InfoServiceType {
    let sdkBundle: Foundation.Bundle
    let decoder: PropertyListDecoder

    enum FileKeys: String {
        case version = "Data4LifeSDK-Version"

        static var type: String { return "plist" }
    }

    init(container: DIContainer) {
        do {
            self.sdkBundle = try container.resolve()
            self.decoder = try container.resolve()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func fetchSDKVersion() -> String {
        guard let url = sdkBundle.url(forResource: FileKeys.version.rawValue, withExtension: FileKeys.type) else {
            fatalError("SDK version info is missing")
        }

        do {
            let data = try Data(contentsOf: url)
            let versionInfo = try decoder.decode(VersionInfo.self, from: data)
            return versionInfo.stringValue
        } catch {
            fatalError("Could not decode version info, error: \(error.localizedDescription)")
        }
    }
}
