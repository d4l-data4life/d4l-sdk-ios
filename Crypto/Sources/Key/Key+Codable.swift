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

extension Key {
    enum CodingKeys: String, CodingKey {
        case type = "t"
        case version = "v"
        case value = "sym"
    }
}

extension Key: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value.base64EncodedString(), forKey: .value)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(1, forKey: .version)
    }
}

extension Key: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)
        let version = try values.decode(Int.self, forKey: .version)

        guard let keyType = KeyType(rawValue: type) else {
            throw Data4LifeCryptoError.invalidKeyType(type)
        }

        let keyExchangeFormat = try KeyExhangeFactory.create(type: keyType, version: version)
        self.algorithm = keyExchangeFormat.algorithm
        self.keySize = keyExchangeFormat.size

        let keyBase64Value = try values.decode(String.self, forKey: .value)
        guard let keyData = Data(base64Encoded: keyBase64Value) else {
            throw Data4LifeCryptoError.couldNotReadBase64EncodedData
        }

        guard (keyData.byteCount * 8) == keySize else {
            throw Data4LifeCryptoError.keyDoesNotMatchExpectedSize
        }

        self.value = keyData
        self.type = keyType
    }
}
