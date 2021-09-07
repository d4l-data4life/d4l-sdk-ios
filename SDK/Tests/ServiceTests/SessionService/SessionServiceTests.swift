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
import Alamofire
import Combine

class SessionServiceTests: XCTestCase {

    private var bundle = Foundation.Bundle.current
    private var encryptedRecordFactory: EncryptedRecordFactory!

    var sessionService: SessionService!
    var versionValidator: SDKVersionValidatorMock!
    var networkReachabilityManager: ReachabilityMock!
    var serverTrustManager: ServerTrustManager!

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        encryptedRecordFactory = try! container.resolve()
        versionValidator = SDKVersionValidatorMock()
        networkReachabilityManager = ReachabilityMock()
        sessionService = SessionService.stubbedSessionService(versionValidator: versionValidator, networkManager: networkReachabilityManager)
        versionValidator.fetchCurrentVersionStatusResult = Just(.supported).asyncFuture()
    }

    func testNetworkUnavailable() {
        let userId = UUID().uuidString
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document)
        let encryptedRecord = encryptedRecordFactory.create(for: record)

        let route = Router.fetchRecord(userId: userId, recordId: record.id)
        stub("GET", "/users/\(userId)/records/\(record.id)", with: encryptedRecord.data)
        let asyncExpectation = self.expectation(description: "No internet connection")
        networkReachabilityManager.isReachableResult = false

        do {
            _ = try sessionService.request(route: route)
            XCTFail("Should throw an error")
        } catch let error as Data4LifeSDKError {
            XCTAssertEqual(error, Data4LifeSDKError.networkUnavailable)
            XCTAssertTrue(networkReachabilityManager.isReachableCalled)
            asyncExpectation.fulfill()
        } catch {
            XCTFail("Should be SDK error type")
        }
        waitForExpectations(timeout: 5)
    }

    func testRequestFailsNoNetwork() {
        let url = URL(string: "https://example.com")!

        networkReachabilityManager.isReachableResult = false
        XCTAssertFalse(networkReachabilityManager.isReachableCalled)

        do {
            _ = try sessionService.request(url: url, method: .get)
            XCTFail("Should throw an error")
        } catch let error as Data4LifeSDKError {
            XCTAssertTrue(networkReachabilityManager.isReachableCalled)
            XCTAssertEqual(error, Data4LifeSDKError.networkUnavailable)
        } catch {
            XCTFail("Should be SDK error type")
        }
    }

    func testUploadFailsNoNetwork() {
        networkReachabilityManager.isReachableResult = false
        XCTAssertFalse(networkReachabilityManager.isReachableCalled)

        do {
            let route = Router.fetchDocument(userId: UUID().uuidString, documentId: UUID().uuidString)
            _ = try sessionService.upload(data: Data([0x00]), route: route)
            XCTFail("Should throw an error")
        } catch let error as Data4LifeSDKError {
            XCTAssertTrue(networkReachabilityManager.isReachableCalled)
            XCTAssertEqual(error, Data4LifeSDKError.networkUnavailable)
        } catch {
            XCTFail("Should be SDK error type")
        }
    }

    func testRequestRouteFailsUnsupportedVersion() {
        networkReachabilityManager.isReachableResult = true
        self.versionValidator.fetchCurrentVersionStatusResult = Just(.unsupported).asyncFuture()
        let expectedError = Data4LifeSDKError.unsupportedVersionRunning

        do {
            let route = Router.fetchRecord(userId: UUID().uuidString, recordId: UUID().uuidString)
            _ = try sessionService.request(route: route)
            XCTFail("Should throw an error")
        } catch let error as Data4LifeSDKError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Should be SDK error type")
        }
    }

    func testRequestURLFailsUnsupportedVersion() {
        networkReachabilityManager.isReachableResult = true
        let env = Environment.staging
        let platform = Platform.D4L
        let baseUrl = URL(string: Router.baseUrlString(from: platform, environment: env))!

        self.versionValidator.fetchCurrentVersionStatusResult = Just(.unsupported).asyncFuture()
        let expectedError = Data4LifeSDKError.unsupportedVersionRunning

        do {
            _ = try sessionService.request(url: baseUrl, method: .get)
            XCTFail("Should throw an error")
        } catch let error as Data4LifeSDKError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Should be SDK error type")
        }
    }

    func testUploadFailsUnsupportedVersion() {
        networkReachabilityManager.isReachableResult = true
        self.versionValidator.fetchCurrentVersionStatusResult = Just(.unsupported).asyncFuture()
        let expectedError = Data4LifeSDKError.unsupportedVersionRunning

        do {
            let route = Router.fetchDocument(userId: UUID().uuidString, documentId: UUID().uuidString)
            _ = try sessionService.upload(data: Data([0x00]), route: route)
            XCTFail("Should throw an error")
        } catch let error as Data4LifeSDKError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Should be SDK error type")
        }
    }

    func testRequestSuccessSSLPinning() {

        let configuration = ClientConfiguration.test(environment: .staging)
        let baseUrlString = Router.baseUrlString(from: configuration.platform,
                                                 environment: configuration.environment)
        let baseUrl = URL(string: baseUrlString)!
        let session = SessionService(versionValidator: versionValidator,
                                     clientConfiguration: configuration,
                                     sdkBundle: bundle)

        let asyncExpectation = expectation(description: "Should return an error")
        do {
            try session.request(url: baseUrl, method: .get)
                .responseData().then(onError: { error in
                    guard case Data4LifeSDKError.network(let sdkError) = error, let afError = sdkError as? AFError else {
                        XCTFail("Wrong error is returned")
                        return
                    }
                    XCTAssertEqual(afError.isResponseValidationError, true)
                    XCTAssertEqual(afError.responseCode, 404)
                }, finally: {
                    asyncExpectation.fulfill()
                })
        } catch {
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 5)
    }

    func testRequestFailsSSLPinning() {
        // development cert is not included in the test bundle so requests will fail
        let configuration = ClientConfiguration.test(environment: .development)
        let baseUrlString = Router.baseUrlString(from: configuration.platform,
                                                 environment: configuration.environment)
        let baseUrl = URL(string: baseUrlString)!
        let session = SessionService(versionValidator: versionValidator,
                                     clientConfiguration: configuration,
                                     sdkBundle: bundle)

        let asyncExpectation = expectation(description: "Should return an error")
        do {
            try session.request(url: baseUrl, method: .get)
                .responseData()
                .then { _ in
                    XCTFail("Should return an error")
                } onError: { error in
                    guard case Data4LifeSDKError.network(let sdkError) = error, let afError = sdkError as? AFError else {
                        XCTFail("Wrong error is returned")
                        return
                    }
                    XCTAssertEqual(afError.isServerTrustEvaluationError, true)
                } finally: {
                    asyncExpectation.fulfill()
                }
        } catch {
            XCTFail(error.localizedDescription)
        }

        waitForExpectations(timeout: 5)
    }
}

private extension ClientConfiguration {
    static func test(platform: Platform = .D4L,
                     environment: Environment = .staging) -> ClientConfiguration {
        ClientConfiguration(clientId: "test"
                            , secret: "test",
                            redirectURLString: "test",
                            environment: environment,
                            platform: platform)
    }
}
