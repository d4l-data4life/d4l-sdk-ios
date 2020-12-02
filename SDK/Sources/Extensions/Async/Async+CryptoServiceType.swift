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
import Data4LifeCrypto
import Then

extension CryptoServiceType {

    func encrypt<T: Encodable>(value: T, key: Key) -> Promise<Data> {
        return Async { resolve, reject in
            do {
                let encodedData = try value.encodedData(with: encoder)
                let encryptedValue = try self.encrypt(data: encodedData, key: key)
                resolve(encryptedValue)
            } catch {
                reject(error)
            }
        }
    }

    func decrypt<T: Decodable>(data: Data, to type: T.Type, key: Key) -> Promise<T> {
        return Async { resolve, reject in
            do {
                let decryptedData = try self.decrypt(data: data, key: key)
                resolve(try self.decoder.decode(type, from: decryptedData))
            } catch {
                reject(error)
            }
        }
    }

    func generateGCKey(_ type: KeyType) -> Async<Key> {
        return Async { resolve, reject in
            do {
                let key = try self.generateGCKey(type)
                resolve(key)
            } catch {
                reject(error)
            }
        }
    }

    func deleteKeyPair() -> Async<Void> {
        return Async { (resolve: @escaping () -> Void, reject: @escaping (Error) -> Void) in
            do {
                try self.deleteKeyPair()
                resolve()
            } catch {
                reject(error)
            }
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
