//  Copyright (c) 2020 D4L data4life gGmbH
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

public enum D4LEnvironment: CaseIterable, Equatable, Hashable {
    case development, staging, production, sandbox

    public var apiBaseString: String {
        switch self {
        case .production:
            return "https://api.data4life.care"
        case .staging:
            return "https://api-staging.data4life.care"
        case .development:
            return "https://api-phdp-dev.hpsgc.de"
        case .sandbox:
            return "https://api-phdp-sandbox.hpsgc.de"
        }
    }
    public var host: String {
        guard let host = apiBaseURL.host else {
            fatalError("API base does no containt proper hostname")
        }
        return host
    }
    public var apiBaseURL: URL {
        guard let url = URL(string: apiBaseString) else {
            fatalError("API base URL is not valid")
        }
        return url
    }
}
