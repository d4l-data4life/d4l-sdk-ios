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
import AppAuth

protocol AuthStateType {
    var lastTokenResponse: OIDTokenResponse? { get }

    func performAction(freshTokens action: @escaping OIDAuthStateAction)
    func performAction(freshTokens action: @escaping OIDAuthStateAction, additionalRefreshParameters: [String: String]?)
    func setNeedsTokenRefresh()
    static func authState(byPresenting authorizationRequest: OIDAuthorizationRequest,
                          presenting viewController: UIViewController,
                          callback: @escaping (AuthStateType?, Error?) -> Void) -> OIDExternalUserAgentSession?
    static func authState(byPresenting authorizationRequest: OIDAuthorizationRequest,
                          presenting externalUserAgent: OIDExternalUserAgent,
                          callback: @escaping (AuthStateType?, Error?) -> Void) -> OIDExternalUserAgentSession?
}

class AuthState: OIDAuthState, AuthStateType {
    static func authState(byPresenting authorizationRequest: OIDAuthorizationRequest,
                          presenting viewController: UIViewController,
                          callback: @escaping (AuthStateType?, Error?) -> Void) -> OIDExternalUserAgentSession? {
        return OIDAuthState.authState(byPresenting: authorizationRequest,
                                      presenting: viewController) { (state, error) in
            if let state = state {
                let authState = AuthState(oidAuthState: state)
                callback(authState, nil)
            }

            if let error = error {
                callback(nil, error)
            }

            callback(nil, nil)
        }
    }
    static func authState(byPresenting authorizationRequest: OIDAuthorizationRequest,
                          presenting externalUserAgent: OIDExternalUserAgent,
                          callback: @escaping (AuthStateType?, Error?) -> Void) -> OIDExternalUserAgentSession? {
        return OIDAuthState.authState(byPresenting: authorizationRequest, externalUserAgent: externalUserAgent) { (state, error) in
            if let state = state {
                let authState = AuthState(oidAuthState: state)
                callback(authState, nil)
            }
            if let error = error {
                callback(nil, error)
            }
            callback(nil, nil)
        }
    }

    convenience init(oidAuthState: OIDAuthState) {
        self.init(authorizationResponse: oidAuthState.lastAuthorizationResponse,
                  tokenResponse: oidAuthState.lastTokenResponse,
                  registrationResponse: oidAuthState.lastRegistrationResponse)
    }
}
