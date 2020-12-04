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

class AppDataServiceMock: HasRecordOperationsDependencies, HasMainRecordOperations, AppDataServiceType {

    var recordService: RecordServiceType = RecordServiceMock<Data,DecryptedAppDataRecord>()
    var keychainService: KeychainServiceType = KeychainServiceMock()
    var cryptoService: CryptoServiceType = CryptoServiceMock()

    // MARK: Main Operations Properties
    var fetchRecordsCalledWith: (DecryptedAppDataRecord.Type, Date?, Date?, [String]?, Int?, Int?)?
    var fetchRecordsResult: Async<[AppDataRecord]>?
    var countRecordsCalledWith: (Data.Type?, [String]?)?
    var countRecordsResult: Async<Int>?
    var fetchRecordWithIdCalledWith: (String, DecryptedAppDataRecord.Type)?
    var fetchRecordWithIdResult: Async<AppDataRecord>?
    var deleteRecordCalledWith: (String)?
    var deleteRecordResult: Async<Void>?

    // MARK: Single Operations Properties
    var createAppDataRecordCalledWith: (Data?, [String]?)
    var createAppDataRecordResult: Async<AppDataRecord>?
    var updateAppDataRecordCalledWith: Data?
    var updateAppDataRecordResult: Async<AppDataRecord>?
}

// MARK: MainOperations Override
extension AppDataServiceMock {
    func countRecords<R: SDKResource>(of type: R.Type, annotations: [String]) -> Promise<Int> {
        countRecordsCalledWith = (type as? Data.Type, annotations)
        return countRecordsResult ?? Async.reject()
    }

    func fetchRecords<DR: DecryptedRecord, Record: SDKRecord>(decryptedRecordType: DR.Type,
                                                              recordType: Record.Type,
                                                              annotations: [String],
                                                              from startDate: Date?,
                                                              to endDate: Date?,
                                                              pageSize: Int?,
                                                              offset: Int?) -> Promise<[Record]> where Record.Resource == DR.Resource {
        fetchRecordsCalledWith = (decryptedRecordType as! DecryptedAppDataRecord.Type, startDate, endDate, annotations, pageSize, offset) // swiftlint:disable:this force_cast
        return fetchRecordsResult as? Async<[Record]> ?? Async.reject()
    }

    func fetchRecord<DR: DecryptedRecord, Record: SDKRecord>(withId identifier: String,
                                                             decryptedRecordType: DR.Type = DR.self) -> Promise<Record> where Record.Resource == DR.Resource {
        fetchRecordWithIdCalledWith = (identifier, decryptedRecordType as! DecryptedAppDataRecord.Type) // swiftlint:disable:this force_cast
        return fetchRecordWithIdResult as? Async<Record> ?? Async.reject()
    }

    func deleteRecord(withId identifier: String) -> Promise<Void> {
        deleteRecordCalledWith = identifier
        return deleteRecordResult ?? Async.reject()
    }
}

// MARK: - Single Operations
extension AppDataServiceMock {
    func createAppDataRecord(_ resource: Data, annotations: [String] = []) -> Promise<AppDataRecord> {
        createAppDataRecordCalledWith = (resource, annotations)
        return createAppDataRecordResult ?? Async.reject()
    }

    func updateAppDataRecord(_ resource: Data, recordId: String, annotations: [String]? = nil) -> Promise<AppDataRecord> {
        updateAppDataRecordCalledWith = resource
        return updateAppDataRecordResult ?? Async.reject()
    }
}
