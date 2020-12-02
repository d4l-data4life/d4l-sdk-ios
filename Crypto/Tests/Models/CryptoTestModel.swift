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
@testable import Data4LifeCrypto

struct AsymCryptoTestModel: Decodable {
    var inputData: Data
    var outputData: Data?
    var keypair: KeyPair

    enum CodingKeys: String, CodingKey {
        case input
        case output
        case privateKey
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let inputBase64Value = try values.decode(String.self, forKey: .input)
        let outputBase64Value = try values.decodeIfPresent(String.self, forKey: .output)

        self.inputData = Data(base64Encoded: inputBase64Value)!
        self.keypair = try values.decode(KeyPair.self, forKey: .privateKey)

        if let output = outputBase64Value {
            self.outputData = Data(base64Encoded: output)
        }
    }
}

struct SymCryptoTestModel: Decodable {
    var inputData: Data
    var outputData: Data
    var inputString: String
    var outputString: String
    var key: Key
    var iv: Data

    enum CodingKeys: String, CodingKey {
        case input
        case output
        case key
        case iv
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let inputBase64Value = try values.decode(String.self, forKey: .input)
        let outputBase64Value = try values.decode(String.self, forKey: .output)
        let ivBase64Value = try values.decodeIfPresent(String.self, forKey: .iv) ?? ""

        self.inputString = inputBase64Value
        self.outputString = outputBase64Value

        self.inputData = Data(base64Encoded: inputBase64Value)!
        self.outputData = Data(base64Encoded: outputBase64Value)!
        self.iv = Data(base64Encoded: ivBase64Value)!
        self.key = try values.decode(Key.self, forKey: .key)
    }
}
