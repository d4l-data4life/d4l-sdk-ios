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
import Data4LifeFHIRCore
import Combine
@_implementationOnly import Data4LifeCrypto

extension FhirService {

    func downloadFhirRecordWithAttachments<DR: DecryptedRecord>(withId identifier: String,
                                                                decryptedRecordType: DR.Type = DR.self) -> SDKFuture<FhirRecord<DR.Resource>> where DR.Resource: FhirSDKResource {
        return combineAsync {
            let userId = try self.keychainService.get(.userId)
            let decryptedRecord = try combineAwait(self.recordService.fetchRecord(recordId: identifier, userId: userId, decryptedRecordType: decryptedRecordType))
            let record = FhirRecord<DR.Resource>(decryptedRecord: decryptedRecord)
            guard let attachmentKey = decryptedRecord.attachmentKey else { return record }

            if let resourceWithAttachments = record.fhirResource as? HasAttachments {
                let ids = resourceWithAttachments.allAttachments?.compactMap { $0.attachmentId }
                let downloadedAttachments: [AttachmentType] = try combineAwait(self.attachmentService.fetchAttachments(for: resourceWithAttachments,
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

    func uploadAttachments<R: FhirSDKResource>(creating resource: R) -> SDKFuture<(resource: R,  key: Key?)> {

        return combineAsync {
            guard let resourceWithAttachments = resource as? HasAttachments else {
                return (resource, nil)
            }

            guard let validatedAttachments = try resourceWithAttachments.validateAttachments() else {
                return (resource, nil)
            }

            let generatedKey = try combineAwait(self.cryptoService.generateGCKey(.attachment))
            let uploadedAttachmentsWithIds: [AttachmentDocumentContext] =
                try combineAwait(self.attachmentService.uploadAttachments(validatedAttachments,
                                                                   key: generatedKey))
            var uploadedAttachments = uploadedAttachmentsWithIds.map { $0.attachment } as [AttachmentType]

            let newAttachmentSchema = try resourceWithAttachments.makeFilledSchema(byMatchingTo: &uploadedAttachments)
            resourceWithAttachments.updateAttachments(from: newAttachmentSchema)
            resourceWithAttachments.allAttachments?.forEach { $0.attachmentDataString = nil }

            if let resourceWithIdentifier = resourceWithAttachments as? CustomIdentifiable {
                let thumbnailCombinedIdentifiers = uploadedAttachmentsWithIds.compactMap { $0.tripleIdentifier }
                resourceWithIdentifier.updateIdentifiers(additionalIds: thumbnailCombinedIdentifiers)
                return (resourceWithIdentifier as! R, generatedKey) // swiftlint:disable:this force_cast
            } else {
                return (resource, generatedKey)
            }
        }
    }

    func uploadAttachments<DR: DecryptedRecord>(updating resource: DR.Resource,
                                                decryptedRecordType: DR.Type = DR.self) -> SDKFuture<(resource: DR.Resource, key: Key?)> where DR.Resource: FhirSDKResource {
        return combineAsync {
            let userId = try self.keychainService.get(.userId)
            guard let recordId = resource.fhirIdentifier else { throw Data4LifeSDKError.invalidResourceMissingId }

            guard
                let resourceWithAttachments = resource as? HasAttachments,
                let attachments = resourceWithAttachments.allAttachments else {
                return (resource, nil)
            }

            let remoteRecord = try combineAwait(self.recordService.fetchRecord(recordId: recordId, userId: userId, decryptedRecordType: decryptedRecordType))
            // Gets all Attachments without data
            let remoteAttachments = (remoteRecord.resource as? HasAttachments)?.allAttachments ?? []
            let newKey = try combineAwait(self.cryptoService.generateGCKey(.attachment))
            let attachmentKey = remoteRecord.attachmentKey ?? newKey

            let classifiedAttachments = self.compareAttachments(local: attachments, remote: remoteAttachments)
            let preparedModifiedAttachments = self.updateDataFields(in: classifiedAttachments.modified)

            let validatedAttachmentsToUpload = try (preparedModifiedAttachments + classifiedAttachments.new).validate()

            let uploadedAttachmentsWithIds = try combineAwait(self.uploadAttachments(validatedAttachmentsToUpload, attachmentKey: attachmentKey))
            let uploadedAttachments = uploadedAttachmentsWithIds.map { $0.attachment }
            var allFilledAttachments = classifiedAttachments.unmodified + uploadedAttachments
            let newAttachmentSchema = try resourceWithAttachments.makeFilledSchema(byMatchingTo: &allFilledAttachments)
            
            resourceWithAttachments.updateAttachments(from: newAttachmentSchema)
            resourceWithAttachments.allAttachments?.forEach { $0.attachmentDataString = nil }

            if let resourceWithIdentifier = resourceWithAttachments as? CustomIdentifiable {
                resourceWithIdentifier.updateIdentifiers(additionalIds: uploadedAttachmentsWithIds.compactMap { $0.tripleIdentifier })
                let attachmentIDs = resourceWithAttachments.allAttachments?.compactMap { $0.attachmentId } ?? []
                try resourceWithIdentifier.removeUnusedThumbnailIdentifier(currentAttachmentIDs: attachmentIDs)
                return (resourceWithIdentifier as! DR.Resource, attachmentKey) // swiftlint:disable:this force_cast
            } else {
                return (resource, attachmentKey)
            }
        }
    }
}

// MARK: - Utils
extension FhirService {

    private func uploadAttachments(
        _ attachments: [AttachmentType],
        attachmentKey: Key) -> SDKFuture<[AttachmentDocumentContext]> {
        return combineAsync {
            if !attachments.isEmpty {
                let updatedAttachmentsWithThumbnailsIds: [AttachmentDocumentContext] =
                    try combineAwait(self.attachmentService.uploadAttachments(attachments,
                                                                       key: attachmentKey))
                return updatedAttachmentsWithThumbnailsIds
            } else {
                return []
            }
        }
    }
}
