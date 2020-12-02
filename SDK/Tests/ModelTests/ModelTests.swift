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
import Data4LifeFHIR

class ModelTests: XCTestCase {
    func testAllModelVersion() {
        let document = FhirFactory.createDocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document)
        XCTAssertEqual(record.modelVersion, DocumentReference.modelVersion)
        XCTAssertEqual(DocumentReference.modelVersion, FhirStu3Resource.modelVersion)
    }

    func testConvertResourceToFHIRModel() {
        let resource = FhirFactory.createCarePlanResource()

        do {
            _ = try resource.map(to: CarePlan.self)
        } catch {
            XCTFail("Should map DomainResource to CarePlan")
        }
    }

    func testFailConvertingResourceToFHIRModel() {
        let resource = FhirFactory.createCarePlanResource()

        do {
            _ = try resource.map(to: MedicationRequest.self)
            XCTFail("Should throw an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
