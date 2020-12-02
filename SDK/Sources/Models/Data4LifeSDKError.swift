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

public enum Data4LifeSDKError: LocalizedError {

    case unsupportedVersionRunning
    case invalidOperationFile
    case invalidRecordDateFormat
    case invalidRecordMissingResource
    case invalidRecordModelVersionNotSupported
    case invalidResourceMissingId
    case invalidResourceCouldNotContainAuthor
    case invalidResourceCouldNotConvertToType(String)
    case couldNotSynchronizeAttachments
    case invalidAttachmentPayloadType
    case invalidAttachmentPayloadHash
    case invalidAttachmentPayloadSize
    case invalidAttachmentMissingData
    case invalidAttachmentAdditionalId(String)
    case malformedAttachmentAdditionalId
    case resizingImageSmallerThanOriginalOne
    case invalidDataNotValidUTF8String
    case jsonSerialization(Error)
    case keyMissingInSerialization(key: String)
    case keychainItemNotFound(String)
    case notLoggedIn
    case timeout
    case network(Error)
    case networkUnavailable
    case couldNotReadBase64EncodedData
    case missingCommonKey
    case missingTagKey
    case invalidEncryptedDataSize
    case couldNotFindAttachment
    case downloadActionWasCancelled
    case couldNotEncodeAppData

    // AppAuth errors (https://github.com/openid/AppAuth-iOS/blob/master/Source/OIDError.h)
    case appAuth(Error)
    case userCanceledAuthFlow
    case authServerError
    case authNetworkError

    public enum ClientConfiguration {
        case clientIdentifierInInfoPlistInWrongFormat
        case appGroupsIdentifierMissingForKeychain
        case couldNotBuildBaseUrl
        case couldNotBuildRedirectUrl
        case couldNotBuildOauthUrls
    }
}

extension Data4LifeSDKError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .network(let error),
             .appAuth(let error),
             .jsonSerialization(let error):
            return error.localizedDescription
        case .unsupportedVersionRunning:
            return "The running SDK Version is unsupported. Please update as soon as possible!"
        case .invalidOperationFile:
            return "Could not operate with a file required for the use of the SDK"
        case .invalidRecordMissingResource:
            return "Record is missing a FHIR resource"
        case .invalidRecordDateFormat:
            return "Could not parse record date format"
        case .invalidResourceMissingId:
            return "Resource is missing an `id` property"
        case .invalidResourceCouldNotContainAuthor:
            return "Could not contain author resource"
        case .invalidResourceCouldNotConvertToType(let type):
            return "Could not convert resource to type \(type)"
        case .invalidAttachmentPayloadType:
            return "Attachment data type is not supported"
        case .invalidAttachmentPayloadSize:
            return "Attachment data size should be under specified limit."
        case .invalidAttachmentPayloadHash:
            return "Could not validate attachment hash"
        case .invalidAttachmentMissingData:
            return "Attachment is missing `data` property"
        case .invalidAttachmentAdditionalId(let typeAndId):
            return "Additional Id usage violation for: `\(typeAndId)`"
        case .malformedAttachmentAdditionalId:
            return "Malformed additional Id using D4L format"
        case .resizingImageSmallerThanOriginalOne:
            return "The selected image to resized is smaller than the original one"
        case .invalidDataNotValidUTF8String:
            return "Input data is not valid UTF8 string"
        case .keyMissingInSerialization(let key):
            return "Key \(key) is missing in payload or is not an url"
        case .timeout:
            return "Action timed out."
        case .notLoggedIn:
            return "User is not logged in."
        case .keychainItemNotFound(let item):
            return "No value found for `\(item)` in keychain"
        case .networkUnavailable:
            return "No internet connection"
        case .userCanceledAuthFlow:
            return "User canceled auth flow"
        case .authServerError:
            return "Auth server error"
        case .authNetworkError:
            return "Auth network error"
        case .invalidRecordModelVersionNotSupported:
            return "Record model version is not supported by in the current SDK version."
        case .missingCommonKey:
            return "Cyrpto service is missing common key"
        case .missingTagKey:
            return "Crypto service is missing tag encryption key"
        case .couldNotReadBase64EncodedData:
            return "Could not read input string as base 64 encoded data"
        case .invalidEncryptedDataSize:
            return "Could not validate encrypted data size"
        case .couldNotFindAttachment:
            return "Could not find attachment to download"
        case .downloadActionWasCancelled:
            return "Download action was cancelled"
        case .couldNotSynchronizeAttachments:
            return "Could not synchronize attachments"
        case .couldNotEncodeAppData:
            return "Could not encode app data"
        }
    }
}

extension Data4LifeSDKError {
    public var errorDescription: String? {
        return description
    }
    public var failureReason: String? {
        switch self {
        case .invalidResourceMissingId:
            return "Can't update a resource that's not created (meaning it does not have an `id`)"
        case .invalidResourceCouldNotContainAuthor:
            return "Author is not one of the expected types (Organization, Practitioner)"
        case .invalidResourceCouldNotConvertToType:
            return "Trying to convert unrelated FHIR types"
        case .invalidAttachmentPayloadType:
            return "Trying to create or fetch unsupported data type"
        case .invalidAttachmentPayloadSize:
            return "Attachment data must be under size limit"
        case .invalidAttachmentMissingData:
            return "Attachment did not have `data` property"
        default:
            return nil
        }
    }
    public var recoverySuggestion: String? {
        switch self {
        case .invalidResourceMissingId:
            return "Make sure to create resource before trying to update it"
        case .invalidResourceCouldNotContainAuthor:
            return "Make sure to use resource supported by the helper method or create FHIR resource manually"
        case .invalidAttachmentMissingData:
            return "Make sure to add some kind of data to the attachment"
        case .timeout,
             .networkUnavailable:
            return "Check internet connection"
        case .invalidRecordModelVersionNotSupported, .unsupportedVersionRunning:
            return "Update SDK to the latest version"
        default:
            return nil
        }
    }
}

extension Data4LifeSDKError.ClientConfiguration: CustomStringConvertible, LocalizedError {

    public var description: String {
        localizedDescription
    }

    public var localizedDescription: String {
        switch self {
        case .clientIdentifierInInfoPlistInWrongFormat:
            return "Please check `clientId` in the `Data4LifeSDK-Info.plist` file is in proper format"
        case .appGroupsIdentifierMissingForKeychain:
            return "In case of using `KeychainSharing` capability SDK also needs `AppGroups` to be able work properly"
        case .couldNotBuildBaseUrl:
            return "API base URL is not valid"
        case .couldNotBuildRedirectUrl:
            return "Could not generate the redirect URL"
        case .couldNotBuildOauthUrls:
            return "Could not generate OAuth URLs"
        }
    }
}

extension Data4LifeSDKError: Equatable {
    public static func == (lhs: Data4LifeSDKError, rhs: Data4LifeSDKError) -> Bool {
        return lhs.description == rhs.description
    }

    public static func == (lhs: Error, rhs: Data4LifeSDKError) -> Bool {
        guard let hcError = lhs as? Data4LifeSDKError else {
            return false
        }

        return hcError == rhs
    }
}
