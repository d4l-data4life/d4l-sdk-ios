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

import Combine
@testable import Data4LifeSDK

class TaggingServiceMock: TaggingServiceType {
    func makeTagGroup<R>(for resource: R, oldTags: [String : String], annotations: [String]?) -> TagGroup where R : SDKResource {
        tagResourceCalledWith = (resource, oldTags, annotations)
        guard let tagResourceResult = tagResourceResult else {
            fatalError("TaggingServiceMock result Not set")
        }
        return tagResourceResult
    }

    func makeTagGroup<R>(for type: R.Type, annotations: [String]?) -> TagGroup where R : SDKResource {
        tagTypeCalledWith = (type, annotations)
        guard let tagTypeResult = tagTypeResult else {
            fatalError("TaggingServiceMock result Not set")
        }
        return tagTypeResult
    }

    var tagResourceCalledWith: (SDKResource?, [String: String]?, [String]?)?
    var tagResourceResult: TagGroup?

    var tagTypeCalledWith: (SDKResource.Type, [String]?)?
    var tagTypeResult: TagGroup?
}
