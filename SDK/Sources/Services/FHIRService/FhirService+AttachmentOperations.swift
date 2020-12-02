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
import Then
import struct Data4LifeCrypto.Key

extension FhirService {

    func downloadFhirRecordWithAttachments<R: FhirSDKResource, DR: DecryptedRecord>(withId identifier: String,
                                                                                    of type: R.Type = R.self,
                                                                                    decryptedRecordType: DR.Type = DR.self) -> Promise<FhirRecord<R>> where DR.Resource == R {
        return async {
            let userId = try await(self.keychainService.get(.userId))
            let decryptedRecord = try await(self.recordService.fetchRecord(recordId: identifier, userId: userId, of: type, decryptedRecordType: decryptedRecordType))
            let record = FhirRecord<R>(decryptedRecord: decryptedRecord)
            guard let attachmentKey = decryptedRecord.attachmentKey else { return record }

            if let resourceWithAttachments = record.fhirResource as? HasAttachments {
                let ids = resourceWithAttachments.allAttachments?.compactMap { $0.attachmentId }
                let downloadedAttachments: [Data4LifeFHIR.Attachment] = try await(self.attachmentService.fetchAttachments(of: Attachment.self,
                                                                                                                          for: resourceWithAttachments,
                                                                                                                          attachmentIds: ids ?? [],
                                                                                                                          downloadType: .full,
                                                                                                                          key: attachmentKey,
                                                                                                                          parentProgress: Progress()))
                var downloadedGenericAttachments = downloadedAttachments as [AttachmentType]
                let newAttachmentSchema = try resourceWithAttachments.makeFilledSchema(byMatchingTo: &downloadedGenericAttachments)
                resourceWithAttachments.updateAttachments(from: newAttachmentSchema)
            }

            return record
        }
    }

    func uploadAttachments<R: FhirSDKResource>(creating resource: R) -> Promise<(resource: R,  key: Key?)> {
        return async {
            guard let resourceWithAttachments = resource as? HasAttachments else {
                return (resource, nil)
            }

            guard let validatedAttachments = try resourceWithAttachments.validateAttachments() as? [Data4LifeFHIR.Attachment] else {
                return (resource, nil)
            }

            let generatedKey = try await(self.cryptoService.generateGCKey(.attachment))
            let uploadedAttachmentsWithIds: [(Data4LifeFHIR.Attachment, [String])]  = try await(self.attachmentService.uploadAttachments(validatedAttachments,
                                                                                                                                         key: generatedKey))
            var uploadedAttachments = uploadedAttachmentsWithIds.map { $0.0 } as [AttachmentType]

            let newAttachmentSchema = try resourceWithAttachments.makeFilledSchema(byMatchingTo: &uploadedAttachments)
            resourceWithAttachments.updateAttachments(from: newAttachmentSchema)
            resourceWithAttachments.allAttachments?.forEach { $0.attachmentData = nil }

            if let resourceWithIdentifier = resourceWithAttachments as? HasIdentifiableAttachments {
                let thumbnailAdditionalIdentifiers = uploadedAttachmentsWithIds.compactMap { ThumbnailsIdFactory.createAdditionalId(from: $0) }
                resourceWithIdentifier.updateIdentifiers(additionalIds: thumbnailAdditionalIdentifiers)
            }

            return (resource, generatedKey)
        }
    }

    func uploadAttachments<R: FhirSDKResource, DR: DecryptedRecord>(updating resource: R, decryptedRecordType: DR.Type = DR.self) -> Promise<(resource: R,  key: Key?)> {
        return async {
            let userId = try await(self.keychainService.get(.userId))
            guard let recordId = resource.fhirIdentifier else { throw Data4LifeSDKError.invalidResourceMissingId }

            guard
                let resourceWithAttachments = resource as? HasAttachments,
                let attachments = resourceWithAttachments.allAttachments else {
                return (resource, nil)
            }

            let remoteRecord = try await(self.recordService.fetchRecord(recordId: recordId, userId: userId, of: R.self, decryptedRecordType: decryptedRecordType))
            //Gets all Attachments without data
            let remoteAttachments = (remoteRecord.resource as? HasAttachments)?.allAttachments as? [Attachment] ?? []
            let newKey = try await(self.cryptoService.generateGCKey(.attachment))
            let attachmentKey = remoteRecord.attachmentKey ?? newKey

            let classifiedAttachments = self.compareAttachments(local: attachments, remote: remoteAttachments)
            let preparedModifiedAttachments = self.updateDataFields(in: classifiedAttachments.modified)

            let validatedAttachmentsToUpload = try (preparedModifiedAttachments + classifiedAttachments.new).validate() as? [Attachment] ?? []

            let uploadedAttachmentsWithIds = try await(self.uploadAttachments(validatedAttachmentsToUpload, attachmentKey: attachmentKey))
            let uploadedAttachments = uploadedAttachmentsWithIds.map { $0.0 }
            var allFilledAttachments = classifiedAttachments.unmodified + uploadedAttachments
            let newAttachmentSchema = try resourceWithAttachments.makeFilledSchema(byMatchingTo: &allFilledAttachments)
            resourceWithAttachments.updateAttachments(from: newAttachmentSchema)

            // We don't wanna upload base64 encoded data (in case of old downloaded attachments)
            resourceWithAttachments.allAttachments?.forEach { $0.attachmentData = nil }

            if let resourceWithIdentifier = resourceWithAttachments as? HasIdentifiableAttachments {
                resourceWithIdentifier.updateIdentifiers(additionalIds: uploadedAttachmentsWithIds.compactMap { ThumbnailsIdFactory.createAdditionalId(from: $0) })
            }

            let cleanedResource = try ThumbnailsIdFactory.cleanObsoleteAdditionalIdentifiers(resource)

            return (cleanedResource, attachmentKey)
        }
    }
}

// MARK: - Utils
extension FhirService {

    private func uploadAttachments(
        _ attachments: [Attachment],
        attachmentKey: Key) -> Promise<[(attachment: Attachment, thumbnailIds: [String])]> {
        return async {
            if attachments.isEmpty == false {
                let updatedAttachmentsWithThumbnailsIds: [(Data4LifeFHIR.Attachment, [String])] = try await(self.attachmentService.uploadAttachments(attachments,
                                                                                                                                                     key: attachmentKey))
                return updatedAttachmentsWithThumbnailsIds
            } else {
                return []
            }
        }
    }
}
