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

import Then
@testable import Data4LifeSDK

class KeychainServiceMock: KeychainServiceType {

    var values: [String: String] = [:]

    subscript(key: KeychainKey) -> String? {
        get {
            return try? await(get(key))
        }

        set {
            try? await(set(newValue, forKey: key))
        }
    }

    var clearCalled = false
    func clear() {
        values = [:]
        clearCalled = true
    }

    var setItemCalledWith: [(String?, KeychainKey)]  = []
    func set(_ item: String?, forKey key: KeychainKey) -> AsyncTask {
        setItemCalledWith.append((item, key))
        values[key.rawValue] = item
        return Async.resolve()
    }

    var getItemCalledWith: [KeychainKey] = []
    func get(_ key: KeychainKey) -> Async<String> {
        getItemCalledWith.append(key)
        if let value = values[key.rawValue] {
            return Async.resolve(value)
        } else {
            return Async.reject(Data4LifeSDKError.keychainItemNotFound(key.rawValue)).bridgeError(to: Data4LifeSDKError.notLoggedIn)
        }
    }

    var getCommonKeyByIdCalledWith: String?
    var getCommonKeyByIdResult: String?
    func getCommonKeyById(_ id: String) -> String? {
        getCommonKeyByIdCalledWith = id
        return getCommonKeyByIdResult ?? values[id]
    }

    var storeCommonKeyCalledWith: (String, String)?
    func store(commonKey: String, commonKeyId: String) {
        storeCommonKeyCalledWith = (commonKey, commonKeyId)
        values[commonKeyId] = commonKey
    }

    var hasCommonKeyCalledWith: String?
    var hasCommonKeyResult: Bool?
    func hasCommonKey(commonKeyId: String) -> Bool {
        hasCommonKeyCalledWith = commonKeyId
        let value = values[commonKeyId] != nil
        return hasCommonKeyResult ?? value
    }
}
