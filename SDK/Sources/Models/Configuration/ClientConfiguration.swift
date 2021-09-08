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

struct ClientConfiguration {

    let clientId: String
    let secret: String
    let redirectURLString: String
    let keychainGroupId: String?
    let appGroupId: String?
    let environment: Environment
    let platform: Platform
    let loggerConfiguration: LoggerConfiguration = LoggerConfiguration.console

    private let partnerIdDelimiter: Character = "#"

    init(clientId: String, secret: String,
         redirectURLString: String, keychainGroupId: String? = nil, appGroupId: String? = nil,
         environment: Environment, platform: Platform) {

        let formattedRedirectURLString =
            redirectURLString.hasSuffix("://oauth/") ? redirectURLString : redirectURLString + "://oauth/"
        self.clientId = clientId
        self.secret = secret
        self.redirectURLString = formattedRedirectURLString
        self.keychainGroupId = keychainGroupId
        self.appGroupId = appGroupId
        self.environment = environment
        self.platform = platform
    }
}

extension ClientConfiguration {

    enum Keychain {
        static let baseName = "de.gesundheitscloud.keychain"
    }

    func partnerId() throws -> String {

        guard clientId.contains(partnerIdDelimiter) else {
            throw Data4LifeSDKError.ClientConfiguration.clientIdentifierInInfoPlistInWrongFormat
        }
        let output = clientId.split(separator: partnerIdDelimiter)
        guard output.count == 2,  let partnerId = output.first else {
            throw Data4LifeSDKError.ClientConfiguration.clientIdentifierInInfoPlistInWrongFormat
        }
        return String(partnerId)
    }

    func redirectURL() throws -> URL {
        guard let url = URL(string: redirectURLString) else {
            throw Data4LifeSDKError.ClientConfiguration.couldNotBuildRedirectUrl
        }
        return url
    }

    func keychainName() throws -> String {
        return Keychain.baseName + "." + environmentHost
    }

    var environmentHost: String {
        return Router.baseUrlHost(from: platform, environment: environment)
    }
}

extension ClientConfiguration {
    func validateKeychainConfiguration() throws {
        if keychainGroupId != nil, appGroupId == nil {
            throw Data4LifeSDKError.ClientConfiguration.appGroupsIdentifierMissingForKeychain
        }
    }
}
