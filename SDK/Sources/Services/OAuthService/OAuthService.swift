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

@_implementationOnly import Alamofire
@_implementationOnly import Then
@_implementationOnly import AppAuth

protocol OAuthServiceType: RequestRetrier {
    var clientId: String { get }
    var redirectURL: URL { get }
    var sessionStateChanged: ((Bool) -> Void)? { get set }

    func handleRedirect(url: URL)
    func logout() -> Async<Void>
    func isSessionActive() -> Async<Void>
    func presentLogin(with userAgent: OAuthExternalUserAgentType,
                      publicKey: String,
                      scopes: [String],
                      animated: Bool,
                      authStateType: AuthStateType.Type) -> Async<Void>
    func refreshTokens(completion: @escaping DefaultResultBlock)
}

class OAuthService: OAuthServiceType {

    var keychainService: KeychainServiceType
    var sessionService: SessionService
    let numberOfRetriesOnTimeout: Int
    var currentRetryCount = 0
    var sessionStateChanged: ((Bool) -> Void)?

    let clientId: String
    let clientSecret: String
    let redirectURL: URL
    let authURL: URL
    let tokenURL: URL

    var storedAuthState: AuthStateType? {
        guard let stringValue = self.keychainService[.authState], let data = Data(base64Encoded: stringValue) else {
            return nil
        }
        if let auth = try? NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: data) {
            return auth as? AuthStateType
        } else if let auth = try? NSKeyedUnarchiver.unarchivedObject(ofClass: AuthState.self, from: data) {
            return auth
        } else if let auth = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? AuthStateType {
            return auth
        }
        return nil
    }
    var externalUserAgentSession: OIDExternalUserAgentSession?
    var serviceConfiguration: OIDServiceConfiguration {
        return OIDServiceConfiguration(authorizationEndpoint: authURL,
                                       tokenEndpoint: tokenURL)
    }

    private var retryRequests: [(RetryResult) -> Void] = []
    var isRefreshing = false

    init(clientId: String,
         clientSecret: String,
         redirectURL: URL,
         authURL: URL,
         tokenURL: URL,
         keychainService: KeychainServiceType,
         sessionService: SessionService,
         authState: AuthStateType? = nil,
         numberOfRetriesOnTimeout: Int = 1) {

        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectURL = redirectURL
        self.authURL = authURL
        self.tokenURL = tokenURL
        self.keychainService = keychainService
        self.sessionService = sessionService
        self.numberOfRetriesOnTimeout = numberOfRetriesOnTimeout
        migrateUnarchiverToD4L()
    }

    private func migrateUnarchiverToD4L() {
        NSKeyedUnarchiver.setClass(Data4LifeSDK.AuthState.self, forClassName: "HCSDK.AuthState")
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {

        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 || response.statusCode == 408 else {
            completion(.doNotRetry)
            return
        }

        if (error as NSError).code == NSURLErrorTimedOut || response.statusCode == 408 {
            if currentRetryCount < numberOfRetriesOnTimeout {
                currentRetryCount += 1
                completion(.retry)
                return
            } else {
                currentRetryCount = 0
                completion(.doNotRetry)
            }
        }

        self.retryRequests.append(completion)

        refreshTokens(completion: { [weak self] _ in
            self?.retryRequests.removeAll()
            self?.isRefreshing = false
        })
    }

    func refreshTokens(completion: @escaping DefaultResultBlock) {
        guard let state = self.storedAuthState else { return }
        guard isRefreshing == false else { return }
        isRefreshing = true
        state.setNeedsTokenRefresh()
        state.performAction(freshTokens: { (accessToken, refreshToken, error) in
            if let error = error {
                self.keychainService.clear()
                self.retryRequests.forEach { $0(.doNotRetry) }
                self.sessionStateChanged?(false)
                completion(.failure(error))
            } else {
                self.keychainService[.refreshToken] = refreshToken
                self.keychainService[.accessToken] = accessToken
                self.retryRequests.forEach { $0(.retry) }
                try? self.saveAuthState(state)
                completion(.success(()))
            }
        }, additionalRefreshParameters: ["client_secret": self.clientSecret])
    }

    func presentLogin(with userAgent: OAuthExternalUserAgentType,
                      publicKey: String,
                      scopes: [String],
                      animated: Bool,
                      authStateType: AuthStateType.Type) -> Async<Void> {
        let authRequest =  OIDAuthorizationRequest(configuration: serviceConfiguration,
                                                   clientId: clientId,
                                                   clientSecret: clientSecret,
                                                   scopes: scopes,
                                                   redirectURL: redirectURL,
                                                   responseType: OIDResponseTypeCode,
                                                   additionalParameters: ["public_key": publicKey])
        return Async { (resolve: @escaping () -> Void, reject: @escaping (Error) -> Void) in
            self.externalUserAgentSession = authStateType.authState(byPresenting: authRequest,
                                                                    presenting: userAgent,
                                                                    callback: { (state, error) in
                                                                        if let error = error {
                                                                            let nsError = error as NSError
                                                                            guard let errorCode = OIDErrorCode(rawValue: nsError.code) else {
                                                                                reject(Data4LifeSDKError.appAuth(error))
                                                                                return
                                                                            }

                                                                            switch errorCode {
                                                                            case .userCanceledAuthorizationFlow:
                                                                                reject(Data4LifeSDKError.userCanceledAuthFlow)
                                                                            case .serverError:
                                                                                reject(Data4LifeSDKError.authServerError)
                                                                            case .networkError:
                                                                                reject(Data4LifeSDKError.authNetworkError)
                                                                            default:
                                                                                reject(Data4LifeSDKError.appAuth(error))
                                                                            }
                                                                        } else if let state = state {
                                                                            do {
                                                                                try self.saveAuthState(state)
                                                                                self.sessionStateChanged?(true)
                                                                                resolve()
                                                                            } catch {
                                                                                reject(error)
                                                                            }
                                                                        }
                                                                    })
        }
    }

    func saveAuthState(_ state: AuthStateType) throws {
        do {
            let stateData = try NSKeyedArchiver.archivedData(withRootObject: state, requiringSecureCoding: false)
            self.keychainService[.authState] = stateData.base64EncodedString()
            self.keychainService[.accessToken] = state.lastTokenResponse?.accessToken
            self.keychainService[.refreshToken] = state.lastTokenResponse?.refreshToken
        } catch {
            throw Data4LifeSDKError.notLoggedIn
        }
    }

    func isSessionActive() -> Async<Void> {
        return async {
            guard let state = self.storedAuthState, state.lastTokenResponse?.refreshToken != nil else {
                throw Data4LifeSDKError.notLoggedIn
            }
            return try wait(self.sessionService.request(route: Router.userInfo).responseEmpty())
        }.bridgeError { error in
            guard (error as? AFError)?.responseCode == 401 else {
                throw Data4LifeSDKError.network(error)
            }
            throw Data4LifeSDKError.notLoggedIn
        }
    }

    func handleRedirect(url: URL) {
        guard  let currentSession = externalUserAgentSession, currentSession.resumeExternalUserAgentFlow(with: url) else {
            return
        }

        externalUserAgentSession = nil
    }

    func logout() -> Async<Void> {
        guard let encodedClientInfo = "\(clientId):\(clientSecret)".data(using: .utf8)?.base64EncodedString() else {
            return Async.reject(Data4LifeSDKError.notLoggedIn)
        }

        return async {
            let refreshToken = try wait(self.keychainService.get(.refreshToken))
            let route = Router.revokeToken(parameters: ["token": refreshToken],
                                           headers: [("Authorization", "Basic \(encodedClientInfo)")])
            _ = try wait(self.sessionService.request(route: route).responseEmpty())
            self.keychainService.clear()
            self.sessionStateChanged?(false)
        }
    }
}
