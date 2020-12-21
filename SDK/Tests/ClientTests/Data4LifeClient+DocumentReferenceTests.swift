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

    func testCreateDocumentReferenceResource() {
        let resource = FhirFactory.createStu3DocumentReferenceResource()
        let record = RecordFactory.create(resource)

        fhirService.createFhirRecordResult = Promise.resolve(record)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.createFhirStu3Record(resource) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.fhirResource, resource)
            XCTAssertEqual(self.fhirService.createFhirRecordCalledWith?.0, resource)
        }

        waitForExpectations(timeout: 5)
    }

    func testCreateDocumentReferenceResources() {
        let firstResource = FhirFactory.createStu3DocumentReferenceResource()
        let firstRecord = RecordFactory.create(firstResource)

        let secondResource = FhirFactory.createStu3DocumentReferenceResource()
        let secondRecord = RecordFactory.create(secondResource)

        let records = [firstRecord, secondRecord]
        let resources = [firstResource, secondResource]

        fhirService.createFhirRecordsResult = Promise.resolve((records, []))

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.createFhirStu3Records(resources) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.success.first?.fhirResource, firstResource)
            XCTAssertEqual(result.value?.success.last?.fhirResource, secondResource)
            XCTAssertEqual(self.fhirService.createFhirRecordsCalledWith?.0, resources)
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateDocumentReferenceResource() {
        let resourceId = UUID().uuidString
        let updateResource = FhirFactory.createStu3DocumentReferenceResource()
        updateResource.id = resourceId
        let record = RecordFactory.create(updateResource)

        fhirService.updateFhirRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.updateFhirStu3Record(updateResource) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.fhirResource, updateResource)
            XCTAssertEqual(result.value?.fhirResource.id, resourceId)
            XCTAssertEqual(result.value?.id, resourceId)
            XCTAssertEqual(self.fhirService.updateFhirRecordCalledWith?.0, updateResource)
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateDocumentReferenceResources() {
        let firstId = UUID().uuidString
        let firstResource = FhirFactory.createStu3DocumentReferenceResource()
        firstResource.id = firstId
        let firstRecord = RecordFactory.create(firstResource)

        let secondId = UUID().uuidString
        let secondResource = FhirFactory.createStu3DocumentReferenceResource()
        secondResource.id = secondId
        let secondRecord = RecordFactory.create(secondResource)

        let records: [FhirRecord<DocumentReference>] = [firstRecord, secondRecord]
        let resources: [DocumentReference]  = [firstResource, secondResource]

        fhirService.updateFhirRecordsResult = Promise.resolve((records, []))

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.updateFhirStu3Records(resources) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.success.first?.fhirResource, firstResource)
            XCTAssertEqual(result.value?.success.last?.fhirResource, secondResource)
            XCTAssertEqual(result.value?.success.first?.id, firstId)
            XCTAssertEqual(result.value?.success.last?.id, secondId)
            XCTAssertEqual(self.fhirService.updateFhirRecordsCalledWith?.0, resources)
        }

        waitForExpectations(timeout: 5)
    }

    func testDownloadDocumentReferenceResourceSpecifyingType() {

        let resourceId = UUID().uuidString
        let resource = FhirFactory.createStu3DocumentReferenceResource()
        resource.id = resourceId
        let record = RecordFactory.create(resource)
        fhirService.downloadSpecificRecordResult = Promise.resolve(record)

        let asyncExpectation = expectation(description: "Should return success result")
        clientForDocumentReferences.downloadFhirStu3Record(withId: resourceId, of: DocumentReference.self) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            guard let resultedResource = result.value?.fhirResource else {
                XCTFail("Value should be a document reference record")
                return
            }

            XCTAssertEqual(resultedResource, resource)
            XCTAssertEqual(self.fhirService.downloadRecordCalledWith?.0, resource.id)
        }

        waitForExpectations(timeout: 90)
    }
}
