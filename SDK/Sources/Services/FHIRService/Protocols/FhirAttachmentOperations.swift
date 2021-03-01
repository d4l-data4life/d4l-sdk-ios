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

@_implementationOnly
import Then

protocol HasAttachmentOperationsDependencies {
    var attachmentService: AttachmentServiceType { get }
}

protocol FhirAttachmentOperations {

    func downloadAttachment<A: AttachmentType, DR: DecryptedRecord>(of type: A.Type,
                                                                    decryptedRecordType: DR.Type,
                                                                    withId identifier: String,
                                                                    recordId: String,
                                                                    downloadType: DownloadType,
                                                                    parentProgress: Progress) -> Promise<A>
    func downloadAttachments<A: AttachmentType, DR: DecryptedRecord>(of type: A.Type,
                                                                     decryptedRecordType: DR.Type,
                                                                     withIds identifiers: [String],
                                                                     recordId: String,
                                                                     downloadType: DownloadType,
                                                                     parentProgress: Progress) -> Promise<[A]>
    func downloadFhirRecordWithAttachments<DR: DecryptedRecord>(withId identifier: String,
                                                                decryptedRecordType: DR.Type) -> Promise<FhirRecord<DR.Resource>> where DR.Resource: FhirSDKResource
    func uploadAttachments<R: FhirSDKResource>(creating resource: R) -> Promise<(resource: R,  key: Key?)>
    func uploadAttachments<DR: DecryptedRecord>(updating resource: DR.Resource, decryptedRecordType: DR.Type) -> Promise<(resource: DR.Resource, key: Key?)> where DR.Resource: FhirSDKResource
}

extension FhirAttachmentOperations where Self: HasAttachmentOperationsDependencies & HasRecordOperationsDependencies {
    func downloadAttachment<A: AttachmentType, DR: DecryptedRecord>(of type: A.Type = A.self,
                                                                    decryptedRecordType: DR.Type = DR.self,
                                                                    withId identifier: String,
                                                                    recordId: String,
                                                                    downloadType: DownloadType,
                                                                    parentProgress: Progress) -> Promise<A> {
        return async {
            let attachments: [A] = try await(self.downloadAttachments(of: type,
                                                                      decryptedRecordType: decryptedRecordType,
                                                                      withIds: [identifier],
                                                                      recordId: recordId,
                                                                      downloadType: downloadType,
                                                                      parentProgress: parentProgress))
            guard
                let attachment = attachments.first,
                let attachmentId = attachment.attachmentId,
                attachmentId.contains(identifier)
            else {
                throw Data4LifeSDKError.couldNotFindAttachment
            }

            return attachment
        }.bridgeError { error in
            throw self.bridgeErrorCancelledAction(error: error)
        }
    }

    func downloadAttachments<A: AttachmentType, DR: DecryptedRecord>(of type: A.Type = A.self,
                                                                     decryptedRecordType: DR.Type = DR.self,
                                                                     withIds identifiers: [String],
                                                                     recordId: String,
                                                                     downloadType: DownloadType,
                                                                     parentProgress: Progress) -> Promise<[A]> {
        return async {
            let userId = try await(self.keychainService.get(.userId))
            let record = try await(self.recordService.fetchRecord(recordId: recordId,
                                                                  userId: userId,
                                                                  decryptedRecordType: DR.self))

            guard
                let attachmentKey = record.attachmentKey,
                let resourceWithAttachments = record.resource as? HasAttachments
            else { throw Data4LifeSDKError.couldNotFindAttachment }
            let attachments: [AttachmentType] = try await(self.attachmentService.fetchAttachments(for: resourceWithAttachments,
                                                                                                  attachmentIds: identifiers,
                                                                                                  downloadType: downloadType,
                                                                                                  key: attachmentKey,
                                                                                                  parentProgress: parentProgress))
            return attachments as? [A] ?? []
        }
        .bridgeError { error in
            throw self.bridgeErrorCancelledAction(error: error)
        }
    }
}

// MARK: - Helpers For attachments
extension FhirAttachmentOperations {

    func bridgeErrorCancelledAction(error: Error) -> Error {
        if (error as? URLError)?.code == .cancelled {
            return Data4LifeSDKError.downloadActionWasCancelled
        }
        return error
    }

    func compareAttachments(local: [AttachmentType], remote: [AttachmentType]) -> AttachmentComparison {
        var new: [AttachmentType] = []
        var modified: [AttachmentType] = []
        var unmodified: [AttachmentType] = []

        for attachment in local {
            if attachment.attachmentId == nil {
                new.append(attachment)
            } else {
                guard let remoteAttachment = remote.first(where: { $0.attachmentId == attachment.attachmentId }) else {
                    // This case should never happen, it means that attachment
                    // has an `id` but it's not found in the current record
                    new.append(attachment)
                    continue
                }
                if remoteAttachment.attachmentHash == attachment.attachmentData?.sha1Hash || attachment.attachmentData == nil {
                    unmodified.append(attachment)
                } else {
                    modified.append(attachment)
                }
            }
        }

        return AttachmentComparison(new: new, modified: modified, unmodified: unmodified)
    }

    func updateDataFields(in attachments: [AttachmentType]) -> [AttachmentType] {
        let preparedAttachments = attachments.map { attachment -> AttachmentType in
            let copy = attachment.copy() as! AttachmentType // swiftlint:disable:this force_cast
            copy.attachmentHash = attachment.attachmentData?.sha1Hash
            copy.attachmentSize = attachment.attachmentData?.count
            return copy
        }

        return preparedAttachments
    }
}
