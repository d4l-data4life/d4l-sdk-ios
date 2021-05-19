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
@testable import Data4LifeSDK
import Combine
import Data4LifeCrypto

enum CommonKeyServiceMockError: Error {
    case noResultSet
}

class CommonKeyServiceMock: CommonKeyServiceType {
    static let initialId = "00000000-0000-0000-0000-000000000000"
    var currentId: String?
    var currentKey: Key?

    var fetchKeyCalledWith: String?
    var fetchKeyResult: SDKFuture<Key>?
    func fetchKey(with commonKeyId: String) -> SDKFuture<Key> {
        fetchKeyCalledWith = commonKeyId
        return fetchKeyResult ?? Fail(error: CommonKeyServiceMockError.noResultSet).asyncFuture
    }

    var storeKeyCalledWith: (Key, String, Bool)?
    func storeKey(_ key: Key, id: String, isCurrent: Bool) {
        storeKeyCalledWith = (key, id, isCurrent)
    }
}
