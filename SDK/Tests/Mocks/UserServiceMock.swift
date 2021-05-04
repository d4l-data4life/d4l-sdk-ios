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

@testable import Data4LifeSDK
import Then

class UserServiceMock: UserServiceType {

    var fetchUserInfoResult: Async<Void>?
    var fetchUserInfoCalled: Bool = false
    func fetchUserInfo() -> Promise<Void> {
        fetchUserInfoCalled = true
        return fetchUserInfoResult ?? Promise.reject()
    }

    var logoutCalledWith: String?
    var logoutResult: Async<Void>?
    func logout(refreshToken: String) -> Promise<Void> {
        logoutCalledWith = (refreshToken)
        return logoutResult ?? Promise.reject()
    }

    var getUserIdResult: String?
    func getUserId() throws -> String {
        guard let result = getUserIdResult else {
            throw Data4LifeSDKError.notLoggedIn
        }
        return result
    }
}
