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

    func testCreateResourceWithAnnotations() {
        let annotations = [UUID().uuidString]
        let resource = FhirFactory.createDocumentReferenceResource()
        let record = RecordFactory.create(resource, annotations: annotations)
        fhirService.createFhirRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.createFhirStu3Record(resource, annotations: annotations) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.fhirResource, resource)
            XCTAssertEqual(result.value?.annotations, annotations)
            XCTAssertEqual(self.fhirService.createFhirRecordCalledWith?.0, resource)
            XCTAssertEqual(self.fhirService.createFhirRecordCalledWith?.1, annotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateResource() {
        let annotations = [UUID().uuidString]
        let updateResource = FhirFactory.createDocumentReferenceResource()
        let record = RecordFactory.create(updateResource, annotations: annotations)

        fhirService.updateFhirRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.updateFhirStu3Record(updateResource, annotations: annotations) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.fhirResource, updateResource)
            XCTAssertEqual(result.value?.annotations, annotations)

            XCTAssertEqual(self.fhirService.updateFhirRecordCalledWith?.0, updateResource)
            XCTAssertEqual(self.fhirService.updateFhirRecordCalledWith?.1, annotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchResource() {
        let resource = FhirFactory.createDocumentReferenceResource()
        let resourceId = UUID().uuidString
        resource.id = resourceId
        let record = RecordFactory.create(resource)

        fhirService.fetchRecordWithIdResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.fetchFhirStu3Record(withId: resourceId, of: DocumentReference.self) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.fhirResource, resource)
            XCTAssertEqual(self.fhirService.fetchRecordWithIdCalledWith?.0, resource.id)
        }

        waitForExpectations(timeout: 5)
    }

    func testDeleteResource() {
        let resourceId = UUID().uuidString
        fhirService.deleteRecordResult = Async.resolve()

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.deleteFhirStu3Record(withId: resourceId) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(self.fhirService.deleteRecordCalledWith, resourceId)
        }

        waitForExpectations(timeout: 5)
    }

    func testSearchResources() {
        let annotations = [UUID().uuidString]
        let resources = [FhirFactory.createDocumentReferenceResource(), FhirFactory.createDocumentReferenceResource()]
        let records = resources.map { RecordFactory.create($0, annotations: annotations) }
        fhirService.fetchRecordsResult = Async.resolve(records)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.fetchFhirStu3Records(of: DocumentReference.self, annotations: annotations) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.first?.fhirResource, records.first?.fhirResource)
            XCTAssertEqual(result.value?.last?.fhirResource, records.last?.fhirResource)
            XCTAssertEqual(result.value?.first?.annotations, annotations)
            XCTAssertEqual(result.value?.last?.annotations, annotations)
            XCTAssertEqual(self.fhirService.fetchRecordsCalledWith?.3, annotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testCountResources() {
        let annotations = [UUID().uuidString]
        let resourceCount = 2
        let resourceType = Data4LifeFHIR.DocumentReference.self

        fhirService.countRecordsResult = Async.resolve(resourceCount)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.countFhirStu3Records(of: resourceType, annotations: annotations) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value, resourceCount)
            XCTAssertEqual(self.fhirService.countRecordsCalledWith?.1, annotations)
        }

        waitForExpectations(timeout: 5)
    }
}
