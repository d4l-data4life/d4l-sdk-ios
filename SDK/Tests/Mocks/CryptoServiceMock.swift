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
import Data4LifeCrypto
import Combine

enum CryptoMockError: Error {
    case missingResult
}

class CryptoServiceMock: CryptoServiceType {

    static var encoder: JSONEncoder = JSONEncoder()
    static var decoder: JSONDecoder = JSONDecoder()

    let missingResultError = CryptoMockError.missingResult

    var didSetKeyPairTag = false
    var keyPairTag: String = "keypair.mock.tag" {
        didSet {
            didSetKeyPairTag = true
        }
    }

    var tagEncryptionKey: Key?

    var encryptValueCalledWith: (Encodable, Key)?
    var encryptValueResult: SDKFuture<Data>?
    func encrypt<T: Encodable>(value: T, key: Key) -> SDKFuture<Data> {
        encryptValueCalledWith = (value, key)
        return encryptValueResult ?? Fail(error: CryptoMockError.missingResult).asyncFuture()
    }

    var decryptStringCalledWith: (String, Key)?
    var decryptStringResult: String?
    func decrypt(string: String, key: Key) throws -> String {
        decryptStringCalledWith = (string, key)

        guard let result = decryptStringResult else {
            throw missingResultError
        }

        return result
    }

    var encryptStringCalledWith: (String, Key)?
    func encrypt(string: String, key: Key) throws -> String {
        encryptStringCalledWith = (string, key)
        return encryptStringResult(for: string)
    }

    func encryptStringResult(for tag: String) -> String {
        return tag
    }

    var fetchOrGenerateKeyPairWithTagCalledWith: (String)?
    var fetchOrGenerateKeyPairWithTagResult: KeyPair?
    func fetchOrGenerateKeyPair(tag: String) throws -> KeyPair {
        fetchOrGenerateKeyPairWithTagCalledWith = (tag)

        guard let result = fetchOrGenerateKeyPairWithTagResult else {
            throw missingResultError
        }

        return result
    }

    var fetchOrGenerateKeyPairCalled = false
    var fetchOrGenerateKeyPairResult: KeyPair?
    func fetchOrGenerateKeyPair() throws -> KeyPair {
        fetchOrGenerateKeyPairCalled = true

        guard let result = fetchOrGenerateKeyPairResult else {
            throw missingResultError
        }

        return result
    }

    var generateKeyPairCalledWith: (AlgorithmType, KeyOptions)?
    var generateKeyPairResult: KeyPair?
    func generateKeyPair(algorithm: AlgorithmType, options: KeyOptions) throws -> KeyPair {
        generateKeyPairCalledWith = (algorithm, options)

        guard let result = generateKeyPairResult else {
            throw missingResultError
        }

        return result
    }

    var generateGCKeyCalledWith: (KeyType)?
    var generateGCKeyResult: Key?
    func generateGCKey(_ type: KeyType) throws -> Key {
        generateGCKeyCalledWith = (type)

        guard let result = generateGCKeyResult else {
            throw missingResultError
        }

        return result
    }

    var loadOrGenerateKeyPairCalledWith: (String)?
    var loadOrGenerateKeyPairResult: KeyPair?
    func loadOrGenerateKeyPair(tag: String) throws -> KeyPair {
        loadOrGenerateKeyPairCalledWith = (tag)

        guard let result = loadOrGenerateKeyPairResult else {
            throw missingResultError
        }

        return result
    }

    var fetchKeyPairCalledWith: (String, AlgorithmType)?
    var fetchKeyPairResult: KeyPair?
    func fetchKeyPair(tag: String, algorithm: AlgorithmType) throws -> KeyPair {
        fetchKeyPairCalledWith = (tag, algorithm)

        guard let result = fetchKeyPairResult else {
            throw missingResultError
        }

        return result
    }

    var deleteKeyPairCalled = false
    var deleteKeyPairResult: Error?
    func deleteKeyPair() throws {
        deleteKeyPairCalled = true
        guard let err = deleteKeyPairResult else {
            return
        }
        throw err
    }

    var deleteKeyPairWithTagCalledWith: (String)?
    var deleteKeyPairWithTagResult: Bool?
    func deleteKeyPair(tag: String) -> Bool {
        deleteKeyPairWithTagCalledWith = (tag)
        return deleteKeyPairWithTagResult ?? false
    }

    var decryptValuesCalledWith: ([String], Key)?
    var decryptValuesResult: [String]?
    func decrypt(values: [String], key: Key) throws -> [String] {
        decryptValuesCalledWith = (values, key)

        guard let result = decryptValuesResult else {
            throw missingResultError
        }

        return result
    }

    var encryptValuesCalledWith: ([String], Key)?
    var encryptValuesResult: [String]?
    func encrypt(values: [String], key: Key) throws -> [String] {
        encryptValuesCalledWith = (values, key)

        guard let result = encryptValuesResult else {
            throw missingResultError
        }

        return result
    }

    var encryptDataKeyPairCalledWith: (Data, KeyPair)?
    var encryptDataKeyPairForInput: [(input: Data, output: Data)]?
    func encrypt(data: Data, keypair: KeyPair) throws -> Data {
        encryptDataKeyPairCalledWith = (data, keypair)

        guard let output = encryptDataKeyPairForInput?.filter({ $0.input == data }).first?.output else {
            throw missingResultError
        }

        return output
    }

    var decryptDataKeyPairCalledWith: (Data, KeyPair)?
    var decryptDataKeyPairForInput: [(input: Data, output: Data)]?
    func decrypt(data: Data, keypair: KeyPair) throws -> Data {
        decryptDataKeyPairCalledWith = (data, keypair)

        guard let output = decryptDataKeyPairForInput?.filter({ $0.input == data }).first?.output else {
            throw missingResultError
        }

        return output
    }

    var encryptDataCalledWith: (Data, Key)?
    var encryptDataResult: Data?
    var encryptDataForInput: [(input: Data?, output: Data?)]?
    func encrypt(data: Data, key: Key) throws -> Data {
        encryptDataCalledWith = (data, key)

        guard let result = encryptDataResult else {
            guard let output = encryptDataForInput?.filter({ $0.input == data }).first?.output else {
                throw missingResultError
            }

            return output
        }

        return result
    }

    var decryptDataCalledWith: (Data, Key)?
    var decryptDataResult: Data?
    var decryptDataForInput: [(input: Data?, output: Data?)]?
    func decrypt(data: Data, key: Key) throws -> Data {
        decryptDataCalledWith = (data, key)

        guard let result = decryptDataResult else {
            guard let output = decryptDataForInput?.filter({ $0.input == data }).first?.output else {
                throw missingResultError
            }

            return output
        }

        return result
    }
}