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
import AppAuth

class AuthStateMock: NSObject, NSCoding, AuthStateType {

    private enum Keys: String {
        case actionResultOne, actionResultTwo, actionResultThree
        case tokenResponseResult
    }

    override init() { }

    required init?(coder aDecoder: NSCoder) {
        performActionWithAdditionalResult = {
            let one = aDecoder.decodeObject(forKey: Keys.actionResultOne.rawValue) as? String
            let two = aDecoder.decodeObject(forKey: Keys.actionResultTwo.rawValue) as? String
            let three = aDecoder.decodeObject(forKey: Keys.actionResultThree.rawValue) as? Error
            return (one, two, three)
        }()
        lastTokenResponseResult = aDecoder.decodeObject(forKey: Keys.tokenResponseResult.rawValue) as? OIDTokenResponse
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(lastTokenResponseResult, forKey: Keys.tokenResponseResult.rawValue)
        if let one = performActionWithAdditionalResult?.0 {
            aCoder.encode(one, forKey: Keys.actionResultOne.rawValue)
        }
        if let two = performActionWithAdditionalResult?.1 {
            aCoder.encode(two, forKey: Keys.actionResultTwo.rawValue)
        }
        if let three = performActionWithAdditionalResult?.2 {
            aCoder.encode(three, forKey: Keys.actionResultThree.rawValue)
        }
    }

    var lastTokenResponseCalled: Bool = false
    var lastTokenResponseResult: OIDTokenResponse?
    var lastTokenResponse: OIDTokenResponse? {
        lastTokenResponseCalled = true
        return lastTokenResponseResult ?? nil
    }

    var setNeedsTokenRefreshCalled: Bool = false
    func setNeedsTokenRefresh() {
        setNeedsTokenRefreshCalled = true
    }

    var performActionCalled: Bool = false
    var performActionResult: (String?, String?, Error?)?
    func performAction(freshTokens action: @escaping OIDAuthStateAction) {
        performActionCalled = true

        guard let (access, refresh, error) = performActionResult else {
            action(nil, nil, OIDErrorUtilities.error(with: .tokenRefreshError, underlyingError: nil, description: nil))
            return
        }

        action(access, refresh, error)
    }

    var performActionWithAdditionalCalled: Bool = false
    var performActionWithAdditionalResult: (String?, String?, Error?)?
    func performAction(freshTokens action: @escaping OIDAuthStateAction,
                       additionalRefreshParameters: [String : String]?) {

        performActionWithAdditionalCalled = true
        guard let (access, refresh, error) = performActionWithAdditionalResult else {
            action(nil, nil, OIDErrorUtilities.error(with: .tokenRefreshError, underlyingError: nil, description: nil))
            return
        }

        action(access, refresh, error)
    }

    static var authStateByPresentingCalledWith: (OIDAuthorizationRequest, UIViewController, (AuthStateType?, Error?) -> Void)?
    static var authStateByPresentingCallbackResult: (AuthStateType?, Error?)?
    static var authStateByPresentingResult: OIDExternalUserAgentSession?

    static func authState(byPresenting authorizationRequest: OIDAuthorizationRequest,
                          presenting viewController: UIViewController,
                          callback: @escaping (AuthStateType?, Error?) -> Void) -> OIDExternalUserAgentSession? {
        authStateByPresentingCalledWith = (authorizationRequest, viewController, callback)
        if let callbackResponse = authStateByPresentingCallbackResult {
            callback(callbackResponse.0, callbackResponse.1)
        }

        return authStateByPresentingResult
    }

    static var authStateByPresentingExternalUserAgentCalledWith: (OIDAuthorizationRequest, OIDExternalUserAgent, (AuthStateType?, Error?) -> Void)? // swiftlint:disable:this identifier_name
    static var authStateByPresentingExternalUserAgentCallbackResult: (AuthStateType?, Error?)? // swiftlint:disable:this identifier_name
    static var authStateByPresentingExternalUserAgentResult: OIDExternalUserAgentSession?

    static func authState(byPresenting authorizationRequest: OIDAuthorizationRequest,
                          presenting externalUserAgent: OIDExternalUserAgent,
                          callback: @escaping (AuthStateType?, Error?) -> Void) -> OIDExternalUserAgentSession? {
        authStateByPresentingExternalUserAgentCalledWith = (authorizationRequest, externalUserAgent, callback)
        if let session = authStateByPresentingExternalUserAgentResult {
            externalUserAgent.present(authorizationRequest, session: session)
        }
        if let callbackResponse = authStateByPresentingExternalUserAgentCallbackResult {
            callback(callbackResponse.0, callbackResponse.1)
        }

        externalUserAgent.dismiss(animated: true, completion: { })
        return authStateByPresentingExternalUserAgentResult
    }
}

extension AuthStateMock {
    static func clearStubs() {
        AuthStateMock.authStateByPresentingCalledWith = nil
        AuthStateMock.authStateByPresentingCallbackResult = nil
        AuthStateMock.authStateByPresentingResult = nil
        AuthStateMock.authStateByPresentingExternalUserAgentResult = nil
        AuthStateMock.authStateByPresentingExternalUserAgentCallbackResult = nil
        AuthStateMock.authStateByPresentingExternalUserAgentCalledWith = nil
    }
}
