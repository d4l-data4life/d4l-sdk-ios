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
import Combine
@testable import Data4LifeSDK
import Data4LifeFHIR

class Data4LifeClientAppDataTests: XCTestCase {
    var client: Data4LifeClient!

    var sessionService: SessionService!
    var oAuthService: OAuthServiceMock!
    var userService: UserServiceMock!
    var cryptoService: CryptoServiceMock!
    var commonKeyService: CommonKeyServiceMock!
    var fhirService: FhirServiceMock<DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>, Attachment>!
    var appDataService: AppDataServiceMock!
    var keychainService: KeychainServiceMock!
    var recordService: RecordServiceMock<Data4LifeFHIR.DocumentReference,DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>>!
    var environment: Environment!
    var versionValidator: SDKVersionValidatorMock!

    override func setUp() {
        super.setUp()

        environment = .development

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        self.client = Data4LifeClient(container: container,
                                      environment: environment,
                                      platform: .d4l)

        do {
            self.sessionService = try container.resolve()
            self.oAuthService = try container.resolve(as: OAuthServiceType.self)
            self.userService = try container.resolve(as: UserServiceType.self)
            self.cryptoService = try container.resolve(as: CryptoServiceType.self)
            self.commonKeyService = try container.resolve(as: CommonKeyServiceType.self)
            self.fhirService = try container.resolve(as: FhirServiceType.self)
            self.recordService = try container.resolve(as: RecordServiceType.self)
            self.keychainService = try container.resolve(as: KeychainServiceType.self)
            self.versionValidator = try container.resolve(as: SDKVersionValidatorType.self)
            self.appDataService = try container.resolve(as: AppDataServiceType.self)
        } catch {
            XCTFail(error.localizedDescription)
        }

        self.keychainService[.userId] = UUID().uuidString
        fhirService.keychainService = keychainService
        fhirService.recordService = recordService
        fhirService.cryptoService = cryptoService
        appDataService.keychainService = keychainService
        appDataService.recordService = recordService
        appDataService.cryptoService = cryptoService
    }

    override func tearDown() {
        super.tearDown()
        clearStubs()
    }
}

extension Data4LifeClientAppDataTests {

    func testCreateAppDataResource() {
        let resource = "test".data(using: .utf8)!
        let annotations = ["test"]
        let record = RecordFactory.create(resource, annotations: annotations)

        appDataService.createAppDataRecordResult = Just(record).asyncFuture()

        let asyncExpectation = expectation(description: "Should return success result")
        client.createAppDataRecord(resource, annotations: annotations) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.data, resource)
            XCTAssertEqual(result.value?.annotations, annotations)
            XCTAssertEqual(self.appDataService.createAppDataRecordCalledWith.0, resource)
            XCTAssertEqual(self.appDataService.createAppDataRecordCalledWith.1, annotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testCreateAppDataCodableResource() {
        let resource = FhirFactory.createAppDataResourceData()
        let annotations = ["test"]
        let record = RecordFactory.create(resource, annotations: annotations)
        appDataService.createAppDataRecordResult = Just(record).asyncFuture()

        let asyncExpectation = expectation(description: "Should return success result")
        client.createAppDataRecord(resource, annotations: annotations) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.data, resource)
            XCTAssertEqual(result.value?.annotations, annotations)
            XCTAssertEqual(self.appDataService.createAppDataRecordCalledWith.0, resource)
            XCTAssertEqual(self.appDataService.createAppDataRecordCalledWith.1, annotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateAppDataResource() {
        let updateResource = FhirFactory.createAppDataResourceData()
        let record = RecordFactory.create(updateResource)
        appDataService.updateAppDataRecordResult = Just(record).asyncFuture()

        let asyncExpectation = expectation(description: "Should return success result")
        client.updateAppDataRecord(updateResource, recordId: record.id) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.data, updateResource)
            XCTAssertEqual(self.appDataService.updateAppDataRecordCalledWith, updateResource)
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateAppDataCodableResource() {
        let updateResource = FhirFactory.createAppDataResource()
        let updateResourceData = FhirFactory.createAppDataResourceData()
        let record = RecordFactory.create(updateResourceData)
        appDataService.updateAppDataRecordResult = Just(record).asyncFuture()

        let asyncExpectation = expectation(description: "Should return success result")
        client.updateCodableAppDataRecord(updateResource, recordId: record.id) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(try? result.value?.getDecodableResource(of: SomeAppDataResource.self), updateResource)
            XCTAssertEqual(self.appDataService.updateAppDataRecordCalledWith, updateResourceData)
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchAppDataResource() {

        let resource = "test".data(using: .utf8)!
        let record = RecordFactory.create(resource)
        let resourceId = record.id
        appDataService.fetchRecordWithIdResult = Just(record).asyncFuture()

        let asyncExpectation = expectation(description: "Should return success result")
        client.fetchAppDataRecord(withId: resourceId) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.data, resource)
            XCTAssertEqual(self.appDataService.fetchRecordWithIdCalledWith?.0, record.id)
        }

        waitForExpectations(timeout: 5)
    }

    func testDeleteAppDataResource() {
        let resourceId = UUID().uuidString
        appDataService.deleteRecordResult = Just(()).asyncFuture()

        let asyncExpectation = expectation(description: "Should return success result")
        client.deleteAppDataRecord(withId: resourceId) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(self.appDataService.deleteRecordCalledWith, resourceId)
        }

        waitForExpectations(timeout: 5)
    }

    func testSearchAppDataResources() {

        let resources = ["test".data(using: .utf8)!, "test2".data(using: .utf8)!]
        let records = resources.map { RecordFactory.create($0) }
        appDataService.fetchRecordsResult = Just(records).asyncFuture()

        let asyncExpectation = expectation(description: "Should return success result")
        client.fetchAppDataRecords { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.first?.data, records.first?.data)
            XCTAssertEqual(result.value?.last?.data, records.last?.data)
            XCTAssertTrue(self.appDataService.fetchRecordsCalledWith?.0 == DecryptedAppDataRecord.self)
        }

        waitForExpectations(timeout: 5)
    }

    func testCountAppDataResources() {
        let resourceCount = 2
        appDataService.countRecordsResult = Just(resourceCount).asyncFuture()

        let asyncExpectation = expectation(description: "Should return success result")
        client.countAppDataRecords { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value, resourceCount)

            XCTAssertTrue(self.appDataService.countRecordsCalledWith?.0 == Data.self)
        }

        waitForExpectations(timeout: 5)
    }
}
