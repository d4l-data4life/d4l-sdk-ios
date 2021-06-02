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
                let futureIdentifier = UUID().uuidString
                let mainAttachmentFuture = self.documentService
                    .create(document: unfoldedDocument.document, key: key)
                    .compactMap { document -> UnfoldedAttachmentDocument? in
                        guard let newAttachment = unfoldedDocument.attachment.copy() as? AttachmentType else {
                            return nil
                        }
                        newAttachment.attachmentId = document.id
                        return UnfoldedAttachmentDocument(attachment: newAttachment, document: document)
                    }
                    .asyncFuture()
                let thumbnailsFuture = self.createThumbnails(originalData: unfoldedDocument.document.data, key: key)
                let combinedFuture = Publishers.CombineLatest(mainAttachmentFuture, thumbnailsFuture)
                    .map { tuple -> UnfoldedAttachmentDocument in
                        let attachmentDocument = tuple.0
                        let thumbnailIds = tuple.1
                        return UnfoldedAttachmentDocument(attachment: attachmentDocument.attachment,
                                                          document: attachmentDocument.document,
                                                          thumbnailsIDs: thumbnailIds)
                    }.asyncFuture()
                return (futureIdentifier, combinedFuture)
            }

            let combineResult = combineAwait(identifiedDocumentFutures)
            try combineResult.throwIfErrored()

            let identifiedUnfoldedDocumentsWithThumbnailsIds = combineResult.successRequests.map { $0.1 }
            return identifiedUnfoldedDocumentsWithThumbnailsIds
        }
    }

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
                let resizedDocument = AttachmentDocument(data: resizedData)
                let futureIdentifier = UUID().uuidString
                let future = self.documentService
                    .create(document: resizedDocument, key: key)
                    .compactMap { document -> (ThumbnailHeight, String)? in
                        guard let id = document.id else {
                            return nil
                        }
                        return (thumbnailHeight, id)
                    }
                    .asyncFuture()
                return (futureIdentifier, future)
            }

            let result = combineAwait(singleThumbnailFutures)
            try result.throwIfErrored()
            return Dictionary(result.successRequests.map { $0.1 }, uniquingKeysWith: { $1 })
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
