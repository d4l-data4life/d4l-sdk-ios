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
import Then
import Data4LifeCrypto
@testable import Data4LifeSDK

class RecordServiceMock<MockR, MockDR: DecryptedRecord>: RecordServiceType where MockDR.Resource == MockR {

    // MARK: Single Operations
    var updateRecordCalledWith: (AnySDKResource<MockR>, [String]?, String, String, Key?)?
    var updateRecordResult: Async<MockDR>?
    func updateRecord<DR>(forResource resource: DR.Resource,
                          annotations: [String]?,
                          userId: String,
                          recordId: String,
                          attachmentKey: Key?,
                          decryptedRecordType: DR.Type) -> Async<DR> where DR : DecryptedRecord {
        guard let resource = resource as? MockR else {
            fatalError()
        }
        updateRecordCalledWith = (AnySDKResource<MockR>(resource: resource), annotations, userId, recordId, attachmentKey)
        return updateRecordResult as? Async<DR> ?? Async.reject()
    }

    var createRecordCalledWith: (AnySDKResource<MockR>, [String]?, String, Key?)?
    var createRecordResult: Async<MockDR>?
    func createRecord<DR: DecryptedRecord>(forResource resource: DR.Resource,
                                           annotations: [String],
                                           userId: String,
                                           attachmentKey: Key?,
                                           decryptedRecordType: DR.Type) -> Async<DR> {
        guard let resource = resource as? MockR else {
            fatalError()
        }
        createRecordCalledWith = (AnySDKResource<MockR>(resource: resource), annotations, userId, attachmentKey)
        return createRecordResult as? Promise<DR> ?? Async.reject()
    }

    var fetchRecordCalledWith: (String, String)?
    var fetchRecordResult: Async<MockDR>?
    var fetchRecordResults: [Async<MockDR>]?
    func fetchRecord<DR>(recordId: String, userId: String, decryptedRecordType: DR.Type) -> Async<DR> where DR : DecryptedRecord {
        fetchRecordCalledWith = (recordId, userId)
        if let results = fetchRecordResults, let first = results.first {
            fetchRecordResults = Array(results.dropFirst())
            return first as? Promise<DR> ?? Async.reject()
        }
        return fetchRecordResult as? Promise<DR> ?? Async.reject()
    }

    var deleteRecordCalledWith: (String, String)?
    var deleteRecordResult: AsyncTask?
    func deleteRecord(recordId: String, userId: String) -> AsyncTask {
        deleteRecordCalledWith = (recordId, userId)
        return deleteRecordResult ?? Async.reject()
    }

    // MARK: Shared operations
    var searchRecordsCalledWith: (Date?, Date?, Int?, Int?, [String]?)?
    var searchRecordsResult: Async<[MockDR]>?
    func searchRecords<DR>(for userId: String,
                           from startDate: Date?,
                           to endDate: Date?,
                           pageSize: Int?,
                           offset: Int?,
                           annotations: [String],
                           decryptedRecordType: DR.Type) -> Async<[DR]> where DR : DecryptedRecord {
        searchRecordsCalledWith = (startDate, endDate, pageSize, offset, annotations)
        return searchRecordsResult as? Promise<[DR]> ?? Async.reject()
    }

    var countRecordsCalledWith: (String, SDKResource.Type?, [String]?)?
    var countRecordsResult: Async<Int>?
    func countRecords<R>(userId: String, resourceType: R.Type, annotations: [String]) -> Async<Int> where R : SDKResource {
        countRecordsCalledWith = (userId, resourceType, annotations)
        return countRecordsResult ?? Async.reject()
    }
}
