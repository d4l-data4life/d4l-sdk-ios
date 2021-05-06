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

public struct AppDataRecord {
    public let id: String
    public let data: Data
    public let metadata: Metadata
    public let annotations: [String]

    init(id: String, resource: Data, metadata: Metadata, annotations: [String] = []) {
        self.id = id
        self.data = resource
        self.metadata = metadata
        self.annotations = annotations
    }
}

extension Data: SDKResource {
    public static var searchTags: [String : String] {
        return [TaggingService.Keys.flag.rawValue.lowercased(): TaggingService.FlagKey.appData.rawValue.lowercased()]
    }

    static var modelVersion: Int { 1 }
}

extension AppDataRecord: SDKRecord {
    var resource: Data {
        return data
    }
}

extension AppDataRecord {
    public func getDecodableResource<D: Decodable>(of type: D.Type = D.self) throws -> D {
        return try JSONDecoder().decode(D.self, from: data)
    }
}
