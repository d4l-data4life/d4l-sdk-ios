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
import Data4LifeSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let configuration = Data4LifeConfiguration()

    var window: UIWindow?
    var initialViewController: UIViewController {
        guard ProcessInfo.processInfo.environment.contains(where: { $0.key == "XCTestConfigurationFilePath" }) == false else {
            return UIViewController(nibName: nil, bundle: nil) // don't load Example app UI in case tests are running
        }
        let storyboard = UIStoryboard(name: "Main", bundle: Foundation.Bundle.main)
        guard let initialViewController = storyboard.instantiateInitialViewController() else {
            fatalError("Could not load inital view controller")
        }
        return initialViewController
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil)
    -> Bool {

        Data4LifeClient.configureWith(clientId: configuration.clientIdentifier,
                                      clientSecret: configuration.clientSecret,
                                      redirectURLString: configuration.redirectSchemeUrlString,
                                      environment: configuration.environment,
                                      platform: configuration.platform)
        setRootViewController(initialViewController)
        return true
    }

    func setRootViewController(_ viewController: UIViewController) {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        self.window = window
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:])
    -> Bool {
        
        Data4LifeClient.default.handle(url: url)

        return true
    }
}
