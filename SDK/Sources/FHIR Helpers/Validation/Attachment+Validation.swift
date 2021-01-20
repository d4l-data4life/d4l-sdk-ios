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

import Data4LifeFHIR
import Data4LifeSDKUtils

enum HashValidity {
    case valid
    case notValid
    case unknown
}

extension AttachmentType {

    var hashValidity: HashValidity {
        guard
            let hash = self.attachmentHash,
            let creationDate = self.creationDate
            else { return .unknown }

        // All attachments created after Mar. 13th 2020 will be validated
        let startingValidationDate = Date(timeIntervalSince1970: 1584144000.0)
        if creationDate.compare(startingValidationDate) == .some(.orderedDescending) {
            return self.getData()?.sha1Hash == hash ? .valid : .notValid
        } else {
            return .unknown
        }
    }
}

extension AttachmentType {

    func validatePayload(using validator: DataValidator = DataValidator.d4lSDK) throws {
        try validatePayloadType(using: validator)
        try validatePayloadSize(using: validator)
        try validatePayloadHash()
    }

    func validatePayloadType(using validator: DataValidator = DataValidator.d4lSDK) throws {
        guard let data = getData() else {
            return
        }

        do { try validator.validateMimeType(of: data) } catch { throw Data4LifeSDKError.invalidAttachmentPayloadType }
        return
    }

    func validatePayloadSize(using validator: DataValidator = DataValidator.d4lSDK) throws {
        guard let data = getData(), let upperFilesizeLimit = validator.upperFilesizeLimitInBytes else {
            return
        }

        guard attachmentSize ?? 0 <= upperFilesizeLimit else {
            throw Data4LifeSDKError.invalidAttachmentPayloadSize
        }
        do { try validator.validateSize(of: data) } catch {
            throw Data4LifeSDKError.invalidAttachmentPayloadSize
        }

        return
    }

    func validatePayloadHash() throws {
        guard hashValidity != .notValid else { throw Data4LifeSDKError.invalidAttachmentPayloadHash }
    }
}

extension Array where Element == AttachmentType {
    @discardableResult
    func validate() throws -> [AttachmentType] {
        try forEach { (attachment) in
            try attachment.validatePayload()
        }
        return self
    }
}
