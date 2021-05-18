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
import Alamofire
import Combine
@testable import AppAuth

class OAuthServiceTests: XCTestCase {
    var keychainService: KeychainServiceMock!
    var oAuthService: OAuthService!
    var clientId: String!
    var clientSecret: String!
    var callbackURL: URL!
    var authURL: URL!
    var tokenURL: URL!
    var sessionService: SessionService!
    var authState: AuthStateMock!
    var versionValidator: SDKVersionValidatorMock!
    var numberOfRetries: Int!
    var bundle: Foundation.Bundle { return Bundle.current }

    var mockedTokenReponse: OIDTokenResponse {
        do {
            let payload = try bundle.json(named: "authStateTokenResponseSuccess")
            guard let stringData = payload?["data"] as? String else {
                fatalError("Could not load mocked payload data")
            }
            let mockedTokenResponse = try NSKeyedUnarchiver.unarchivedObject(ofClass: OIDTokenResponse.self, from: Data(base64Encoded: stringData)!)
            return mockedTokenResponse!
        } catch {
            fatalError("Could not load mocked payload data: \(error)")
        }
    }

    override func setUp() {
        super.setUp()

        callbackURL = URL(string: "https://example.com")!
        clientId = UUID().uuidString
        clientSecret = UUID().uuidString
        Router.baseUrl = "https://api.example2.com"
        tokenURL = try! Router.fetchTokenUrl()
        authURL = try! Router.authorizeUrl()

        keychainService = KeychainServiceMock()
        authState = AuthStateMock()
        versionValidator = SDKVersionValidatorMock()
        versionValidator.fetchCurrentVersionStatusResult = Just(.supported)
        sessionService = SessionService.stubbedSessionService(versionValidator: versionValidator)
        numberOfRetries = 2

        oAuthService = OAuthService(clientId: clientId,
                                    clientSecret: clientSecret,
                                    redirectURL: callbackURL,
                                    authURL: authURL,
                                    tokenURL: tokenURL,
                                    keychainService: keychainService,
                                    sessionService: sessionService,
                                    authState: authState,
                                    numberOfRetriesOnTimeout: numberOfRetries)
    }

    override func tearDown() {
        super.tearDown()
        AuthStateMock.clearStubs()
        clearStubs()
    }

    func testLoginSuccess() {
        let viewController = UIViewController()
        let pubKey = UUID().uuidString
        let scopes = [UUID().uuidString]
        let animated = true
        let authStateType = AuthStateMock.self
        let userAgent = OAuthExternalUserAgentMock(with: viewController)

        AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult = (AuthStateMock(), nil)
        AuthStateMock.authStateByPresentingExternalUserAgentResult = OAuthExternalUserAgentSessionMock()

        let asyncExpectation = self.expectation(description: "should return login success")
        oAuthService.presentLogin(with: userAgent,
                                  publicKey: pubKey,
                                  scopes: scopes,
                                  animated: animated,
                                  authStateType: authStateType)
            .then { _ in
                XCTAssertNotNil(userAgent.presentCalledWith)
                XCTAssertTrue(AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult?.0 is AuthStateMock)
                XCTAssertNil(AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult?.1)
                XCTAssertNotNil(AuthStateMock.authStateByPresentingExternalUserAgentCalledWith)
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testLoginFailNetworkError() {
        let viewController = UIViewController()
        let pubKey = UUID().uuidString
        let scopes = [UUID().uuidString]
        let animated = true
        let authStateType = AuthStateMock.self
        let userAgent = OAuthExternalUserAgentMock(with: viewController)

        let authError = OIDErrorUtilities.error(with: OIDErrorCode.networkError,
                                                underlyingError: nil,
                                                description: nil)

        AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult = (nil, authError)
        AuthStateMock.authStateByPresentingExternalUserAgentResult = OAuthExternalUserAgentSessionMock()

        let asyncExpectation = self.expectation(description: "should return login failure")
        oAuthService.presentLogin(with: userAgent,
                                  publicKey: pubKey,
                                  scopes: scopes,
                                  animated: animated,
                                  authStateType: authStateType)
            .then { _ in
                XCTFail("Should fail with error")
            }.onError { error in
                XCTAssertNotNil(userAgent.presentCalledWith)
                XCTAssertNil(AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult?.0)
                XCTAssertNotNil(AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult?.1)
                XCTAssertNotNil(AuthStateMock.authStateByPresentingExternalUserAgentCalledWith)
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.authNetworkError)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testLoginFailServerError() {
        let viewController = UIViewController()
        let pubKey = UUID().uuidString
        let scopes = [UUID().uuidString]
        let animated = true
        let authStateType = AuthStateMock.self
        let userAgent = OAuthExternalUserAgentMock(with: viewController)

        let authError = OIDErrorUtilities.error(with: OIDErrorCode.serverError,
                                                underlyingError: nil,
                                                description: nil)

        AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult = (nil, authError)

        let asyncExpectation = self.expectation(description: "should return login failure")
        oAuthService.presentLogin(with: userAgent,
                                  publicKey: pubKey,
                                  scopes: scopes,
                                  animated: animated,
                                  authStateType: authStateType)
            .then { _ in
                XCTFail("Should fail with error")
            }.onError { error in
                XCTAssertNil(userAgent.presentCalledWith)
                XCTAssertNil(AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult?.0)
                XCTAssertNotNil(AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult?.1)
                XCTAssertNotNil(AuthStateMock.authStateByPresentingExternalUserAgentCalledWith)
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.authServerError)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testLoginFailGeneralError() {
        let viewController = UIViewController()
        let pubKey = UUID().uuidString
        let scopes = [UUID().uuidString]
        let animated = true
        let authStateType = AuthStateMock.self
        let userAgent = OAuthExternalUserAgentMock(with: viewController)

        let authError = OIDErrorUtilities.error(with: OIDErrorCode.invalidDiscoveryDocument,
                                                underlyingError: nil,
                                                description: nil)

        AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult = (nil, authError)

        let asyncExpectation = self.expectation(description: "should return general login error")
        oAuthService.presentLogin(with: userAgent,
                                  publicKey: pubKey,
                                  scopes: scopes,
                                  animated: animated,
                                  authStateType: authStateType)
            .then { _ in
                XCTFail("Should fail with error")
            }.onError { error in
                XCTAssertNil(userAgent.presentCalledWith)
                XCTAssertNil(AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult?.0)
                XCTAssertNotNil(AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult?.1)
                XCTAssertNotNil(AuthStateMock.authStateByPresentingExternalUserAgentCalledWith)
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.appAuth(authError))
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testLoginFailUserCanceled() {
        let window = UIWindow(frame: .zero)
        let viewController = UIViewController()
        window.rootViewController = viewController

        let pubKey = UUID().uuidString
        let scopes = [UUID().uuidString]
        let animated = true
        let authStateType = AuthStateMock.self
        let userAgent = OAuthExternalUserAgentMock(with: viewController)

        let authError = OIDErrorUtilities.error(with: OIDErrorCode.userCanceledAuthorizationFlow,
                                                underlyingError: nil,
                                                description: nil)

        AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult = (nil, authError)

        let asyncExpectation = self.expectation(description: "should return login failure")
        oAuthService.presentLogin(with: userAgent,
                                  publicKey: pubKey,
                                  scopes: scopes,
                                  animated: animated,
                                  authStateType: authStateType)
            .then { _ in
                XCTFail("Should fail with error")
            }.onError { error in
                XCTAssertNil(userAgent.presentCalledWith)
                XCTAssertNil(AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult?.0)
                XCTAssertNotNil(AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult?.1)
                XCTAssertNotNil(AuthStateMock.authStateByPresentingExternalUserAgentCalledWith)
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.userCanceledAuthFlow)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testShouldRetryOnUnauthorized() throws {
        let url = URL(string: Router.baseUrl)!
        stub("GET", url.path, with: [], code: 401)

        keychainService[.refreshToken] = UUID().uuidString
        keychainService[.accessToken] = UUID().uuidString

        let accessToken = UUID().uuidString
        let refreshToken = UUID().uuidString
        authState.performActionWithAdditionalResult = (accessToken, refreshToken, nil)

        let stateData = try NSKeyedArchiver.archivedData(withRootObject: authState!, requiringSecureCoding: false)
        keychainService[.authState] = stateData.base64EncodedString()

        let asyncExpectation = self.expectation(description: "should retry")
        let request = try sessionService.request(url: url, method: .get)
        request.response { result in
            guard result.response?.statusCode == 401 else {
                XCTFail("Status code should be 401")
                return
            }

            self.oAuthService.retry(request, for: self.sessionService.session, dueTo: Data4LifeSDKError.timeout) { (retryResult) -> Void in
                defer { asyncExpectation.fulfill() }
                XCTAssertTrue(retryResult.isRetry)

                XCTAssertEqual(self.keychainService[.accessToken], accessToken)
                XCTAssertEqual(self.keychainService[.refreshToken], refreshToken)
            }
        }

        waitForExpectations(timeout: 5)
    }

    func testShouldRetryOnTimeout() throws {
        let url = URL(string: Router.baseUrl)!
        let error = Data4LifeSDKError.timeout
        stub("GET", url.path, with: [], code: 408)
        var retryCount = 0

        let asyncExpectation = self.expectation(description: "should retry number of times")
        let request = try sessionService.request(url: url, method: .get)
        request.response { result in
            guard result.response?.statusCode == 408 else {
                XCTFail("Status code should be 408")
                return
            }

            self.oAuthService.retry(request, for: self.sessionService.session, dueTo: error) { (retryResult) -> Void in

                XCTAssertTrue(retryResult.isRetry)
                retryCount += 1

                self.oAuthService.retry(request, for: self.sessionService.session, dueTo: error) { (retryResult) -> Void in
                    retryCount += 1
                    XCTAssertTrue(retryResult.isRetry)
                    XCTAssertEqual(retryCount, self.numberOfRetries)

                    self.oAuthService.retry(request, for: self.sessionService.session, dueTo: error) { (retryResult) -> Void in
                        defer { asyncExpectation.fulfill() }
                        XCTAssertFalse(retryResult.isRetry)
                        XCTAssertEqual(self.oAuthService.currentRetryCount, 0)
                    }
                }
            }
        }
        waitForExpectations(timeout: 5)
    }

        func testShouldClearKeychainWhenRefreshFails() throws {
            let url = URL(string: Router.baseUrl)!
            stub("GET", url.path, with: [], code: 401)
            let accessToken = UUID().uuidString
            let refreshToken = UUID().uuidString

            let refreshError = OIDErrorUtilities.error(with: OIDErrorCode.tokenRefreshError,
                                                       underlyingError: nil,
                                                       description: nil)
            authState.performActionWithAdditionalResult = (nil, nil, refreshError)
            let stateData = try NSKeyedArchiver.archivedData(withRootObject: authState!, requiringSecureCoding: false)

            keychainService[.refreshToken] = refreshToken
            keychainService[.accessToken] = accessToken
            keychainService[.authState] = stateData.base64EncodedString()

            let asyncExpectation = self.expectation(description: "should clear keychain on error")
            let request = try sessionService.request(url: url, method: .get)
            request.response { result in
                guard result.response?.statusCode == 401 else {
                    XCTFail("Status code should be 401")
                    return
                }
                self.oAuthService.retry(request, for: self.sessionService.session, dueTo: Data4LifeSDKError.timeout) { (retryResult) -> Void in
                    defer { asyncExpectation.fulfill() }
                    XCTAssertFalse(retryResult.isRetry)
                    XCTAssertEqual(self.keychainService[.accessToken], nil)
                    XCTAssertEqual(self.keychainService[.refreshToken], nil)
                    XCTAssertEqual(self.keychainService[.authState], nil)
                    XCTAssertTrue(self.keychainService.clearCalled)
                }
            }

            waitForExpectations(timeout: 5)
        }

    func testLogout() {
        let refreshToken = UUID().uuidString
        let postData = "token=\(refreshToken)".data(using: .utf8)
        let headerValue = "\(clientId!):\(clientSecret!)".data(using: .utf8)!.base64EncodedString()

        keychainService[.refreshToken] = refreshToken
        stub("POST", "/oauth/revoke", with: [])

        let asyncExpectation = expectation(description: "should return empty response")

        oAuthService.logout().then {
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(self.keychainService[.authState])
            XCTAssertTrue(self.keychainService.clearCalled)
            XCTAssertRequestDataEquals("POST", "/oauth/revoke", with: postData as Any)
            XCTAssertRequestHeadersContain("POST", "/oauth/revoke", headers: ["Authorization": "Basic \(headerValue)"])
        }

        waitForExpectations(timeout: 5)
    }

    func testIsSessionActiveSuccess() throws {
        authState.lastTokenResponseResult = mockedTokenReponse
        let stateData = try NSKeyedArchiver.archivedData(withRootObject: authState!, requiringSecureCoding: false)
        keychainService[.authState] = stateData.base64EncodedString()

        stub("GET", "/userinfo", with: [], code: 200)

        let asyncExpectation = expectation(description: "Should return success")
        oAuthService.isSessionActive()
            .then { _ in
                XCTAssertRouteCalled("GET", "/userinfo")
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testIsSessionActiveFailMissingKeys() {
        let expectedError = Data4LifeSDKError.notLoggedIn
        let asyncExpectation = expectation(description: "Should return an error")

        oAuthService.isSessionActive()
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testIsSessionActiveFailInvalidTokens() {
        let expectedError = Data4LifeSDKError.notLoggedIn
        stub("GET", "/userinfo", with: [], code: 401)
        authState.lastTokenResponseResult = mockedTokenReponse
        let asyncExpectation = expectation(description: "Should return an error")

        oAuthService.isSessionActive()
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
                XCTAssertRouteCalled("GET", "/userinfo")
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testSaveAuthState() throws {
        XCTAssertNil(keychainService[.accessToken])
        XCTAssertNil(keychainService[.refreshToken])
        XCTAssertNil(keychainService[.authState])

        authState.lastTokenResponseResult = mockedTokenReponse
        try oAuthService.saveAuthState(authState)

        XCTAssertNotNil(keychainService[.accessToken])
        XCTAssertNotNil(keychainService[.refreshToken])
        XCTAssertNotNil(keychainService[.authState])
    }
}

extension RetryResult {
    var isRetry: Bool {
        switch self {
        case .retry: return true
        default: return false
        }
    }
}
