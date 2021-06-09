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
                           key: Key) -> SDKFuture<[AttachmentDocumentContext]>

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
                           key: Key) -> SDKFuture<[AttachmentDocumentContext]> {
        return combineAsync {
            return try attachments
                .map { try AttachmentDocumentContext.makeForUploadRequest(attachment: $0) }
                .map { try $0.validatedBeforeUploading() }
                .map { attachmentDocumentContext -> AttachmentDocumentContext in
                    let attachmentDocument = try combineAwait(self.documentService.create(document: attachmentDocumentContext.document, key: key))
                    return attachmentDocumentContext.updatingInfo(withCreated: attachmentDocument)
                }
                .map { attachmentDocumentContext -> AttachmentDocumentContext in
                    guard let data = attachmentDocumentContext.data,
                          let attachmentId = attachmentDocumentContext.fullAttachmentId,
                          self.imageResizer.isImageData(data) else {
                        return attachmentDocumentContext
                    }

                    let thumbnailsIds = try combineAwait(self.createThumbnails(attachmentId: attachmentId, originalData: data, key: key))
                    return attachmentDocumentContext.updatingThumbnailsIds(thumbnailsIds)
                }
        }
    }

    func fetchAttachments(for resourceWithAttachments: HasAttachments,
                          attachmentIds: [String],
                          downloadType: DownloadType,
                          key: Key,
                          parentProgress: Progress) -> SDKFuture<[AttachmentType]> {

        return combineAsync {
            return try AttachmentDocumentContext.makeForAllFetchRequests(for: resourceWithAttachments, attachmentIdentifiers: attachmentIds)
                .map { try $0.validatedBeforeDownloading() }
                .compactMap { attachmentDocumentContext -> AttachmentDocumentContext? in
                    guard let fullAttachmentId = attachmentDocumentContext.document.id else {
                        return nil
                    }

                    let attachmentIdToFetch = attachmentDocumentContext.attachmentThumbnailIdentifier(for: downloadType) ?? fullAttachmentId
                    let attachmentDocument = try combineAwait(self.documentService.fetchDocument(withId: attachmentIdToFetch, key: key, parentProgress: parentProgress))
                    return try attachmentDocumentContext.updatingInfo(withFetched: attachmentDocument, for: downloadType)
                }
                .map { try $0.validated(afterDownloadingWith: downloadType) }
                .map { $0.attachment }
        }
    }
}

extension AttachmentService {
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

fileprivate extension AttachmentDocumentContext {
    func updatingInfo(withCreated createdAttachmentDocument: AttachmentDocument) -> AttachmentDocumentContext {
        // swiftlint:disable force_cast
        let newAttachment = attachment.copy() as! AttachmentType
        newAttachment.attachmentId = createdAttachmentDocument.id
        return AttachmentDocumentContext(document: createdAttachmentDocument, attachment: newAttachment, thumbnailsIDs: thumbnailsIDs)
    }

    func updatingInfo(withFetched fetchedAttachmentDocument: AttachmentDocument, for downloadType: DownloadType) throws -> AttachmentDocumentContext {
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

        return AttachmentDocumentContext(document: fetchedAttachmentDocument,
                                         attachment: newAttachment,
                                         thumbnailsIDs: thumbnailsIDs)
    }

    func validatedBeforeUploading() throws -> AttachmentDocumentContext {
        try attachment.validatePayloadType()
        try attachment.validatePayloadSize()
        return self
    }

    func validatedBeforeDownloading() throws -> AttachmentDocumentContext {
        try attachment.validatePayloadSize()
        return self
    }

    func validated(afterDownloadingWith downloadType: DownloadType) throws -> AttachmentDocumentContext {
        if !downloadType.isThumbnailType {
            try attachment.validatePayloadHash()
        }
        try attachment.validatePayloadType()
        return self
    }

    func thumbnailDisplayIdentifier(for downloadType: DownloadType) -> String? {
        guard let fullID = attachment.attachmentId,
              let thumbnailHeight = downloadType.thumbnailHeight,
              let thumbnailID = thumbnailsIDs[thumbnailHeight] else {
            return nil
        }
        return [fullID, thumbnailID].joined(separator: String(AttachmentDocumentContext.thumbnailIdentifierSeparator))
    }
}
