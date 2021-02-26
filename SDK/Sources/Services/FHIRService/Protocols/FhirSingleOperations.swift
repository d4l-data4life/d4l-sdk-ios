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
@_implementationOnly import Then

protocol FhirSingleOperations {
    func fetchFhirRecord<DR: DecryptedRecord>(withId identifier: String, decryptedRecordType: DR.Type) -> Promise<FhirRecord<DR.Resource>> where DR.Resource: FhirSDKResource
    func fetchFhirRecords<DR: DecryptedRecord>(from: Date?,
                                               to: Date?,
                                               pageSize: Int?,
                                               offset: Int?,
                                               annotations: [String],
                                               decryptedRecordType: DR.Type) -> Promise<[FhirRecord<DR.Resource>]> where DR.Resource: FhirSDKResource
    func deleteFhirRecord(withId identifier: String) -> Promise<Void>
    func countFhirRecords<R: FhirSDKResource>(of type: R.Type, annotations: [String]) -> Promise<Int>
    func createFhirRecord<DR: DecryptedRecord>(_ resource: DR.Resource, annotations: [String], decryptedRecordType: DR.Type) -> Promise<FhirRecord<DR.Resource>> where DR.Resource: FhirSDKResource
    func updateFhirRecord<DR: DecryptedRecord>(_ resource: DR.Resource, annotations: [String]?, decryptedRecordType: DR.Type) -> Promise<FhirRecord<DR.Resource>> where DR.Resource: FhirSDKResource
}

extension FhirSingleOperations where Self: HasMainRecordOperations {

    func fetchFhirRecord<DR: DecryptedRecord>(withId identifier: String, decryptedRecordType: DR.Type) -> Promise<FhirRecord<DR.Resource>> where DR.Resource: FhirSDKResource {
        return fetchRecord(withId: identifier, decryptedRecordType: decryptedRecordType)
    }

    func fetchFhirRecords<DR: DecryptedRecord>(from: Date?,
                                               to: Date?,
                                               pageSize: Int?,
                                               offset: Int?,
                                               annotations: [String],
                                               decryptedRecordType: DR.Type) -> Promise<[FhirRecord<DR.Resource>]> where DR.Resource: FhirSDKResource {
        fetchRecords(decryptedRecordType: decryptedRecordType,
                     recordType: FhirRecord<DR.Resource>.self,
                     annotations: annotations,
                     from: from,
                     to: to,
                     pageSize: pageSize,
                     offset: offset)
    }

    func deleteFhirRecord(withId identifier: String) -> Promise<Void> {
        return deleteRecord(withId: identifier)
    }

    func countFhirRecords<R: FhirSDKResource>(of type: R.Type, annotations: [String]) -> Promise<Int> {
        countRecords(of: R.self, annotations: annotations)
    }
}
