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
import Alamofire
import Then

public typealias Parameters = [String : Any]

class SessionService: SessionManager {

    private var policyManager: ServerTrustPolicyManager?
    private var networkReachabilityManager: ReachabilityType
    private var handler: (DefaultDataResponse) -> Void = { _ in }
    private var versionValidator: SDKVersionValidatorType

    init(hostname: String,
         sdkBundle: Bundle,
         versionValidator: SDKVersionValidatorType,
         networkManager: ReachabilityType = Reachability(),
         adapter: SessionAdapterType? = nil) {
        let publicKeys = ServerTrustPolicy.publicKeys(in: sdkBundle)
        self.versionValidator = versionValidator

        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: true,
            validateHost: true
        )
        let serverTrustPolicyManager = ServerTrustPolicyManager(policies: [hostname: serverTrustPolicy])

        self.policyManager = serverTrustPolicyManager
        self.networkReachabilityManager = networkManager

        super.init(serverTrustPolicyManager: serverTrustPolicyManager)
        self.adapter = adapter
    }

    init(configuration: URLSessionConfiguration,
         versionValidator: SDKVersionValidatorType,
         serverTrustPolicyManager: ServerTrustPolicyManager?,
         networkManager: ReachabilityType = Reachability(),
         adapter: SessionAdapterType?) {
        self.versionValidator = versionValidator
        self.networkReachabilityManager = networkManager
        super.init(configuration: configuration, serverTrustPolicyManager: serverTrustPolicyManager)
        self.adapter = adapter
    }

    func request(route: Router) throws -> DataRequest {
        guard networkReachabilityManager.isReachable else {
             throw Data4LifeSDKError.networkUnavailable
        }

        if route.needsVersionValidation {
            try await(validateSDKVersion())
        }

        return request(route)
            .logged
            .validate()
            .response(completionHandler: { [weak self] response in
                //self?.log(response)
                self?.handler(response)
            })
    }

    func request(url: URL, method: HTTPMethod) throws -> DataRequest {
        guard networkReachabilityManager.isReachable else {
            throw Data4LifeSDKError.networkUnavailable
        }

        try await(validateSDKVersion())

        return request(url, method: method)
            .logged
            .validate()
            .response(completionHandler: {  [weak self] response in
                //self?.log(response)
                self?.handler(response)
            })
    }

    func upload(data: Data, route: Router) throws -> DataRequest {
        guard networkReachabilityManager.isReachable else {
            throw Data4LifeSDKError.networkUnavailable
        }

        if route.needsVersionValidation {
            try await(validateSDKVersion())
        }

        return upload(data, with: route)
            .logged
            .response(completionHandler: { [weak self] response in
                //self?.log(response)
                self?.handler(response)
            })
    }
}

private extension SessionService {

    func log(_ response: DefaultDataResponse) {

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
        //logDebug("Request cURL: \(self.debugDescription)")
        return self
    }
}
