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

extension AsymmetricKey {
    /**
     Adds header prefix per ASN.1 to the PKCS#1 public key exported from iOS Keychain and create SPKI compatible data.
     Header data taken from https://github.com/datatheorem/TrustKit/blob/master/TrustKit/Pinning/TSKSPKIHashCache.m
     
     - parameter key: RSA public key as SecKey
     */
    static func appendSPKIHeader(forSecKey key: SecKey) throws -> Data {
        guard let publicAttributes = SecKeyCopyAttributes(key) as? [String: Any] else {
            throw Data4LifeCryptoError.couldNotReadKeyAttributes
        }

        guard (publicAttributes[kSecAttrKeyType as String] as? String) == (kSecAttrKeyTypeRSA as String) else {
            throw Data4LifeCryptoError.keyIsNotRSAKey
        }

        guard (publicAttributes[kSecAttrKeyClass as String] as? String) == (kSecAttrKeyClassPublic as String) else {
            throw Data4LifeCryptoError.keyIsNotPublicKey
        }

        guard let keySize = publicAttributes[kSecAttrKeySizeInBits as String] as? Int else {
            throw Data4LifeCryptoError.couldNotReadKeySize
        }

        let keyData = try key.asData()
        var headerData = try rsaHeaderBytes(forSize: keySize)

        headerData.append(keyData)
        return headerData
    }

    private static func rsaHeaderBytes(forSize size: Int) throws -> Data {
        switch size {
        case 2048:
            return Data([0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
                         0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00])
        case 4096:
            return Data([0x30, 0x82, 0x02, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
                         0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0f, 0x00])
        default:
            throw Data4LifeCryptoError.missingHeaderBytesForKeySize(size)
        }
    }
}
