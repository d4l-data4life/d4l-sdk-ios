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
import Combine
@_implementationOnly import Data4LifeCrypto

extension CryptoServiceType {

    func encrypt<T: Encodable>(value: T, key: Key) -> SDKFuture<Data> {
        return combineAsync {
            let encodedData = try value.encodedData(with: encoder)
            let encryptedValue = try self.encrypt(data: encodedData, key: key)
            return encryptedValue
        }
    }

    func decrypt<T: Decodable>(data: Data, to type: T.Type, key: Key) -> SDKFuture<T> {
        return combineAsync {
            let decryptedData = try self.decrypt(data: data, key: key)
            let decodedData = try self.decoder.decode(type, from: decryptedData)
            return decodedData
        }
    }

    func generateGCKey(_ type: KeyType) -> SDKFuture<Key> {
        return combineAsync {
            let key = try self.generateGCKey(type)
            return key
        }
    }

    func deleteKeyPair() -> SDKFuture<Void> {
        return combineAsync {
            try self.deleteKeyPair()
        }
    }

    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.with(format: .iso8601TimeZone))
        return decoder
    }

    var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(DateFormatter.with(format: .iso8601TimeZone))
        return encoder
    }
}
