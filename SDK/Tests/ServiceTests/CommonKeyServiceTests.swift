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
import Then

class CommonKeyServiceTests: XCTestCase {
    var commonKeyService: CommonKeyService!
    var keychainService: KeychainServiceMock!
    var cryptoService: CryptoServiceMock!
    var sessionService: SessionService!
    var bundle: Foundation.Bundle!
    var versionValidator: SDKVersionValidatorMock!

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()

        commonKeyService = CommonKeyService(container: container)

        do {
            keychainService = try container.resolve(as: KeychainServiceType.self)
            cryptoService = try container.resolve(as: CryptoServiceType.self)
            sessionService = try container.resolve()
            bundle = try container.resolve()
            versionValidator = try container.resolve(as: SDKVersionValidatorType.self)
        } catch {
            XCTFail(error.localizedDescription)
        }

        versionValidator.fetchCurrentVersionStatusResult = Async.resolve(.supported)
    }

    func testInitialCommonKeyId() {
        let expectedInitialCommonKeyId = "00000000-0000-0000-0000-000000000000"
        XCTAssertEqual(expectedInitialCommonKeyId, CommonKeyService.initialId)
    }

    func testLoadAndStoreCommonKey() {
        let commonKeyId = UUID().uuidString
        let commonKey = KeyFactory.createKey(.common)
        let base64EncodedKey = try! JSONEncoder().encode(commonKey).base64EncodedString()

        commonKeyService.storeKey(commonKey, id: commonKeyId, isCurrent: false)
        XCTAssertEqual(self.keychainService.storeCommonKeyCalledWith!.0, base64EncodedKey)
        XCTAssertEqual(self.keychainService.storeCommonKeyCalledWith!.1, commonKeyId)

        let asyncExpectation = expectation(description: "should return common key")
        commonKeyService.fetchKey(with: commonKeyId)
            .then { result in
                defer { asyncExpectation.fulfill() }
                XCTAssertNil(self.commonKeyService.currentId)

                XCTAssertEqual(self.keychainService.getCommonKeyByIdCalledWith, commonKeyId)
                XCTAssertNotNil(result)
                XCTAssertEqual(result, commonKey)
        }
        waitForExpectations(timeout: 5)
    }

    func testLoadAndStoreCurrentCommonKey() {
        let commonKeyId = UUID().uuidString
        let commonKey = KeyFactory.createKey(.common)
        let base64EncodedKey = try! JSONEncoder().encode(commonKey).base64EncodedString()

        XCTAssertNil(commonKeyService.currentKey)

        commonKeyService.storeKey(commonKey, id: commonKeyId, isCurrent: true)
        XCTAssertEqual(self.keychainService.storeCommonKeyCalledWith!.0, base64EncodedKey)
        XCTAssertEqual(self.keychainService.storeCommonKeyCalledWith!.1, commonKeyId)

        let asyncExpectation = expectation(description: "should return common key")
        commonKeyService.fetchKey(with: commonKeyId)
            .then { result in
                defer { asyncExpectation.fulfill() }
                XCTAssertNotNil(self.commonKeyService.currentId)
                XCTAssertEqual(self.commonKeyService.currentId, commonKeyId)

                XCTAssertEqual(self.keychainService.getCommonKeyByIdCalledWith, commonKeyId)
                XCTAssertNotNil(result)
                XCTAssertEqual(result, commonKey)

                XCTAssertNotNil(self.commonKeyService.currentKey)
                XCTAssertEqual(self.commonKeyService.currentKey, commonKey)
        }
        waitForExpectations(timeout: 5)
    }

    func testFetchCommonKeyLocallyWithInitialCommonKeyId() {
        let commonKeyId = CommonKeyService.initialId
        let expectedCommonKey = KeyFactory.createKey()

        commonKeyService.storeKey(expectedCommonKey, id: commonKeyId, isCurrent: false)

        XCTAssertNil(keychainService.storeCommonKeyCalledWith)

        let asyncExpectation = expectation(description: "should return common key")
        commonKeyService.fetchKey(with: commonKeyId)
            .then { result in
                defer { asyncExpectation.fulfill() }
                XCTAssertNil(self.commonKeyService.currentId)

                XCTAssertNil(self.keychainService.getCommonKeyByIdCalledWith)
                XCTAssertNotNil(result)
                XCTAssertEqual(result, expectedCommonKey)
        }
        waitForExpectations(timeout: 5)
    }

    func testLoadAndStoreCommonKeyBackwardsCompatibility() {
        let commonKey = KeyFactory.createKey(.common)
        let base64EncodedKey = try! JSONEncoder().encode(commonKey).base64EncodedString()

        keychainService[.commonKey] = base64EncodedKey
        XCTAssertNil(commonKeyService.currentId)

        let commonKeyResult = commonKeyService.currentKey
        XCTAssertEqual(commonKeyResult, commonKey)
    }

    func testFetchCommonKey() {
        let userId = UUID().uuidString
        let commonKeyId = UUID().uuidString
        let keypair: KeyPair = try! bundle.decodable(fromJSON: "asymPrivateExchangeKeyPKCS8")
        let commonKey: Key = try! bundle.decodable(fromJSON: "symCommonExchangeKey")
        let expectedCommonKey = try! JSONEncoder().encode(commonKey).base64EncodedString()

        guard
            let encryptedTestData = try? bundle.json(named: "encryptedCommonTekKeys") as? [String: String],
            let encryptedCommonKey = encryptedTestData["encrypted_common_key"]
            else {
                XCTFail("Should load test data")
                return
        }

        let ckData: Data = try! JSONEncoder().encode(commonKey)
        let eckData: Data = Data(base64Encoded: encryptedCommonKey)!

        self.keychainService[.userId] = userId
        cryptoService.fetchOrGenerateKeyPairResult = keypair
        cryptoService.decryptDataKeyPairForInput = [(eckData, ckData)]

        let data: [String: String] = ["common_key": encryptedCommonKey]

        stub("GET", "/users/\(userId)/commonkeys/\(commonKeyId)", with: data)
        let asyncExpectation = expectation(description: "should return common key")
        commonKeyService.fetchKey(with: commonKeyId)
            .then { _ in
                defer { asyncExpectation.fulfill() }
                XCTAssertNil(self.commonKeyService.currentId)

                XCTAssertEqual(self.keychainService.storeCommonKeyCalledWith?.0, expectedCommonKey)
                XCTAssertEqual(self.keychainService.storeCommonKeyCalledWith?.1, commonKeyId)
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchCommonKeyRemotelyFailMissingKeys() {
        let userId = UUID().uuidString
        let commonKeyId = UUID().uuidString

        self.keychainService[.userId] = userId
        stub("GET", "/users/\(userId)/commonkeys/\(commonKeyId)", with: ["": ""])
        let asyncExpectation = expectation(description: "should fail fetching common key")

        commonKeyService.fetchKey(with: commonKeyId)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertRouteCalled("GET", "/users/\(userId)/commonkeys/\(commonKeyId)")
                XCTAssertTrue(error.localizedDescription.contains("The data couldn’t be read because it is missing."))
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchCommonKeyFailMissingCommonKey() {
        let userId = UUID().uuidString
        let commonKeyId = UUID().uuidString

        self.keychainService[.userId] = userId
        self.keychainService[.commonKeyId] = nil
        self.keychainService.hasCommonKeyResult = true
        self.keychainService.getCommonKeyByIdResult = nil

        let asyncExpectation = expectation(description: "should fail fetching common key")
        let expectedError = Data4LifeSDKError.missingCommonKey

        commonKeyService.fetchKey(with: commonKeyId)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchCommonKeyRemotelyCouldNotBase64DecodeKeys() {
        let userId = UUID().uuidString
        let commonKeyId = UUID().uuidString
        let string = String(describing: Data([0x00, 0x01]))

        self.keychainService[.userId] = userId
        stub("GET", "/users/\(userId)/commonkeys/\(commonKeyId)", with: ["common_key": string])

        let expectedError = Data4LifeSDKError.couldNotReadBase64EncodedData
        let asyncExpectation = expectation(description: "should fail fetching common key")

        commonKeyService.fetchKey(with: commonKeyId)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertRouteCalled("GET", "/users/\(userId)/commonkeys/\(commonKeyId)")
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchCommonKeyFailsUnsupportedVersion() {
        let userId = UUID().uuidString
        let commonKeyId = UUID().uuidString

        self.versionValidator.fetchCurrentVersionStatusResult = Async.resolve(.unsupported)
        self.keychainService[.userId] = userId

        let asyncExpectation = expectation(description: "should fail because the version is unsupported")
        let expectedError = Data4LifeSDKError.unsupportedVersionRunning

        commonKeyService.fetchKey(with: commonKeyId)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}
