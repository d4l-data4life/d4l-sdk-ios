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
@testable import Data4LifeSDK
import Combine
import Data4LifeFHIR
import Data4LifeCrypto

enum AppDataServiceMockError: Error {
    case noResultSet
}

class AppDataServiceMock: HasRecordOperationsDependencies, HasMainRecordOperations, AppDataServiceType {

    var recordService: RecordServiceType = RecordServiceMock<Data,DecryptedAppDataRecord>()
    var keychainService: KeychainServiceType = KeychainServiceMock()
    var cryptoService: CryptoServiceType = CryptoServiceMock()

    // MARK: Main Operations Properties
    var fetchRecordsCalledWith: (DecryptedAppDataRecord.Type, Date?, Date?, [String]?, Int?, Int?)?
    var fetchRecordsResult: SDKFuture<[AppDataRecord]>?
    var countRecordsCalledWith: (Data.Type?, [String]?)?
    var countRecordsResult: SDKFuture<Int>?
    var fetchRecordWithIdCalledWith: (String, DecryptedAppDataRecord.Type)?
    var fetchRecordWithIdResult: SDKFuture<AppDataRecord>?
    var deleteRecordCalledWith: (String)?
    var deleteRecordResult: SDKFuture<Void>?

    // MARK: Single Operations Properties
    var createAppDataRecordCalledWith: (Data?, [String]?)
    var createAppDataRecordResult: SDKFuture<AppDataRecord>?
    var updateAppDataRecordCalledWith: Data?
    var updateAppDataRecordResult: SDKFuture<AppDataRecord>?
}

// MARK: MainOperations Override
extension AppDataServiceMock {
    func countRecords<R: SDKResource>(of type: R.Type, annotations: [String]) -> SDKFuture<Int> {
        countRecordsCalledWith = (type as? Data.Type, annotations)
        return countRecordsResult ?? Fail(error: AppDataServiceMockError.noResultSet).asyncFuture()
    }

    func fetchRecords<DR: DecryptedRecord, Record: SDKRecord>(decryptedRecordType: DR.Type,
                                                              recordType: Record.Type,
                                                              annotations: [String],
                                                              from startDate: Date?,
                                                              to endDate: Date?,
                                                              pageSize: Int?,
                                                              offset: Int?) -> SDKFuture<[Record]> where Record.Resource == DR.Resource {
        fetchRecordsCalledWith = (decryptedRecordType as! DecryptedAppDataRecord.Type, startDate, endDate, annotations, pageSize, offset) // swiftlint:disable:this force_cast
        return fetchRecordsResult as? SDKFuture<[Record]> ?? Fail(error: AppDataServiceMockError.noResultSet).asyncFuture()
    }

    func fetchRecord<DR: DecryptedRecord, Record: SDKRecord>(withId identifier: String,
                                                             decryptedRecordType: DR.Type = DR.self) -> SDKFuture<Record> where Record.Resource == DR.Resource {
        fetchRecordWithIdCalledWith = (identifier, decryptedRecordType as! DecryptedAppDataRecord.Type) // swiftlint:disable:this force_cast
        return fetchRecordWithIdResult as? SDKFuture<Record> ?? Fail(error: AppDataServiceMockError.noResultSet).asyncFuture()
    }

    func deleteRecord(withId identifier: String) -> SDKFuture<Void> {
        deleteRecordCalledWith = identifier
        return deleteRecordResult ?? Fail(error: AppDataServiceMockError.noResultSet).asyncFuture()
    }
}

// MARK: - Single Operations
extension AppDataServiceMock {
    func createAppDataRecord(_ resource: Data, annotations: [String] = []) -> SDKFuture<AppDataRecord> {
        createAppDataRecordCalledWith = (resource, annotations)
        return createAppDataRecordResult ?? Fail(error: AppDataServiceMockError.noResultSet).asyncFuture()
    }

    func updateAppDataRecord(_ resource: Data, recordId: String, annotations: [String]? = nil) -> SDKFuture<AppDataRecord> {
        updateAppDataRecordCalledWith = resource
        return updateAppDataRecordResult ?? Fail(error: AppDataServiceMockError.noResultSet).asyncFuture()
    }
}
