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
@testable import Data4LifeSDK

struct EncryptedRecordFactory {

    private let builder: RecordServiceParameterBuilder
    private let cryptoService: CryptoServiceMock

    init(container: DIContainer) {
        do {
            self.builder = try container.resolve()
            self.cryptoService = try container.resolve(as: CryptoServiceType.self)
        } catch {
            fatalError(error.localizedDescription)
        }

        cryptoService.tagEncryptionKey = KeyFactory.createKey(.tag)
    }

    func create<T, DR: DecryptedRecord>(for decryptedRecord: DR, resource: T, commonKeyId: String? = nil) -> EncryptedRecord where DR.Resource == T {

        let resourceData: Data = try! resource.encodedData(with: JSONEncoder())
        let dataKeyData: Data = try! JSONEncoder().encode(decryptedRecord.dataKey)
        let attachmentKeyData: Data? = try? JSONEncoder().encode(decryptedRecord.attachmentKey)
        let tagGroup = TagGroup(tags: decryptedRecord.tags, annotations: decryptedRecord.annotations)
        let tagParameters = tagsParameter(for: tagGroup)

        return EncryptedRecord(id: decryptedRecord.id,
                               encryptedTags: tagParameters,
                               encryptedBody: resourceData.base64EncodedString(),
                               createdAt: decryptedRecord.metadata.updatedDate,
                               date: decryptedRecord.metadata.createdDate,
                               encryptedDataKey: dataKeyData.base64EncodedString(),
                               encryptedAttachmentKey: attachmentKeyData?.base64EncodedString() ?? nil,
                               modelVersion: decryptedRecord.modelVersion,
                               commonKeyId: commonKeyId,
                               status: decryptedRecord.metadata.status)
    }

    func create<T, DR: DecryptedRecord>(for decryptedRecord: DR, commonKeyId: String? = nil) -> EncryptedRecord where DR.Resource == T {
        return self.create(for: decryptedRecord, resource: decryptedRecord.resource, commonKeyId: commonKeyId)
    }

    func tagsParameter(for tagGroup: TagGroup) -> [String] {
        let commaSeparatedTags = try! builder.searchParameters(tagGroup: tagGroup, supportingLegacyTags: false)["tags"] as? String
        return commaSeparatedTags?.components(separatedBy: ",") ?? []
    }
}

extension EncryptedRecord {
    var json: [String: Any] {
        var payload: [String: Any] = [
            "record_id": self.id,
            "encrypted_tags": self.encryptedTags,
            "encrypted_body": self.encryptedBody,
            "createdAt": self.createdAt.ISO8601FormattedString(),
            "date": self.date.yyyyMmDdFormattedString(),
            "encrypted_key": self.encryptedDataKey,
            "model_version": self.modelVersion,
            "status": self.status.rawValue
        ]

        guard  let attachmentKey = encryptedAttachmentKey else {
            return payload
        }

        payload["attachment_key"] = attachmentKey
        return payload
    }
    var data: Data {
        return try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    }

    var encryptedBodyData: Data { return Data(base64Encoded: encryptedBody)! }
    var encryptedDataKeyData: Data { return Data(base64Encoded: encryptedDataKey)! }
    var encryptedAttachmentKeyData: Data? {
        guard let attachmentKey = encryptedAttachmentKey else {
            return nil
        }
        return Data(base64Encoded: attachmentKey)
    }
}
