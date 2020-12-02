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

protocol FhirServiceBatchOperations {
    func createFhirRecords<R: FhirSDKResource, DR: DecryptedRecord>(_ resources: [R],
                                                                    annotations: [String],
                                                                    decryptedRecordType: DR.Type) -> Promise<BatchResult<FhirRecord<R>, R>> where DR.Resource == R
    func updateFhirRecords<R: FhirSDKResource, DR: DecryptedRecord>(_ resources: [R],
                                                                    annotations: [String]?,
                                                                    decryptedRecordType: DR.Type) -> Promise<BatchResult<FhirRecord<R>, R>> where DR.Resource == R
    func fetchFhirRecords<R: FhirSDKResource, DR: DecryptedRecord>(withIds identifiers: [String],
                                                                   of type: R.Type,
                                                                   decryptedRecordType: DR.Type) -> Promise<BatchResult<FhirRecord<R>, String>> where DR.Resource == R
    func downloadFhirRecordsWithAttachments<R: FhirSDKResource, DR: DecryptedRecord>(withIds identifiers: [String],
                                                                                     of type: R.Type,
                                                                                     decryptedRecordType: DR.Type,
                                                                                     parentProgress: Progress) -> Promise<BatchResult<FhirRecord<R>, String>> where DR.Resource == R
    func deleteFhirRecords(withIds identifiers: [String]) -> Promise<BatchResult<String, String>>
}
