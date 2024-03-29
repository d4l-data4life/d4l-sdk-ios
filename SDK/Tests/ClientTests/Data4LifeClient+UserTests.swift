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

import XCTest
import Alamofire
import SafariServices
import Combine
@testable import Data4LifeSDK
import Data4LifeFHIR
import Data4LifeCrypto

class Data4LifeClientUserTests: XCTestCase {
    var client: Data4LifeClient!

    var sessionService: SessionService!
    var oAuthService: OAuthServiceMock!
    var userService: UserServiceMock!
    var cryptoService: CryptoServiceMock!
    var commonKeyService: CommonKeyServiceMock!
    var fhirService: FhirServiceMock<DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>, Attachment>!
    var appDataService: AppDataServiceMock!
    var keychainService: KeychainServiceMock!
    var recordService: RecordServiceMock<Data4LifeFHIR.DocumentReference,DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>>!
    var environment: Environment!
    var versionValidator: SDKVersionValidatorMock!

    override func setUp() {
        super.setUp()

        environment = .development

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        self.client = Data4LifeClient(container: container,
                                      environment: environment,
                                      platform: .d4l)

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
        } catch {
            XCTFail(error.localizedDescription)
        }

        self.keychainService[.userId] = UUID().uuidString
        fhirService.keychainService = keychainService
        fhirService.recordService = recordService
        fhirService.cryptoService = cryptoService
        appDataService.keychainService = keychainService
        appDataService.recordService = recordService
        appDataService.cryptoService = cryptoService
    }

    override func tearDown() {
        super.tearDown()
        clearStubs()
    }
}

extension Data4LifeClientUserTests {
    func testClientInfoValid() {
        let clientId = UUID().uuidString
        let redirectURL = URL(string: "http://domain.example.com/")!

        oAuthService.redirectURL = redirectURL
        oAuthService.clientId = clientId

        XCTAssertEqual(client.clientId, clientId)
        XCTAssertEqual(client.redirectURL, redirectURL.absoluteString)
    }

    func testClientConfigureDependencies() {
        XCTAssertNotNil(self.versionValidator.setSessionServiceCalledWith, "Session Service wasn't injected in the validator as the dependencies configuration were expecting")
        XCTAssertEqual(self.versionValidator.fetchVersionConfigOnlineCalled, true, "Expected version configuration endpoint wasn't called")
    }

    func testLoginSuccessWithDefaultScopes() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let viewController = UIViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()

        let tag = "de.gesundheitscloud.keypair.present.login"

        let keypair = KeyFactory.createKeyPair(tag: tag)
        let encodedPublicKey = try! JSONEncoder().encode(keypair).base64EncodedString()

        oAuthService.presentLoginResult = Just(()).asyncFuture()
        cryptoService.fetchOrGenerateKeyPairResult = keypair
        userService.fetchUserInfoResult = Just(()).asyncFuture()

        let asyncExpectation = expectation(description: "should perform successful login")
        client.presentLogin(on: viewController, animated: true) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(viewController.presentedViewController)
            XCTAssertNotNil(window.rootViewController)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.0 is OAuthExternalUserAgent)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.1 == encodedPublicKey)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.2 == self.client.defaultScopes)
            XCTAssertTrue(self.userService.fetchUserInfoCalled)
            XCTAssertNil(result.error)
            XCTAssertNotNil(try? KeyPair.destroy(tag: tag))
        }

        waitForExpectations(timeout: 5)
    }

    func testLoginSuccessWithCustomScopes() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let viewController = UIViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()

        let tag = "de.gesundheitscloud.keypair.present.login"
        let scopes = ["test", "scope"]
        let keypair = KeyFactory.createKeyPair(tag: tag)
        let encodedPublicKey = try! JSONEncoder().encode(keypair).base64EncodedString()

        oAuthService.presentLoginResult = Just(()).asyncFuture()
        cryptoService.fetchOrGenerateKeyPairResult = keypair
        userService.fetchUserInfoResult = Just(()).asyncFuture()

        let asyncExpectation = expectation(description: "should perform successful login")
        client.presentLogin(on: viewController, animated: true, scopes: scopes) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(viewController.presentedViewController)
            XCTAssertNotNil(window.rootViewController)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.0 is OAuthExternalUserAgent)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.1 == encodedPublicKey)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.2 == scopes)
            XCTAssertTrue(self.userService.fetchUserInfoCalled)
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

        let expectedError = Data4LifeSDKError.notLoggedIn
        oAuthService.presentLoginResult = Fail(error: expectedError).asyncFuture()
        cryptoService.fetchOrGenerateKeyPairResult = keypair

        let asyncExpectation = expectation(description: "should fail login")
        client.presentLogin(on: viewController, animated: true) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(viewController.presentedViewController)
            XCTAssertNotNil(window.rootViewController)
            XCTAssertNotNil(result.error)
            XCTAssertEqual(expectedError, result.error as? Data4LifeSDKError)
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
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let viewController = UIViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        let expectedError = Data4LifeSDKError.notLoggedIn

        let tag = "de.gesundheitscloud.keypair.fail.load.user.info"
        let keypair = KeyFactory.createKeyPair(tag: tag)
        let encodedPublicKey = try! JSONEncoder().encode(keypair).base64EncodedString()

        oAuthService.presentLoginResult = Just(()).asyncFuture()
        cryptoService.fetchOrGenerateKeyPairResult = keypair
        userService.fetchUserInfoResult = Fail(error: expectedError).asyncFuture()

        let asyncExpectation = expectation(description: "should perform successful login")
        client.presentLogin(on: viewController, animated: true) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(viewController.presentedViewController)
            XCTAssertNotNil(window.rootViewController)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.0 is OAuthExternalUserAgent)
            XCTAssertTrue(self.oAuthService.presentLoginCalled?.1 == encodedPublicKey)
            XCTAssertTrue(self.userService.fetchUserInfoCalled)
            XCTAssertNotNil(result.error)
            XCTAssertEqual(expectedError, result.error as? Data4LifeSDKError)
            XCTAssertNotNil(try? KeyPair.destroy(tag: tag))
        }

        waitForExpectations(timeout: 5)
    }

    func testLogout() {
        XCTAssertFalse(oAuthService.logoutCalled)
        oAuthService.logoutResult = Just(()).asyncFuture()

        let asyncExpectation = expectation(description: "should logout")

        client.logout { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)

            XCTAssertTrue(self.oAuthService.logoutCalled)
            XCTAssertTrue(self.cryptoService.deleteKeyPairCalled)
        }

        waitForExpectations(timeout: 5)
    }

    func testLoggedInTrue() {
        cryptoService.tagEncryptionKey = KeyFactory.createKey(.tag)
        commonKeyService.currentKey = KeyFactory.createKey(.common)
        oAuthService.isSessionActiveResult = Just(()).asyncFuture()

        let asyncExpectation = expectation(description: "should return success true")
        client.isUserLoggedIn { result  in
            defer { asyncExpectation.fulfill() }
            XCTAssertTrue(self.oAuthService.isSessionActiveCalled)
            XCTAssertNil(result.error)
        }

        waitForExpectations(timeout: 5)
    }

    func testLoggedInFalse() {
        cryptoService.tagEncryptionKey = KeyFactory.createKey(.tag)
        commonKeyService.currentKey = KeyFactory.createKey(.common)

        let asyncExpectation = expectation(description: "should return success false")
        client.isUserLoggedIn { result  in
            defer { asyncExpectation.fulfill() }
            XCTAssertTrue(self.oAuthService.isSessionActiveCalled)
            XCTAssertNotNil(result.error)
        }

        waitForExpectations(timeout: 5)
    }

    func testLoggedInFalseMissingKeys() {
        let asyncExpectation = expectation(description: "should return success false")
        client.isUserLoggedIn { result  in
            defer { asyncExpectation.fulfill() }
            XCTAssertFalse(self.oAuthService.isSessionActiveCalled)
            XCTAssertNotNil(result.error)
            XCTAssertEqual(result.error as? Data4LifeSDKError, Data4LifeSDKError.notLoggedIn)
        }

        waitForExpectations(timeout: 5)
    }

    func testCountAll() {
        let userId = UUID().uuidString
        let count = 3

        keychainService[.userId] = userId
        fhirService.countRecordsResult = Just(count).asyncFuture()

        let asyncExpectation = expectation(description: "should return count of all resources")
        client.countFhirStu3Records(of: Data4LifeFHIR.DocumentReference.self) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertEqual(count, result.value)
            XCTAssertTrue(self.recordService.countRecordsCalledWith?.1 == nil)
        }

        waitForExpectations(timeout: 5)
    }

    func testCallbackOnBackgroundThread() {
        let count = 3
        let queue = DispatchQueue.global(qos: .background)

        keychainService[.userId] = UUID().uuidString
        fhirService.countRecordsResult = Just(count).asyncFuture()

        let asyncExpectation = expectation(description: "should return response with count on background thread")
        client.countFhirStu3Records(of: Data4LifeFHIR.DocumentReference.self, queue: queue) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertEqual(result.value, count)
            XCTAssertFalse(Thread.isMainThread)
        }

        waitForExpectations(timeout: 5)
    }

    func testCallbackOnUIThread() {
        let count = 3
        let queue = DispatchQueue.main

        keychainService[.userId] = UUID().uuidString
        fhirService.countRecordsResult = Just(count).asyncFuture()

        let asyncExpectation = expectation(description: "should return response with count on UI thread")
        client.countFhirStu3Records(of: Data4LifeFHIR.DocumentReference.self, queue: queue) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertEqual(result.value, count)
            XCTAssertTrue(Thread.isMainThread)
        }

        waitForExpectations(timeout: 5)
    }

    func testSessionStateBecomeActive() {
        let state = true
        let asyncExpectation = expectation(description: "should return response after state changes")

        client.sessionStateDidChange { newState in
            asyncExpectation.fulfill()
            XCTAssertEqual(state, newState)
        }

        // mock state change call
        oAuthService.sessionStateChanged?(state)
        waitForExpectations(timeout: 5)
    }

    func testSessionStateRegisterDuplicateListener() {
        let asyncExpectation = expectation(description: "should recieve response in first callback")
        let firstCallback: (Bool) -> Void = { _ in asyncExpectation.fulfill() }
        let secondCallback: (Bool) -> Void = { _ in }

        client.sessionStateDidChange(completion: firstCallback)
        XCTAssertNotNil(oAuthService.sessionStateChanged)
        client.sessionStateDidChange(completion: secondCallback)

        // mock state change call
        oAuthService.sessionStateChanged?(true)
        waitForExpectations(timeout: 5)
    }

    func testGetUserIdWhenLoggedIn() {
        let userId = UUID().uuidString
        userService.getUserIdResult = userId

        let asyncExpectation = expectation(description: "should return response with count on UI thread")
        client.getUserId { result  in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertEqual(result.value, userId)
        }

        waitForExpectations(timeout: 5)
    }

    func testGetUserIdWhenLoggedOutError() {
        userService.getUserIdResult = nil

        let asyncExpectation = expectation(description: "should return response with count on UI thread")
        client.getUserId { result  in
            defer { asyncExpectation.fulfill() }
            XCTAssertEqual(result.error as? Data4LifeSDKError, Data4LifeSDKError.notLoggedIn)
            XCTAssertNil(result.value)
        }

        waitForExpectations(timeout: 5)
    }
}
