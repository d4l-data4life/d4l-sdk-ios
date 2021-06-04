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
    private let imageResizer: DataResizer

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

            let attachmentDocumentInfos = try attachments.map { try AttachmentDocumentInfo.makeForUploadRequest(attachment: $0) }

            let identifiedCreateDocumentFutures = attachmentDocumentInfos.compactMap { attachmentDocumentInfo -> (String, SDKFuture<AttachmentDocumentInfo>)? in
                guard let attachmentData = attachmentDocumentInfo.document.data else {
                    return nil
                }
                let futureIdentifier = "combined attachment upload: " + UUID().uuidString

                let mainAttachmentFuture = self
                    .documentService.create(document: attachmentDocumentInfo.document, key: key)
                    .compactMap { attachmentDocumentInfo.updatingInfo(withCreated: $0) }
                    .asyncFuture()

                let thumbnailsFuture = self
                    .createThumbnails(originalData: attachmentData, key: key)

                let combinedFuture = Publishers.CombineLatest(mainAttachmentFuture, thumbnailsFuture)
                    .map { tuple -> AttachmentDocumentInfo in
                        let attachmentDocument = tuple.0
                        let thumbnailIds = tuple.1
                        return AttachmentDocumentInfo(document: attachmentDocument.document,
                                                      attachment: attachmentDocument.attachment,
                                                      thumbnailsIDs: thumbnailIds)
                    }.asyncFuture()

                return (futureIdentifier, combinedFuture)
            }

            let combineResult = try combineAwait(identifiedCreateDocumentFutures).throwIfErrored()
            return combineResult.values
        }
    }

    func fetchAttachments(for resourceWithAttachments: HasAttachments,
                          attachmentIds: [String],
                          downloadType: DownloadType,
                          key: Key,
                          parentProgress: Progress) -> SDKFuture<[AttachmentType]> {

        return combineAsync {

            let attachmentDocumentInfos = try AttachmentDocumentInfo.makeForFetchRequest(resource: resourceWithAttachments, attachmentIdentifiers: attachmentIds)

            let identifiedDocumentFutures = attachmentDocumentInfos.compactMap { attachmentDocumentInfo -> (String, SDKFuture<AttachmentType>)? in
                guard let fullAttachmentId = attachmentDocumentInfo.document.id else {
                    return nil
                }
                let futureIdentifier = "attachment fetch: " + UUID().uuidString
                let attachmentIdToFetch = attachmentDocumentInfo.attachmentThumbnailIdentifier(for: downloadType) ?? fullAttachmentId
                let fetchAttachmentFuture = self.documentService
                    .fetchDocument(withId: attachmentIdToFetch, key: key, parentProgress: parentProgress)
                    .tryCompactMap { try attachmentDocumentInfo.updatingInfo(withFetched: $0, for: downloadType) }
                    .tryMap { try $0.validateFetched(as: downloadType).attachment }
                    .asyncFuture()

                return (futureIdentifier, fetchAttachmentFuture)
            }

            let combineResult = try combineAwait(identifiedDocumentFutures).throwIfErrored()
            return combineResult.values
        }
    }
}

extension AttachmentService {
    private func createThumbnails(originalData: Data,
                                  key: Key) -> SDKFuture<[ThumbnailHeight: String]> {
        return combineAsync {
            guard let imageToResize = UIImage(data: originalData) else {
                return [:]
            }

            let singleThumbnailFutures = ThumbnailHeight.allCases.compactMap { thumbnailHeight -> (String, SDKFuture<(ThumbnailHeight, String)>)? in
                guard let resizedData = try? self.imageResizer.resizedData(of: imageToResize, with: thumbnailHeight) else {
                    return nil
                }

                let futureIdentifier = "thumbnail upload: " + UUID().uuidString
                let createDocumentFuture: SDKFuture<(ThumbnailHeight, String)> = combineAsync { () -> (ThumbnailHeight, String?) in
                    let document = try combineAwait(self.documentService.create(document: AttachmentDocument(data: resizedData), key: key))
                    return (thumbnailHeight, document.id)
                }
                .compactMap { tuple -> (ThumbnailHeight, String)? in
                    guard let id = tuple.1 else {
                        return nil
                    }
                    return (tuple.0, id)
                }
                .asyncFuture()
                return (futureIdentifier, createDocumentFuture)
            }

            let result = try combineAwait(singleThumbnailFutures).throwIfErrored()

            var dictionary: [ThumbnailHeight: String] = [:]
            result.values.forEach { tuple in
                dictionary[tuple.0] = tuple.1
            }
            return dictionary
        }
    }
}
