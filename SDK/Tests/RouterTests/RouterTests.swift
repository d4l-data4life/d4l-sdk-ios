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

import XCTest
@testable import Data4LifeSDK

class RouterTests: XCTestCase {
    func testAuthorizeUrl() throws {
        Router.baseUrl = "https://www.example.com"
        let url = try Router.authorizeUrl()
        XCTAssertEqual(url, URL(string: "https://www.example.com/oauth/authorize"))
    }

    func testFetchTokenUrl() throws {
        Router.baseUrl = "https://www.example.com"
        let url = try Router.fetchTokenUrl()
        XCTAssertEqual(url, URL(string: "https://www.example.com/oauth/token"))
    }

    func testAuthorizeUrlFails() throws {
        Router.baseUrl = "invalid base url"
        XCTAssertThrowsError(try Router.authorizeUrl(), "It should throw an configurationError") { (error) in
            XCTAssertTrue(error is Data4LifeSDKError.ClientConfiguration)
            XCTAssertEqual(error as? Data4LifeSDKError.ClientConfiguration, .couldNotBuildOauthUrls)
        }
    }

    func testFetchTokenUrlFails() throws {
        Router.baseUrl = "invalid base url"
        XCTAssertThrowsError(try Router.fetchTokenUrl(), "It should throw an error") { (error) in
            XCTAssertTrue(error is Data4LifeSDKError.ClientConfiguration)
            XCTAssertEqual(error as? Data4LifeSDKError.ClientConfiguration, .couldNotBuildOauthUrls)
        }
    }

    func testVersionInfoDoesntNeedVersionValidation() throws {
        Router.baseUrl = "https://www.example.com"
        let route = Router.versionInfo(version: "version1")
        XCTAssertFalse(route.needsVersionValidation, "The version Info route doesn't need validation")
    }

    func testRoutesNeedVersionValidation() throws {
        Router.baseUrl = "https://www.example.com"
        let id = UUID().uuidString
        let createDocumentRoute = Router.createDocument(userId: id, headers: [("Content-Type", "application/octet-stream")])
        XCTAssertTrue(createDocumentRoute.needsVersionValidation, "The version Info route needs validation")

        let createRecordRoute = Router.createRecord(userId: id, parameters: [:])
        XCTAssertTrue(createRecordRoute.needsVersionValidation, "The version Info route needs validation")

        let deleteRecordRoute = Router.deleteRecord(userId: id, recordId: id)
        XCTAssertTrue(deleteRecordRoute.needsVersionValidation, "The version Info route needs validation")
    }

    func testRouteBaseUrlBuildingD4lStaging() throws {
        let configuration = ClientConfigurationFactory.d4lTest(for: .staging)
        Router.configure(with: configuration)
        XCTAssertEqual(Router.baseUrl, "https://api-staging.data4life.care")
    }

    func testRouteBaseUrlBuildingD4lDevelopment() throws {
        let configuration = ClientConfigurationFactory.d4lTest(for: .development)
        Router.configure(with: configuration)
        XCTAssertEqual(Router.baseUrl, "https://api-phdp-dev.hpsgc.de")
    }

    func testRouteBaseUrlBuildingD4lProduction() throws {
        let configuration = ClientConfigurationFactory.d4lTest(for: .production)
        Router.configure(with: configuration)
        XCTAssertEqual(Router.baseUrl, "https://api.data4life.care")
    }

    func testRouteBaseUrlBuildingD4lSandbox() throws {
        let configuration = ClientConfigurationFactory.d4lTest(for: .sandbox)
        Router.configure(with: configuration)
        XCTAssertEqual(Router.baseUrl, "https://api-phdp-sandbox.hpsgc.de")
    }

    func testRouteBaseUrlBuildingS4hStaging() throws {
        let configuration = ClientConfigurationFactory.s4hTest(for: .staging)
        Router.configure(with: configuration)
        XCTAssertEqual(Router.baseUrl, "https://api-staging.smart4health.eu")
    }

    func testRouteBaseUrlBuildingS4hDevelopment() throws {
        let configuration = ClientConfigurationFactory.s4hTest(for: .development)
        Router.configure(with: configuration)
        XCTAssertEqual(Router.baseUrl, "https://api-dev.smart4health.eu")
    }

    func testRouteBaseUrlBuildingS4hProduction() throws {
        let configuration = ClientConfigurationFactory.s4hTest(for: .production)
        Router.configure(with: configuration)
        XCTAssertEqual(Router.baseUrl, "https://api.smart4health.eu")
    }

    func testRouteBaseUrlBuildingS4hSandbox() throws {
        let configuration = ClientConfigurationFactory.s4hTest(for: .sandbox)
        Router.configure(with: configuration)
        XCTAssertEqual(Router.baseUrl, "https://api-sandbox.smart4health.eu")
    }
}
