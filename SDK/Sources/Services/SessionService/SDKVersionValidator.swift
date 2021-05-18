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
import Combine

protocol SDKVersionValidatorType {
    var sessionService: SessionService? { get }
    func fetchCurrentVersionStatus() -> SDKFuture<VersionStatus>
    func fetchVersionConfigurationRemotely() -> SDKFuture<Void>
    func setSessionService(_ sessionService: SessionService)
}

class SDKVersionValidator: SDKVersionValidatorType {

    private var infoService: InfoServiceType
    private var sdkBundle: Foundation.Bundle
    private let sdkFileManager: SDKFileManagerType
    weak var sessionService: SessionService?

    enum ValidatorVersion: String {
        case v1
    }

    init(container: DIContainer) {
        do {
            self.infoService = try container.resolve()
            self.sdkBundle = try container.resolve()
            self.sdkFileManager = try container.resolve()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func fetchCurrentVersionStatus() -> SDKFuture<VersionStatus> {
            return combineAsync {
                let currentVersion = self.infoService.fetchSDKVersion()
                let versionConfiguration = try combineAwait(self.fetchVersionConfigurationLocally())
                return self.fetchStatus(currentVersion: currentVersion, versionConfiguration: versionConfiguration)
            }
    }

    func fetchVersionConfigurationRemotely() -> SDKFuture<Void> {
        return combineAsync {
            guard let sessionService = self.sessionService else {
                fatalError("Session service required to use the VersionValidator")
            }

            let versionConfiguration: SDKVersionConfiguration = try combineAwait(
                sessionService.request(route:
                    Router.versionInfo(version: ValidatorVersion.v1.rawValue))
                    .responseDecodable())
            let versionConfigurationData = try JSONEncoder().encode(versionConfiguration)
            try? self.sdkFileManager.saveVersionConfiguration(data: versionConfigurationData)
        }
    }

    func setSessionService(_ sessionService: SessionService) {
        self.sessionService = sessionService
    }

    private func fetchVersionConfigurationLocally() -> SDKFuture<SDKVersionConfiguration?> {
        return combineAsync {
            let fileData = try self.sdkFileManager.readVersionConfiguration()
            return try JSONDecoder().decode(SDKVersionConfiguration.self, from: fileData)
        }
    }

    private func fetchStatus(currentVersion: String, versionConfiguration: SDKVersionConfiguration?) -> VersionStatus {
        guard let versionConfiguration = versionConfiguration else { return .unknown }

        for versionRange in versionConfiguration.versionRanges {
            if version(currentVersion, isWithin: versionRange) {
                return versionRange.status
            }
        }

        return .supported
    }
}

// MARK: - Helpers
extension SDKVersionValidator {
    private func version(_ currentVersion: String, isWithin versionRange: VersionRange) -> Bool {
        return versionRange.fromVersion.compare(currentVersion, options: .numeric) != .orderedDescending &&
            currentVersion.compare(versionRange.toVersion, options: .numeric) != .orderedDescending
    }
}
