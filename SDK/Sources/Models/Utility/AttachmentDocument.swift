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

struct AttachmentDocumentContext {
    static var tripleIdentifierPrefix = "d4l_f_p_t"
    static var thumbnailIdentifierSeparator: Character = "#"

    private(set) var document: AttachmentDocument
    private(set) var attachment: AttachmentType
    private(set) var thumbnailsIDs: [ThumbnailHeight: String] = [:]
}

extension AttachmentDocumentContext {
    static func makeForAllFetchRequests(for resource: HasAttachments, attachmentIdentifiers: [String]) throws -> [AttachmentDocumentContext] {
        guard let attachments = resource.allAttachments else { return [] }
        return try attachments.compactMap { attachment -> AttachmentDocumentContext? in

            guard let attachmentId = attachment.attachmentId, attachmentIdentifiers.contains(attachmentId) else { return nil }
            let document = AttachmentDocument(id: attachmentId)
            let thumbnailIDs = try thumbnailIdentifiers(for: attachmentId, from: resource)
            return AttachmentDocumentContext(document: document, attachment: attachment,
                                          thumbnailsIDs: thumbnailIDs)
        }
    }

    static func makeForUploadRequest(attachment: AttachmentType) throws -> AttachmentDocumentContext {

        guard let base64EncodedString = attachment.attachmentDataString, let data = Data(base64Encoded: base64EncodedString) else {
            throw Data4LifeSDKError.invalidAttachmentMissingData
        }

        return AttachmentDocumentContext(document: AttachmentDocument(data: data),
                                      attachment: attachment)
    }
}

extension AttachmentDocumentContext {
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
        return [AttachmentDocumentContext.tripleIdentifierPrefix, fullID, mediumID, smallID].joined(separator: String(AttachmentDocumentContext.thumbnailIdentifierSeparator))
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
}

extension AttachmentDocumentContext {
    private static func thumbnailIdentifiers(for attachmentId: String, from resourceWithAttachments: HasAttachments) throws -> [ThumbnailHeight: String] {
        guard let customIdentifiableResource = resourceWithAttachments as? CustomIdentifiable,
              let identifiers = customIdentifiableResource.customIdentifiers,
              let combinedIdentifier = identifiers
                .compactMap({$0.valueString})
                .first(where: { $0.contains(attachmentId) }) else {
            return [:]
        }

        let singleIdentifiers = combinedIdentifier.split(separator: AttachmentDocumentContext.thumbnailIdentifierSeparator)
        guard singleIdentifiers.count == 4 else {
            throw Data4LifeSDKError.malformedAttachmentAdditionalId
        }
        return [ThumbnailHeight.mediumHeight: String(singleIdentifiers[2]),
                ThumbnailHeight.smallHeight: String(singleIdentifiers[3])]
    }
}
