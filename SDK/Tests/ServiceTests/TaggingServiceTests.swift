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

class TaggingServiceTests: XCTestCase {
    var taggingService: TaggingService!
    let partnerId = UUID().uuidString
    var clientId: String { return partnerId + "#ios" }

    override func setUp() {
        super.setUp()
        taggingService = TaggingService(clientId: clientId, partnerId: partnerId)
    }

    func testParsingPartnerId() {
        guard let partnerId = clientId.split(separator: "#").first else {
            XCTFail("ClientId should have `#` delimiter")
            return
        }

        XCTAssertEqual(taggingService.partnerId, String(partnerId))
    }

    func testDocumentReferenceTags() {
        let document = FhirFactory.createDocumentReferenceResource()
        var expectedTags = [TaggingService.Keys.resourceType.rawValue: type(of: document).resourceType,
                            TaggingService.Keys.fhirVersion.rawValue: type(of: document).fhirVersion,
                            TaggingService.Keys.client.rawValue: self.clientId,
                            TaggingService.Keys.partner.rawValue: self.taggingService.partnerId]
        let expectedAnnotations = ["ExampleAnnotation1", "ExampleAnnotation2"]
        expectedTags.lowercased()

        let asyncExpectation = expectation(description: "should create tags")
        taggingService.makeTagGroup(for: document, oldTags: [:], annotations: expectedAnnotations)
            .then { tagGroup in
                asyncExpectation.fulfill()
                XCTAssertEqual(tagGroup.tags, expectedTags, "Expected tags doesn't match the saved tags")
                XCTAssertEqual(tagGroup.annotations, expectedAnnotations, "Expected annotations doesn't match the saved annotations")
        }

        waitForExpectations(timeout: 5)
    }

    func testDocumentReferenceTypeTag() {
        let expectedAnnotations = ["exampleAnnotation1"]
        var expectedTags = [TaggingService.Keys.resourceType.rawValue: DocumentReference.resourceType]
        expectedTags.lowercased()

        let asyncExpectation = expectation(description: "should create tags")
        taggingService.makeTagGroup(for: DocumentReference.self, annotations: expectedAnnotations)
            .then { tagGroup in
                asyncExpectation.fulfill()
                XCTAssertEqual(tagGroup.tags, expectedTags, "Expected tags doesn't match the saved tags")
                XCTAssertEqual(tagGroup.annotations, expectedAnnotations, "Expected annotations doesn't match the saved annotations")
        }

        waitForExpectations(timeout: 5)
    }

    func testDocumentReferenceUpdatedByClientTag() {
        let document = FhirFactory.createDocumentReferenceResource()
        let creator = "some-other-client"
        var oldTags = [TaggingService.Keys.resourceType.rawValue: type(of: document).resourceType,
                       TaggingService.Keys.client.rawValue: creator]
        oldTags.lowercased()
        let expectedAnnotations = ["ExampleAnnotation1", "ExampleAnnotation2"]

        let asyncExpectation = expectation(description: "should create updated by client tag")
        taggingService.makeTagGroup(for: document, oldTags: oldTags, annotations: expectedAnnotations)
            .then { tagGroup in
                asyncExpectation.fulfill()
                XCTAssertEqual(tagGroup.tags[TaggingService.Keys.updatedByClient.rawValue.lowercased()], self.clientId.lowercased())
                XCTAssertEqual(tagGroup.tags[TaggingService.Keys.client.rawValue.lowercased()], creator)
                XCTAssertEqual(tagGroup.annotations, expectedAnnotations, "Expected annotations doesn't match the saved annotations")
        }

        waitForExpectations(timeout: 5)
    }

    func testDocumentReferenceUpdatedByPartnerTag() {
        let document = FhirFactory.createDocumentReferenceResource()
        let creator = "some-other-partner"
        var oldTags = [TaggingService.Keys.resourceType.rawValue: type(of: document).resourceType,
                       TaggingService.Keys.partner.rawValue: creator]
        oldTags.lowercased()

        let asyncExpectation = expectation(description: "should create updated by partner tag")
        taggingService.makeTagGroup(for: document, oldTags: oldTags, annotations: nil)
            .then { tagGroup in
                asyncExpectation.fulfill()
                XCTAssertEqual(tagGroup.tags[TaggingService.Keys.updatedByPartner.rawValue.lowercased()], self.taggingService.partnerId.lowercased())
                XCTAssertEqual(tagGroup.tags[TaggingService.Keys.partner.rawValue.lowercased()], creator)
        }

        waitForExpectations(timeout: 5)
    }
}

extension TaggingServiceTests {

    func testAppDataTag() {
        let appData = "test".data(using: .utf8)!
        var expectedTags = [TaggingService.Keys.client.rawValue: self.clientId,
                            TaggingService.Keys.partner.rawValue: self.taggingService.partnerId,
                            TaggingService.Keys.flag.rawValue : TaggingService.FlagKey.appData.rawValue]
        let asyncExpectation = expectation(description: "should create tags")
        expectedTags.lowercased()
        let expectedAnnotations = ["ExampleAnnotation1", "ExampleAnnotation2"]

        taggingService.makeTagGroup(for: appData, annotations: expectedAnnotations)
            .then { tagGroup in
                asyncExpectation.fulfill()
                XCTAssertEqual(tagGroup.tags, expectedTags, "Expected tags doesn't match the saved tags")
                XCTAssertEqual(tagGroup.annotations, expectedAnnotations, "Expected annotations doesn't match the saved annotations")
        }

        waitForExpectations(timeout: 5)
    }

    func testAppDataTypeTag() {
        var expectedTags = [TaggingService.Keys.flag.rawValue : TaggingService.FlagKey.appData.rawValue]
        let asyncExpectation = expectation(description: "should create tags")
        expectedTags.lowercased()
        taggingService.makeTagGroup(for: Data.self)
            .then { tagGroup in
                asyncExpectation.fulfill()
                XCTAssertEqual(tagGroup.tags, expectedTags, "Expected tags doesn't match the saved tags")
        }

        waitForExpectations(timeout: 5)
    }
}
