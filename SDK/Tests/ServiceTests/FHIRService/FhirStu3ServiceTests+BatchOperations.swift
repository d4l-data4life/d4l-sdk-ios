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
import Then
import Data4LifeFHIR

extension FhirStu3ServiceTests {
    func testCreateResources() {
        let userId = UUID().uuidString
        let resource = FhirFactory.createStu3CarePlanResource()
        let record = DecryptedRecordFactory.create(resource)

        keychainService[.userId] = userId
        recordService.createRecordResult = Promise.resolve(record)

        let asyncExpectation = expectation(description: "should return array with one record")
        fhirService.createFhirRecords([resource], decryptedRecordType: DecryptedFhirStu3Record<CarePlan>.self)
            .then { result in
                XCTAssertNotNil(result)
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, resource)
                XCTAssertEqual(result.success.first?.id, record.id)
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchResources() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let resource = FhirFactory.createStu3CarePlanResource()
        resource.id = resourceId
        let record = DecryptedRecordFactory.create(resource)

        keychainService[.userId] = userId
        recordService.fetchRecordResult = Promise.resolve(record)

        let asyncExpectation = expectation(description: "should return a resource")
        fhirService.fetchFhirRecords(withIds: [resourceId], decryptedRecordType: DecryptedFhirStu3Record<CarePlan>.self)
            .then { (result: BatchResult<FhirRecord<CarePlan>, String>) in
                XCTAssertNotNil(result)
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.0, resourceId)
                XCTAssertEqual(result.success.first?.id, record.id)
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateResources() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let resource = FhirFactory.createStu3CarePlanResource()
        resource.id = resourceId
        let record = DecryptedRecordFactory.create(resource)
        let futureResource = resource.copy() as! CarePlan // swiftlint:disable:this force_cast
        futureResource.language = UUID().uuidString
        let futureRecord = record.copy(with: futureResource)

        keychainService[.userId] = userId
        recordService.updateRecordResult = Promise.resolve(futureRecord)

        let asyncExpectation = expectation(description: "should update language property")
        fhirService.updateFhirRecords([resource], decryptedRecordType: DecryptedFhirStu3Record<CarePlan>.self)
            .then { result in
                XCTAssertNotNil(result)
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0.resource, resource)
                XCTAssertEqual(result.success.first?.id, record.id)
                XCTAssertNotEqual(result.success.first?.fhirResource, resource)
                XCTAssertEqual(result.success.first?.fhirResource, futureResource)
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testDeleteResources() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString

        keychainService[.userId] = userId
        recordService.deleteRecordResult = Promise.resolve()

        let asyncExpectation = expectation(description: "should return success")
        fhirService.deleteFhirRecords(withIds: [resourceId])
            .then { result in
                XCTAssertEqual(self.recordService.deleteRecordCalledWith?.0, resourceId)
                XCTAssertEqual(self.recordService.deleteRecordCalledWith?.1, userId)
                XCTAssertEqual(result.success, [resourceId])
            }.onError { error in
                XCTAssertNil(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}
