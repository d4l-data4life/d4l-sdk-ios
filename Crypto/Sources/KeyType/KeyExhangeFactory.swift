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

public typealias KeyExchangeFormat = (algorithm: AlgorithmType, size: KeySize)

public struct KeyExhangeFactory {
    public static func create(type: KeyType, version: Int = 1) throws -> KeyExchangeFormat {
        guard version == 1 else {
            throw Data4LifeCryptoError.invalidKeyAlgorithmVersion(type.rawValue)
        }

        switch type {
        case .common, .data, .attachment:
            let algo = AESAlgorithm(cipher: .aes, padding: .noPadding, blockMode: .gcm, hash: nil)
            return (algo, 256)
        case .tag:
            let algo = AESAlgorithm(cipher: .aes, padding: .pkcs7, blockMode: .cbc, hash: nil)
            return (algo, 256)
        case .appPrivate, .appPublic:
            return (RSAAlgorithm(), 2048)
        }
    }
}
