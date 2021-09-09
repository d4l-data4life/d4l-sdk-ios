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
import Data4LifeFHIR
import Foundation

final class AppDataServiceTests: XCTestCase {

    var recordService: RecordServiceMock<Data,DecryptedAppDataRecord>!
    var keychainService: KeychainServiceMock!
    var cryptoService: CryptoServiceMock!
    var appDataService: AppDataService!
    var attachmentService: AttachmentServiceMock!

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        container.register(scope: .containerInstance) { (_) -> RecordServiceType in
            RecordServiceMock<Data,DecryptedAppDataRecord>()
        }

        appDataService = AppDataService(container: container)

        do {
            recordService = try container.resolve(as: RecordServiceType.self)
            keychainService = try container.resolve(as: KeychainServiceType.self)
            attachmentService = try container.resolve(as: AttachmentServiceType.self)
            cryptoService = try container.resolve(as: CryptoServiceType.self)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSearchResources() {
        let userId = UUID().uuidString
        let appDataResource = "test".data(using: .utf8)!
        let record = DecryptedRecordFactory.create(appDataResource)
        let offset = 1
        let pageSize = 2
        let from = Date()
        let to = Date()

        keychainService[.userId] = userId
        recordService.searchRecordsResult = Just([record]).asyncFuture()

        let asyncExpectation = expectation(description: "should return resources")
        appDataService.fetchAppDataRecords(from: from, to: to, pageSize: pageSize, offset: offset)
            .then { result in
                XCTAssertNotNil(result)
                XCTAssertEqual(result.count, 1)
                XCTAssertNotNil(self.recordService.searchRecordsCalledWith?.0)
                XCTAssertNotNil(self.recordService.searchRecordsCalledWith?.1)
                XCTAssertNotNil(self.recordService.searchRecordsCalledWith?.2)
                XCTAssertNotNil(self.recordService.searchRecordsCalledWith?.3)
        } onError: { error in
            XCTFail(error.localizedDescription)
        } finally: {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCountResources() {
        let userId = UUID().uuidString
        let count = 1

        keychainService[.userId] = userId
        recordService.countRecordsResult = Just(count).asyncFuture()

        let asyncExpectation = expectation(description: "should return count of resources")
        appDataService.countAppDataRecords()
            .then { result in
                XCTAssertEqual(count, result)
                XCTAssertTrue(self.recordService.countRecordsCalledWith?.1 == Data.self)
        } onError: { error in
            XCTFail(error.localizedDescription)
        } finally: {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}