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

protocol SessionAdapterType: RequestAdapter {}

final class SessionAdapter: SessionAdapterType {
    private let keychainService: KeychainServiceType
    private let sdkVersion: String

    init(keychainService: KeychainServiceType, sdkVersion: String) {
        self.keychainService = keychainService
        self.sdkVersion = sdkVersion
    }

    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        guard let urlString = urlRequest.url?.absoluteString,
            urlString.hasPrefix(Router.baseUrl) else {
                return urlRequest
        }

        var urlRequest = urlRequest
        urlRequest.setValue("ios-\(sdkVersion)", forHTTPHeaderField: "hc-sdk-version")

        guard let accessToken = keychainService[.accessToken],
            urlRequest.allHTTPHeaderFields?["Authorization"]?.isEmpty == true else {
            return urlRequest
        }

        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return urlRequest
    }
}
