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
import Then

class LoginViewModel {
    private let client: Data4LifeClient

    init(client: Data4LifeClient) {
        self.client = client
    }

    var loginInProgressCallback: ((Bool) -> Void)?
    var loginInProgress: Bool = false {
        didSet {
            loginInProgressCallback?(loginInProgress)
        }
    }

    func presentLoginScreen(on viewController: UIViewController, scopes: [String]) -> Async<Void> {
        loginInProgress = true

        do {
            try? client.cryptoService.deleteKeyPair()
            let keypair = try client.cryptoService.fetchOrGenerateKeyPair()
            let encodedPublicKey = try JSONEncoder().encode(keypair).base64EncodedString()
            let userAgent = OAuthExternalUserAgent(with: viewController)

            return async {
                _ =  try await(self.client.oAuthService.presentLogin(with: userAgent,
                                                                     publicKey: encodedPublicKey,
                                                                     scopes: scopes,
                                                                     animated: true,
                                                                     authStateType: AuthState.self))
                _ = try await(self.client.userService.fetchUserInfo())
            }
        } catch {
            loginInProgress = false
            return Async.reject(error)
        }
    }
}
