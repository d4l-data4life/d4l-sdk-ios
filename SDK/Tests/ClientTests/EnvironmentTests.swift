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

class EnvironmentTests: XCTestCase {
    func testProductionEnv() {
        let envURL = URL(string: "https://api.data4life.care")!
        let env: Environment = .production

        XCTAssertEqual(env.apiBaseURL, envURL)
    }

    func testStagingEnv() {
        let envURL = URL(string: "https://api-staging.data4life.care")!
        let env: Environment = .staging

        XCTAssertEqual(env.apiBaseURL, envURL)
    }

    func testDevelopmentEnv() {
        let envURL = URL(string: "https://api-phdp-dev.hpsgc.de")!
        let env: Environment = .development

        XCTAssertEqual(env.apiBaseURL, envURL)
    }

    func testDevelopmentSandboxEnv() {
        let envURL = URL(string: "https://api-phdp-sandbox.hpsgc.de")!
        let env: Environment = .sandbox

        XCTAssertEqual(env.apiBaseURL, envURL)
    }
}