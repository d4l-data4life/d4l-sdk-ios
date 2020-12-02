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

typealias Attributes = [String: Any]

public protocol KeyPairType {
    var publicKey: AsymmetricKey { get }
    var privateKey: AsymmetricKey { get }
    var algorithm: AlgorithmType { get }
    var keySize: KeySize { get }

    static func generate(tag: String, keySize: Int, algorithm: AlgorithmType) throws -> Self
    static func load(tag: String, algorithm: AlgorithmType) throws -> Self
    static func destroy(tag: String) throws
}

public struct KeyPair: KeyPairType {
    public let privateKey: AsymmetricKey
    public let publicKey: AsymmetricKey
    public let keySize: KeySize
    public let algorithm: AlgorithmType

    init(privateKey: SecKey, publicKey: SecKey, keySize: KeySize, algorithm: AlgorithmType) {
        self.privateKey = AsymmetricKey(value: privateKey, type: .private)
        self.publicKey = AsymmetricKey(value: publicKey, type: .public)
        self.keySize = keySize
        self.algorithm = algorithm
    }

    init(privateKey: Data, publicKey: Data, keySize: KeySize, algorithm: AlgorithmType) throws {
        self.privateKey = try AsymmetricKey(data: privateKey, type: .private, keySize: keySize)
        self.publicKey = try AsymmetricKey(data: publicKey, type: .public, keySize: keySize)
        self.keySize = keySize
        self.algorithm = algorithm
    }

    public static func load(tag: String, algorithm: AlgorithmType) throws -> KeyPair {
        let privateKeyQuery: Attributes = [kSecClass as String: kSecClassKey,
                                           kSecAttrApplicationTag as String: tag,
                                           kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                           kSecReturnRef as String: true]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(privateKeyQuery as CFDictionary, &item)

        guard status == errSecSuccess else {
            throw Data4LifeCryptoError.couldNotReadKeyPair(tag)
        }

        let privateKey = item as! SecKey // swiftlint:disable:this force_cast

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw Data4LifeCryptoError.couldNotReadPublicKey
        }

        guard let privateKeyAttributes = SecKeyCopyAttributes(privateKey) as? Attributes,
            let keySize = privateKeyAttributes[kSecAttrKeySizeInBits as String] as? Int else {
                throw Data4LifeCryptoError.couldNotReadPrivateKey
        }

        return KeyPair(privateKey: privateKey,
                         publicKey: publicKey,
                         keySize: keySize,
                         algorithm: algorithm)
    }

    public static func destroy(tag: String) throws {
        let query: Attributes = [kSecClass as String: kSecClassKey,
                                 kSecAttrApplicationTag as String: tag,
                                 kSecAttrKeyType as String: kSecAttrKeyTypeRSA]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw Data4LifeCryptoError.couldNotDeleteKeyPair(tag)
        }
    }

    public static func generate(tag: String, keySize: Int, algorithm: AlgorithmType) throws -> KeyPair {
        let privateKeyAttributes: Attributes = [kSecAttrIsPermanent as String: true,
                                                kSecAttrApplicationTag as String: tag]

        let attributes: Attributes = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                      kSecAttrKeySizeInBits as String: keySize,
                                      kSecPrivateKeyAttrs as String: privateKeyAttributes]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw Data4LifeCryptoError.couldNotReadPublicKey
        }

        return KeyPair(privateKey: privateKey,
                         publicKey: publicKey,
                         keySize: keySize,
                         algorithm: algorithm)
    }
}
