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
import Data4LifeFHIR

extension Promise where T == FhirRecord<Data4LifeFHIR.DocumentReference> {
    func transformRecord<R: FhirSDKResource>(to valueType: R.Type) -> Promise<FhirRecord<R>> {
        return async {
            let value = try wait(self)
            let resource = try value.fhirResource.map(to: R.self)
            return FhirRecord(id: value.id, resource: resource, metadata: value.metadata, annotations: value.annotations)
        }
    }
}

extension Promise where T == BatchResult<FhirRecord<Data4LifeFHIR.DocumentReference>, Data4LifeFHIR.DocumentReference> {
    func transformRecords<R: FhirSDKResource>(to valueType: R.Type) -> Promise<BatchResult<FhirRecord<R>, R>> {
        return async {
            let value = try wait(self)
            let success = try value.success.map { oldRecord -> FhirRecord<R> in
                let resource = try oldRecord.fhirResource.map(to: R.self)
                return FhirRecord(id: oldRecord.id, resource: resource, metadata: oldRecord.metadata, annotations: oldRecord.annotations)
            }
            let failed = try value.failed.map { input -> (R, Error) in
                let resource = try input.object.map(to: R.self)
                return (resource, input.error)
            }
            return (success, failed)
        }
    }
}
