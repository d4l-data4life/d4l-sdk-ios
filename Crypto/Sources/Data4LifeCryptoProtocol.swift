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
@_implementationOnly import CryptoSwift

protocol Data4LifeCryptoProtocol {
    static func symEncrypt(key: Key, data: Data, iv: Data) throws -> Data
    static func symDecrypt(key: Key, data: Data, iv: Data) throws -> Data
    static func asymEncrypt(key: KeyPair, data: Data) throws -> Data
    static func asymDecrypt(key: KeyPair, data: Data) throws -> Data
    static func generateAsymKeyPair(algorithm: AlgorithmType, options: KeyOptions) throws -> KeyPair
    static func generateSymKey(algorithm: AlgorithmType, options: KeyOptions, type: KeyType) throws -> Key
}

public struct Data4LifeCrypto: Data4LifeCryptoProtocol {
    public static func symEncrypt(key: Key, data: Data, iv: Data) throws -> Data {
        return try symmetricEncrypt(key: key.value, data: data, algorithm: key.algorithm, iv: iv)
    }

    public static func symDecrypt(key: Key, data: Data, iv: Data) throws -> Data {
        return try symmetricDecrypt(key: key.value, data: data, algorithm: key.algorithm, iv: iv)
    }

    public static func asymEncrypt(key: KeyPair, data: Data) throws -> Data {
        return try cipher(key: key.publicKey.value, algorithm: key.algorithm).encrypt(data)
    }

    public static func asymDecrypt(key: KeyPair, data: Data) throws -> Data {
        return try cipher(key: key.privateKey.value, algorithm: key.algorithm).decrypt(data)
    }

    public static func generateAsymKeyPair(algorithm: AlgorithmType, options: KeyOptions) throws -> KeyPair {
        guard let tag = options.tag else {
            throw Data4LifeCryptoError.missingKeyPairTagOption
        }
        return try KeyPair.generate(tag: tag, keySize: options.size, algorithm: algorithm)
    }

    public static func generateSymKey(algorithm: AlgorithmType, options: KeyOptions, type: KeyType) throws -> Key {
        return try Key.generate(keySize: options.size, algorithm: algorithm, type: type)
    }

    // MARK: Private helpers
    private static func symmetricEncrypt(key: Data, data: Data, algorithm: AlgorithmType, iv: Data) throws -> Data {
        switch algorithm.type {
        case (.aes, .noPadding, .gcm?, _):
            let blockMode = GCM(iv: iv.asBytes, mode: .combined)
            let cipher = try AES(key: key.asBytes, blockMode: blockMode , padding: .noPadding)
            return try cipher.encrypt(data.asBytes).asData
        case (.aes, .pkcs7, .cbc?, _):
            let blockMode = CBC(iv: iv.asBytes)
            let cipher = try AES(key: key.asBytes, blockMode: blockMode, padding: .pkcs7)
            return try cipher.encrypt(data.asBytes).asData
        default:
            throw Data4LifeCryptoError.unsupportedAlgorithmCombination
        }
    }

    private static func symmetricDecrypt(key: Data, data: Data, algorithm: AlgorithmType, iv: Data) throws -> Data {
        switch algorithm.type {
        case (.aes, .noPadding, .gcm?, _):
            let block = GCM(iv: iv.asBytes, additionalAuthenticatedData: nil, mode: .combined)
            let cipher = try AES(key: key.asBytes, blockMode: block , padding: .noPadding)
            return try cipher.decrypt(data.asBytes).asData
        case (.aes, .pkcs7, .cbc?, _):
            let blockMode = CBC(iv: iv.asBytes)
            let cipher = try AES(key: key.asBytes, blockMode: blockMode, padding: .pkcs7)
            return try cipher.decrypt(data.asBytes).asData
        default:
            throw Data4LifeCryptoError.unsupportedAlgorithmCombination
        }
    }

    private static func cipher(key: SecKey, algorithm: AlgorithmType) throws -> RSACipher {
        switch algorithm.type {
        case (.rsa, .oaep, _, .sha256?):
            return RSACipher(key: key, algorithm: SecKeyAlgorithm.rsaEncryptionOAEPSHA256)
        default:
            throw Data4LifeCryptoError.unsupportedAlgorithmCombination
        }
    }
}
