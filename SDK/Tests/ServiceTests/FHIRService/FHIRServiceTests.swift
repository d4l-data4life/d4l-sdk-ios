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

final class FhirStu3ServiceTests: XCTestCase {

    var recordService: RecordServiceMock<CarePlan,DecryptedFhirStu3Record<CarePlan>>!
    var keychainService: KeychainServiceMock!
    var cryptoService: CryptoServiceMock!
    var fhirService: FhirService!
    var attachmentService: AttachmentServiceMock<Attachment>!

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        container.register(scope: .containerInstance) { (_) -> RecordServiceType in
            RecordServiceMock<CarePlan,DecryptedFhirStu3Record<CarePlan>>()
        }

        fhirService = FhirService(container: container)

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
        let recordId = UUID().uuidString
        let fhirResource = FhirFactory.createCarePlanResource()
        fhirResource.id = recordId
        let record = DecryptedRecordFactory.create(fhirResource)
        let offset = 1
        let pageSize = 2
        let from = Date()
        let to = Date()

        keychainService[.userId] = userId
        recordService.searchRecordsResult = Async.resolve([record])

        let asyncExpectation = expectation(description: "should return resources")
        fhirService.fetchRecords(of: type(of: fhirResource),
                                 decryptedRecordType: DecryptedFhirStu3Record<CarePlan>.self,
                                 recordType: FhirRecord<CarePlan>.self,
                                 annotations: [],
                                 from: from,
                                 to: to,
                                 pageSize: pageSize,
                                 offset: offset)
            .then { result in
                XCTAssertNotNil(result)
                XCTAssertEqual(result.count, 1)
                XCTAssertEqual(result.first?.id, fhirResource.id)
                XCTAssertNotNil(self.recordService.searchRecordsCalledWith?.0)
                XCTAssertNotNil(self.recordService.searchRecordsCalledWith?.1)
                XCTAssertNotNil(self.recordService.searchRecordsCalledWith?.2)
                XCTAssertNotNil(self.recordService.searchRecordsCalledWith?.3)
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCountResources() {
        let userId = UUID().uuidString
        let count = 1

        keychainService[.userId] = userId
        recordService.countRecordsResult = Async.resolve(count)

        let asyncExpectation = expectation(description: "should return count of resources")
        fhirService.countRecords(of: CarePlan.self, annotations: [])
            .then { result in
                XCTAssertEqual(count, result)
                XCTAssertTrue(self.recordService.countRecordsCalledWith?.1 == CarePlan.self)
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}
