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

public enum Data4LifeCryptoError: LocalizedError {
    case couldNotReadPublicKey
    case couldNotReadPrivateKey
    case couldNotReadKeyAttributes
    case couldNotReadKeySize
    case couldNotReadBase64EncodedData
    case couldNotReadKeyPair(String)
    case couldNotDeleteKeyPair(String)
    case couldNotCopySecureRandomBytes
    case couldNotEncryptData
    case couldNotDecryptData
    case keyDoesNotMatchExpectedSize
    case keyIsNotRSAKey
    case keyIsNotPublicKey
    case invalidKeyType(String)
    case invalidKeyAlgorithmVersion(String)
    case missingHeaderBytesForKeySize(Int)
    case missingKeyPairTagOption
    case unsupportedAlgorithmCombination
}

extension Data4LifeCryptoError: CustomStringConvertible {
    public var description: String {
        switch  self {
        case .couldNotReadPublicKey:
            return "Could not read public key"
        case .couldNotReadPrivateKey:
            return "Could not read private key, expected formats: PKCS1 or PKCS8"
        case .couldNotReadKeyAttributes:
            return "Could not read key attributes"
        case .couldNotReadKeySize:
            return "Could not read key size"
        case .couldNotReadBase64EncodedData:
            return "Could not read base64 encoded data"
        case .couldNotReadKeyPair(let tag):
            return "Could not read key pair with tag: \(tag)"
        case .couldNotDeleteKeyPair(let tag):
            return "Could not delete key pair with tag: \(tag)"
        case .couldNotCopySecureRandomBytes:
            return "Could not copy secure random bytes"
        case .keyDoesNotMatchExpectedSize:
            return "Provided key does not match expected size"
        case .keyIsNotRSAKey:
            return "Provided key is not RSA key"
        case .keyIsNotPublicKey:
            return "Provided key is not public key"
        case .invalidKeyType(let type):
            return "Invalid key type: \(type)"
        case .invalidKeyAlgorithmVersion(let type):
            return "Invalid key algorithm version for key type \(type)"
        case .missingHeaderBytesForKeySize(let size):
            return "Missing RSA headers for key size: \(size)"
        case .unsupportedAlgorithmCombination:
            return "Unsupported algorithm combination"
        case .missingKeyPairTagOption:
            return "KeyPair operations required a tag to be provided in the options"
        case .couldNotEncryptData:
            return "Could not encrypt data"
        case .couldNotDecryptData:
            return "Could not decrypt data"
        }
    }
}

extension Data4LifeCryptoError {
    public var errorDescription: String? {
        return description
    }
    public var failureReason: String? {
        return nil
    }
    public var recoverySuggestion: String? {
        return nil
    }
}

extension Data4LifeCryptoError: Equatable {
    public static func == (lhs: Data4LifeCryptoError, rhs: Data4LifeCryptoError) -> Bool {
        return lhs.description == rhs.description
    }

    public static func == (lhs: Error, rhs: Data4LifeCryptoError) -> Bool {
        guard let error = lhs as? Data4LifeCryptoError else {
            return false
        }

        return error == rhs
    }
}
