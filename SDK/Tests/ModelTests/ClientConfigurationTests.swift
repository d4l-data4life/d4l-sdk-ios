//  Copyright (c) 2021 D4L data4life gGmbH
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

import XCTest
@testable import Data4LifeSDK

class ClientConfigurationTests: XCTestCase {
    func testClientConfigSuccessfulGeneratedProperties() throws {

        let id = UUID().uuidString
        let redirectUrlString = "scheme://host.com"
        let environment = Environment.staging
        let config = ClientConfiguration.test(id: id, redirectUrlString: redirectUrlString, environment: environment)

        XCTAssertEqual(try config.partnerId(), id, "It should return the correct partner id")
        XCTAssertEqual(try config.redirectURL(), URL(string: redirectUrlString)!, "It should return the correct redirect Url")
        XCTAssertEqual(try config.environmentHost(), "api-staging.data4life.care", "It should return the correct host")
        XCTAssertEqual(config.apiBaseUrlString, "https://api-staging.data4life.care", "It should return the correct base url")
        XCTAssertEqual(try config.keychainName(), "de.gesundheitscloud.keychain.api-staging.data4life.care",
                       "It should return the correct keychain name")
    }

    func testClientConfigThrowingGeneratedProperties() throws {

        let id = UUID().uuidString
        let redirectUrlString = "invalid scheme"
        let environment = Environment.staging
        let config = ClientConfiguration.test(id: id, platform: nil, redirectUrlString: redirectUrlString, environment: environment)

        XCTAssertThrowsError(try config.partnerId(), "It should throw an error", { error in
            XCTAssertTrue(error is Data4LifeSDKError.ClientConfiguration)
            XCTAssertEqual(error as? Data4LifeSDKError.ClientConfiguration,
                           Data4LifeSDKError.ClientConfiguration.clientIdentifierInInfoPlistInWrongFormat)
        })
        XCTAssertThrowsError(try config.redirectURL(), "It should throw an error", { error in
            XCTAssertTrue(error is Data4LifeSDKError.ClientConfiguration)
            XCTAssertEqual(error as? Data4LifeSDKError.ClientConfiguration, Data4LifeSDKError.ClientConfiguration.couldNotBuildRedirectUrl)
        })
    }

    func testClientConfigSuccessfulKeychainValidation() throws {

        let keyChainId = "example"
        let appGroupId = "also.an.example"
        let config = ClientConfiguration.test(keychainGroup: keyChainId, appGroup: appGroupId)
        XCTAssertNoThrow(try config.validateKeychainConfiguration(), "It should not throw an error")
    }

    func testClientConfigThrowingKeychainValidation() throws {

        let keyChainId = "example"
        let appGroupId: String? = nil
        let config = ClientConfiguration.test(keychainGroup: keyChainId, appGroup: appGroupId)
        XCTAssertThrowsError(try config.validateKeychainConfiguration(), "It should throw an error", { error in
            XCTAssertTrue(error is Data4LifeSDKError.ClientConfiguration)
            XCTAssertEqual(error as? Data4LifeSDKError.ClientConfiguration,
                           Data4LifeSDKError.ClientConfiguration.appGroupsIdentifierMissingForKeychain)
        })
    }
}

fileprivate extension ClientConfiguration {
    static func test(id: String = UUID().uuidString,
                     platform: String? = "ios",
                     secret: String = "secret",
                     redirectUrlString: String = "scheme://host.com",
                     keychainGroup: String? = "keychain.group",
                     appGroup: String? = "app.group",
                     environment: Environment = .staging) -> ClientConfiguration {
        let clientId = [id, platform]
            .compactMap { $0 }
            .joined(separator: "#")
        let config = ClientConfiguration(clientId: clientId, secret: secret,
                                         redirectURLString: redirectUrlString, keychainGroupId: keychainGroup, appGroupId: appGroup,
                                         environment: environment)
        return config
    }
}