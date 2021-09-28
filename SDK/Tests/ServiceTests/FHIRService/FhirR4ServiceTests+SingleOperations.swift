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
import Combine
import ModelsR4

extension FhirR4ServiceTests {
    func testCreateR4Resource() {
        let userId = UUID().uuidString
        let fhirResource = FhirFactory.createR4CarePlanResource()
        let record = DecryptedRecordFactory.create(fhirResource)
        fhirResource.id = record.id.asFHIRStringPrimitive()

        keychainService[.userId] = userId
        recordService.createRecordResult = Just(record).asyncFuture()

        let asyncExpectation = expectation(description: "should return a resource")
        fhirService.createFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirR4Record<ModelsR4.CarePlan>.self)
            .then { result in
                XCTAssertNotNil(result)
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, fhirResource)
                XCTAssertEqual(fhirResource, result.fhirResource)
                XCTAssertEqual(result.id, record.id)
            } onError: { error in
                XCTFail(error.localizedDescription)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testFetchR4Resource() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let fhirResource = FhirFactory.createR4CarePlanResource()
        fhirResource.id = resourceId.asFHIRStringPrimitive()
        let record = DecryptedRecordFactory.create(fhirResource)

        keychainService[.userId] = userId
        recordService.fetchRecordResult = Just(record).asyncFuture()

        let asyncExpectation = expectation(description: "should return a resource")
        fhirService.fetchFhirRecord(withId: resourceId, decryptedRecordType: DecryptedFhirR4Record<ModelsR4.CarePlan>.self)
            .then { (result: FhirRecord<ModelsR4.CarePlan>) in
                XCTAssertNotNil(result)
                XCTAssertEqual(fhirResource, result.fhirResource)
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.0, resourceId)
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.1, userId)
            } onError: { error in
                XCTFail(error.localizedDescription)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testUpdateR4Resource() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let fhirResource = FhirFactory.createR4CarePlanResource()
        fhirResource.id = resourceId.asFHIRStringPrimitive()
        let record = DecryptedRecordFactory.create(fhirResource)
        let updateResource = fhirResource.copy() as! ModelsR4.CarePlan // swiftlint:disable:this force_cast
        updateResource.language = UUID().uuidString.asFHIRStringPrimitive()
        let updatedRecord = record.copy(with: updateResource)

        keychainService[.userId] = userId
        recordService.updateRecordResult = Just(updatedRecord).asyncFuture()

        let asyncExpectation = expectation(description: "should update language property")
        fhirService.updateFhirRecord(updateResource, decryptedRecordType: DecryptedFhirR4Record<ModelsR4.CarePlan>.self)
            .then { result in
                XCTAssertNotNil(result)
                XCTAssertNotEqual(result.fhirResource, fhirResource)
                XCTAssertEqual(result.fhirResource, updateResource)
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0.resource, updateResource)
            } onError: { error in
                XCTFail(error.localizedDescription)
            } finally: {
                asyncExpectation.fulfill()
            }
        waitForExpectations(timeout: 5)
    }

    func testUpdateR4ResourceMissingId() {
        let userId = UUID().uuidString
        let fhirResource = FhirFactory.createR4CarePlanResource()
        let expectedError = Data4LifeSDKError.invalidResourceMissingId

        keychainService[.userId] = userId

        let asyncExpectation = expectation(description: "should throw an error")
        fhirService.updateFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirR4Record<ModelsR4.CarePlan>.self)
            .then { _ in
                XCTFail("Should throw an error")
            } onError: { error in
                let sdkError = error as? Data4LifeSDKError
                XCTAssertNotNil(sdkError)
                XCTAssertEqual(sdkError, expectedError)
            } finally: {
                asyncExpectation.fulfill()
            }
        waitForExpectations(timeout: 5)
    }

    func testDeleteR4Resource() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString

        recordService.deleteRecordResult = Just(()).asyncFuture()
        keychainService[.userId] = userId

        let asyncExpectation = expectation(description: "should return success")
        fhirService.deleteFhirRecord(withId: resourceId)
            .then { _ in
                XCTAssertTrue(self.recordService.deleteRecordCalledWith! == (resourceId, userId))
            } onError: { error in
                XCTAssertNil(error.localizedDescription)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testSearchR4Resources() {
        let userId = UUID().uuidString
        let recordId = UUID().uuidString
        let fhirResource = FhirFactory.createR4CarePlanResource()
        fhirResource.id = recordId.asFHIRStringPrimitive()
        let record = DecryptedRecordFactory.create(fhirResource)
        let query = SearchQueryFactory.create()

        keychainService[.userId] = userId
        recordService.searchRecordsResult = Just([record]).asyncFuture()

        let asyncExpectation = expectation(description: "should return resources")
        fhirService.fetchRecords(decryptedRecordType: DecryptedFhirR4Record<ModelsR4.CarePlan>.self,
                                 recordType: FhirRecord<ModelsR4.CarePlan>.self,
                                 query: query)
            .then { result in
                XCTAssertNotNil(result)
                XCTAssertEqual(result.count, 1)
                XCTAssertEqual(result.first?.id, fhirResource.id?.value?.string)
                XCTAssertNotNil(self.recordService.searchRecordsCalledWith?.0)
                XCTAssertNotNil(self.recordService.searchRecordsCalledWith?.1)
            } onError: { error in
                XCTFail(error.localizedDescription)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testCountR4Resources() {
        let userId = UUID().uuidString
        let count = 1

        keychainService[.userId] = userId
        recordService.countRecordsResult = Just(count).asyncFuture()

        let asyncExpectation = expectation(description: "should return count of resources")
        fhirService.countRecords(of: ModelsR4.CarePlan.self, annotations: [])
            .then { result in
                XCTAssertEqual(count, result)
                XCTAssertTrue(self.recordService.countRecordsCalledWith?.1 == ModelsR4.CarePlan.self)
            } onError: { error in
                XCTFail(error.localizedDescription)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }
}
