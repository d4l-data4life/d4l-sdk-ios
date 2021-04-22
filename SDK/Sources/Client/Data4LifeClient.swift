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
@_implementationOnly import Then

/// Returns either an error or an object
public typealias ResultBlock<Value> = (Result<Value, Error>) -> Void
public typealias DefaultResultBlock = ResultBlock<Void>

/// Returns array of Sucess Result and Failed Results
public typealias BatchResult<T,R> = (success: [T], failed: [(object: R, error: Error)])

/// Manages and stores session data
public class Data4LifeClient {

    private let container: DIContainer
    private let versionValidator: SDKVersionValidatorType

    /// Holds client configuration used for SDK setup
    static var clientConfiguration: ClientConfiguration?

    /// SessionService that stores context data and sends requests
    let sessionService: SessionService
    let sessionServiceInterceptor: RequestInterceptorType

    /// Manages the OAuth Authorization, also acts an adapter for the sessionService
    var oAuthService: OAuthServiceType

    /// Manages access to user specific functionality
    let userService: UserServiceType

    /// Handles all EE2E operations
    let cryptoService: CryptoServiceType

    /// Handles all common key operations
    let commonKeyService: CommonKeyServiceType

    /// Handles all common key operations
    let keychainService: KeychainServiceType

    /// Handles all operations for all of the FHIR types
    let fhirService: FhirServiceType

    /// Handles all operations for App related Generic Data
    let appDataService: AppDataServiceType

    /// Default response queue
    static public var responseQueue: DispatchQueue {
        return DispatchQueue.main
    }

    /// Default oauth scopes
    var defaultScopes: [String] {
        return ["perm:r", "rec:r", "rec:w", "attachment:r", "attachment:w", "user:r", "user:q"]
    }

    /// Singleton instance of client. `configure` needs to be called before first use
    public static let `default` = Data4LifeClient()

    /**
     Initialize a client.
     */
    init() {
        guard let clientConfiguration = Data4LifeClient.clientConfiguration else {
            fatalError("Data4LifeClient is not configured, call `Data4LifeClient.configure(with: ...)` before using the SDK")
        }

        let container = Data4LifeDIContainer()
        container.registerDependencies(with: clientConfiguration)
        self.container = container
        do {
            self.sessionService = try container.resolve()
            self.sessionServiceInterceptor = try container.resolve()
            self.oAuthService = try container.resolve()
            self.cryptoService = try container.resolve()
            self.commonKeyService = try container.resolve()
            self.userService = try container.resolve()
            self.fhirService = try container.resolve()
            self.versionValidator = try container.resolve()
            self.keychainService = try container.resolve()
            self.appDataService = try container.resolve()
        } catch {
            fatalError(error.localizedDescription)
        }
        configureDependencies()
    }

    /**
     This should only be used for testing purposes by dependency injection.
     */
    init(container: DIContainer, environment: Environment) {

        Router.baseUrl = environment.apiBaseURL.absoluteString

        self.container = container
        do {
            self.sessionService = try container.resolve()
            self.sessionServiceInterceptor = try container.resolve()
            self.oAuthService = try container.resolve()
            self.cryptoService = try container.resolve()
            self.commonKeyService = try container.resolve()
            self.userService = try container.resolve()
            self.fhirService = try container.resolve()
            self.versionValidator = try container.resolve()
            self.keychainService = try container.resolve()
            self.appDataService = try container.resolve()
        } catch {
            fatalError(error.localizedDescription)
        }

        // Calling this method provide a way to test that the dependencies were configured properly
        configureDependencies()
    }

    /// OAuth client id
    public var clientId: String? {
        return oAuthService.clientId
    }

    /// OAuth redirect url
    public var redirectURL: String? {
        return oAuthService.redirectURL.absoluteString
    }

    /// Enables logging for debug configurations, defaults to false
    public var isLoggingEnabled: Bool {
        get {
            let loggerService: LoggerService? = try? container.resolve()
            return loggerService?.isLoggingEnabled ?? false
        }
        set {
            let loggerService: LoggerService? = try? container.resolve()
            loggerService?.isLoggingEnabled = newValue
        }
    }

    deinit { }
}

extension Data4LifeClient {
    private func configureDependencies() {
        sessionServiceInterceptor.setRetrier(oAuthService)
        versionValidator.setSessionService(sessionService)
        try? await(versionValidator.fetchVersionConfigurationRemotely())
    }
}

extension Data4LifeClient {
    /**
     Prepare SDK before usage, should be called before any other action

     - parameter clientId: client identifier
     - parameter clientSecret: client secret
     - parameter redirectURLString: OAuth redirect address
     - parameter keychainGroupId: Keychain Sharing group identifier
     */
    public static func configureWith(clientId: String,
                                     clientSecret: String,
                                     redirectURLString: String,
                                     environment: Environment,
                                     keychainGroupId: String? = nil,
                                     appGroupId: String? = nil) {

        let clientConfiguration = ClientConfiguration(clientId: clientId,
                                                      secret: clientSecret,
                                                      redirectURLString: redirectURLString,
                                                      keychainGroupId: keychainGroupId,
                                                      appGroupId: appGroupId,
                                                      environment: environment)

        do {
            try clientConfiguration.validateKeychainConfiguration()
            Router.configure(with: clientConfiguration)
            try Resource.configure(with: clientConfiguration)
            Data4LifeClient.clientConfiguration = clientConfiguration
        } catch {
            fatalError(error.localizedDescription)
        }
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
                               _ completion: @escaping ResultBlock<Data>) {
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
}

extension Data4LifeClient {
    /**
     Handles URL callback for OAuth protocol

     - parameter url: Callback url
     */
    public func handle(url: URL) {
        oAuthService.handleRedirect(url: url)
    }
}
