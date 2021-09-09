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

struct SDKVersionConfiguration: Codable {
    let versionRanges: [VersionRange]

    enum CodingKeys: String, CodingKey {
        case versionRanges
        case config
    }

    enum NestedInfoKeys: String, CodingKey {
        case versionRanges = "version_ranges"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nestedContainer = try container.nestedContainer(keyedBy: NestedInfoKeys.self, forKey: .config)
        versionRanges = try nestedContainer.decode([VersionRange].self, forKey: .versionRanges)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var nestedContainer = container.nestedContainer(keyedBy: NestedInfoKeys.self, forKey: .config)
        try nestedContainer.encode(versionRanges, forKey: .versionRanges)
    }
}

struct VersionRange: Codable {
    let fromVersion: String
    let toVersion: String
    let status: VersionStatus

    enum CodingKeys: String, CodingKey {
        case fromVersion = "from_version"
        case toVersion = "to_version"
        case status
    }
}

enum VersionStatus: String, Codable {
    case unsupported, deprecated, supported, unknown
}