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
@_implementationOnly import Data4LifeCrypto
import Data4LifeFHIRCore
import Combine

protocol AttachmentServiceType {
    func uploadAttachments(_ attachments: [AttachmentType],
                           key: Key) -> SDKFuture<[AttachmentDocumentInfo]>

    func fetchAttachments(for resourceWithAttachments: HasAttachments,
                          attachmentIds: [String],
                          downloadType: DownloadType,
                          key: Key,
                          parentProgress: Progress) -> SDKFuture<[AttachmentType]>
}

final class AttachmentService: AttachmentServiceType {

    private let documentService: DocumentServiceType
    private let imageResizer: ImageResizer

    init(container: DIContainer) {
        do {
            self.documentService = try container.resolve()
            self.imageResizer = try container.resolve()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func uploadAttachments(_ attachments: [AttachmentType],
                           key: Key) -> SDKFuture<[AttachmentDocumentInfo]> {
        return combineAsync {
            return try attachments
                .map { try AttachmentDocumentInfo.makeForUploadRequest(attachment: $0) }
                .map { try $0.validatedBeforeUploading() }
                .map { attachmentDocumentInfo -> AttachmentDocumentInfo in
                    let attachmentDocument = try combineAwait(self.documentService.create(document: attachmentDocumentInfo.document, key: key))
                    return attachmentDocumentInfo.updatingInfo(withCreated: attachmentDocument)
                }
                .compactMap { attachmentDocumentInfo -> AttachmentDocumentInfo? in
                    guard let data = attachmentDocumentInfo.data,
                          let attachmentId = attachmentDocumentInfo.fullAttachmentId,
                          self.imageResizer.isImageData(data) else {
                        return attachmentDocumentInfo
                    }

                    let thumbnailsIds = try combineAwait(self.createThumbnails(attachmentId: attachmentId, originalData: data, key: key))
                    return AttachmentDocumentInfo(document: attachmentDocumentInfo.document,
                                                  attachment: attachmentDocumentInfo.attachment,
                                                  thumbnailsIDs: thumbnailsIds)
                }
        }
    }

    func fetchAttachments(for resourceWithAttachments: HasAttachments,
                          attachmentIds: [String],
                          downloadType: DownloadType,
                          key: Key,
                          parentProgress: Progress) -> SDKFuture<[AttachmentType]> {

        return combineAsync {
            let attachments = try AttachmentDocumentInfo.makeForFetchRequest(resource: resourceWithAttachments, attachmentIdentifiers: attachmentIds)
                .map { try $0.validatedBeforeDownloading() }
                .compactMap { attachmentDocumentInfo -> AttachmentDocumentInfo? in
                    guard let fullAttachmentId = attachmentDocumentInfo.document.id else {
                        return nil
                    }

                    let attachmentIdToFetch = attachmentDocumentInfo.attachmentThumbnailIdentifier(for: downloadType) ?? fullAttachmentId
                    let attachmentDocument = try combineAwait(self.documentService.fetchDocument(withId: attachmentIdToFetch, key: key, parentProgress: parentProgress))
                    return try attachmentDocumentInfo.updatingInfo(withFetched: attachmentDocument, for: downloadType)
                }
                .map { try $0.validated(afterDownloadingWith: downloadType) }
                .map { $0.attachment }
            return attachments
        }
    }

    private func createThumbnails(attachmentId: String,
                                  originalData: Data,
                                  key: Key) -> SDKFuture<[ThumbnailHeight: String]> {
        return combineAsync {
            guard let imageToResize = UIImage(data: originalData) else {
                return [:]
            }

            var thumbnailsIds = [ThumbnailHeight: String]()

            for thumbnailHeight in ThumbnailHeight.allCases {
                guard let resizedData = try? self.imageResizer.resizedData(imageToResize, for: thumbnailHeight) else {
                    continue
                }
                let uploaded = try combineAwait(self.documentService.create(document: AttachmentDocument(data: resizedData), key: key))
                thumbnailsIds[thumbnailHeight] = uploaded.id
            }

            return thumbnailsIds
        }
    }
}
