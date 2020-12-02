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
    func testCreateResource() {
        let userId = UUID().uuidString
        let fhirResource = FhirFactory.createCarePlanResource()
        let record = DecryptedRecordFactory.create(fhirResource)
        fhirResource.id = record.id

        keychainService[.userId] = userId
        recordService.createRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return a resource")
        fhirService.createFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<CarePlan>.self)
            .then { result in
                XCTAssertNotNil(result)
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, fhirResource)
                XCTAssertEqual(fhirResource, result.fhirResource)
                XCTAssertEqual(result.id, record.id)
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchResource() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let fhirResource = FhirFactory.createCarePlanResource()
        fhirResource.id = resourceId
        let record = DecryptedRecordFactory.create(fhirResource)

        keychainService[.userId] = userId
        recordService.fetchRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return a resource")
        fhirService.fetchFhirRecord(withId: resourceId, decryptedRecordType: DecryptedFhirStu3Record<CarePlan>.self)
            .then { (result: FhirRecord<CarePlan>) in
                XCTAssertNotNil(result)
                XCTAssertEqual(fhirResource, result.fhirResource)
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.0, resourceId)
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.1, userId)
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateResource() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let fhirResource = FhirFactory.createCarePlanResource()
        fhirResource.id = resourceId
        let record = DecryptedRecordFactory.create(fhirResource)
        let updateResource = fhirResource.copy() as! CarePlan // swiftlint:disable:this force_cast
        updateResource.language = UUID().uuidString
        let updatedRecord = record.copy(with: updateResource)

        keychainService[.userId] = userId
        recordService.updateRecordResult = Async.resolve(updatedRecord)

        let asyncExpectation = expectation(description: "should update language property")
        fhirService.updateFhirRecord(updateResource, decryptedRecordType: DecryptedFhirStu3Record<CarePlan>.self)
            .then { result in
                XCTAssertNotNil(result)
                XCTAssertNotEqual(result.fhirResource, fhirResource)
                XCTAssertEqual(result.fhirResource, updateResource)
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0.resource, updateResource)
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testUpdateResourceMissingId() {
        let userId = UUID().uuidString
        let fhirResource = FhirFactory.createCarePlanResource()
        let expectedError = Data4LifeSDKError.invalidResourceMissingId

        keychainService[.userId] = userId

        let asyncExpectation = expectation(description: "should throw an error")
        fhirService.updateFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<CarePlan>.self)
            .then { _ in
                XCTFail("Should throw an error")
            }.onError { error in
                let sdkError = error as? Data4LifeSDKError
                XCTAssertNotNil(sdkError)
                XCTAssertEqual(sdkError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testDeleteResource() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString

        recordService.deleteRecordResult = Async.resolve()
        keychainService[.userId] = userId

        let asyncExpectation = expectation(description: "should return success")
        fhirService.deleteFhirRecord(withId: resourceId)
            .then { _ in
                XCTAssertTrue(self.recordService.deleteRecordCalledWith! == (resourceId, userId))
            }.onError { error in
                XCTAssertNil(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}
