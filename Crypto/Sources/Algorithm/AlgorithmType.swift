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

public protocol AlgorithmType {
    var cipher: CipherType { get }
    var padding: Padding { get }
    var blockMode: BlockMode? { get }
    var hash: HashType? { get }
}

extension AlgorithmType {
    var type: (CipherType, Padding, BlockMode?, HashType?) {
        return (cipher, padding, blockMode, hash)
    }
}

public enum BlockMode: String, CaseIterable {
    case cbc = "CBC"
    case gcm = "GCM"
}

public enum CipherType: String, CaseIterable {
    case aes = "AES"
    case rsa = "RSA"
}

public enum Padding: String, CaseIterable {
    case noPadding = "nopadding"
    case pkcs1 = "PKCS1"
    case pkcs5 = "PKCS5"
    case pkcs7 = "PKCS7"
    case oaep = "OAEP"
}

public enum HashType: String, CaseIterable {
    case sha256 = "SHA-256"
}
