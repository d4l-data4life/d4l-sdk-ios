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
                           key: Key) -> SDKFuture<[UnfoldedAttachmentDocument]>
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
                           key: Key) -> SDKFuture<[UnfoldedAttachmentDocument]> {

        return combineAsync {

            let unfoldedDocuments = try attachments.map { attachment -> UnfoldedAttachmentDocument in
                guard let base64EncodedString = attachment.attachmentDataString, let data = Data(base64Encoded: base64EncodedString) else {
                    throw Data4LifeSDKError.invalidAttachmentMissingData
                }
                do { try attachment.validatePayloadType() } catch { throw Data4LifeSDKError.invalidAttachmentPayloadType }
                do { try attachment.validatePayloadSize() } catch { throw Data4LifeSDKError.invalidAttachmentPayloadSize }

                return UnfoldedAttachmentDocument(attachment: attachment,
                                            document: AttachmentDocument(data: data))
            }

            let identifiedDocumentFutures = unfoldedDocuments.map { unfoldedDocument -> (String, SDKFuture<UnfoldedAttachmentDocument>) in
                let identifier = UUID().uuidString
                let future = self.documentService.create(document: unfoldedDocument.document, key: key)
                    .map { document -> UnfoldedAttachmentDocument in
                        let newAttachment = unfoldedDocument.attachment.copy() as! AttachmentType
                        newAttachment.attachmentId = document.id
                        return UnfoldedAttachmentDocument(attachment: newAttachment, document: document)
                    }
                    .asyncFuture()
                return (identifier, future)
            }

            let combineResult = combineAwait(identifiedDocumentFutures)
            try combineResult.throwIfErrored()

            let identifiedUnfoldedDocuments = combineResult.successRequests.map { $0.1 }
            let identifiedUnfoldedDocumentsWithThumbnailsIds = try identifiedUnfoldedDocuments.map { identifiedUnfoldedDocument -> UnfoldedAttachmentDocument in
                var thumbnailsIds: [ThumbnailHeight: String]?
                if let attachmentId = identifiedUnfoldedDocument.id, self.imageResizer.isImageData(identifiedUnfoldedDocument.document.data) {
                    thumbnailsIds = try combineAwait(self.createThumbnails(attachmentId: attachmentId, originalData: identifiedUnfoldedDocument.document.data, key: key))
                }

                var identifiedUnfoldedDocument = identifiedUnfoldedDocument
                identifiedUnfoldedDocument.thumbnailsIDs = thumbnailsIds ?? [:]
                return identifiedUnfoldedDocument
            }
            return identifiedUnfoldedDocumentsWithThumbnailsIds
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
                do {
                    let resizedData = try self.imageResizer.resizedData(of: imageToResize, with: thumbnailHeight)
                    let uploaded = try combineAwait(self.documentService.create(document: AttachmentDocument(data: resizedData), key: key))
                    guard let thumbnailId = uploaded.id else {
                        // A created document should always have got an id
                        return [:]
                    }
                    thumbnailsIds[thumbnailHeight] = thumbnailId
                } catch Data4LifeSDKError.resizingImageSmallerThanOriginalOne {

                }
            }

            return thumbnailsIds
        }
    }

    func fetchAttachments(for resourceWithAttachments: HasAttachments,
                          attachmentIds: [String],
                          downloadType: DownloadType,
                          key: Key,
                          parentProgress: Progress) -> SDKFuture<[AttachmentType]> {
        return combineAsync {
            guard let attachments = resourceWithAttachments.allAttachments else { return [] }

            let filledAttachments = try attachments.compactMap { attachment -> AttachmentType? in
                guard let attachmentId = attachment.attachmentId, attachmentIds.contains(attachmentId) else { return nil }
                // Size validation has to be done from the fhir property in order to avoid the attachment's downloading time
                do { try attachment.validatePayloadSize() } catch {
                    throw Data4LifeSDKError.invalidAttachmentPayloadSize
                }

                var selectedDocumentId: String?
                if let resourceWithIdentifiableAttachments = resourceWithAttachments as? CustomIdentifiable, downloadType.isThumbnailType {
                    selectedDocumentId = try self.selectDocumentId(resourceWithIdentifiableAttachments, downloadType: downloadType, for: attachmentId)
                    attachment.attachmentId = ThumbnailsIdFactory.displayAttachmentId(attachmentId, for: selectedDocumentId)
                }

                let documentId: String = selectedDocumentId ?? attachmentId
                let data = try combineAwait(self.documentService.fetchDocument(withId: documentId, key: key, parentProgress: parentProgress)).data

                let attachmentCopy = attachment.copy() as! AttachmentType // swiftlint:disable:this force_cast
                attachmentCopy.attachmentDataString = data.base64EncodedString()

                do { try attachmentCopy.validatePayloadType() } catch {
                    throw Data4LifeSDKError.invalidAttachmentPayloadType
                }

                if downloadType.isThumbnailType {
                    attachmentCopy.attachmentHash = data.sha1Hash
                    attachmentCopy.attachmentSize = data.count
                } else {
                    do { try attachmentCopy.validatePayloadHash() } catch {
                        throw Data4LifeSDKError.invalidAttachmentPayloadHash
                    }
                }

                return attachmentCopy
            }

            return filledAttachments
        }
    }

    private func selectDocumentId(_ resourceWithIdentifiableAttachments: CustomIdentifiable, downloadType: DownloadType,
                                  for attachmentId: String) throws -> String? {
        guard let identifiers = resourceWithIdentifiableAttachments.customIdentifiers else { return attachmentId }

        let additionalIds = identifiers.compactMap { $0.valueString }

        let selectedDocumentId = try additionalIds.filter {
            return $0.contains(attachmentId)
        }.compactMap { additionalId -> String? in
            do {
                let documentId = try ThumbnailsIdFactory.setDocumentId(additionalId: additionalId, for: downloadType)
                return documentId
            } catch Data4LifeSDKError.malformedAttachmentAdditionalId {
                throw Data4LifeSDKError.invalidAttachmentAdditionalId("Attachment Id: \(attachmentId)")
            }
        }

        return selectedDocumentId.first ?? nil
    }
}
