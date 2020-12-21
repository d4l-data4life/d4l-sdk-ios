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
@testable import Data4LifeSDK

extension AttachmentType {
    func copyWithId(_ id: String? = nil) -> Self {
        let attachment = copy() as! Self // swiftlint:disable:this force_cast
        if let id = id {
            attachment.attachmentId = id
        }
        return attachment
    }
}

extension AttachmentType {
    var testable: AnyAttachmentType {
        AnyAttachmentType(attachmentType: self)
    }
}

final class AnyAttachmentType: AttachmentType, Equatable {

    private let attachment: AttachmentType
    init(attachmentType: AttachmentType) {
        self.attachment = attachmentType
    }

    var attachmentId: String? {
        get { attachment.attachmentId }
        set { attachment.attachmentId = newValue }
    }

    var attachmentContentType: String? {
        get { attachment.attachmentContentType }
        set { attachment.attachmentContentType = newValue }
    }

    var attachmentDataString: String? {
        get { attachment.attachmentDataString }
        set { attachment.attachmentDataString = newValue }
    }

    var attachmentHash: String? {
        get { attachment.attachmentHash }
        set { attachment.attachmentHash = newValue }
    }

    var attachmentSize: Int? {
        get { attachment.attachmentSize }
        set { attachment.attachmentSize = newValue }
    }

    var creationDate: Date? {
        get { attachment.creationDate }
        set { attachment.creationDate = newValue }
    }

    var attachmentData: Data? { attachment.attachmentData }

    func copy(with zone: NSZone? = nil) -> Any {
        return attachment.copy(with: nil)
    }

    static func == (lhs: AnyAttachmentType, rhs: AnyAttachmentType) -> Bool {
        lhs.attachmentId == rhs.attachmentId &&
            lhs.attachmentContentType == rhs.attachmentContentType &&
            lhs.attachmentDataString == rhs.attachmentDataString &&
            lhs.attachmentHash == rhs.attachmentHash &&
            lhs.attachmentSize == rhs.attachmentSize &&
            lhs.attachmentData == rhs.attachmentData &&
            lhs.attachmentDataString == rhs.attachmentDataString &&
            lhs.creationDate == rhs.creationDate
    }
}
