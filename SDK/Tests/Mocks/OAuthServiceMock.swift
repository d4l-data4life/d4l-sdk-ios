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

import Foundation
@testable import Data4LifeSDK
import Alamofire
import Combine

enum OAuthServiceMockError: Error {
    case noResultSet
}

class OAuthServiceMock: OAuthServiceType {

    var sessionStateChanged: ((Bool) -> Void)?
    var redirectURL: URL = URL(string: "example.com")!
    var clientId: String = ""

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        completion(.doNotRetry)
    }

    func handleRedirect(url: URL) {

    }

    var isSessionActiveCalled = false
    var isSessionActiveResult: SDKFuture<Void>?
    func isSessionActive() -> SDKFuture<Void> {
        isSessionActiveCalled = true
        return isSessionActiveResult ?? Fail(error: OAuthServiceMockError.noResultSet).asyncFuture()
    }

    var logoutCalled = false
    var logoutResult: SDKFuture<Void>?
    func logout() -> SDKFuture<Void> {
        logoutCalled = true
        return logoutResult ?? Fail(error: OAuthServiceMockError.noResultSet).asyncFuture()
    }

    var presentLoginCalled: (OAuthExternalUserAgentType, String, [String], Bool, AuthStateType.Type)?
    var presentLoginResult: SDKFuture<Void>?
    func presentLogin(with userAgent: OAuthExternalUserAgentType,
                      publicKey: String,
                      scopes: [String],
                      animated: Bool,
                      authStateType: AuthStateType.Type = AuthStateMock.self) -> SDKFuture<Void> {
        presentLoginCalled = (userAgent, publicKey, scopes, animated, authStateType)
        return presentLoginResult ?? Fail(error: OAuthServiceMockError.noResultSet).asyncFuture()
    }

    func refreshTokens(completion: @escaping DefaultResultBlock) { }
}
