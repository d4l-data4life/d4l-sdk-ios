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

public enum AsymmetricKeyType: String {
    case `public`
    case `private`
}

public struct AsymmetricKey {
    public let value: SecKey
    public let type: AsymmetricKeyType

    init(value: SecKey, type: AsymmetricKeyType ) {
        self.value = value
        self.type = type
    }

    init(data: Data, type: AsymmetricKeyType, keySize: KeySize) throws {
        var keyData = data
        let keyType = type == .private ? kSecAttrKeyClassPrivate : kSecAttrKeyClassPublic
        var error: Unmanaged<CFError>?

        let attributes: Attributes = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                      kSecAttrKeyClass as String: keyType,
                                      kSecAttrKeySizeInBits as String : keySize]

        if type == .private {
            guard let normalizedPrivateKey = try AsymmetricKey.stripPKCS8Header(forKey: data) else {
                throw Data4LifeCryptoError.couldNotReadPrivateKey
            }

            keyData = normalizedPrivateKey
        }

        guard let secKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        self.value = secKey
        self.type = type
    }

    public func asData() throws -> Data {
        return try self.value.asData()
    }

    public func asBase64EncodedString() throws -> String {
        return try asData().base64EncodedString()
    }

    public func asSPKIBase64EncodedString() throws -> String {
        let paddedData = try AsymmetricKey.appendSPKIHeader(forSecKey: self.value)
        return paddedData.base64EncodedString()
    }
}
