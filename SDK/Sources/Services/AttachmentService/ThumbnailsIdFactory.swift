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

struct ThumbnailsIdFactory {

    private static let splitChar: Character = "#"
    private static let downscaledAttachmentIdsFormat = "d4l_f_p_t"

    static func createAdditionalId(from attachmentWithIds: (attachment: AttachmentType, thumbnailIds: [String])) -> String? {
        let attachment = attachmentWithIds.0
        let ids = attachmentWithIds.1

        guard !ids.isEmpty, let attachmentId = attachment.attachmentId, ids.count == 2 else {
            return nil
        }

        var additionalAttachmentId = "\(downscaledAttachmentIdsFormat)\(splitChar)\(attachmentId)"
        for additionalId in ids {
            additionalAttachmentId.append("\(splitChar)\(additionalId)")
        }

        return additionalAttachmentId
    }

    static func setDocumentId(additionalId: String, for downloadType: DownloadType) throws -> String? {
        guard additionalId.contains(downscaledAttachmentIdsFormat) else {
            return nil
        }
        let ids = additionalId.split(separator: splitChar)
        guard ids.count == 4 else {
            throw Data4LifeSDKError.malformedAttachmentAdditionalId
        }

        var selectedId: String?

        switch downloadType {
        case .full:
            selectedId = String(ids[1])
        case .medium:
            selectedId = String(ids[2])
        case .small:
            selectedId = String(ids[3])
        }

        return selectedId
    }

    static func cleanObsoleteAdditionalIdentifiers<R: FhirSDKResource>(_ resource: R) throws -> R {
        guard
            let resourceWithIdentifiableAttachments = resource as? HasIdentifiableAttachments,
            let identifiers = resourceWithIdentifiableAttachments.customIdentifiers
        else {
            return resource
        }

        let currentAttachmentsIds = resourceWithIdentifiableAttachments.allAttachments?.compactMap { $0.attachmentId }

        let updatedIdentifiers = try identifiers.compactMap { identifier -> FhirIdentifierType? in
            guard identifier.valueString?.contains(downscaledAttachmentIdsFormat) ?? false else {
                return identifier
            }
            guard
                let ids = identifier.valueString?.split(separator: splitChar),
                ids.count == 4
            else {
                let resourceId = resource.fhirIdentifier ?? "Not available"
                throw Data4LifeSDKError.invalidAttachmentAdditionalId("Resource Id: \(resourceId)")
            }

            let attachmentId = String(ids[1])
            let identifierIsInUse = currentAttachmentsIds?.contains(attachmentId) ?? false

            return identifierIsInUse ? identifier : nil
        }
        resourceWithIdentifiableAttachments.customIdentifiers = updatedIdentifiers.isEmpty ? nil : updatedIdentifiers
        return resource
    }

    static func displayAttachmentId(_ attachmentId: String, for documentId: String?) -> String {
        guard let documentId = documentId else { return attachmentId }
        return "\(attachmentId)\(splitChar)\(documentId)"
    }
}
