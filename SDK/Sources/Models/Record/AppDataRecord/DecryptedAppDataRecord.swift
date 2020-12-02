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
import Data4LifeCrypto
import Then
import CryptoSwift

struct DecryptedAppDataRecord: DecryptedRecord {
    var id: String
    var metadata: Metadata
    var resource: Data
    var tags: [String: String]
    var annotations: [String]
    var dataKey: Key
    let attachmentKey: Key? = nil
    let modelVersion: Int

    static func from(encryptedRecord: EncryptedRecord, cryptoService: CryptoServiceType, commonKeyService: CommonKeyServiceType) -> Async<DecryptedAppDataRecord> {
        return async {
            let commonKey = try decryptCommonKey(from: encryptedRecord, commonKeyService: commonKeyService)
            let dataKey = try decryptDataKey(from: encryptedRecord, commonKey: commonKey, cryptoService: cryptoService)

            let decryptedTagGroup = try decryptTagGroup(from: encryptedRecord, cryptoService: cryptoService)
            let encryptedBase64EncodedData = try resourceData(from: encryptedRecord)
            let decryptedBase64Data = try cryptoService.decrypt(data: encryptedBase64EncodedData,
                                                                key: dataKey)

            let meta = metaData(from: encryptedRecord)
            return DecryptedAppDataRecord(id: encryptedRecord.id,
                                          metadata: meta,
                                          resource: decodeDataIfNeeded(fromBase64EncodedData: decryptedBase64Data),
                                          tags: decryptedTagGroup.tags,
                                          annotations: decryptedTagGroup.annotations,
                                          dataKey: dataKey,
                                          modelVersion: encryptedRecord.modelVersion)
        }
    }
}

private extension DecryptedAppDataRecord {
    /**
     This method is needed because data is always Base64 encoded before uploading, but when retrieved if not decrypted into a type, data needs to be manually base64 decoded.
     The base64 data encoded as Data contains quotes to trim at both ends of the string, therefore dropFirst and dropLast are called
    */
    static func decodeDataIfNeeded(fromBase64EncodedData data: Data) -> Data {
        if let cleanedDataString = String(data: data, encoding: .utf8)?.dropFirst().dropLast(),
           let cleanedData = cleanedDataString.data(using: .utf8),
           let decryptedBase64DecodedData = Data(base64Encoded: cleanedData) {
            return decryptedBase64DecodedData
        } else {
            return data
        }
    }
}
