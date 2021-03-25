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
import Then

final class LoginViewController: UIViewController {

    private let viewModel: LoginViewModel
    private let scopes: [String]
    private var foregroundObserver: NSObjectProtocol?
    private let notificationCenter: NotificationCenter = NotificationCenter.default

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.hidesWhenStopped = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.startAnimating()
        return view
    }()
    var successHandler: Promise<Void> = Promise()

    // MARK: - Life cycle methods
    public init(client: Data4LifeClient = Data4LifeClient.default, scopes: [String]) {
        self.viewModel = LoginViewModel(client: client)
        self.scopes = scopes
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureBehavior()
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        super.viewWillDisappear(animated)
    }

    func presentLoginScreen() {
        viewModel.presentLoginScreen(on: self, scopes: scopes)
            .then { [weak self] in
                self?.successHandler.fulfill(())
            }.onError { [weak self] error in
                self?.successHandler.reject(error)
            }.finally { [weak self] in
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                }
            }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LoginViewController {
    private func configureView() {
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func configureBehavior() {
        viewModel.loginInProgressCallback = { [weak self] state in
            DispatchQueue.main.async {
                if state {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
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
}
