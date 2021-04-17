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
@_implementationOnly import Alamofire
@_implementationOnly import Then

public typealias Parameters = [String : Any]

final class SessionService {

    private var networkReachabilityManager: ReachabilityType
    private var versionValidator: SDKVersionValidatorType
    private(set) var session: Session
    private var serverTrustManager: ServerTrustManager?
    private var interceptor: RequestInterceptorType?

    init(configuration: URLSessionConfiguration,
         versionValidator: SDKVersionValidatorType,
         serverTrustManager: ServerTrustManager?,
         networkManager: ReachabilityType = Reachability(),
         interceptor: RequestInterceptorType?) {

        self.versionValidator = versionValidator
        self.networkReachabilityManager = networkManager
        self.serverTrustManager = serverTrustManager
        self.interceptor = interceptor
        self.session = Session(configuration: configuration, interceptor: interceptor, serverTrustManager: serverTrustManager)
    }

    convenience init(hostname: String,
                     sdkBundle: Foundation.Bundle,
                     versionValidator: SDKVersionValidatorType,
                     networkManager: ReachabilityType = Reachability(),
                     interceptor: RequestInterceptorType? = nil) {

        let publicKeys = sdkBundle.af.publicKeys
        let serverTrustPolicy = PublicKeysTrustEvaluator(keys: publicKeys, performDefaultValidation: true, validateHost: true)
        let serverTrustManager = ServerTrustManager(evaluators: [hostname: serverTrustPolicy])
        self.init(configuration: URLSessionConfiguration.af.default,
                  versionValidator: versionValidator,
                  serverTrustManager: serverTrustManager,
                  networkManager: networkManager,
                  interceptor: interceptor)
    }
}

extension SessionService {
    func request(route: Router) throws -> DataRequest {
        guard networkReachabilityManager.isReachable else {
            throw Data4LifeSDKError.networkUnavailable
        }

        if route.needsVersionValidation {
            try await(validateSDKVersion())
        }

        return session.request(route, interceptor: interceptor)
            .logged
            .validate()
            .response(completionHandler: { [weak self] response in
                self?.log(response)
            })
    }

    func request(url: URL, method: HTTPMethod) throws -> DataRequest {
        guard networkReachabilityManager.isReachable else {
            throw Data4LifeSDKError.networkUnavailable
        }

        try await(validateSDKVersion())

        return session.request(url, method: method, interceptor: interceptor)
            .logged
            .validate()
            .response(completionHandler: {  [weak self] response in
                self?.log(response)
            })
    }

    func upload(data: Data, route: Router) throws -> DataRequest {
        guard networkReachabilityManager.isReachable else {
            throw Data4LifeSDKError.networkUnavailable
        }

        if route.needsVersionValidation {
            try await(validateSDKVersion())
        }

        return session.upload(data, with: route, interceptor: interceptor)
            .logged
            .response(completionHandler: { [weak self] response in
                self?.log(response)
            })
    }
}

private extension SessionService {

    func log(_ response: AFDataResponse<Data?>) {

        if let httpUrlResponseDescription = response.response?.description {
            logDebug("Response Headers: \(httpUrlResponseDescription)")
        }

        if let error = response.error {
            logDebug("Response error: \(error)")
        }

        if let data = response.data {
            if let dataDescription = String(data: data, encoding: .utf8) {
                logDebug("Response body: \(dataDescription)")
            } else {
                logDebug("Response data size: \(data.description)")
            }
        }
    }

    private func validateSDKVersion() -> Async<Void> {
        return async {
            var versionStatus = try await(self.versionValidator.fetchCurrentVersionStatus())
            if versionStatus == .unknown {
                try await(self.versionValidator.fetchVersionConfigurationRemotely())
                versionStatus = try await(self.versionValidator.fetchCurrentVersionStatus())
            }

            try self.alertIfNeeded(for: versionStatus)
        }
    }

    private func alertIfNeeded(for status: VersionStatus) throws {
        switch status {
        case .unknown:
            logDebug("The current version status is UNKNOWN. The app can continue working but it might crash.")
        case .unsupported:
            throw Data4LifeSDKError.unsupportedVersionRunning
        case .deprecated:
            logDebug("The current version status is DEPRECATED. Please update to the latest version as soon as possible")
        case .supported:
            break
        }
    }
}

private extension DataRequest {
    var logged: DataRequest {
        logDebug("Request cURL: \(self.description)")
        return self
    }
}
