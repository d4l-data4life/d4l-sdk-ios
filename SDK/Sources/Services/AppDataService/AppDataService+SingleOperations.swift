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

import Then

protocol AppDataServiceSingleOperations {
    func createAppDataRecord(_ data: Data, annotations: [String]) -> Promise<AppDataRecord>
    func updateAppDataRecord(_ data: Data, recordId: String, annotations: [String]?) -> Promise<AppDataRecord>
    func fetchAppDataRecord(withId identifier: String) -> Promise<AppDataRecord>
    func fetchAppDataRecords(from: Date?, to: Date?, pageSize: Int?, offset: Int?, annotations: [String]) -> Promise<[AppDataRecord]>
    func deleteAppDataRecord(withId identifier: String) -> Promise<Void>
    func countAppDataRecords(annotations: [String]) -> Promise<Int>
}

extension AppDataServiceSingleOperations where Self: HasMainRecordOperations {
    func fetchAppDataRecord(withId identifier: String) -> Promise<AppDataRecord> {
        return fetchRecord(withId: identifier, decryptedRecordType: DecryptedAppDataRecord.self)
    }

    func deleteAppDataRecord(withId identifier: String) -> Promise<Void> {
        return deleteRecord(withId: identifier)
    }

    func countAppDataRecords(annotations: [String] = []) -> Promise<Int> {
        return countRecords(of: Data.self, annotations: annotations)
    }

    func fetchAppDataRecords(from: Date?, to: Date?, pageSize: Int?, offset: Int?, annotations: [String] = []) -> Promise<[AppDataRecord]> {
        return fetchRecords(decryptedRecordType: DecryptedAppDataRecord.self,
                            recordType: AppDataRecord.self,
                            annotations: annotations,
                            from: from,
                            to: to,
                            pageSize: pageSize,
                            offset: offset)
    }
}

extension AppDataService {
    func createAppDataRecord(_ data: Data, annotations: [String] = []) -> Promise<AppDataRecord> {
        return async {
            let userId = try await(self.keychainService.get(.userId))
            let record: DecryptedAppDataRecord = try await(self.recordService.createRecord(forResource: data,
                                                                                           annotations: annotations,
                                                                                           userId: userId,
                                                                                           attachmentKey: nil,
                                                                                           decryptedRecordType: DecryptedAppDataRecord.self))
            return AppDataRecord(decryptedRecord: record)

        }
    }

    func updateAppDataRecord(_ data: Data, recordId: String, annotations: [String]? = nil) -> Promise<AppDataRecord> {
        return async {
            let userId = try await(self.keychainService.get(.userId))
            let updatedRecord = try await(self.recordService.updateRecord(forResource: data,
                                                                          annotations: annotations,
                                                                          userId: userId,
                                                                          recordId: recordId,
                                                                          attachmentKey: nil,
                                                                          decryptedRecordType: DecryptedAppDataRecord.self))
            return AppDataRecord(decryptedRecord: updatedRecord)
        }
    }
}
