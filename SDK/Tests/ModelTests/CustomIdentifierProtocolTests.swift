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

class CustomIdentifierProtocolTests: XCTestCase {
    func testAddAndRemoveCustomIdentifier() {
        let partnerId = UUID().uuidString
        let customIdentifierValue = UUID().uuidString
        let otherIdentifier = Identifier(identifier: UUID().uuidString, partnerId: UUID().uuidString)

        Resource.partnerId = partnerId
        let resource = FhirFactory.createStu3CarePlanResource()

        resource.identifier = [otherIdentifier]
        XCTAssertNil(resource.getAdditionalIds())

        resource.addAdditionalId(customIdentifierValue)
        guard let ids = resource.getAdditionalIds() else {
            XCTFail("Should have additional ids array")
            return
        }

        XCTAssertEqual(ids.first, customIdentifierValue)
        XCTAssertEqual(ids.count, 1)

        resource.setAdditionalIds([])
        XCTAssertNil(resource.getAdditionalIds())
        XCTAssertEqual(resource.identifier?.first, otherIdentifier)
    }

    func testEncodeAndDecodeCustomIdentifiers() {
        let partnerId = UUID().uuidString
        let firstIdentifierValue = UUID().uuidString
        let secondIdentifierValue = UUID().uuidString

        Resource.partnerId = partnerId
        let resource = FhirFactory.createStu3CarePlanResource()

        resource.setAdditionalIds([firstIdentifierValue, secondIdentifierValue])

        do {
            let jsonData = try JSONEncoder().encode(resource)
            let decodedResource = try JSONDecoder().decode(CarePlan.self, from: jsonData)
            guard let ids = decodedResource.getAdditionalIds() else {
                XCTFail("Should have additional ids array")
                return
            }

            XCTAssertEqual(decodedResource, resource)
            XCTAssertEqual(ids.first, firstIdentifierValue)
            XCTAssertEqual(ids.last, secondIdentifierValue)
            XCTAssertEqual(ids.count, 2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
