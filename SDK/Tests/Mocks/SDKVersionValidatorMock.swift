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
@testable import Data4LifeSDK

enum SDKVersionValidatorMockError: Error {
    case noResultSet
}

class SDKVersionValidatorMock: SDKVersionValidatorType {
    var sessionService: SessionService?

    var fetchCurrentVersionStatusResult: SDKFuture<VersionStatus>?
    func fetchCurrentVersionStatus() -> SDKFuture<VersionStatus> {
        return fetchCurrentVersionStatusResult ?? Fail(error: SDKVersionValidatorMockError.noResultSet).asyncFuture
    }

    var fetchVersionConfigOnlineCalled: Bool = false
    var fetchVersionConfigOnlineResult: SDKFuture<Void>?
    func fetchVersionConfigurationRemotely() -> SDKFuture<Void> {
        fetchVersionConfigOnlineCalled = true
        return fetchVersionConfigOnlineResult ?? Fail(error: SDKVersionValidatorMockError.noResultSet).asyncFuture
    }

    var setSessionServiceCalledWith: (SessionService)?
    func setSessionService(_ sessionService: SessionService) {
        setSessionServiceCalledWith = sessionService
    }
}
