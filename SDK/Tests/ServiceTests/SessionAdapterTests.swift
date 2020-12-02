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
    var sessionAdapter: SessionAdapterType!
    var keychainService: KeychainServiceMock!
    var versionValidator: SDKVersionValidatorMock!
    let sdkVersion = UUID().uuidString

    override func setUp() {
        super.setUp()

        Router.baseUrl = "http://example.com"
        keychainService = KeychainServiceMock()
        versionValidator = SDKVersionValidatorMock()
        sessionAdapter = SessionAdapter(keychainService: keychainService,
                                        sdkVersion: sdkVersion)
        sessionService = SessionService.stubbedSessionService(versionValidator: versionValidator, adapter: sessionAdapter)
    }

    func testAdaptRequestDomainPinning() {
        let accessToken = UUID().uuidString
        keychainService[.accessToken] = accessToken

        // Test the path with same baseURl gets adapted
        let url = URL(string: Router.baseUrl)!.appendingPathComponent("/somepath")
        let urlRequest = URLRequest(url: url)
        let adaptedUrlRequest = try? sessionAdapter.adapt(urlRequest)
        XCTAssertEqual(adaptedUrlRequest?.allHTTPHeaderFields?["hc-sdk-version"], "ios-\(sdkVersion)")

        // Test that any other request will not be adapted
        let arbitaryUrl = URL(string: "https://someotherdomain.com/something")!
        let arbitaryUrlRequest = URLRequest(url: arbitaryUrl)
        let arbitaryAdaptedUrlRequest = try? sessionAdapter.adapt(arbitaryUrlRequest)
        XCTAssertNil(arbitaryAdaptedUrlRequest?.allHTTPHeaderFields?["GC-SDK-Version"], sdkVersion)
    }

    func testAdaptRequestUnauthorized() {
        let accessToken = UUID().uuidString

        keychainService[.accessToken] = accessToken
        let urlRequest = try! Router.authorize.asURLRequest()
        let adaptedUrlRequest = try? sessionAdapter.adapt(urlRequest)

        let adaptedAuthorizatioHeaderValue = adaptedUrlRequest?.allHTTPHeaderFields?["Authorization"]
        XCTAssertNil(adaptedAuthorizatioHeaderValue)
    }

    func testAdaptRequestAuthorized() {
        let accessToken = UUID().uuidString
        keychainService[.accessToken] = accessToken

        let urlRequest = try! Router.userInfo.asURLRequest()
        let adaptedUrlRequest = try? sessionAdapter.adapt(urlRequest)

        let adaptedAuthorizatioHeaderValue = adaptedUrlRequest?.allHTTPHeaderFields?["Authorization"]
        XCTAssertNotNil(adaptedAuthorizatioHeaderValue)
        XCTAssertEqual("Bearer \(accessToken)", adaptedAuthorizatioHeaderValue)
    }
}
