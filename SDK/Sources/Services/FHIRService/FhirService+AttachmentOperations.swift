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

    func downloadFhirRecordWithAttachments<DR: DecryptedRecord>(withId identifier: String,
                                                                decryptedRecordType: DR.Type = DR.self) -> Promise<FhirRecord<DR.Resource>> where DR.Resource: FhirSDKResource {
        return async {
            let userId = try await(self.keychainService.get(.userId))
            let decryptedRecord = try await(self.recordService.fetchRecord(recordId: identifier, userId: userId, decryptedRecordType: decryptedRecordType))
            let record = FhirRecord<DR.Resource>(decryptedRecord: decryptedRecord)
            guard let attachmentKey = decryptedRecord.attachmentKey else { return record }

            if let resourceWithAttachments = record.fhirResource as? HasAttachments {
                let ids = resourceWithAttachments.allAttachments?.compactMap { $0.attachmentId }
                let downloadedAttachments: [AttachmentType] = try await(self.attachmentService.fetchAttachments(for: resourceWithAttachments,
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

            guard let validatedAttachments = try resourceWithAttachments.validateAttachments() else {
                return (resource, nil)
            }

            let generatedKey = try await(self.cryptoService.generateGCKey(.attachment))
            let uploadedAttachmentsWithIds: [(AttachmentType, [String])] =
                try await(self.attachmentService.uploadAttachments(validatedAttachments,
                                                                   key: generatedKey))
            var uploadedAttachments = uploadedAttachmentsWithIds.map { $0.0 } as [AttachmentType]

            let newAttachmentSchema = try resourceWithAttachments.makeFilledSchema(byMatchingTo: &uploadedAttachments)
            resourceWithAttachments.updateAttachments(from: newAttachmentSchema)
            resourceWithAttachments.allAttachments?.forEach { $0.attachmentDataString = nil }

            if let resourceWithIdentifier = resourceWithAttachments as? CustomIdentifierProtocol {
                let thumbnailAdditionalIdentifiers = uploadedAttachmentsWithIds.compactMap { ThumbnailsIdFactory.createAdditionalId(from: $0) }
                resourceWithIdentifier.updateIdentifiers(additionalIds: thumbnailAdditionalIdentifiers)
                return (resourceWithIdentifier as! R, generatedKey) // swiftlint:disable:this force_cast
            } else {
                return (resource, generatedKey)
            }
        }
    }

    func uploadAttachments<DR: DecryptedRecord>(updating resource: DR.Resource,
                                                decryptedRecordType: DR.Type = DR.self) -> Promise<(resource: DR.Resource, key: Key?)> where DR.Resource: FhirSDKResource {
        return async {
            let userId = try await(self.keychainService.get(.userId))
            guard let recordId = resource.fhirIdentifier else { throw Data4LifeSDKError.invalidResourceMissingId }

            guard
                let resourceWithAttachments = resource as? HasAttachments,
                let attachments = resourceWithAttachments.allAttachments else {
                return (resource, nil)
            }

            let remoteRecord = try await(self.recordService.fetchRecord(recordId: recordId, userId: userId, decryptedRecordType: decryptedRecordType))
            //Gets all Attachments without data
            let remoteAttachments = (remoteRecord.resource as? HasAttachments)?.allAttachments ?? []
            let newKey = try await(self.cryptoService.generateGCKey(.attachment))
            let attachmentKey = remoteRecord.attachmentKey ?? newKey

            let classifiedAttachments = self.compareAttachments(local: attachments, remote: remoteAttachments)
            let preparedModifiedAttachments = self.updateDataFields(in: classifiedAttachments.modified)

            let validatedAttachmentsToUpload = try (preparedModifiedAttachments + classifiedAttachments.new).validate()

            let uploadedAttachmentsWithIds = try await(self.uploadAttachments(validatedAttachmentsToUpload, attachmentKey: attachmentKey))
            let uploadedAttachments = uploadedAttachmentsWithIds.map { $0.0 }
            var allFilledAttachments = classifiedAttachments.unmodified + uploadedAttachments
            let newAttachmentSchema = try resourceWithAttachments.makeFilledSchema(byMatchingTo: &allFilledAttachments)
            resourceWithAttachments.updateAttachments(from: newAttachmentSchema)

            // We don't wanna upload base64 encoded data (in case of old downloaded attachments)
            resourceWithAttachments.allAttachments?.forEach { $0.attachmentDataString = nil }

            if let resourceWithIdentifier = resourceWithAttachments as? CustomIdentifierProtocol {
                resourceWithIdentifier.updateIdentifiers(additionalIds: uploadedAttachmentsWithIds.compactMap { ThumbnailsIdFactory.createAdditionalId(from: $0) })
                let cleanedResource = try resourceWithIdentifier.cleanObsoleteAdditionalIdentifiers(resourceId: resource.fhirIdentifier,
                                                                                                    attachmentIds: resourceWithAttachments.allAttachments?.compactMap { $0.attachmentId } ?? [])
                return (cleanedResource as! DR.Resource, attachmentKey) // swiftlint:disable:this force_cast
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
        attachmentKey: Key) -> Promise<[(attachment: AttachmentType, thumbnailIds: [String])]> {
        return async {
            if !attachments.isEmpty {
                let updatedAttachmentsWithThumbnailsIds: [(AttachmentType, [String])] =
                    try await(self.attachmentService.uploadAttachments(attachments,
                                                                       key: attachmentKey))
                return updatedAttachmentsWithThumbnailsIds
            } else {
                return []
            }
        }
    }
}
