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
import Then
@testable import Data4LifeSDK
import Data4LifeFHIR

extension Data4LifeClientTests {

    func testCreateAppDataResource() {
        let resource = "test".data(using: .utf8)!
        let annotations = ["test"]
        let record = RecordFactory.create(resource, annotations: annotations)

        appDataService.createAppDataRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.createAppDataRecord(resource, annotations: annotations) { result in
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
        appDataService.createAppDataRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.createAppDataRecord(resource, annotations: annotations) { result in
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
        appDataService.updateAppDataRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.updateAppDataRecord(updateResource, recordId: record.id) { result in
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
        appDataService.updateAppDataRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.updateCodableAppDataRecord(updateResource, recordId: record.id) { result in
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
        appDataService.fetchRecordWithIdResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.fetchAppDataRecord(withId: resourceId) { result in
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
        appDataService.deleteRecordResult = Async.resolve()

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.deleteAppDataRecord(withId: resourceId) { result in
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
        appDataService.fetchRecordsResult = Async.resolve(records)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.fetchAppDataRecords { result in
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
        appDataService.countRecordsResult = Async.resolve(resourceCount)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.countAppDataRecords { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value, resourceCount)

            XCTAssertTrue(self.appDataService.countRecordsCalledWith?.0 == Data.self)
        }

        waitForExpectations(timeout: 5)
    }
}
