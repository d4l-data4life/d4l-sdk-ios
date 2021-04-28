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
import Data4LifeFHIR
import Data4LifeFHIRCore
import ModelsR4

@_implementationOnly import Data4LifeCrypto
@_implementationOnly import Then

struct DecryptedFhirStu3Record<T: FhirStu3Resource>: DecryptedRecord {
    var id: String
    var metadata: Metadata
    var tags: [String: String]
    var annotations: [String]
    var resource: T
    var dataKey: Key
    var attachmentKey: Key?
    let modelVersion: Int

    static func from(encryptedRecord: EncryptedRecord,
                     cryptoService: CryptoServiceType,
                     commonKeyService: CommonKeyServiceType) -> Async<DecryptedFhirStu3Record<T>> {
        return async {
            guard encryptedRecord.modelVersion <= T.modelVersion else {
                throw Data4LifeSDKError.invalidRecordModelVersionNotSupported
            }

            let tagGroup = try decryptTagGroup(from: encryptedRecord, cryptoService: cryptoService)
            let commonKey = try decryptCommonKey(from: encryptedRecord, commonKeyService: commonKeyService)
            let encryptedData = try resourceData(from: encryptedRecord)

            let dataKey = try decryptDataKey(from: encryptedRecord, commonKey: commonKey, cryptoService: cryptoService)
            let attachmentKey = try decryptAttachmentKey(from: encryptedRecord, commonKey: commonKey, cryptoService: cryptoService)

            let anyResource = try `await`(cryptoService.decrypt(data: encryptedData,
                                                              to: AnyResource<T>.self,
                                                              key: dataKey))
            let meta = metaData(from: encryptedRecord)
            anyResource.resource.id = encryptedRecord.id
            return DecryptedFhirStu3Record(id: encryptedRecord.id,
                                           metadata: meta,
                                           tags: tagGroup.tags,
                                           annotations: tagGroup.annotations,
                                           resource: anyResource.resource,
                                           dataKey: dataKey,
                                           attachmentKey: attachmentKey,
                                           modelVersion: encryptedRecord.modelVersion)
        }
    }
}

extension DecryptedFhirStu3Record {

    private static func decryptAttachmentKey(from encryptedRecord: EncryptedRecord, commonKey: Key, cryptoService: CryptoServiceType) throws -> Key? {
        if let eak = encryptedRecord.encryptedAttachmentKey, let attachmentKeyPayload = Data(base64Encoded: eak) {
            let decryptedAttachmentKey: Data = try cryptoService.decrypt(data: attachmentKeyPayload, key: commonKey)
            return try JSONDecoder().decode(Key.self, from: decryptedAttachmentKey)
        } else {
            return nil
        }
    }
}

struct DecryptedFhirR4Record<T: FhirR4Resource>: DecryptedRecord {
    var id: String
    var metadata: Metadata
    var tags: [String: String]
    var annotations: [String]
    var resource: T
    var dataKey: Key
    var attachmentKey: Key?
    let modelVersion: Int

    static func from(encryptedRecord: EncryptedRecord,
                     cryptoService: CryptoServiceType,
                     commonKeyService: CommonKeyServiceType) -> Async<DecryptedFhirR4Record<T>> {
        return async {
            guard encryptedRecord.modelVersion <= T.modelVersion else {
                throw Data4LifeSDKError.invalidRecordModelVersionNotSupported
            }

            let decryptedTagGroup = try decryptTagGroup(from: encryptedRecord, cryptoService: cryptoService)
            let commonKey = try decryptCommonKey(from: encryptedRecord, commonKeyService: commonKeyService)
            let encryptedData = try resourceData(from: encryptedRecord)

            let dataKey = try decryptDataKey(from: encryptedRecord, commonKey: commonKey, cryptoService: cryptoService)
            let attachmentKey = try decryptAttachmentKey(from: encryptedRecord, commonKey: commonKey, cryptoService: cryptoService)

            let resourceProxy = try `await`(cryptoService.decrypt(data: encryptedData,
                                                                to: ResourceProxy.self,
                                                                key: dataKey))
            guard let resource = resourceProxy.get(if: T.self) else {
                throw Data4LifeSDKError.invalidResourceCouldNotConvertToType(String(describing: T.self))
            }

            let meta = metaData(from: encryptedRecord)
            resource.id = encryptedRecord.id.asFHIRStringPrimitive()
            return DecryptedFhirR4Record(id: encryptedRecord.id,
                                         metadata: meta,
                                         tags: decryptedTagGroup.tags,
                                         annotations: decryptedTagGroup.annotations,
                                         resource: resource,
                                         dataKey: dataKey,
                                         attachmentKey: attachmentKey,
                                         modelVersion: encryptedRecord.modelVersion)
        }
    }
}

extension DecryptedFhirR4Record {

    private static func decryptAttachmentKey(from encryptedRecord: EncryptedRecord, commonKey: Key, cryptoService: CryptoServiceType) throws -> Key? {
        if let eak = encryptedRecord.encryptedAttachmentKey, let attachmentKeyPayload = Data(base64Encoded: eak) {
            let decryptedAttachmentKey: Data = try cryptoService.decrypt(data: attachmentKeyPayload, key: commonKey)
            return try JSONDecoder().decode(Key.self, from: decryptedAttachmentKey)
        } else {
            return nil
        }
    }
}
