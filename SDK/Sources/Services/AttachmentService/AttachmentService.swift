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
import Data4LifeFHIR
import Data4LifeCrypto
import Then

protocol AttachmentServiceType {
    func uploadAttachments<A: AttachmentType>(_ attachments: [A],
                                              key: Key) -> Promise<[(attachment: A, thumbnailIds: [String])]>
    func fetchAttachments<A: AttachmentType>(of type: A.Type,
                                             for resourceWithAttachments: HasAttachments,
                                             attachmentIds: [String],
                                             downloadType: DownloadType,
                                             key: Key,
                                             parentProgress: Progress) -> Promise<[A]>
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

    func uploadAttachments<A: AttachmentType>(_ attachments: [A],
                                              key: Key) -> Promise<[(attachment: A, thumbnailIds: [String])]> {
        return async {
            let documentsWithAdditionalIds = try attachments.map { attachment -> (A, [String]) in
                guard let base64EncodedString = attachment.attachmentData, let data = Data(base64Encoded: base64EncodedString) else {
                    throw Data4LifeSDKError.invalidAttachmentMissingData
                }
                do { try attachment.validatePayloadType() } catch { throw Data4LifeSDKError.invalidAttachmentPayloadType }
                do { try attachment.validatePayloadSize() } catch { throw Data4LifeSDKError.invalidAttachmentPayloadSize }

                let document = Document(data: data)
                let uploaded = try await(self.documentService.create(document: document, key: key))

                var thumbnailsIds: [String]?
                if let attachmentId = uploaded.id {
                    if self.imageResizer.isResizable(document.data) {
                        thumbnailsIds = try await(self.createThumbnails(attachmentId: attachmentId, originalData: document.data, key: key))
                    }
                }

                let attachmentCopy = attachment.copy() as! A // swiftlint:disable:this force_cast
                attachmentCopy.attachmentId = uploaded.id
                return (attachmentCopy, thumbnailsIds ?? [])
            }

            return documentsWithAdditionalIds
        }
    }

    func fetchAttachments<A: AttachmentType>(of type: A.Type = A.self,
                                             for resourceWithAttachments: HasAttachments,
                                             attachmentIds: [String],
                                             downloadType: DownloadType,
                                             key: Key,
                                             parentProgress: Progress) -> Promise<[A]> {
        return async {
            guard let attachments = resourceWithAttachments.allAttachments else { return [] }

            let filledAttachments = try attachments.compactMap { attachment -> A? in
                guard let attachmentId = attachment.attachmentId, attachmentIds.contains(attachmentId) else { return nil }
                //Size validation has to be done from the fhir property in order to avoid the attachment's downloading time
                do { try attachment.validatePayloadSize() } catch {
                    throw Data4LifeSDKError.invalidAttachmentPayloadSize
                }

                var selectedDocumentId: String?
                if let resourceWithIdentifiableAttachments = resourceWithAttachments as? HasIdentifiableAttachments,
                    downloadType.isThumbnailType {
                    selectedDocumentId = try self.selectDocumentId(resourceWithIdentifiableAttachments, downloadType: downloadType, for: attachmentId)
                    attachment.attachmentId = ThumbnailsIdFactory.displayAttachmentId(attachmentId, for: selectedDocumentId)
                }

                let documentId: String = selectedDocumentId ?? attachmentId
                let data = try await(self.documentService.fetchDocument(withId: documentId, key: key, parentProgress: parentProgress)).data

                let attachmentCopy = attachment.copy() as! A // swiftlint:disable:this force_cast
                attachmentCopy.attachmentData = data.base64EncodedString()

                do { try attachmentCopy.validatePayloadType() } catch {
                    throw Data4LifeSDKError.invalidAttachmentPayloadType
                }

                if downloadType.isThumbnailType {
                    //Update hash and size for thumbnails attachments
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
                                  key: Key) -> Promise<[String]> {
        return async {
            //Convert imageData to UIImage
            guard let imageToResize = UIImage(data: originalData) else {
                //Data is not an image. This case should never happen, because the mimeType is actually an image
                return []
            }

            var thumbnailsIds = [String]()

            for imageSize in ImageSize.allCases {
                let selectedSize = self.imageResizer.getSize(imageSize, for: imageToResize)
                do {
                    guard let resizedData = try self.imageResizer.resize(imageToResize, for: selectedSize) else {
                        //This case should never happen
                        return []
                    }

                    let uploaded = try await(self.documentService.create(document: Document(data: resizedData), key: key))
                    guard let thumbnailId = uploaded.id else {
                        //A created document should always have got an id
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

    private func selectDocumentId(_ resourceWithIdentifiableAttachments: HasIdentifiableAttachments, downloadType: DownloadType,
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
