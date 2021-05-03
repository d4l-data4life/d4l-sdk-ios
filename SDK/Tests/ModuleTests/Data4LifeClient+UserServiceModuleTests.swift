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
import Alamofire
import SafariServices
import Then
@testable import Data4LifeSDK
import Data4LifeFHIR
import Data4LifeCrypto

class Data4LifeClientUserServiceModuleTests: XCTestCase {
    private var client: Data4LifeClient!
    private var userService: UserService!

    private var bundle: Foundation.Bundle!

    private var sessionService: SessionService!
    private var oAuthService: OAuthServiceMock!
    private var cryptoService: CryptoServiceMock!
    private var commonKeyService: CommonKeyServiceMock!
    private var fhirService: FhirServiceMock<DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>, Attachment>!
    private var appDataService: AppDataServiceMock!
    private var keychainService: KeychainServiceMock!
    private var recordService: RecordServiceMock<Data4LifeFHIR.DocumentReference,DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>>!
    private var environment: Environment!
    private var versionValidator: SDKVersionValidatorMock!

    override func setUp() {
        super.setUp()

        environment = .development

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        container.register(scope: .containerInstance) { (_) -> UserServiceType in
            UserService(container: container)
        }

        self.client = Data4LifeClient(container: container,
                                      environment: environment)

        do {
            self.sessionService = try container.resolve()
            self.oAuthService = try container.resolve(as: OAuthServiceType.self)
            self.userService = try container.resolve(as: UserServiceType.self)
            self.cryptoService = try container.resolve(as: CryptoServiceType.self)
            self.commonKeyService = try container.resolve(as: CommonKeyServiceType.self)
            self.fhirService = try container.resolve(as: FhirServiceType.self)
            self.recordService = try container.resolve(as: RecordServiceType.self)
            self.keychainService = try container.resolve(as: KeychainServiceType.self)
            self.versionValidator = try container.resolve(as: SDKVersionValidatorType.self)
            self.appDataService = try container.resolve(as: AppDataServiceType.self)
            self.bundle = try container.resolve()
        } catch {
            XCTFail(error.localizedDescription)
        }

        fhirService.keychainService = keychainService
        fhirService.recordService = recordService
        fhirService.cryptoService = cryptoService
        appDataService.keychainService = keychainService
        appDataService.recordService = recordService
        appDataService.cryptoService = cryptoService

        Router.baseUrl = "http://example.com"
        versionValidator.fetchCurrentVersionStatusResult = Async.resolve(.supported)
    }

    override func tearDown() {
        super.tearDown()
        clearStubs()
        keychainService.clear()
    }
}

extension Data4LifeClientUserServiceModuleTests {

    func testLoginSuccessWithDefaultScopes() {
        let userId = UUID().uuidString
        stubUserInfo(with: userId)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let viewController = UIViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()

        let tag = "de.gesundheitscloud.keypair.present.login"

        let keypair = KeyFactory.createKeyPair(tag: tag)
        let encodedPublicKey = try! JSONEncoder().encode(keypair).base64EncodedString()

        oAuthService.presentLoginResult = Async.resolve()
        cryptoService.fetchOrGenerateKeyPairResult = keypair

        let asyncExpectation = expectation(description: "should perform successful login")
        client.presentLogin(on: viewController, animated: true) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(viewController.presentedViewController)
            XCTAssertNotNil(window.rootViewController)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.0 is OAuthExternalUserAgent)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.1 == encodedPublicKey)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.2 == self.client.defaultScopes)
            XCTAssertNil(result.error)
            XCTAssertNotNil(try? KeyPair.destroy(tag: tag))
        }

        waitForExpectations(timeout: 5)
    }

    func testLoginSuccessWithCustomScopes() {
        let userId = UUID().uuidString
        stubUserInfo(with: userId)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let viewController = UIViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()

        let tag = "de.gesundheitscloud.keypair.present.login"
        let scopes = ["test", "scope"]
        let keypair = KeyFactory.createKeyPair(tag: tag)
        let encodedPublicKey = try! JSONEncoder().encode(keypair).base64EncodedString()

        oAuthService.presentLoginResult = Async.resolve()
        cryptoService.fetchOrGenerateKeyPairResult = keypair

        let asyncExpectation = expectation(description: "should perform successful login")
        client.presentLogin(on: viewController, animated: true, scopes: scopes) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(viewController.presentedViewController)
            XCTAssertNotNil(window.rootViewController)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.0 is OAuthExternalUserAgent)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.1 == encodedPublicKey)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.2 == scopes)
            XCTAssertNil(result.error)
            XCTAssertNotNil(try? KeyPair.destroy(tag: tag))
        }

        waitForExpectations(timeout: 5)
    }

    func testLoginFail() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let viewController = UIViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()

        let tag = "de.gesundheitscloud.keypair.present.login"
        let keypair = KeyFactory.createKeyPair(tag: tag)

        let err = Data4LifeSDKError.notLoggedIn
        oAuthService.presentLoginResult = Async.reject(err)
        cryptoService.fetchOrGenerateKeyPairResult = keypair

        let asyncExpectation = expectation(description: "should fail login")
        client.presentLogin(on: viewController, animated: true) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(viewController.presentedViewController)
            XCTAssertNotNil(window.rootViewController)
            XCTAssertNotNil(result.error)
            XCTAssertEqual(err, result.error as? Data4LifeSDKError)
            XCTAssertNotNil(try? KeyPair.destroy(tag: tag))
        }

        waitForExpectations(timeout: 5)
    }

    func testLoginFailCouldNotGenerateKeypair() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let viewController = UIViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()

        cryptoService.fetchKeyPairResult = nil

        let asyncExpectation = expectation(description: "should fail fetching keypair")
        client.presentLogin(on: viewController, animated: true) { error in
            defer { asyncExpectation.fulfill() }
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(viewController.presentedViewController)
            XCTAssertNotNil(window.rootViewController)
            XCTAssertNotNil(error)
        }

        waitForExpectations(timeout: 5)
    }

    func testLoginFailPresentationSuccess() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let viewController = UIViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()

        cryptoService.fetchKeyPairResult = nil

        let asyncExpectation = expectation(description: "should fail fetching keypair")
        let presentationExpectation = expectation(description: "should return presentation success")

        client.presentLogin(on: viewController,
                            animated: true,
                            scopes: nil,
                            presentationCompletion: { presentationExpectation.fulfill() },
                            loginCompletion: { result in
                                defer { asyncExpectation.fulfill() }
                                XCTAssertTrue(Thread.isMainThread)
                                XCTAssertNil(viewController.presentedViewController)
                                XCTAssertNotNil(window.rootViewController)
                                XCTAssertNotNil(result.error)
                            })

        waitForExpectations(timeout: 5)
    }

    func testLoginFailCouldNotLoadUserInfo() {
        stub("GET", "/userinfo", with: ["invalid-payload"])

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let viewController = UIViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()

        let tag = "de.gesundheitscloud.keypair.fail.load.user.info"
        let keypair = KeyFactory.createKeyPair(tag: tag)
        let encodedPublicKey = try! JSONEncoder().encode(keypair).base64EncodedString()

        oAuthService.presentLoginResult = Async.resolve()
        cryptoService.fetchOrGenerateKeyPairResult = keypair

        let asyncExpectation = expectation(description: "should not perform successful login")
        client.presentLogin(on: viewController, animated: true) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(viewController.presentedViewController)
            XCTAssertNotNil(window.rootViewController)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.0 is OAuthExternalUserAgent)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.1 == encodedPublicKey)
            XCTAssertNotNil(result.error)
            XCTAssertEqual(result.error?.localizedDescription.contains("The data couldn’t be read because it isn’t in the correct format."), true)
            XCTAssertNotNil(try? KeyPair.destroy(tag: tag))
        }

        waitForExpectations(timeout: 5)
    }

    func testGetUserIdWhenLoggedIn() {
        let userId = UUID().uuidString
        stubUserInfo(with: userId)

        let asyncExpectation = expectation(description: "should return response with count on UI thread")
        client.getUserId { result  in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertEqual(result.value, userId)
        }

        waitForExpectations(timeout: 5)
    }

    func testGetUserIdWhenLoggedOutError() {
        let asyncExpectation = expectation(description: "should return response with count on UI thread")
        client.getUserId { result  in
            defer { asyncExpectation.fulfill() }
            XCTAssertEqual(result.error as? Data4LifeSDKError, Data4LifeSDKError.notLoggedIn)
            XCTAssertNil(result.value)
        }

        waitForExpectations(timeout: 5)
    }
}

private extension Data4LifeClientUserServiceModuleTests {
    func stubUserInfo(with userId: String) {
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
        keychainService[.userId] = userId

        let data: [String: String] = [ "sub": userId,
                                       "common_key": encryptedCommonKey,
                                       "tag_encryption_key": encryptedTagKey]

        stub("GET", "/userinfo", with: data)
    }
}
