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
import AppAuth
import SafariServices
@testable import Data4LifeSDK

class OAuthExternalUserAgentTests: XCTestCase {

    var window: UIWindow!
    var viewController: UIViewController!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: .init(x: 0, y: 0, width: 330, height: 330))
        viewController = UIViewController(nibName: nil, bundle: nil)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        super.tearDown()
        window = nil
        viewController = nil
        AuthStateMock.clearStubs()
    }

    func testPresentViewController() {
        let agent = OAuthExternalUserAgent(with: viewController)
        let endpoint = URL(string: "https://example.com")!
        let serviceConfig = OIDServiceConfiguration(authorizationEndpoint: endpoint, tokenEndpoint: endpoint)
        let authorizationRequest = OIDAuthorizationRequest(configuration: serviceConfig,
                                                           clientId: UUID().uuidString,
                                                           clientSecret: UUID().uuidString,
                                                           scopes: [UUID().uuidString],
                                                           redirectURL: endpoint,
                                                           responseType: OIDResponseTypeCode,
                                                           additionalParameters: nil)

        let sessionMock = OAuthExternalUserAgentSessionMock()
        let authStateMock = AuthStateMock()
        AuthStateMock.authStateByPresentingExternalUserAgentResult = sessionMock
        AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult = (authStateMock, nil)

        let asyncExpectation = expectation(description: "should return auth state and present safari")
        let session = AuthStateMock.authState(byPresenting: authorizationRequest, presenting: agent) { (state, error) in
            asyncExpectation.fulfill()
            XCTAssertTrue(state is AuthStateMock)
            XCTAssertNil(error)
            XCTAssertTrue(AuthStateMock.authStateByPresentingExternalUserAgentCalledWith?.0 == authorizationRequest)
            XCTAssertTrue(AuthStateMock.authStateByPresentingExternalUserAgentCalledWith?.1 is OAuthExternalUserAgent)
        }
        XCTAssertNotNil(session)
        waitForExpectations(timeout: 5)
    }

    func testDuplicatePresentation() {
        let agent = OAuthExternalUserAgent(with: viewController)
        let endpoint = URL(string: "https://example.com")!
        let config = OIDServiceConfiguration(authorizationEndpoint: endpoint, tokenEndpoint: endpoint)
        let session = OAuthExternalUserAgentSessionMock()
        let request =  OIDAuthorizationRequest(configuration: config,
                                               clientId: UUID().uuidString,
                                               clientSecret: UUID().uuidString,
                                               scopes: [UUID().uuidString],
                                               redirectURL: endpoint,
                                               responseType: OIDResponseTypeCode,
                                               additionalParameters: nil)

        let didPresent = agent.present(request, session: session)
        XCTAssertTrue(didPresent)
        let didPresentTwice = agent.present(request, session: session)
        XCTAssertFalse(didPresentTwice)
    }
}