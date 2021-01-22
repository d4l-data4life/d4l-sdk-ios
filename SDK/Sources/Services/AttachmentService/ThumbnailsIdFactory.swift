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

    static let splitChar: Character = "#"
    static let downscaledAttachmentIdsFormat = "d4l_f_p_t"

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

    static func displayAttachmentId(_ attachmentId: String, for documentId: String?) -> String {
        guard let documentId = documentId else { return attachmentId }
        return "\(attachmentId)\(splitChar)\(documentId)"
    }
}
