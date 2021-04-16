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
@testable import Data4LifeCrypto

class KeyPairTests: XCTestCase {
    func testGenerateLoadAndDestroyKeyPair() {
        do {
            let tag = UUID().uuidString
            let size = 2048
            let algo = RSAAlgorithm()

            let generatedKeyPair = try KeyPair.generate(tag: tag, keySize: size, algorithm: algo)
            let loadedKeyPair = try KeyPair.load(tag: tag, algorithm: algo)

            let privateBase64String = try generatedKeyPair.privateKey.asBase64EncodedString()
            XCTAssertEqual(privateBase64String, try loadedKeyPair.privateKey.asBase64EncodedString())
            XCTAssertEqual(generatedKeyPair.algorithm.blockMode?.rawValue, loadedKeyPair.algorithm.blockMode?.rawValue)
            XCTAssertEqual(generatedKeyPair.algorithm.cipher.rawValue, loadedKeyPair.algorithm.cipher.rawValue)
            XCTAssertEqual(generatedKeyPair.algorithm.padding.rawValue, loadedKeyPair.algorithm.padding.rawValue)
            XCTAssertEqual(generatedKeyPair.algorithm.hash?.rawValue, loadedKeyPair.algorithm.hash?.rawValue)

            try KeyPair.destroy(tag: tag)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testGenerateKeyPairAndExportPubKeyAsSPKI() {
        let tag = UUID().uuidString
        let size = 2048
        let algo = RSAAlgorithm()

        do {
            let keyPair = try KeyPair.generate(tag: tag, keySize: size, algorithm: algo)
            _ = try keyPair.publicKey.asSPKIBase64EncodedString()
            try KeyPair.destroy(tag: tag)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testGenerateKeyPairAndFailExportingAsSPKI() {
        let tag = UUID().uuidString
        let size = 1024 // there is no SPKI header for 1024 key, but it's possible to create keypair
        let algo = RSAAlgorithm()

        do {
            let keyPair = try KeyPair.generate(tag: tag, keySize: size, algorithm: algo)
            _ = try keyPair.publicKey.asSPKIBase64EncodedString()
            XCTFail("Should not generate SPKI public key")
        } catch {
            try! KeyPair.destroy(tag: tag)
        }
    }
}
