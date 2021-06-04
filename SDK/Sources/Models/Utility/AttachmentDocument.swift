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

struct AttachmentDocument {
    let id: String?
    let data: Data?

    init(id: String? = nil, data: Data? = nil) {
        self.id = id
        self.data = data
    }
}

struct AttachmentDocumentInfo {
    static var tripleIdentifierPrefix = "d4l_f_p_t"
    static var thumbnailIdentifierSeparator: Character = "#"

    private(set) var document: AttachmentDocument
    private(set) var attachment: AttachmentType
    private(set) var thumbnailsIDs: [ThumbnailHeight: String] = [:]
}

extension AttachmentDocumentInfo {
    static func makeForFetchRequest(resource: HasAttachments, attachmentIdentifiers: [String]) throws -> [AttachmentDocumentInfo] {
        guard let attachments = resource.allAttachments else { return [] }
        return try attachments.compactMap { attachment -> AttachmentDocumentInfo? in

            guard let attachmentId = attachment.attachmentId, attachmentIdentifiers.contains(attachmentId) else { return nil }
            do { try attachment.validatePayloadSize() } catch { throw Data4LifeSDKError.invalidAttachmentPayloadSize }

            let document = AttachmentDocument(id: attachmentId)
            let thumbnailIDs = try thumbnailIdentifiers(for: attachmentId, from: resource)
            return AttachmentDocumentInfo(document: document, attachment: attachment,
                                          thumbnailsIDs: thumbnailIDs)
        }
    }

    static func makeForUploadRequest(attachment: AttachmentType) throws -> AttachmentDocumentInfo {

        guard let base64EncodedString = attachment.attachmentDataString, let data = Data(base64Encoded: base64EncodedString) else {
            throw Data4LifeSDKError.invalidAttachmentMissingData
        }
        try attachment.validatePayloadType()
        try attachment.validatePayloadSize()

        return AttachmentDocumentInfo(document: AttachmentDocument(data: data),
                                      attachment: attachment)
    }
}

extension AttachmentDocumentInfo {
    func updatingInfo(withCreated createdAttachmentDocument: AttachmentDocument) -> AttachmentDocumentInfo {
        let newAttachment = attachment.copy() as! AttachmentType
        newAttachment.attachmentId = createdAttachmentDocument.id
        return AttachmentDocumentInfo(document: createdAttachmentDocument, attachment: newAttachment, thumbnailsIDs: thumbnailsIDs)
    }

    func updatingInfo(withFetched fetchedAttachmentDocument: AttachmentDocument, for downloadType: DownloadType) throws -> AttachmentDocumentInfo {
        guard let data = fetchedAttachmentDocument.data else {
            throw Data4LifeSDKError.invalidAttachmentMissingData
        }

        let newAttachment = attachment.copy() as! AttachmentType // swiftlint:disable:this force_cast

        newAttachment.attachmentDataString = data.base64EncodedString()
        if downloadType.isThumbnailType {
            newAttachment.attachmentHash = data.sha1Hash
            newAttachment.attachmentSize = data.count
        }

        let newIdentifier = thumbnailDisplayIdentifier(for: downloadType) ?? newAttachment.attachmentId
        newAttachment.attachmentId = newIdentifier

        return AttachmentDocumentInfo(document: fetchedAttachmentDocument,
                                      attachment: newAttachment,
                                      thumbnailsIDs: thumbnailsIDs)
    }

    func validateFetched(as downloadType: DownloadType) throws -> AttachmentDocumentInfo {
        if !downloadType.isThumbnailType {
            try attachment.validatePayloadHash()
        }
        try attachment.validatePayloadType()
        return self
    }
}

extension AttachmentDocumentInfo {
    var fullAttachmentId: String? {
        attachment.attachmentId
    }
    var data: Data? {
        document.data
    }

    var tripleIdentifier: String? {
        guard let fullID = attachment.attachmentId, thumbnailsIDs.count == 2 else {
            return nil
        }

        let mediumID = thumbnailsIDs[.mediumHeight] ?? fullID
        let smallID = thumbnailsIDs[.smallHeight] ?? thumbnailsIDs[.mediumHeight] ?? fullID
        return [AttachmentDocumentInfo.tripleIdentifierPrefix, fullID, mediumID, smallID].joined(separator: String(AttachmentDocumentInfo.thumbnailIdentifierSeparator))
    }

    func attachmentThumbnailIdentifier(for downloadType: DownloadType) -> String? {
        switch downloadType {
        case .full:
            return fullAttachmentId
        case .medium:
            return thumbnailsIDs[.mediumHeight] ?? fullAttachmentId
        case .small:
            return thumbnailsIDs[.smallHeight] ?? thumbnailsIDs[.mediumHeight] ?? fullAttachmentId
        }
    }

    private func thumbnailDisplayIdentifier(for downloadType: DownloadType) -> String? {
        guard let fullID = attachment.attachmentId,
              let thumbnailHeight = downloadType.thumbnailHeight,
              let thumbnailID = thumbnailsIDs[thumbnailHeight] else {
            return nil
        }
        return [fullID, thumbnailID].joined(separator: String(AttachmentDocumentInfo.thumbnailIdentifierSeparator))
    }
}

extension AttachmentDocumentInfo {
    private static func thumbnailIdentifiers(for attachmentId: String, from resourceWithAttachments: HasAttachments) throws -> [ThumbnailHeight: String] {
        guard let customIdentifiableResource = resourceWithAttachments as? CustomIdentifiable,
              let identifiers = customIdentifiableResource.customIdentifiers,
              let combinedIdentifier = identifiers
                .compactMap({$0.valueString})
                .first(where: { $0.contains(attachmentId) }) else {
            return [:]
        }

        let singleIdentifiers = combinedIdentifier.split(separator: AttachmentDocumentInfo.thumbnailIdentifierSeparator)
        guard singleIdentifiers.count == 4 else {
            throw Data4LifeSDKError.malformedAttachmentAdditionalId
        }
        return [ThumbnailHeight.mediumHeight: String(singleIdentifiers[2]),
                ThumbnailHeight.smallHeight: String(singleIdentifiers[3])]
    }
}
