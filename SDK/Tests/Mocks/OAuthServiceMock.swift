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

import Foundation
@testable import Data4LifeSDK
import Alamofire
import Then

class OAuthServiceMock: OAuthServiceType {
    var sessionStateChanged: ((Bool) -> Void)?
    var redirectURL: URL = URL(string: "example.com")!
    var clientId: String = ""

    func should(_ manager: SessionManager,
                retry request: Request,
                with error: Error,
                completion: @escaping RequestRetryCompletion) {
        completion(false, 0.0)
    }

    func handleRedirect(url: URL) {

    }

    var isSessionActiveCalled = false
    var isSessionActiveResult: Async<Void>?
    func isSessionActive() -> Promise<Void> {
        isSessionActiveCalled = true
        return isSessionActiveResult ?? Promise.reject()
    }

    var logoutCalled = false
    var logoutResult: Async<Void>?
    func logout() -> Promise<Void> {
        logoutCalled = true
        return logoutResult ?? Async.reject()
    }

    var presentLoginCalled: (OAuthExternalUserAgentType, String, [String], Bool, AuthStateType.Type)?
    var presentLoginResult: Promise<Void>?
    func presentLogin(with userAgent: OAuthExternalUserAgentType,
                      publicKey: String,
                      scopes: [String],
                      animated: Bool,
                      authStateType: AuthStateType.Type = AuthStateMock.self) -> Promise<Void> {
        presentLoginCalled = (userAgent, publicKey, scopes, animated, authStateType)
        return presentLoginResult ?? Async.reject()
    }

    func refreshTokens(completion: @escaping DefaultResultBlock) { }
}
