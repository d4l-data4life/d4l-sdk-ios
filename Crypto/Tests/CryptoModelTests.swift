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
import Data4LifeCrypto

class CryptoModelTests: XCTestCase {
    var bundle: Foundation.Bundle!

    override func setUp() {
        super.setUp()
        bundle = Bundle(for: type(of: self))
    }

    override func tearDown() {
        bundle = nil
        super.tearDown()
    }

    func testKeyCommonV1Success() {
        do {
            let filename = "symCommonExchangeKey"
            let key: Key = try bundle.decodable(fromJSON: filename)

            XCTAssertEqual(key.keySize, 256)
            XCTAssertEqual(key.type, KeyType.common)
            XCTAssertEqual(key.algorithm.cipher, CipherType.aes)
            XCTAssertEqual(key.algorithm.padding, Padding.noPadding)
            XCTAssertEqual(key.algorithm.blockMode, BlockMode.gcm)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testKeyV1Fail() {
        do {
            let filename = "symCommonExchangeKeyInvalid"
            let _: Key = try bundle.decodable(fromJSON: filename)
            XCTFail("Should fail loading key from json")
        } catch {
            let keyType: KeyType = .common
            let expectedError = Data4LifeCryptoError.invalidKeyAlgorithmVersion(keyType.rawValue)
            XCTAssertEqual(error as? Data4LifeCryptoError, expectedError)
        }
    }

    func testKeyTekV1Success() {
        do {
            let filename = "symTagExchangeKey"
            let key: Key = try bundle.decodable(fromJSON: filename)

            XCTAssertEqual(key.keySize, 256)
            XCTAssertEqual(key.type, KeyType.tag)
            XCTAssertEqual(key.algorithm.cipher, CipherType.aes)
            XCTAssertEqual(key.algorithm.padding, Padding.pkcs7)
            XCTAssertEqual(key.algorithm.blockMode, BlockMode.cbc)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testKeyPairV1PKCS8() {
        do {
            let filename = "asymPrivateExchangeKeyPKCS8"
            let keypair: KeyPair = try bundle.decodable(fromJSON: filename)

            XCTAssertEqual(keypair.keySize, 2048)
            XCTAssertEqual(keypair.algorithm.cipher, CipherType.rsa)
            XCTAssertEqual(keypair.algorithm.padding, Padding.oaep)
            XCTAssertEqual(keypair.algorithm.hash, HashType.sha256)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testKeyPairV1PKCS1() {
        do {
            let filename = "asymPrivateExchangeKeyPKCS1"
            let keypair: KeyPair = try bundle.decodable(fromJSON: filename)

            guard
                let json: [String: Any]  = try bundle.json(named: filename),
                let privateKeyBase64EncodedString = json["priv"] as? String else {
                    XCTFail("Could not load JSON data")
                    return
            }

            XCTAssertEqual(keypair.keySize, 2048)
            XCTAssertEqual(keypair.algorithm.cipher, CipherType.rsa)
            XCTAssertEqual(keypair.algorithm.padding, Padding.oaep)
            XCTAssertEqual(keypair.algorithm.hash, HashType.sha256)
            XCTAssertEqual(try! keypair.privateKey.asBase64EncodedString(), privateKeyBase64EncodedString)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
