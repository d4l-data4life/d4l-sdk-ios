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
@_implementationOnly import Then
import SVProgressHUD

class LoginViewController: UIViewController {

    let viewModel: LoginViewModel
    let scopes: [String]
    var successHandler: Promise<Void> = Promise()
    private var foregroundObserver: NSObjectProtocol?
    private let notificationCenter: NotificationCenter = NotificationCenter.default

    // MARK: - Life cycle methods
    public init(client: Data4LifeClient = Data4LifeClient.default, scopes: [String]) {
        self.viewModel = LoginViewModel(client: client)
        self.scopes = scopes
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSpinner()

        viewModel.loginInProgressCallback = { state in
            if state {
                self.showProgress(userInteractionEnabled: true)
            } else {
                self.hideProgress()
            }
        }

        let notification = UIApplication.willEnterForegroundNotification
        foregroundObserver = notificationCenter.addObserver(forName: notification, object: nil, queue: nil) { [weak self] _ in
            guard self?.presentedViewController == nil else {
                // SafariViewController is already presented so there is no need to do it again
                return
            }
            self?.presentLoginScreen()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        super.viewWillDisappear(animated)
    }

    func presentLoginScreen() {
        viewModel.presentLoginScreen(on: self, scopes: scopes)
            .then {
                self.successHandler.fulfill(())
            }.onError { error in
                self.successHandler.reject(error)
            }.finally {
                self.hideProgress()
            }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - SVProgressHUD Spinner
    func setupSpinner() {
        SVProgressHUD.setDefaultStyle(.custom)
        SVProgressHUD.setCornerRadius(10.0)
        SVProgressHUD.setRingThickness(4.0)
        SVProgressHUD.setForegroundColor(.primary)
        SVProgressHUD.setBorderColor(UIColor.spinnerBorder.withAlphaComponent(0.1))
        SVProgressHUD.setBorderWidth(0.5)
    }

    public func showProgress(userInteractionEnabled: Bool) {
        SVProgressHUD.setDefaultMaskType(userInteractionEnabled ? .none : .clear)
        SVProgressHUD.show()
    }

    public func hideProgress() {
        SVProgressHUD.dismiss()
    }
}
