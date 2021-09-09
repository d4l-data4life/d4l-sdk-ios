//  Copyright (c) 2021 D4L data4life gGmbH
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
import Combine
import Data4LifeCrypto
@testable import Data4LifeSDK

enum RecordServiceMockError: Error {
    case noResultSet
}

class RecordServiceMock<MockR, MockDR: DecryptedRecord>: RecordServiceType where MockDR.Resource == MockR {

    // MARK: Single Operations
    var updateRecordCalledWith: (AnySDKResource<MockR>, [String]?, String, String, Key?)?
    var updateRecordResult: SDKFuture<MockDR>?
    func updateRecord<DR>(forResource resource: DR.Resource,
                          annotations: [String]?,
                          userId: String,
                          recordId: String,
                          attachmentKey: Key?,
                          decryptedRecordType: DR.Type) -> SDKFuture<DR> where DR : DecryptedRecord {
        guard let resource = resource as? MockR else {
            fatalError()
        }
        updateRecordCalledWith = (AnySDKResource<MockR>(resource: resource), annotations, userId, recordId, attachmentKey)
        return updateRecordResult as? SDKFuture<DR> ?? Fail(error: RecordServiceMockError.noResultSet).asyncFuture()
    }

    var createRecordCalledWith: (AnySDKResource<MockR>, [String]?, String, Key?)?
    var createRecordResult: SDKFuture<MockDR>?
    func createRecord<DR: DecryptedRecord>(forResource resource: DR.Resource,
                                           annotations: [String],
                                           userId: String,
                                           attachmentKey: Key?,
                                           decryptedRecordType: DR.Type) -> SDKFuture<DR> {
        guard let resource = resource as? MockR else {
            fatalError()
        }
        createRecordCalledWith = (AnySDKResource<MockR>(resource: resource), annotations, userId, attachmentKey)
        return createRecordResult as? SDKFuture<DR> ?? Fail(error: RecordServiceMockError.noResultSet).asyncFuture()
    }

    var fetchRecordCalledWith: (String, String)?
    var fetchRecordResult: SDKFuture<MockDR>?
    var fetchRecordResults: [SDKFuture<MockDR>]?
    func fetchRecord<DR>(recordId: String, userId: String, decryptedRecordType: DR.Type) -> SDKFuture<DR> where DR : DecryptedRecord {
        fetchRecordCalledWith = (recordId, userId)
        if let results = fetchRecordResults, let first = results.first {
            fetchRecordResults = Array(results.dropFirst())
            return first as? SDKFuture<DR> ?? Fail(error: RecordServiceMockError.noResultSet).asyncFuture()
        }
        return fetchRecordResult as? SDKFuture<DR> ?? Fail(error: RecordServiceMockError.noResultSet).asyncFuture()
    }

    var deleteRecordCalledWith: (String, String)?
    var deleteRecordResult: SDKFuture<Void>?
    func deleteRecord(recordId: String, userId: String) -> SDKFuture<Void> {
        deleteRecordCalledWith = (recordId, userId)
        return deleteRecordResult ?? Fail(error: RecordServiceMockError.noResultSet).asyncFuture()
    }

    // MARK: Shared operations
    var searchRecordsCalledWith: (Date?, Date?, Int?, Int?, [String]?)?
    var searchRecordsResult: SDKFuture<[MockDR]>?
    func searchRecords<DR>(for userId: String,
                           from startDate: Date?,
                           to endDate: Date?,
                           pageSize: Int?,
                           offset: Int?,
                           annotations: [String],
                           decryptedRecordType: DR.Type) -> SDKFuture<[DR]> where DR : DecryptedRecord {
        searchRecordsCalledWith = (startDate, endDate, pageSize, offset, annotations)
        return searchRecordsResult as? SDKFuture<[DR]> ?? Fail(error: RecordServiceMockError.noResultSet).asyncFuture()
    }

    var countRecordsCalledWith: (String, SDKResource.Type?, [String]?)?
    var countRecordsResult: SDKFuture<Int>?
    func countRecords<R>(userId: String, resourceType: R.Type, annotations: [String]) -> SDKFuture<Int> where R : SDKResource {
        countRecordsCalledWith = (userId, resourceType, annotations)
        return countRecordsResult ?? Fail(error: RecordServiceMockError.noResultSet).asyncFuture()
    }
}