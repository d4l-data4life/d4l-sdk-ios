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
@testable import Data4LifeSDK

struct RecordFactory {
    static func create<R: FhirSDKResource>(_ fhirResource: R, annotations: [String] = []) -> FhirRecord<R> {
        let metadata = Metadata(updatedDate: Date(), createdDate: Date(), status: .active)
        return FhirRecord<R>(id: fhirResource.fhirIdentifier ?? UUID().uuidString, resource: fhirResource, metadata: metadata, annotations: annotations)
    }

    static func create(_ data: Data, annotations: [String] = []) -> AppDataRecord {
        let metadata = Metadata(updatedDate: Date(), createdDate: Date(), status: .active)
        return AppDataRecord(id: UUID().uuidString, resource: data, metadata: metadata, annotations: annotations)
    }
}

struct SearchQueryFactory {
    static func create(limit: Int = 10, offset: Int = 0,
                       startDate: Date? = nil, endDate: Date? = nil,
                       startUpdatedDate: Date? = nil, endUpdatedDate: Date? = nil,
                       includingDeleted: Bool = false,
                       tagGroup: TagGroup = TagGroup(tags: [:], annotations: [])) -> RecordServiceParameterBuilder.SearchQuery {
        return RecordServiceParameterBuilder.SearchQuery(limit: limit,
                                                         offset: offset,
                                                         startDate: startDate,
                                                         endDate: endDate,
                                                         startUpdatedDate: startUpdatedDate,
                                                         endUpdatedDate: endUpdatedDate,
                                                         includingDeleted: includingDeleted,
                                                         tagGroup: tagGroup)
    }
}
