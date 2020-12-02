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

extension AppDataServiceTests {
    func testcreateAppDataResourceData() {
        let userId = UUID().uuidString
        let appData = FhirFactory.createAppDataResourceData()
        let record = DecryptedRecordFactory.create(appData)

        keychainService[.userId] = userId
        recordService.createRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return a resource")
        appDataService.createAppDataRecord(appData)
            .then { result in
                XCTAssertNotNil(result)
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, appData)
                XCTAssertEqual(appData, result.data)
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
        let appData = FhirFactory.createAppDataResourceData()
        let record = DecryptedRecordFactory.create(appData)

        keychainService[.userId] = userId
        recordService.fetchRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return a resource")
        appDataService.fetchAppDataRecord(withId: resourceId)
            .then { (result: AppDataRecord) in
                XCTAssertNotNil(result)
                XCTAssertEqual(appData, result.data)
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
        let appData = FhirFactory.createAppDataResourceData()
        var record = DecryptedRecordFactory.create(appData)
        record.id = resourceId

        let oldBaseData = try! JSONDecoder().decode(SomeAppDataResource.self, from: appData)
        var newBaseData = oldBaseData
        newBaseData.subtitle = "modified"
        let newData = try! JSONEncoder().encode(newBaseData)
        let updatedResource = newData
        let updatedRecord = record.copy(with: updatedResource)

        keychainService[.userId] = userId
        recordService.updateRecordResult = Async.resolve(updatedRecord)

        let asyncExpectation = expectation(description: "should update language property")
        appDataService.updateAppDataRecord(updatedResource, recordId: record.id)
            .then { result in
                XCTAssertNotNil(result)
                XCTAssertNotEqual(result.data, appData)
                XCTAssertEqual(result.data, updatedResource)
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0.resource, updatedResource)
        }.onError { error in
            XCTFail(error.localizedDescription)
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
        appDataService.deleteAppDataRecord(withId: resourceId)
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
