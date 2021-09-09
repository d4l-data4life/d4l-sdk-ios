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

protocol HasRecordOperationsDependencies {
    var recordService: RecordServiceType { get }
    var keychainService: KeychainServiceType { get }
    var cryptoService: CryptoServiceType { get }
}

protocol HasMainRecordOperations {
    func countRecords<R: SDKResource>(of type: R.Type, annotations: [String]) -> SDKFuture<Int>
    func deleteRecord(withId identifier: String) -> SDKFuture<Void>
    func fetchRecord<DR: DecryptedRecord, Record: SDKRecord>(withId identifier: String,
                                                             decryptedRecordType: DR.Type) -> SDKFuture<Record> where Record.Resource == DR.Resource
    func fetchRecords<DR: DecryptedRecord, Record: SDKRecord>(decryptedRecordType: DR.Type,
                                                              recordType: Record.Type,
                                                              annotations: [String],
                                                              from startDate: Date?,
                                                              to endDate: Date?,
                                                              pageSize: Int?,
                                                              offset: Int?) -> SDKFuture<[Record]> where Record.Resource == DR.Resource
}

extension HasMainRecordOperations where Self: HasRecordOperationsDependencies {
    func countRecords<R: SDKResource>(of type: R.Type, annotations: [String]) -> SDKFuture<Int> {
        return combineAsync {
            let userId = try self.keychainService.get(.userId)
            return try combineAwait(self.recordService.countRecords(userId: userId, resourceType: type, annotations: annotations))
        }
    }

    func deleteRecord(withId identifier: String) -> SDKFuture<Void> {
        return combineAsync {
            let userId = try self.keychainService.get(.userId)
            return try combineAwait(self.recordService.deleteRecord(recordId: identifier, userId: userId))
        }
    }

    func fetchRecord<DR: DecryptedRecord, Record: SDKRecord>(withId identifier: String,
                                                             decryptedRecordType: DR.Type = DR.self) -> SDKFuture<Record> where Record.Resource == DR.Resource {
        return combineAsync {
            let userId = try self.keychainService.get(.userId)
            let decryptedRecord: DR = try combineAwait(self.recordService.fetchRecord(recordId: identifier, userId: userId))
            return Record(decryptedRecord: decryptedRecord)
        }
    }

    func fetchRecords<DR: DecryptedRecord, Record: SDKRecord>(decryptedRecordType: DR.Type,
                                                              recordType: Record.Type,
                                                              annotations: [String],
                                                              from startDate: Date?,
                                                              to endDate: Date?,
                                                              pageSize: Int?,
                                                              offset: Int?) -> SDKFuture<[Record]> where Record.Resource == DR.Resource {
        return combineAsync {
            let userId = try self.keychainService.get(.userId)
            let decryptedRecords: [DR] = try combineAwait(self.recordService.searchRecords(for: userId,
                                                                                    from: startDate,
                                                                                    to: endDate,
                                                                                    pageSize: pageSize,
                                                                                    offset: offset,
                                                                                    annotations: annotations,
                                                                                    decryptedRecordType: decryptedRecordType))
            return decryptedRecords.compactMap { Record.init(decryptedRecord: $0)}
        }
    }
}
