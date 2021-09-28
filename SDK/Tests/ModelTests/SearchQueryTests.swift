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

import XCTest
@testable import Data4LifeSDK

extension RecordServiceParameterBuilder.SearchQuery: Equatable {
    public static func == (lhs: RecordServiceParameterBuilder.SearchQuery, rhs: RecordServiceParameterBuilder.SearchQuery) -> Bool {
        return lhs.includingDeleted == rhs.includingDeleted &&
        lhs.tagGroup == rhs.tagGroup &&
        lhs.endUpdatedDate == rhs.endUpdatedDate &&
        lhs.startUpdatedDate == rhs.startUpdatedDate &&
        lhs.startDate == rhs.startDate &&
        lhs.endDate == rhs.endDate &&
        lhs.limit == rhs.limit &&
        lhs.offset == rhs.offset
    }
}
