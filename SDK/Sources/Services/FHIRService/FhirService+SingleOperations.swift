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
import Data4LifeFHIR
import struct Data4LifeCrypto.Key

extension FhirService {
    func createFhirRecord<DR: DecryptedRecord>(_ resource: DR.Resource,
                                               annotations: [String] = [],
                                               decryptedRecordType: DR.Type = DR.self) ->
    Promise<FhirRecord<DR.Resource>> where DR.Resource: FhirSDKResource {
        return async {
            let userId = try await(self.keychainService.get(.userId))
            let resourceWithKey = try await(self.uploadAttachments(creating: resource))
            let decryptedRecord = try await(self.recordService.createRecord(forResource: resourceWithKey.resource,
                                                                            annotations: annotations,
                                                                            userId: userId,
                                                                            attachmentKey: resourceWithKey.key,
                                                                            decryptedRecordType: decryptedRecordType))
            return FhirRecord(decryptedRecord: decryptedRecord)
        }
    }

    func updateFhirRecord<DR: DecryptedRecord>(_ resource: DR.Resource,
                                               annotations: [String]? = nil,
                                               decryptedRecordType: DR.Type = DR.self) -> Promise<FhirRecord<DR.Resource>> where DR.Resource: FhirSDKResource {
        return async {
            let userId = try await(self.keychainService.get(.userId))
            guard let recordId = resource.fhirIdentifier else { throw Data4LifeSDKError.invalidResourceMissingId }

            let resourceWithKey = try await(self.uploadAttachments(updating: resource, decryptedRecordType: decryptedRecordType))

            let updatedRecord = try await(self.recordService.updateRecord(forResource: resourceWithKey.resource,
                                                                          annotations: annotations,
                                                                          userId: userId,
                                                                          recordId: recordId,
                                                                          attachmentKey: resourceWithKey.key,
                                                                          decryptedRecordType: decryptedRecordType))
            return FhirRecord(decryptedRecord: updatedRecord)
        }
    }
}
