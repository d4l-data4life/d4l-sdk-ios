//  Copyright (c) 2021 D4L data4life gGmbH
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
@_implementationOnly import Data4LifeCrypto

protocol DecryptedRecord {
    associatedtype Resource: SDKResource

    var id: String { get }
    var metadata: Metadata { get }
    var tags: [String: String] { get }
    var annotations: [String] { get }
    var resource: Resource { get }
    var dataKey: Key { get }
    var attachmentKey: Key? { get }
    var modelVersion: Int { get }

    static func from(encryptedRecord: EncryptedRecord,
                     cryptoService: CryptoServiceType,
                     commonKeyService: CommonKeyServiceType) throws -> Self
}

extension DecryptedRecord {

    static func decryptCommonKey(from encryptedRecord: EncryptedRecord, commonKeyService: CommonKeyServiceType) throws -> Key {
        let recordCommonKeyId = encryptedRecord.commonKeyId ?? CommonKeyService.initialId
        return try combineAwait(commonKeyService.fetchKey(with: recordCommonKeyId))
    }
    static func decryptDataKey(from encryptedRecord: EncryptedRecord, commonKey: Key, cryptoService: CryptoServiceType) throws -> Key {
        guard let dataKeyPayload = Data(base64Encoded: encryptedRecord.encryptedDataKey) else {
            throw Data4LifeSDKError.couldNotReadBase64EncodedData
        }

        let decryptedDataKey: Data = try cryptoService.decrypt(data: dataKeyPayload, key: commonKey)
        return try JSONDecoder().decode(Key.self, from: decryptedDataKey)
    }
    static func decryptTagGroup(from encryptedRecord: EncryptedRecord, cryptoService: CryptoServiceType) throws -> TagGroup {
        guard let tagKey = cryptoService.tagEncryptionKey else {
            throw Data4LifeSDKError.missingTagKey
        }
        return TagGroup(from: try cryptoService.decrypt(values: encryptedRecord.encryptedTags, key: tagKey))
    }
    static func resourceData(from encryptedRecord: EncryptedRecord) throws -> Data {
        guard let resourceData = Data(base64Encoded: encryptedRecord.encryptedBody) else {
            throw Data4LifeSDKError.couldNotReadBase64EncodedData
        }
        return resourceData
    }
    static func metaData(from encryptedRecord: EncryptedRecord) -> Metadata {
        let metadata = Metadata(updatedDate: encryptedRecord.createdAt,
                                createdDate: encryptedRecord.date,
                                status: encryptedRecord.status)
        return metadata
    }
}
