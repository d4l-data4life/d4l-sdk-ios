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
import SafariServices
@_implementationOnly import AppAuth

/*
 * In order to make UX better, SDK uses custom user agent for presenting controller,
 * since there is not SSO feature (yet) there is no need to use `SFAuthenticationSession`.
 * More info can be found here: https://github.com/openid/AppAuth-iOS/issues/177
 */

protocol OAuthExternalUserAgentType: OIDExternalUserAgent {
    init(with presentingViewController: UIViewController)
}

class OAuthExternalUserAgent: NSObject, OAuthExternalUserAgentType {

    private let presentingViewController: UIViewController
    private var authorizationFlowInProgress: Bool = false
    private weak var session: OIDExternalUserAgentSession?

    required init(with presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        super.init()
    }

    func present(_ request: OIDExternalUserAgentRequest, session: OIDExternalUserAgentSession) -> Bool {
        guard  authorizationFlowInProgress == false else {
            return false
        }
        guard let requestURL = request.externalUserAgentRequestURL() else {
            return false
        }
        self.authorizationFlowInProgress = true
        self.session = session
        let safarViewController = SFSafariViewController(url: requestURL)
        safarViewController.delegate = self
        DispatchQueue.main.async {
            safarViewController.modalPresentationStyle = .fullScreen
            self.presentingViewController.present(safarViewController, animated: true, completion: nil)
        }
        return true
    }

    func dismiss(animated: Bool, completion: @escaping () -> Void) {
        authorizationFlowInProgress = false
        session = nil
        DispatchQueue.main.async {
          self.presentingViewController.dismiss(animated: animated, completion: completion)
        }
    }
}

extension OAuthExternalUserAgent: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        guard authorizationFlowInProgress == true else {
            return
        }
        let error = OIDErrorUtilities.error(with: OIDErrorCode.userCanceledAuthorizationFlow, underlyingError: nil, description: nil)
        session?.failExternalUserAgentFlowWithError(error)
        authorizationFlowInProgress = false
        session = nil
    }
}