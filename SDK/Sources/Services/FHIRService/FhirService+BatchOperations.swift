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

extension FhirService {
    func createFhirRecords<DR: DecryptedRecord>(_ resources: [DR.Resource],
                                                annotations: [String] = [],
                                                decryptedRecordType: DR.Type = DR.self) -> SDKFuture<BatchResult<FhirRecord<DR.Resource>, DR.Resource>> where DR.Resource: FhirSDKResource {
        return combineAsync {
            var success: [FhirRecord<DR.Resource>] = []
            var failed: [(DR.Resource, Error)] = []
            try resources.forEach { (resource) in
                try combineAwait(self
                            .createFhirRecord(resource, annotations: annotations, decryptedRecordType: decryptedRecordType)
                            .map { record -> FhirRecord<DR.Resource> in
                                success.append(record)
                                return record }
                            .mapError { error -> Error in
                                failed.append((resource, error))
                                return error
                            }.eraseToAnyPublisher().asyncFuture()
                )
            }

            return ((success, failed))
        }
    }

    func updateFhirRecords<DR: DecryptedRecord>(_ resources: [DR.Resource],
                                                annotations: [String]? = nil,
                                                decryptedRecordType: DR.Type = DR.self) -> SDKFuture<BatchResult<FhirRecord<DR.Resource>, DR.Resource>> where DR.Resource: FhirSDKResource {
        return combineAsync {
            var success: [FhirRecord<DR.Resource>] = []
            var failed: [(DR.Resource, Error)] = []
            try resources.forEach { resource in
                let future = self
                    .updateFhirRecord(resource, annotations: annotations, decryptedRecordType: decryptedRecordType)
                    .map { record -> FhirRecord<DR.Resource> in
                        success.append(record)
                        return record }
                    .mapError { error -> Error in
                        failed.append((resource, error))
                        return error
                    }.eraseToAnyPublisher().asyncFuture()
                try combineAwait(future)
            }

            return (success, failed)
        }
    }

    func fetchFhirRecords<DR: DecryptedRecord>(withIds identifiers: [String],
                                               decryptedRecordType: DR.Type = DR.self) -> SDKFuture<BatchResult<FhirRecord<DR.Resource>, String>> where DR.Resource: FhirSDKResource {
        return combineAsync {
            var success: [FhirRecord<DR.Resource>] = []
            var failed: [(String, Error)] = []
            try identifiers.forEach { recordId in
                let future = self
                    .fetchFhirRecord(withId: recordId, decryptedRecordType: decryptedRecordType)
                    .mapError { error -> Error in
                        failed.append((recordId, error))
                        return error }
                    .map { record -> FhirRecord<DR.Resource> in
                        success.append(record)
                        return record
                    }
                    .eraseToAnyPublisher()
                    .asyncFuture()
                try combineAwait(future)
            }

            return ((success, failed))
        }
    }

    func downloadFhirRecordsWithAttachments<DR: DecryptedRecord>(withIds identifiers: [String],
                                                                 decryptedRecordType: DR.Type = DR.self,
                                                                 parentProgress: Progress)
    -> SDKFuture<BatchResult<FhirRecord<DR.Resource>, String>> where DR.Resource: FhirSDKResource {
        return combineAsync {
            var success: [FhirRecord<DR.Resource>] = []
            var fail: [(String, Error)] = []
            identifiers.forEach { identifier in
                do {
                    let downloadProgress = Progress(totalUnitCount: 1, parent: parentProgress, pendingUnitCount: 1)
                    downloadProgress.becomeCurrent(withPendingUnitCount: 1)
                    let record: FhirRecord<DR.Resource> = try combineAwait(self.downloadFhirRecordWithAttachments(withId: identifier, decryptedRecordType: decryptedRecordType))
                    success.append(record)
                    downloadProgress.resignCurrent()
                } catch {
                    fail.append((identifier, error))
                }
            }
            return (success, fail)
        }
    }

    func deleteFhirRecords(withIds identifiers: [String]) -> SDKFuture<BatchResult<String, String>> {
        return combineAsync {
            var success: [String] = []
            var failed: [(String, Error)] = []
            try identifiers.forEach { recordId in
                let future = self
                    .deleteRecord(withId: recordId)
                    .mapError { error -> Error in
                        failed.append((recordId, error))
                        return error }
                    .map { _ in
                        success.append(recordId)
                    }
                    .eraseToAnyPublisher()
                    .asyncFuture()
                try combineAwait(future)
            }
            return ((success, failed))
        }
    }
}
