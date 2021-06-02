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
    let data: Data

    init(id: String? = nil, data: Data) {
        self.id = id
        self.data = data
    }
}

struct UnfoldedAttachmentDocument {

    private static var tripleIdentifierPrefix = "d4l_f_p_t"
    private static var thumbnailIdentifierSeparator = "#"

    var attachment: AttachmentType
    var document: AttachmentDocument
    var thumbnailsIDs: [ThumbnailHeight: String] = [:]
    var id: String? {
        attachment.attachmentId
    }
    var data: Data {
        document.data
    }
}

extension UnfoldedAttachmentDocument {
    var tripleIdentifier: String? {
        guard let fullID = attachment.attachmentId, thumbnailsIDs.count == 2 else {
            return nil
        }

        let mediumID = thumbnailsIDs[.mediumHeight] ?? fullID
        let smallID = thumbnailsIDs[.smallHeight] ?? thumbnailsIDs[.mediumHeight] ?? fullID
        return [UnfoldedAttachmentDocument.tripleIdentifierPrefix, fullID, mediumID, smallID].joined(separator: UnfoldedAttachmentDocument.thumbnailIdentifierSeparator)
    }

    func thumbnailIdentifier(for height: ThumbnailHeight) -> String? {
        guard let fullID = attachment.attachmentId, let thumbnailID = thumbnailsIDs[height] else {
            return nil
        }
        return [fullID, thumbnailID].joined(separator: UnfoldedAttachmentDocument.thumbnailIdentifierSeparator)
    }
}
