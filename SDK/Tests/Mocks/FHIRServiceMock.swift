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
@testable import Data4LifeSDK
import Combine
import Data4LifeFHIR
import Data4LifeCrypto

enum FhirServiceMockError: Error {
    case noResultSet
}

class FhirServiceMock<MDR: DecryptedRecord, MA: AttachmentType>: HasRecordOperationsDependencies, HasMainRecordOperations, FhirServiceType where MDR.Resource: FhirSDKResource {

    var attachmentService: AttachmentServiceType = AttachmentServiceMock()
    var recordService: RecordServiceType = RecordServiceMock<MDR.Resource,MDR>()
    var keychainService: KeychainServiceType = KeychainServiceMock()
    var cryptoService: CryptoServiceType = CryptoServiceMock()

    // MARK: Main Operations Properties
    var fetchRecordsCalledWith: (MDR.Type, Date?, Date?, [String]?, Int?, Int?)?
    var fetchRecordsResult: SDKFuture<[FhirRecord<MDR.Resource>]>?
    var countRecordsCalledWith: (MDR.Resource.Type, [String]?)?
    var countRecordsResult: SDKFuture<Int>?
    var fetchRecordWithIdCalledWith: (String, MDR.Type)?
    var fetchRecordWithIdResult: SDKFuture<FhirRecord<MDR.Resource>>?
    var deleteRecordCalledWith: (String)?
    var deleteRecordResult: SDKFuture<Void>?

    // MARK: Single Operations Properties
    var createFhirRecordCalledWith: (MDR.Resource?, [String])?
    var createFhirRecordResult: SDKFuture<FhirRecord<MDR.Resource>>?
    var updateFhirRecordCalledWith: (MDR.Resource?, [String]?)?
    var updateFhirRecordResult: SDKFuture<FhirRecord<MDR.Resource>>?

    // MARK: Batch Operations Properties
    var createFhirRecordsCalledWith: ([MDR.Resource], [String])?
    var createFhirRecordsResult: SDKFuture<BatchResult<FhirRecord<MDR.Resource>, MDR.Resource>>?
    var fetchFhirRecordsWithIdsCalledWith: ([String], MDR.Type)?
    var fetchFhirRecordsWithIdsResult: SDKFuture<BatchResult<FhirRecord<MDR.Resource>, String>>?
    var updateFhirRecordsCalledWith: ([MDR.Resource], [String]?)?
    var updateFhirRecordsResult: SDKFuture<BatchResult<FhirRecord<MDR.Resource>, MDR.Resource>>?
    var deleteFhirRecordsWithIdsCalledWith: ([String])?
    var deleteFhirRecordsWithIdsResult: SDKFuture<BatchResult<String, String>>?
    var downloadFhirRecordsCalledWith: ([String], Progress)?
    var downloadFhirRecordsResult: SDKFuture<BatchResult<FhirRecord<MDR.Resource>, String>>?

    // MARK: Attachment Operations Properties
    var downloadRecordCalledWith: (String, MDR.Type)?
    var downloadGenericRecordResult: SDKFuture<FhirRecord<FhirStu3Resource>>?
    var downloadSpecificRecordResult: SDKFuture<FhirRecord<MDR.Resource>>?
    var uploadAttachmentsCreatingCalledWith: (MDR.Resource)?
    var uploadAttachmentsCreatingResult: SDKFuture<(resource: MDR.Resource, key: Key?)>?
    var uploadAttachmentsUpdatingCalledWith: (MDR.Resource)?
    var uploadAttachmentsUpdatingResult: SDKFuture<(resource: MDR.Resource, key: Key?)>?
    var downloadAttachmentCalledWith: (String, String, DownloadType, Progress)?
    var downloadAttachmentResult: SDKFuture<MA>?
    var downloadAttachmentsCalledWith: ([String], String, DownloadType, Progress)?
    var downloadAttachmentsResult: SDKFuture<[MA]>?
}

// MARK: MainOperations Override
extension FhirServiceMock {
    func countRecords<R: SDKResource>(of type: R.Type, annotations: [String] = []) -> SDKFuture<Int> {
        countRecordsCalledWith = (type as! MDR.Resource.Type, annotations) // swiftlint:disable:this force_cast
        return countRecordsResult ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }

    func fetchRecords<DR: DecryptedRecord, Record: SDKRecord>(decryptedRecordType: DR.Type,
                                                              recordType: Record.Type,
                                                              annotations: [String] = [],
                                                              from startDate: Date?,
                                                              to endDate: Date?,
                                                              pageSize: Int?,
                                                              offset: Int?) -> SDKFuture<[Record]> where Record.Resource == DR.Resource {
        fetchRecordsCalledWith = (decryptedRecordType as! MDR.Type, startDate, endDate, annotations, pageSize, offset) // swiftlint:disable:this force_cast
        return fetchRecordsResult as? SDKFuture<[Record]> ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }

    func fetchRecord<DR: DecryptedRecord, Record: SDKRecord>(withId identifier: String,
                                                             decryptedRecordType: DR.Type = DR.self) -> SDKFuture<Record> where Record.Resource == DR.Resource {
        fetchRecordWithIdCalledWith = (identifier, decryptedRecordType as! MDR.Type) // swiftlint:disable:this force_cast
        return fetchRecordWithIdResult as? SDKFuture<Record> ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }

    func deleteRecord(withId identifier: String) -> SDKFuture<Void> {
        deleteRecordCalledWith = identifier
        return deleteRecordResult ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }
}

// MARK: - Single Operations
extension FhirServiceMock {
    func createFhirRecord<DR: DecryptedRecord>(_ resource: DR.Resource,
                                               annotations: [String] = [],
                                               decryptedRecordType: DR.Type) -> SDKFuture<FhirRecord<DR.Resource>> where DR.Resource: FhirSDKResource {
        createFhirRecordCalledWith = (resource as? MDR.Resource, annotations)
        return createFhirRecordResult as? SDKFuture<FhirRecord<DR.Resource>> ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }

    func updateFhirRecord<DR: DecryptedRecord>(_ resource: DR.Resource, annotations: [String]?, decryptedRecordType: DR.Type) -> SDKFuture<FhirRecord<DR.Resource>> where DR.Resource: FhirSDKResource {
        updateFhirRecordCalledWith = (resource as? MDR.Resource, annotations)
        return updateFhirRecordResult as? SDKFuture<FhirRecord<DR.Resource>> ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }
}

// MARK: - Attachment Operations
extension FhirServiceMock {

    func downloadFhirRecordWithAttachments<DR: DecryptedRecord>(withId identifier: String,
                                                                decryptedRecordType: DR.Type) -> SDKFuture<FhirRecord<DR.Resource>> where DR.Resource : FhirSDKResource {
        downloadRecordCalledWith = (identifier, decryptedRecordType as! MDR.Type) // swiftlint:disable:this force_cast

        if let downloadGenericRecordResult = downloadGenericRecordResult {
            return downloadGenericRecordResult as! SDKFuture<FhirRecord<DR.Resource>> // swiftlint:disable:this force_cast
        } else if let downloadSpecificRecordResult = downloadSpecificRecordResult {
            return downloadSpecificRecordResult as! SDKFuture<FhirRecord<DR.Resource>> // swiftlint:disable:this force_cast
        } else {
            return Fail(error: FhirServiceMockError.noResultSet).asyncFuture
        }
    }

    func uploadAttachments<R: FhirSDKResource>(creating resource: R) -> SDKFuture<(resource: R,  key: Key?)> {
        uploadAttachmentsCreatingCalledWith = resource as? MDR.Resource
        return uploadAttachmentsCreatingResult as? SDKFuture<(resource: R, key: Key?)> ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }

    func uploadAttachments<R: FhirSDKResource, DR: DecryptedRecord>(updating resource: R, decryptedRecordType: DR.Type) -> SDKFuture<(resource: R,  key: Key?)> {
        uploadAttachmentsUpdatingCalledWith = resource as? MDR.Resource
        return uploadAttachmentsUpdatingResult as? SDKFuture<(resource: R, key: Key?)> ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }

    func downloadAttachments<A: AttachmentType, DR: DecryptedRecord>(of type: A.Type,
                                                                     decryptedRecordType: DR.Type,
                                                                     withIds identifiers: [String],
                                                                     recordId: String,
                                                                     downloadType: DownloadType,
                                                                     parentProgress: Progress) -> SDKFuture<[A]> {
        downloadAttachmentsCalledWith = (identifiers, recordId, downloadType, parentProgress)
        return downloadAttachmentsResult as? SDKFuture<[A]> ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }

    func downloadAttachment<A: AttachmentType, DR: DecryptedRecord>(of type: A.Type,
                                                                    decryptedRecordType: DR.Type,
                                                                    withId identifier: String,
                                                                    recordId: String,
                                                                    downloadType: DownloadType,
                                                                    parentProgress: Progress) -> SDKFuture<A> {
        downloadAttachmentCalledWith = (identifier, recordId, downloadType, parentProgress)
        return downloadAttachmentResult as? SDKFuture<A> ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }
}

// MARK: Batch Operations
extension FhirServiceMock {

    func createFhirRecords<DR: DecryptedRecord>(_ resources: [DR.Resource],
                                                annotations: [String] = [],
                                                decryptedRecordType: DR.Type) -> SDKFuture<BatchResult<FhirRecord<DR.Resource>, DR.Resource>> where DR.Resource: FhirSDKResource {
        createFhirRecordsCalledWith = (resources as! [MDR.Resource], annotations) // swiftlint:disable:this force_cast
        return  createFhirRecordsResult as? SDKFuture<BatchResult<FhirRecord<DR.Resource>, DR.Resource>> ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }

    func updateFhirRecords<DR: DecryptedRecord>(_ resources: [DR.Resource],
                                                annotations: [String]? = nil,
                                                decryptedRecordType: DR.Type) -> SDKFuture<BatchResult<FhirRecord<DR.Resource>, DR.Resource>> where DR.Resource: FhirSDKResource {
        updateFhirRecordsCalledWith = (resources as! [MDR.Resource], annotations) // swiftlint:disable:this force_cast
        return  updateFhirRecordsResult as? SDKFuture<(success: [FhirRecord<DR.Resource>], failed: [(object: DR.Resource, error: Error)])> ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }

    func fetchFhirRecords<DR: DecryptedRecord>(withIds identifiers: [String],
                                               decryptedRecordType: DR.Type) -> SDKFuture<BatchResult<FhirRecord<DR.Resource>, String>> where DR.Resource: FhirSDKResource {
        fetchFhirRecordsWithIdsCalledWith = (identifiers, decryptedRecordType as! MDR.Type) // swiftlint:disable:this force_cast
        return fetchFhirRecordsWithIdsResult as? SDKFuture<BatchResult<FhirRecord<DR.Resource>, String>> ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }

    func deleteFhirRecords(withIds identifiers: [String]) -> SDKFuture<BatchResult<String, String>> {
        deleteFhirRecordsWithIdsCalledWith = identifiers
        return deleteFhirRecordsWithIdsResult ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }

    func downloadFhirRecordsWithAttachments<DR: DecryptedRecord>(withIds identifiers: [String],
                                                                 decryptedRecordType: DR.Type,
                                                                 parentProgress: Progress) -> SDKFuture<BatchResult<FhirRecord<DR.Resource>, String>> where DR.Resource: FhirSDKResource {
            downloadFhirRecordsCalledWith = (identifiers, parentProgress)
            return downloadFhirRecordsResult as? SDKFuture<BatchResult<FhirRecord<DR.Resource>, String>> ?? Fail(error: FhirServiceMockError.noResultSet).asyncFuture
    }
}
