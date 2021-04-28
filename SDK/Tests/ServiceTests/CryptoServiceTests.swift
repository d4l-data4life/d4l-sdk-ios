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

import XCTest
@testable import Data4LifeSDK
import Data4LifeCrypto

class CryptoServiceTests: XCTestCase {

    var crypto: CryptoService!
    var keychainService: KeychainServiceMock!
    var bundle: Foundation.Bundle!
    let keyPairTag = "crypto.tests.keypair"

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        crypto = CryptoService(container: container, keyPairTag: keyPairTag)

        do {
            keychainService = try container.resolve(as: KeychainServiceType.self)
            bundle = try container.resolve()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    override func tearDown() {
        try? crypto.deleteKeyPair()
        crypto = nil
        keychainService = nil
        super.tearDown()
    }

    func testLoadAndStoreTek() {
        let tek = KeyFactory.createKey(.tag)
        let base64EncodedKey = try! JSONEncoder().encode(tek).base64EncodedString()
        XCTAssertNil(crypto.tek)
        crypto.tek = tek
        XCTAssertTrue(keychainService.setItemCalledWith.contains(where: {
            $0.0 == base64EncodedKey && $0.1 == KeychainKey.tagEncryptionKey
        }))
        XCTAssertNotNil(crypto.tek)
        XCTAssertEqual(self.keychainService[.tagEncryptionKey], base64EncodedKey)
    }

    func testEncryptDecryptData() {
        let input = Data([0x00, 0x001])
        let commonKey = KeyFactory.createKey(.common)

        do {
            let encryptedData = try crypto.encrypt(data: input, key: commonKey)
            let decryptedData = try crypto.decrypt(data: encryptedData, key: commonKey)
            XCTAssertEqual(input, decryptedData)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testEncryptDecryptValues() {
        let values = ["one", "two"]
        let key = KeyFactory.createKey()

        do {
            let encryptedValues = try crypto.encrypt(values: values, key: key)
            let decryptedValues = try crypto.decrypt(values: encryptedValues, key: key)
            XCTAssertEqual(values, decryptedValues)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDecryptStringFailEncodingCiphertext() {
        let expectedError = Data4LifeSDKError.couldNotReadBase64EncodedData
        do {
            let key = KeyFactory.createKey()
            let ciphertext = String(describing: Data([0x00]))
            _ = try crypto.decrypt(string: ciphertext, key: key)
            XCTFail("Should fail decoding base64 data")
        } catch let error as Data4LifeSDKError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Should be an SDK error")
        }
    }

    func testDecryptPayloadDoesNotContainIV() {
        let data = Data([0x00])
        let key = KeyFactory.createKey()
        let expectedError = Data4LifeSDKError.invalidEncryptedDataSize
        do {
            _ = try crypto.decrypt(data: data, key: key)
            XCTFail("Should throw an error")
        } catch let error as Data4LifeSDKError {
            XCTAssertEqual(expectedError, error)
        } catch {
            XCTFail("Should return SDK error type")
        }
    }
}

struct KeyFactory {
    static func createKey(_ type: KeyType = .common) -> Key {
        let exchangeFormat = try! KeyExhangeFactory.create(type: type)
        return try! Key.generate(keySize: exchangeFormat.size, algorithm: exchangeFormat.algorithm, type: type)
    }

    static func createKeyPair(tag: String) -> KeyPair {
        return try! KeyPair.generate(tag: tag, keySize: 2048, algorithm: RSAAlgorithm())
    }
}
