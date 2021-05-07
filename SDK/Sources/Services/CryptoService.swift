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
@_implementationOnly import Data4LifeCrypto

protocol CryptoServiceType {

    var tek: Key? { get set }
    var keyPairTag: String { get }

    func encrypt(data: Data, key: Key) throws -> Data
    func decrypt(data: Data, key: Key) throws -> Data

    func decrypt(string: String, key: Key) throws -> String
    func encrypt(string: String, key: Key) throws -> String

    func encrypt(values: [String], key: Key) throws -> [String]
    func decrypt(values: [String], key: Key) throws -> [String]

    func encrypt(data: Data, keypair: KeyPair) throws -> Data
    func decrypt(data: Data, keypair: KeyPair) throws -> Data

    func generateGCKey(_ type: KeyType) throws -> Key
    func fetchOrGenerateKeyPair() throws -> KeyPair
    func deleteKeyPair() throws
}

final class CryptoService: CryptoServiceType {

    private var ivGenerator: InitializationVectorGeneratorProtocol
    private var keychainService: KeychainServiceType
    private(set) var keyPairTag: String

    var tek: Key? {
        get {
            guard
                let tagEncryptionKeyBase64EncodedString = self.keychainService[.tagEncryptionKey],
                let tekData = Data(base64Encoded: tagEncryptionKeyBase64EncodedString),
                let tek: Key = try? decoder.decode(Key.self, from: tekData)
                else {
                    return nil
            }
            return tek
        }
        set {
            if let key = newValue {
                let encodedTagKey = try? encoder.encode(key).base64EncodedString()
                self.keychainService[.tagEncryptionKey] = encodedTagKey
            } else {
                self.keychainService[.tagEncryptionKey] = nil
            }
        }
    }

    init(container: DIContainer, keyPairTag: String) {
        do {
            self.keychainService = try container.resolve()
            self.ivGenerator = try container.resolve()
        } catch {
            fatalError(error.localizedDescription)
        }

        self.keyPairTag = keyPairTag
    }

    // MARK: Helpers around symmetric crypto operations that handle IV for easier usage
    func encrypt(data: Data, key: Key) throws -> Data {
        let iv = ivGenerator.randomIVData(of: key.ivSize)
        let encryptedData = try Data4LifeCryptor.symEncrypt(key: key, data: data, iv: iv)
        return iv + encryptedData
    }

    func decrypt(data: Data, key: Key) throws -> Data {
        let byteCount = key.ivSize
        guard data.byteCount > byteCount  else {
            throw Data4LifeSDKError.invalidEncryptedDataSize
        }

        let ivData = data[..<byteCount]
        let inputData = data[byteCount...]

        return try Data4LifeCryptor.symDecrypt(key: key, data: inputData, iv: ivData)
    }

    // MARK: Helpers around asymmetric crypto operations
    func encrypt(data: Data, keypair: KeyPair) throws -> Data {
        return try Data4LifeCryptor.asymEncrypt(key: keypair, data: data)
    }

    func decrypt(data: Data, keypair: KeyPair) throws -> Data {
        return try Data4LifeCryptor.asymDecrypt(key: keypair, data: data)
    }

    // MARK: GCKey related methods
    func generateGCKey(_ type: KeyType) throws -> Key {
        let keyExchangeFormat = try KeyExhangeFactory.create(type: type)
        let options = KeyOptions(size: keyExchangeFormat.size)
        return try Data4LifeCryptor.generateSymKey(algorithm: keyExchangeFormat.algorithm, options: options, type: type)
    }

    // MARK: GCKeyPair related methods
    func fetchOrGenerateKeyPair() throws -> KeyPair {
        let type: KeyType = .appPrivate
        let keyExchangeFormat = try KeyExhangeFactory.create(type: type)
        let algorithm = keyExchangeFormat.algorithm
        let options = KeyOptions(size: keyExchangeFormat.size, tag: keyPairTag)

        do {
            return try KeyPair.load(tag: keyPairTag, algorithm: algorithm)
        } catch {
            return try Data4LifeCryptor.generateAsymKeyPair(algorithm: algorithm, options: options)
        }
    }

    func deleteKeyPair() throws {
        return try KeyPair.destroy(tag: keyPairTag)
    }

    // MARK: Helpers for tag crypto operations (not meant to be used for general data as it's not secure)
    func decrypt(string: String, key: Key) throws -> String {
        guard let data = Data(base64Encoded: string) else {
            throw Data4LifeSDKError.couldNotReadBase64EncodedData
        }
        let blankIV = [UInt8](repeating: 0x00, count: key.ivSize).asData
        let decryptedData = try Data4LifeCryptor.symDecrypt(key: key, data: data, iv: blankIV)
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw Data4LifeSDKError.invalidDataNotValidUTF8String
        }
        return decryptedString
    }

    func encrypt(string: String, key: Key) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw Data4LifeSDKError.invalidDataNotValidUTF8String
        }
        let blankIV = [UInt8](repeating: 0x00, count: key.ivSize).asData
        let encryptedData: Data = try Data4LifeCryptor.symEncrypt(key: key, data: data, iv: blankIV)
        let encryptedString = encryptedData.base64EncodedString()
        return encryptedString
    }

    func encrypt(values: [String], key: Key) throws -> [String] {
        return try values.map { try encrypt(string: $0, key: key) }
    }

    func decrypt(values: [String], key: Key) throws -> [String] {
        return try values.map { try decrypt(string: $0, key: key) }
    }
}
