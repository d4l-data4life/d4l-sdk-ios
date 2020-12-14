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
import Then
import Data4LifeFHIR
import Data4LifeCrypto

class FhirServiceMock<MDR: DecryptedRecord, MA: AttachmentType>: HasRecordOperationsDependencies, HasMainRecordOperations, FhirServiceType where MDR.Resource: FhirSDKResource {

    var attachmentService: AttachmentServiceType = AttachmentServiceMock()
    var recordService: RecordServiceType = RecordServiceMock<MDR.Resource,MDR>()
    var keychainService: KeychainServiceType = KeychainServiceMock()
    var cryptoService: CryptoServiceType = CryptoServiceMock()

    // MARK: Main Operations Properties
    var fetchRecordsCalledWith: (MDR.Type, Date?, Date?, [String]?, Int?, Int?)?
    var fetchRecordsResult: Async<[FhirRecord<MDR.Resource>]>?
    var countRecordsCalledWith: (MDR.Resource.Type, [String]?)?
    var countRecordsResult: Async<Int>?
    var fetchRecordWithIdCalledWith: (String, MDR.Type)?
    var fetchRecordWithIdResult: Async<FhirRecord<MDR.Resource>>?
    var deleteRecordCalledWith: (String)?
    var deleteRecordResult: Async<Void>?

    // MARK: Single Operations Properties
    var createFhirRecordCalledWith: (MDR.Resource?, [String])?
    var createFhirRecordResult: Async<FhirRecord<MDR.Resource>>?
    var updateFhirRecordCalledWith: (MDR.Resource?, [String]?)?
    var updateFhirRecordResult: Async<FhirRecord<MDR.Resource>>?

    // MARK: Batch Operations Properties
    var createFhirRecordsCalledWith: ([MDR.Resource], [String])?
    var createFhirRecordsResult: Promise<BatchResult<FhirRecord<MDR.Resource>, MDR.Resource>>?
    var fetchFhirRecordsWithIdsCalledWith: ([String], MDR.Type)?
    var fetchFhirRecordsWithIdsResult: Promise<BatchResult<FhirRecord<MDR.Resource>, String>>?
    var updateFhirRecordsCalledWith: ([MDR.Resource], [String]?)?
    var updateFhirRecordsResult: Promise<BatchResult<FhirRecord<MDR.Resource>, MDR.Resource>>?
    var deleteFhirRecordsWithIdsCalledWith: ([String])?
    var deleteFhirRecordsWithIdsResult: Promise<BatchResult<String, String>>?
    var downloadFhirRecordsCalledWith: ([String], Progress)?
    var downloadFhirRecordsResult: Promise<BatchResult<FhirRecord<MDR.Resource>, String>>?

    // MARK: Attachment Operations Properties
    var downloadRecordCalledWith: (String, MDR.Type)?
    var downloadGenericRecordResult: Promise<FhirRecord<FhirStu3Resource>>?
    var downloadSpecificRecordResult: Promise<FhirRecord<DocumentReference>>?
    var uploadAttachmentsCreatingCalledWith: (MDR.Resource)?
    var uploadAttachmentsCreatingResult: Async<(resource: MDR.Resource, key: Key?)>?
    var uploadAttachmentsUpdatingCalledWith: (MDR.Resource)?
    var uploadAttachmentsUpdatingResult: Async<(resource: MDR.Resource, key: Key?)>?
    var downloadAttachmentCalledWith: (String, String, DownloadType, Progress)?
    var downloadAttachmentResult: Promise<MA>?
    var downloadAttachmentsCalledWith: ([String], String, DownloadType, Progress)?
    var downloadAttachmentsResult: Promise<[MA]>?
}

// MARK: MainOperations Override
extension FhirServiceMock {
    func countRecords<R: SDKResource>(of type: R.Type, annotations: [String] = []) -> Promise<Int> {
        countRecordsCalledWith = (type as! MDR.Resource.Type, annotations) // swiftlint:disable:this force_cast
        return countRecordsResult ?? Async.reject()
    }

    func fetchRecords<DR: DecryptedRecord, Record: SDKRecord>(decryptedRecordType: DR.Type,
                                                              recordType: Record.Type,
                                                              annotations: [String] = [],
                                                              from startDate: Date?,
                                                              to endDate: Date?,
                                                              pageSize: Int?,
                                                              offset: Int?) -> Promise<[Record]> where Record.Resource == DR.Resource {
        fetchRecordsCalledWith = (decryptedRecordType as! MDR.Type, startDate, endDate, annotations, pageSize, offset) // swiftlint:disable:this force_cast
        return fetchRecordsResult as? Async<[Record]> ?? Async.reject()
    }

    func fetchRecord<DR: DecryptedRecord, Record: SDKRecord>(withId identifier: String,
                                                             decryptedRecordType: DR.Type = DR.self) -> Promise<Record> where Record.Resource == DR.Resource {
        fetchRecordWithIdCalledWith = (identifier, decryptedRecordType as! MDR.Type) // swiftlint:disable:this force_cast
        return fetchRecordWithIdResult as? Async<Record> ?? Async.reject()
    }

    func deleteRecord(withId identifier: String) -> Promise<Void> {
        deleteRecordCalledWith = identifier
        return deleteRecordResult ?? Async.reject()
    }
}

// MARK: - Single Operations
extension FhirServiceMock {
    func createFhirRecord<DR: DecryptedRecord>(_ resource: DR.Resource,
                                               annotations: [String] = [],
                                               decryptedRecordType: DR.Type) -> Promise<FhirRecord<DR.Resource>> where DR.Resource: FhirSDKResource {
        createFhirRecordCalledWith = (resource as? MDR.Resource, annotations)
        return createFhirRecordResult as? Async<FhirRecord<DR.Resource>> ?? Async.reject()
    }

    func updateFhirRecord<DR: DecryptedRecord>(_ resource: DR.Resource, annotations: [String]?, decryptedRecordType: DR.Type) -> Promise<FhirRecord<DR.Resource>> where DR.Resource: FhirSDKResource {
        updateFhirRecordCalledWith = (resource as? MDR.Resource, annotations)
        return updateFhirRecordResult as? Async<FhirRecord<DR.Resource>> ?? Async.reject()
    }
}

// MARK: - Attachment Operations
extension FhirServiceMock {

    func downloadFhirRecordWithAttachments<DR: DecryptedRecord>(withId identifier: String,
                                                                decryptedRecordType: DR.Type) -> Promise<FhirRecord<DR.Resource>> where DR.Resource : FhirSDKResource {
        downloadRecordCalledWith = (identifier, decryptedRecordType as! MDR.Type) // swiftlint:disable:this force_cast

        if let downloadGenericRecordResult = downloadGenericRecordResult {
            return downloadGenericRecordResult as! Promise<FhirRecord<DR.Resource>> // swiftlint:disable:this force_cast
        } else if let downloadSpecificRecordResult = downloadSpecificRecordResult {
            return downloadSpecificRecordResult as! Promise<FhirRecord<DR.Resource>> // swiftlint:disable:this force_cast
        } else {
            return Async.reject()
        }
    }

    func uploadAttachments<R: FhirSDKResource>(creating resource: R) -> Promise<(resource: R,  key: Key?)> {
        uploadAttachmentsCreatingCalledWith = resource as? MDR.Resource
        return uploadAttachmentsCreatingResult as? Async<(resource: R, key: Key?)> ?? Async.reject()
    }

    func uploadAttachments<R: FhirSDKResource, DR: DecryptedRecord>(updating resource: R, decryptedRecordType: DR.Type) -> Promise<(resource: R,  key: Key?)> {
        uploadAttachmentsUpdatingCalledWith = resource as? MDR.Resource
        return uploadAttachmentsUpdatingResult as? Async<(resource: R, key: Key?)> ?? Async.reject()
    }

    func downloadAttachments<A: AttachmentType, DR: DecryptedRecord>(of type: A.Type,
                                                                     decryptedRecordType: DR.Type,
                                                                     withIds identifiers: [String],
                                                                     recordId: String,
                                                                     downloadType: DownloadType,
                                                                     parentProgress: Progress) -> Promise<[A]> {
        downloadAttachmentsCalledWith = (identifiers, recordId, downloadType, parentProgress)
        return downloadAttachmentsResult as? Promise<[A]> ?? Promise.reject()
    }

    func downloadAttachment<A: AttachmentType, DR: DecryptedRecord>(of type: A.Type,
                                                                    decryptedRecordType: DR.Type,
                                                                    withId identifier: String,
                                                                    recordId: String,
                                                                    downloadType: DownloadType,
                                                                    parentProgress: Progress) -> Promise<A> {
        downloadAttachmentCalledWith = (identifier, recordId, downloadType, parentProgress)
        return downloadAttachmentResult as? Promise<A> ?? Promise.reject()
    }
}

// MARK: Batch Operations
extension FhirServiceMock {

    func createFhirRecords<DR: DecryptedRecord>(_ resources: [DR.Resource],
                                                annotations: [String] = [],
                                                decryptedRecordType: DR.Type) -> Promise<BatchResult<FhirRecord<DR.Resource>, DR.Resource>> where DR.Resource: FhirSDKResource {
        createFhirRecordsCalledWith = (resources as! [MDR.Resource], annotations) // swiftlint:disable:this force_cast
        return  createFhirRecordsResult as? Promise<BatchResult<FhirRecord<DR.Resource>, DR.Resource>> ?? Async.reject()
    }

    func updateFhirRecords<DR: DecryptedRecord>(_ resources: [DR.Resource],
                                                annotations: [String]? = nil,
                                                decryptedRecordType: DR.Type) -> Promise<BatchResult<FhirRecord<DR.Resource>, DR.Resource>> where DR.Resource: FhirSDKResource {
        updateFhirRecordsCalledWith = (resources as! [MDR.Resource], annotations) // swiftlint:disable:this force_cast
        return  updateFhirRecordsResult as? Promise<(success: [FhirRecord<DR.Resource>], failed: [(object: DR.Resource, error: Error)])> ?? Async.reject()
    }

    func fetchFhirRecords<DR: DecryptedRecord>(withIds identifiers: [String],
                                               decryptedRecordType: DR.Type) -> Promise<BatchResult<FhirRecord<DR.Resource>, String>> where DR.Resource: FhirSDKResource {
        fetchFhirRecordsWithIdsCalledWith = (identifiers, decryptedRecordType as! MDR.Type) // swiftlint:disable:this force_cast
        return fetchFhirRecordsWithIdsResult as? Promise<BatchResult<FhirRecord<DR.Resource>, String>> ?? Async.reject()
    }

    func deleteFhirRecords(withIds identifiers: [String]) -> Promise<BatchResult<String, String>> {
        deleteFhirRecordsWithIdsCalledWith = identifiers
        return deleteFhirRecordsWithIdsResult ?? Async.reject()
    }

    func downloadFhirRecordsWithAttachments<DR: DecryptedRecord>(withIds identifiers: [String],
                                                                 decryptedRecordType: DR.Type,
                                                                 parentProgress: Progress) -> Promise<BatchResult<FhirRecord<DR.Resource>, String>> where DR.Resource: FhirSDKResource {
            downloadFhirRecordsCalledWith = (identifiers, parentProgress)
            return downloadFhirRecordsResult as? Promise<BatchResult<FhirRecord<DR.Resource>, String>> ?? Async.reject()
    }
}
