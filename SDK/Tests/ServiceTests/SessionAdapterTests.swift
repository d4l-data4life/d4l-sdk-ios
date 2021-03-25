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
import Then

class SessionAdapterTests: XCTestCase {
    var sessionService: SessionService!
    var interceptor: RequestInterceptorType!
    var keychainService: KeychainServiceMock!
    var versionValidator: SDKVersionValidatorMock!
    var oAuthService: OAuthServiceType!

    let sdkVersion = UUID().uuidString

    override func setUp() {
        super.setUp()

        Router.baseUrl = "http://example.com"
        keychainService = KeychainServiceMock()
        versionValidator = SDKVersionValidatorMock()
        oAuthService = OAuthServiceMock()

        interceptor = SessionServiceInterceptor(keychainService: keychainService,
                                                sdkVersion: sdkVersion)
        interceptor.setRetrier(oAuthService)
        sessionService = SessionService.stubbedSessionService(versionValidator: versionValidator, interceptor: interceptor)
    }

        func testAdaptableRequestDomainPinning() {
            let adaptedRequestExpectation = expectation(description: "adaptedRequest")
            let accessToken = UUID().uuidString
            keychainService[.accessToken] = accessToken

            // Test the path with same baseURl gets adapted
            let url = URL(string: Router.baseUrl)!.appendingPathComponent("/somepath")
            let urlRequest = URLRequest(url: url)
            interceptor.adapt(urlRequest, for: sessionService.session, completion: { [weak self] (result) in
                guard let self = self else { return }
                XCTAssertEqual(result.value?.allHTTPHeaderFields?["hc-sdk-version"], "ios-\(self.sdkVersion)")
                adaptedRequestExpectation.fulfill()
            })

            waitForExpectations(timeout: 0.5, handler: nil)
        }

    func testNonAdaptableRequestDomainPinning() {
        let adaptedRequestExpectation = expectation(description: "adaptedRequest")
        let accessToken = UUID().uuidString
        keychainService[.accessToken] = accessToken
        // Test that any other request will not be adapted
        let arbitaryUrl = URL(string: "https://someotherdomain.com/something")!
        let arbitaryUrlRequest = URLRequest(url: arbitaryUrl)
        interceptor.adapt(arbitaryUrlRequest, for: sessionService.session, completion: { [weak self] (result) in
            guard let self = self else { return }
            XCTAssertNil(result.value?.allHTTPHeaderFields?["GC-SDK-Version"], self.sdkVersion)
            adaptedRequestExpectation.fulfill()
        })
        waitForExpectations(timeout: 0.5, handler: nil)
    }

        func testAdaptRequestUnauthorized() {
            let adaptedRequestExpectation = expectation(description: "adaptedRequest")
            let accessToken = UUID().uuidString

            keychainService[.accessToken] = accessToken
            let urlRequest = try! Router.authorize.asURLRequest()
            interceptor.adapt(urlRequest, for: sessionService.session, completion: { (result) in
                let adaptedAuthorizatioHeaderValue = result.value?.allHTTPHeaderFields?["Authorization"]
                XCTAssertNil(adaptedAuthorizatioHeaderValue)
                adaptedRequestExpectation.fulfill()
            })

            waitForExpectations(timeout: 0.5, handler: nil)
        }

        func testAdaptRequestAuthorized() {
            let accessToken = UUID().uuidString
            let adaptedRequestExpectation = expectation(description: "adaptedRequest")
            keychainService[.accessToken] = accessToken

            let urlRequest = try! Router.userInfo.asURLRequest()
            interceptor.adapt(urlRequest, for: sessionService.session, completion: { (result) in
                let adaptedAuthorizatioHeaderValue = result.value?.allHTTPHeaderFields?["Authorization"]
                XCTAssertNotNil(adaptedAuthorizatioHeaderValue)
                XCTAssertEqual("Bearer \(accessToken)", adaptedAuthorizatioHeaderValue)
                adaptedRequestExpectation.fulfill()
            })

            waitForExpectations(timeout: 0.5, handler: nil)
        }
}
