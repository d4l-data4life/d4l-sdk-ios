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
import Alamofire
import Then

class UserServiceTests: XCTestCase {
    var userService: UserService!
    var sessionService: SessionService!
    var cryptoService: CryptoServiceMock!
    var commonKeyService: CommonKeyServiceMock!
    var keychainService: KeychainServiceMock!
    var bundle: Foundation.Bundle!
    var keyPairTag = "come.exmaple.keypair"
    var versionValidator: SDKVersionValidatorMock!

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        userService = UserService(container: container)

        do {
            sessionService = try container.resolve()
            cryptoService = try container.resolve(as: CryptoServiceType.self)
            keychainService = try container.resolve(as: KeychainServiceType.self)
            commonKeyService = try container.resolve(as: CommonKeyServiceType.self)
            bundle = try container.resolve()
            versionValidator = try container.resolve(as: SDKVersionValidatorType.self)
        } catch {
            XCTFail(error.localizedDescription)
        }

        Router.baseUrl = "http://example.com"
        versionValidator.fetchCurrentVersionStatusResult = Async.resolve(.supported)
    }

    func testFetchUserInfo() {
        let userId = UUID().uuidString
        let keypair: KeyPair = try! bundle.decodable(fromJSON: "asymPrivateExchangeKeyPKCS8")
        let commonKey: Key = try! bundle.decodable(fromJSON: "symCommonExchangeKey")
        let tagKey: Key = try! bundle.decodable(fromJSON: "symTagExchangeKey")

        guard
            let encryptedTestData = try? bundle.json(named: "encryptedCommonTekKeys") as? [String: String],
            encryptedTestData["tek_iv"] != nil,
            let encryptedCommonKey = encryptedTestData["encrypted_common_key"],
            let encryptedTagKey = encryptedTestData["encrypted_tek"]
            else {
                XCTFail("Should load test data")
                return
        }

        let ckData: Data = try! JSONEncoder().encode(commonKey)
        let tekData: Data = try! JSONEncoder().encode(tagKey)
        let eckData: Data = Data(base64Encoded: encryptedCommonKey)!
        let etekData: Data = Data(base64Encoded: encryptedTagKey)!

        cryptoService.fetchOrGenerateKeyPairResult = keypair
        cryptoService.decryptDataKeyPairForInput = [(eckData, ckData)]
        cryptoService.decryptDataForInput = [(etekData, tekData)]

        let data: [String: String] = [ "sub": userId,
                                       "common_key": encryptedCommonKey,
                                       "tag_encryption_key": encryptedTagKey]

        stub("GET", "/userinfo", with: data)
        let asyncExpectation = expectation(description: "should return user info")
        userService.fetchUserInfo()
            .then {
                defer { asyncExpectation.fulfill() }
                XCTAssertNotNil(self.cryptoService.tek)
                XCTAssertEqual(self.commonKeyService.storeKeyCalledWith?.0, commonKey)
                XCTAssertEqual(self.commonKeyService.storeKeyCalledWith?.1, CommonKeyService.initialId)
                XCTAssertTrue(self.commonKeyService.storeKeyCalledWith?.2 ?? false)

                XCTAssertEqual(self.keychainService[.userId], userId)
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchUserInfoFailInvalidPayload() {
        stub("GET", "/userinfo", with: ["invalid-payload"])
        let asyncExpectation = expectation(description: "should fail fetching user info")

        userService.fetchUserInfo()
            .then {
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertRouteCalled("GET", "/userinfo")
                XCTAssertTrue(error.localizedDescription.contains("The data couldn’t be read because it isn’t in the correct format."))
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testFetchUserInfoFailMissingKeys() {
        stub("GET", "/userinfo", with: ["tag_encryption_key": "", "commmon_key": ""])
        let asyncExpectation = expectation(description: "should fail fetching user info")

        userService.fetchUserInfo()
            .then {
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertRouteCalled("GET", "/userinfo")
                XCTAssertTrue(error.localizedDescription.contains("The data couldn’t be read because it is missing."))
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchUserInfoCouldNotBase64DecodeKeys() {
        let string = String(describing: Data([0x00, 0x01]))
        stub("GET", "/userinfo", with: ["sub": string, "tag_encryption_key": string, "common_key": string])

        let expectedError = Data4LifeSDKError.couldNotReadBase64EncodedData
        let asyncExpectation = expectation(description: "should fail fetching user info")

        userService.fetchUserInfo()
            .then {
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertRouteCalled("GET", "/userinfo")
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchUserInfoFailsUnsupportedVersion() {
        versionValidator.fetchCurrentVersionStatusResult = Async.resolve(.unsupported)
        let expectedError = Data4LifeSDKError.unsupportedVersionRunning

        let asyncExpectation = expectation(description: "should fail fetching user info")

        userService.fetchUserInfo()
            .then {
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}
