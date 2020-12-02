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

extension FhirService {
    func createFhirRecords<R: FhirSDKResource, DR: DecryptedRecord>(_ resources: [R],
                                                                    annotations: [String] = [],
                                                                    decryptedRecordType: DR.Type = DR.self) -> Promise<BatchResult<FhirRecord<R>, R>> where DR.Resource == R {
        return async {
            var success: [FhirRecord<R>] = []
            var failed: [(R, Error)] = []
            try resources.forEach { (resource) in
                try await(self.createFhirRecord(resource, annotations: annotations, decryptedRecordType: decryptedRecordType)
                            .then { success.append($0) }
                            .onError { failed.append((resource, $0)) }
                )
            }

            return ((success, failed))
        }
    }

    func updateFhirRecords<R: FhirSDKResource, DR: DecryptedRecord>(_ resources: [R],
                                                                    annotations: [String]? = nil,
                                                                    decryptedRecordType: DR.Type = DR.self) -> Promise<BatchResult<FhirRecord<R>, R>> where DR.Resource == R {
        return async {
            var success: [FhirRecord<R>] = []
            var failed: [(R, Error)] = []
            try resources.forEach { resource in
                try await(self.updateFhirRecord(resource, annotations: annotations, decryptedRecordType: decryptedRecordType)
                            .then { success.append($0) }
                            .onError { failed.append((resource, $0)) }
                )
            }

            return (success, failed)
        }
    }

    func fetchFhirRecords<R: FhirSDKResource, DR: DecryptedRecord>(withIds identifiers: [String],
                                                                   of type: R.Type = R.self,
                                                                   decryptedRecordType: DR.Type = DR.self) -> Promise<BatchResult<FhirRecord<R>, String>>  where DR.Resource == R {
        return async {
            var success: [FhirRecord<R>] = []
            var failed: [(String, Error)] = []
            try identifiers.forEach { recordId in
                try await(self.fetchFhirRecord(withId: recordId, decryptedRecordType: decryptedRecordType)
                            .then { success.append($0) }
                            .onError { failed.append((recordId, $0)) }
                )
            }
            return ((success, failed))
        }
    }

    func downloadFhirRecordsWithAttachments<R: FhirSDKResource, DR: DecryptedRecord>(withIds identifiers: [String],
                                                                                     of type: R.Type = R.self,
                                                                                     decryptedRecordType: DR.Type = DR.self,
                                                                                     parentProgress: Progress)
    -> Promise<BatchResult<FhirRecord<R>, String>> where DR.Resource == R {
        return async {
            var success: [FhirRecord<R>] = []
            var fail: [(String, Error)] = []
            identifiers.forEach { identifier in
                do {
                    let downloadProgress = Progress(totalUnitCount: 1, parent: parentProgress, pendingUnitCount: 1)
                    downloadProgress.becomeCurrent(withPendingUnitCount: 1)
                    let record: FhirRecord<R> = try await(self.downloadFhirRecordWithAttachments(withId: identifier, of: type, decryptedRecordType: decryptedRecordType))
                    success.append(record)
                    downloadProgress.resignCurrent()
                } catch {
                    fail.append((identifier, error))
                }
            }
            return (success, fail)
        }
    }

    func deleteFhirRecords(withIds identifiers: [String]) -> Promise<BatchResult<String, String>> {
        return async {
            var success: [String] = []
            var failed: [(String, Error)] = []
            try identifiers.forEach { recordId in
                try await(self.deleteRecord(withId: recordId)
                            .then { success.append(recordId) }
                            .onError { failed.append((recordId, $0)) }
                )
            }
            return ((success, failed))
        }
    }
}
