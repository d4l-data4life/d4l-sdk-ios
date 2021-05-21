//
//  Combine+UIKit.swift
//  Data4LifeSDK
//
//  Created by Alessio Borraccino on 20.05.21.
//  Copyright © 2021 HPS Gesundheitscloud gGmbH. All rights reserved.
//

import Foundation

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
