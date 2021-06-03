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

import XCTest
@testable import Data4LifeSDK

class SDKVersionValidatorTests: XCTestCase {

    var infoService: InfoServiceMock!
    var bundle: Foundation.Bundle!
    var sdkFileManager: SDKFileManagerMock!
    var validator: SDKVersionValidator!

    var sessionService: SessionService!

    var versionConfigurationSample: Data {
        guard let url = bundle.url(forResource: "VersionConfiguration", withExtension: "json") else {
            fatalError("Wrong URL for the sample config file")
        }
        return try! Data(contentsOf: url)
    }

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        validator = SDKVersionValidator(container: container)

        do {
            infoService = try container.resolve(as: InfoServiceType.self)
            bundle = try container.resolve()
            sdkFileManager = try container.resolve(as: SDKFileManagerType.self)

            sessionService = try container.resolve()
        } catch {
            XCTFail(error.localizedDescription)
        }

        Router.baseUrl = "http://example.com"
    }

    func testFetchCurrentVersionStatusFetchingFileOnline() {
        infoService.fetchSDKVersionResult = "1.5"
        sdkFileManager.readVersionConfigResult = versionConfigurationSample

        let asyncExpectation = expectation(description: "should fetch current version status")
        validator.fetchCurrentVersionStatus().then { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertEqual(result, VersionStatus.supported)
            XCTAssertTrue(self.infoService.fetchSDKVersionCalled, "This method wasn't called")
            XCTAssertTrue(self.sdkFileManager.readVersionConfigCalled, "This method wasn't called with the expected arguments")
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchCurrentVersionStatusReadingFile() {
        infoService.fetchSDKVersionResult = "1.5"
        sdkFileManager.readVersionConfigResult = versionConfigurationSample

        let asyncExpectation = expectation(description: "should fetch current version status")
        validator.fetchCurrentVersionStatus().then { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertEqual(result, VersionStatus.supported)
            XCTAssertTrue(self.infoService.fetchSDKVersionCalled, "This method wasn't called")
            XCTAssertTrue(self.sdkFileManager.readVersionConfigCalled, "This method wasn't called with the expected arguments")
        } onError: { error in
            XCTFail("Should not receive error: \(error.localizedDescription)")
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchCurrentVersionStatusUnknown() {
        infoService.fetchSDKVersionResult = "1.5.0"
        validator.setSessionService(sessionService)

        let asyncExpectation = expectation(description: "should fetch current version status")
        validator.fetchCurrentVersionStatus().then { result in
            XCTAssertEqual(result, VersionStatus.unknown)
            XCTAssertTrue(self.infoService.fetchSDKVersionCalled, "This method wasn't called")
            XCTAssertTrue(self.sdkFileManager.readVersionConfigCalled, "This method wasn't called with the expected arguments")
        } onError: { error in
            XCTFail("Should not receive error: \(error.localizedDescription)")
        } finally: {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchCurrentVersionStatusDeprecatedReadingFile() {
        infoService.fetchSDKVersionResult = "1.0.0"
        sdkFileManager.readVersionConfigResult = versionConfigurationSample

        let asyncExpectation = expectation(description: "should fetch current version status")
        validator.fetchCurrentVersionStatus().then { result in
            XCTAssertEqual(result, VersionStatus.deprecated)
            XCTAssertTrue(self.infoService.fetchSDKVersionCalled, "This method wasn't called")
            XCTAssertTrue(self.sdkFileManager.readVersionConfigCalled, "This method wasn't called with the expected arguments")
        } finally: {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchCurrentVersionStatusUnsupportedReadingFile() {
        infoService.fetchSDKVersionResult = "0.5.0"
        sdkFileManager.readVersionConfigResult = versionConfigurationSample

        let asyncExpectation = expectation(description: "should fetch current version status")
        validator.fetchCurrentVersionStatus().then { result in

            XCTAssertEqual(result, VersionStatus.unsupported)
            XCTAssertTrue(self.infoService.fetchSDKVersionCalled, "This method wasn't called")
            XCTAssertTrue(self.sdkFileManager.readVersionConfigCalled, "This method wasn't called with the expected arguments")
        } finally: {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchVersionConfigurationRemotely() {
        validator.setSessionService(sessionService)
        stub("GET", "/sdk/v1/ios/versions.json", with: versionConfigurationSample)

        let asyncExpectation = expectation(description: "should fetch version config remotely")

        validator.fetchVersionConfigurationRemotely().then { _ in
            XCTAssertNotNil(self.sdkFileManager.saveVersionConfigCalledWith)
        } finally: {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchVersionConfigurationRemotelyFailsInvalidResponse() {
        validator.setSessionService(sessionService)
        stub("GET", "/sdk/v1/ios/versions.json", with: [], code: 404)

        let asyncExpectation = expectation(description: "it should send any error")

        validator.fetchVersionConfigurationRemotely().then { _ in
            XCTFail("Shouldn't return an error")
        } onError: { error in
            XCTAssertNotNil(error is Data4LifeSDKError)
        } finally: {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testSetSessionService() {
        XCTAssertNil(validator.sessionService, "SessionService expected to be nil")
        validator.setSessionService(sessionService)
        XCTAssertNotNil(validator.sessionService, "SessionService expected to be not nil")
    }
}
