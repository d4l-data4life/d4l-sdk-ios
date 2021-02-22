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
import Data4LifeCrypto

struct DecryptedRecordFactory {
    static func create<R: FhirR4Resource>(_ fhirResource: R,
                                          annotations: [String] = [],
                                          dataKey: Key = KeyFactory.createKey(),
                                          attachmentKey: Key? = KeyFactory.createKey()) -> DecryptedFhirR4Record<R> {
        let tags = ["resourcetype": Swift.type(of: fhirResource).resourceType.rawValue.lowercased()]
        let metadata = Metadata(updatedDate: Date(), createdDate: Date())
        let id = fhirResource.id ?? UUID().uuidString.asFHIRStringPrimitive()
        fhirResource.id = id
        return DecryptedFhirR4Record(id: id.value!.string,
                                     metadata: metadata,
                                     tags: tags,
                                     annotations: annotations,
                                     resource: fhirResource,
                                     dataKey: dataKey,
                                     attachmentKey: attachmentKey,
                                     modelVersion: R.modelVersion)
    }
    static func create<R: FhirStu3Resource>(_ fhirResource: R,
                                            annotations: [String] = [],
                                            dataKey: Key = KeyFactory.createKey(),
                                            attachmentKey: Key? = KeyFactory.createKey()) -> DecryptedFhirStu3Record<R> {
        let tags = ["resourcetype": Swift.type(of: fhirResource).resourceType.lowercased()]
        let metadata = Metadata(updatedDate: Date(), createdDate: Date())
        let id = fhirResource.id ?? UUID().uuidString
        fhirResource.id = id
        return DecryptedFhirStu3Record(id: id,
                                       metadata: metadata,
                                       tags: tags,
                                       annotations: annotations,
                                       resource: fhirResource.copy() as! R, // swiftlint:disable:this force_cast
            dataKey: dataKey,
            attachmentKey: attachmentKey,
            modelVersion: R.modelVersion)
    }

    static func create(_ appData: Data,
                       annotations: [String] = [],
                       dataKey: Key = KeyFactory.createKey()) -> DecryptedAppDataRecord {
        let tags = ["flag":"appdata"]
        let metadata = Metadata(updatedDate: Date(), createdDate: Date())
        return DecryptedAppDataRecord(id: UUID().uuidString,
                                      metadata: metadata,
                                      resource: appData,
                                      tags: tags,
                                      annotations: annotations,
                                      dataKey: dataKey,
                                      modelVersion: Data.modelVersion)
    }
}

extension DecryptedFhirR4Record {
    func copy<R: FhirR4Resource>(with resource: R) -> DecryptedFhirR4Record<R> {
        return DecryptedFhirR4Record<R>(id: id,
                                        metadata: metadata,
                                        tags: tags,
                                        annotations: annotations,
                                        resource: resource.copy() as! R, // swiftlint:disable:this force_cast
                                        dataKey: dataKey,
                                        attachmentKey: attachmentKey,
                                        modelVersion: modelVersion)
    }
}

extension DecryptedFhirStu3Record {
    func copy<R: FhirStu3Resource>(with resource: R) -> DecryptedFhirStu3Record<R> {
        return DecryptedFhirStu3Record<R>(id: id,
                                          metadata: metadata,
                                          tags: tags,
                                          annotations: annotations,
                                          resource: resource.copy() as! R, // swiftlint:disable:this force_cast
            dataKey: dataKey,
            attachmentKey: attachmentKey,
            modelVersion: modelVersion)
    }
}

extension DecryptedAppDataRecord {

    func copy(with resource: Data) -> DecryptedAppDataRecord {
        return DecryptedAppDataRecord(id: id,
                                      metadata: metadata,
                                      resource: resource,
                                      tags: tags,
                                      annotations: annotations,
                                      dataKey: dataKey,
                                      modelVersion: modelVersion)
    }
}
