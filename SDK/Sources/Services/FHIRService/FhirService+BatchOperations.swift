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
import Combine

extension FhirService {
    func createFhirRecords<DR: DecryptedRecord>(_ resources: [DR.Resource],
                                                annotations: [String] = [],
                                                decryptedRecordType: DR.Type = DR.self) -> NoErrorFuture<BatchResult<FhirRecord<DR.Resource>, DR.Resource>> where DR.Resource: FhirSDKResource {
        return combineAsync {
            let identifiedFutures = resources.map { ($0, createFhirRecord($0, annotations: annotations, decryptedRecordType: decryptedRecordType)) }
            let combineResult = combineAwait(identifiedFutures)
            return (combineResult.successRequests.map { $0.1 }, combineResult.failedRequests)
        }
    }

    func updateFhirRecords<DR: DecryptedRecord>(_ resources: [DR.Resource],
                                                annotations: [String]? = nil,
                                                decryptedRecordType: DR.Type = DR.self) -> NoErrorFuture<BatchResult<FhirRecord<DR.Resource>, DR.Resource>> where DR.Resource: FhirSDKResource {
        return combineAsync {
            let identifiedFutures = resources.map { ($0, updateFhirRecord($0, annotations: annotations, decryptedRecordType: decryptedRecordType)) }
            let combineResult = combineAwait(identifiedFutures)
            return (combineResult.successRequests.map { $0.1 }, combineResult.failedRequests)
        }
    }

    func fetchFhirRecords<DR: DecryptedRecord>(withIds identifiers: [String],
                                               decryptedRecordType: DR.Type = DR.self) -> NoErrorFuture<BatchResult<FhirRecord<DR.Resource>, String>> where DR.Resource: FhirSDKResource {
        return combineAsync {
            let identifiedFutures = identifiers.map { ($0, fetchFhirRecord(withId: $0, decryptedRecordType: decryptedRecordType)) }
            let combineResult = combineAwait(identifiedFutures)
            return (combineResult.successRequests.map { $0.1 }, combineResult.failedRequests)
        }
    }

    func deleteFhirRecords(withIds identifiers: [String]) -> NoErrorFuture<BatchResult<String, String>> {
        return combineAsync {
            let identifiedFutures = identifiers.map { ($0, deleteRecord(withId: $0)) }
            let combineResult = combineAwait(identifiedFutures)
            return (combineResult.successRequests.map { $0.0 }, combineResult.failedRequests)
        }
    }

    func downloadFhirRecordsWithAttachments<DR: DecryptedRecord>(withIds identifiers: [String],
                                                                 decryptedRecordType: DR.Type = DR.self,
                                                                 parentProgress: Progress)
    -> NoErrorFuture<BatchResult<FhirRecord<DR.Resource>, String>> where DR.Resource: FhirSDKResource {
        return combineAsync {
            let identifiedFutures = identifiers.map { ($0, downloadFhirRecordWithAttachments(withId: $0, decryptedRecordType: decryptedRecordType)) }
            let combineResult = combineAwait(identifiedFutures, progress: parentProgress)
            return (combineResult.successRequests.map { $0.1 }, combineResult.failedRequests)
        }
    }
}
