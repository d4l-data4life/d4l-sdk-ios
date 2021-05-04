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

import UIKit

extension Data4LifeClient {

    /// OAuth client id
    public var clientId: String? {
        return oAuthService.clientId
    }

    /// OAuth redirect url
    public var redirectURL: String? {
        return oAuthService.redirectURL.absoluteString
    }

    /**
     Pushes the loginView to the provided viewController.

     - parameter viewController: ViewController on which the loginView is pushed
     - parameter animated: Bool that decides if animations should happen in the loginView
     - parameter scopes: request permissions with OAuth2 scopes
     - parameter presentationCompletion: Callback that is called when the viewController is opened
     - parameter loginCompletion: Callback that is called when login process is done
     */
    public func presentLogin(on viewController: UIViewController,
                             animated: Bool,
                             scopes: [String]? = nil,
                             presentationCompletion: (() -> Void)? = nil,
                             loginCompletion: @escaping DefaultResultBlock) {
        let loginViewController = LoginViewController(client: self, scopes: scopes ?? defaultScopes)

        viewController
            .present(loginViewController, animated: animated)
            .chain { presentationCompletion?() }
            .then(loginViewController.presentLoginScreen)

        loginViewController
            .successHandler
            .chain(loginViewController.dismiss(animated: animated))
            .complete(loginCompletion)
    }

    /**
     Clears all credentials from the client and performs logout

     - parameter completion: Completion that returns an empty result
     */
    public func logout(queue: DispatchQueue = responseQueue,
                       completion: @escaping DefaultResultBlock) {
        oAuthService
            .logout()
            .then(cryptoService.deleteKeyPair())
            .complete(queue: queue, completion)
    }

    /**
     Checks if the user is logged in, requires active internet connection

     - parameter completion: Completion that returns boolean representing current state
     */
    public func isUserLoggedIn(queue: DispatchQueue = responseQueue,
                               _ completion: @escaping ResultBlock<Void>) {
        guard commonKeyService.currentKey != nil, cryptoService.tek != nil else {
            completion(.failure(Data4LifeSDKError.notLoggedIn))
            return
        }

        oAuthService.isSessionActive().complete(queue: queue, completion)
    }

    /**
     Refresh data tokens

     - parameter completion: Completion closure to be called after the token have been refreshed
     */
    public func refreshedAccessToken(completion: @escaping ResultBlock<String?>) {
        oAuthService.refreshTokens { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                completion(.success(self.keychainService[.accessToken]))
            }
        }
    }

    /**
     Returns a boolean indicating session state change. It's possible to register only one listener.

     - parameter completion: Completion that returns boolean representing current state
     */
    public func sessionStateDidChange(queue: DispatchQueue = responseQueue,
                                      completion: @escaping (Bool) -> Void) {
        guard oAuthService.sessionStateChanged == nil else { return }
        oAuthService.sessionStateChanged = completion
    }

    /**
     Returns the userID connected with the account, only if the account is logged in, returns a Not Logged In error otherwise.

     - parameter completion: Completion that returns the userID connected with the account.
     */
    public func getUserId(completion: @escaping ResultBlock<String>) {
        do {
            let userId = try userService.getUserId()
            completion(.success(userId))
        } catch {
            completion(.failure(error))
        }
    }
}
