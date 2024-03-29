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
import Combine

protocol TaggingServiceType {
    func makeTagGroup<R: SDKResource>(for resource: R, oldTags: [String: String], annotations: [String]?) -> TagGroup
    func makeTagGroup<R: SDKResource>(for type: R.Type, annotations: [String]?) -> TagGroup
}

struct TaggingService: TaggingServiceType {

    enum Keys: String {
        case client
        case partner
        case updatedByClient = "updatedbyclient"
        case updatedByPartner = "updatedbypartner"
        case resourceType = "resourcetype"
        case fhirVersion = "fhirversion"
        case flag = "flag"
        case custom = "custom"
    }

    enum FlagKey: String {
        case appData = "appdata"
    }

    let clientId: String
    let partnerId: String

    init(clientId: String, partnerId: String) {
        self.clientId = clientId
        self.partnerId = partnerId
    }
}

extension TaggingService {

    func makeTagGroup<R: SDKResource>(for type: R.Type, annotations: [String]? = nil) -> TagGroup {
        return TagGroup(tags: type.searchTags, annotations: annotations?.lowercased ?? [])
    }

    func makeTagGroup<R: SDKResource>(for resource: R, oldTags: [String: String] = [:], annotations: [String]?) -> TagGroup {
        var tags = makeCommonTags(fromOldTags: oldTags)
        tags.merge(R.searchTags) { (tagsValue, _) -> String in
            return tagsValue
        }
        return TagGroup(tags: tags, annotations: annotations?.lowercased ?? [])
    }

    private func makeCommonTags(fromOldTags oldTags: [String: String] = [:]) -> [String:String] {
        var tags: [String: String] = oldTags

        if tags[Keys.client.rawValue] == nil {
            tags[Keys.client.rawValue] = self.clientId
        } else {
            tags[Keys.updatedByClient.rawValue] = self.clientId
        }

        if tags[Keys.partner.rawValue] == nil {
            tags[Keys.partner.rawValue] = self.partnerId
        } else {
            tags[Keys.updatedByPartner.rawValue] = self.partnerId
        }
        return tags.lowercased
    }
}
