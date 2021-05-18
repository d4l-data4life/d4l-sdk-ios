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
                           key: Key) -> SDKFuture<[(attachment: AttachmentType, thumbnailIds: [String])]>
    func fetchAttachments(for resourceWithAttachments: HasAttachments,
                          attachmentIds: [String],
                          downloadType: DownloadType,
                          key: Key,
                          parentProgress: Progress) -> SDKFuture<[AttachmentType]>
}

final class AttachmentService: AttachmentServiceType {

    let documentService: DocumentServiceType
    let imageResizer: Resizable

    init(container: DIContainer) {
        do {
            self.documentService = try container.resolve()
            self.imageResizer = try container.resolve()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func uploadAttachments(_ attachments: [AttachmentType],
                           key: Key) -> SDKFuture<[(attachment: AttachmentType, thumbnailIds: [String])]> {
        return combineAsync {
            let documentsWithAdditionalIds = try attachments.map { attachment -> (AttachmentType, [String]) in
                guard let base64EncodedString = attachment.attachmentDataString, let data = Data(base64Encoded: base64EncodedString) else {
                    throw Data4LifeSDKError.invalidAttachmentMissingData
                }
                do { try attachment.validatePayloadType() } catch { throw Data4LifeSDKError.invalidAttachmentPayloadType }
                do { try attachment.validatePayloadSize() } catch { throw Data4LifeSDKError.invalidAttachmentPayloadSize }

                let document = Document(data: data)
                let uploaded = try combineAwait(self.documentService.create(document: document, key: key))

                var thumbnailsIds: [String]?
                if let attachmentId = uploaded.id {
                    if self.imageResizer.isResizable(document.data) {
                        thumbnailsIds = try combineAwait(self.createThumbnails(attachmentId: attachmentId, originalData: document.data, key: key))
                    }
                }

                let attachmentCopy = attachment.copy() as! AttachmentType // swiftlint:disable:this force_cast
                attachmentCopy.attachmentId = uploaded.id
                return (attachmentCopy, thumbnailsIds ?? [])
            }

            return documentsWithAdditionalIds
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
                if let resourceWithIdentifiableAttachments = resourceWithAttachments as? CustomIdentifiable,
                    downloadType.isThumbnailType {
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
                    // Update hash and size for thumbnails attachments
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

    private func createThumbnails(attachmentId: String,
                                  originalData: Data,
                                  key: Key) -> SDKFuture<[String]> {
        return combineAsync {
            // Convert imageData to UIImage
            guard let imageToResize = UIImage(data: originalData) else {
                // Data is not an image. This case should never happen, because the mimeType is actually an image
                return []
            }

            var thumbnailsIds = [String]()

            for imageSize in ImageSize.allCases {
                let selectedSize = self.imageResizer.getSize(imageSize, for: imageToResize)
                do {
                    guard let resizedData = try self.imageResizer.resize(imageToResize, for: selectedSize) else {
                        // This case should never happen
                        return []
                    }

                    let uploaded = try combineAwait(self.documentService.create(document: Document(data: resizedData), key: key))
                    guard let thumbnailId = uploaded.id else {
                        // A created document should always have got an id
                        return []
                    }
                    thumbnailsIds.append(thumbnailId)
                } catch Data4LifeSDKError.resizingImageSmallerThanOriginalOne {
                        thumbnailsIds.append(attachmentId)
                }
            }

            return thumbnailsIds
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
