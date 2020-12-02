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
import Then
@testable import Data4LifeSDK
@testable import Data4LifeCrypto
import Data4LifeFHIR

class AttachmentServiceMock<MA: AttachmentType>: AttachmentServiceType {
    var fetchAttachmentsCalledWith: (HasAttachments, [String], DownloadType, Key, Progress)?
    var fetchAttachmentsResult: Async<[MA]>?
    func fetchAttachments<A: AttachmentType>(of type: A.Type,
                                             for resourceWithAttachments: HasAttachments,
                                             attachmentIds: [String],
                                             downloadType: DownloadType,
                                             key: Key,
                                             parentProgress: Progress) -> Promise<[A]> {
        fetchAttachmentsCalledWith = (resourceWithAttachments, attachmentIds, downloadType, key, parentProgress)
        return fetchAttachmentsResult as? Async<[A]> ?? Async.reject()
    }

    var uploadAttachmentsCalledWith: ([MA], Key)?
    var uploadAttachmentsResult: Async<[(attachment: MA, thumbnailIds: [String])]>?
    var uploadAttachmentsResults: [Async<[(attachment: MA, thumbnailIds: [String])]>]?

    func uploadAttachments<A: AttachmentType>(_ attachments: [A], key: Key) -> Promise<[(attachment: A, thumbnailIds: [String])]> {

        uploadAttachmentsCalledWith = (attachments as! [MA], key) // swiftlint:disable:this force_cast
        if let results = uploadAttachmentsResults, let first = results.first as? Async<[(attachment: A, thumbnailIds: [String])]> {
            uploadAttachmentsResults = Array(results.dropFirst())
            return first
        }
        return uploadAttachmentsResult as? Async<[(attachment: A, thumbnailIds: [String])]> ?? Async.reject()
    }
}
