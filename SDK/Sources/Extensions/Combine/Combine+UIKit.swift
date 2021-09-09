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
import UIKit

extension UIViewController {
    func present(_ viewControllerToPresent: UIViewController, animated: Bool) -> NoErrorFuture<Void> {
        return NoErrorFuture { promise in
            DispatchQueue.main.async {
                viewControllerToPresent.modalPresentationStyle = .fullScreen
                self.present(viewControllerToPresent, animated: animated) {
                    promise(.success(()))
                }
            }
        }
    }

    func dismiss(animated: Bool) -> NoErrorFuture<Void> {
        return NoErrorFuture { promise in
            DispatchQueue.main.async {
                self.dismiss(animated: animated) {
                    promise(.success(()))
                }
            }
        }
    }
}
