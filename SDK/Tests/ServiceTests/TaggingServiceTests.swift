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
import Data4LifeFHIR
import ModelsR4

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

    func testStu3DocumentReferenceTags() {
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let expectedTags = [TaggingService.Keys.resourceType.rawValue: type(of: document).resourceType.lowercased(),
                            TaggingService.Keys.fhirVersion.rawValue: type(of: document).fhirVersion.lowercased(),
                            TaggingService.Keys.client.rawValue: self.clientId.lowercased(),
                            TaggingService.Keys.partner.rawValue: self.taggingService.partnerId.lowercased()]
        let expectedAnnotations = ["exampleannotation1", "exampleannotation2"]

        let tagGroup = taggingService.makeTagGroup(for: document, oldTags: [:], annotations: expectedAnnotations)
        XCTAssertEqual(tagGroup.tags, expectedTags, "Expected tags doesn't match the saved tags")
        XCTAssertEqual(tagGroup.annotations, expectedAnnotations, "Expected annotations doesn't match the saved annotations")
    }

    func testStu3DocumentReferenceTypeTag() {
        let expectedAnnotations = ["exampleAnnotation1"]
        let expectedTags = [TaggingService.Keys.resourceType.rawValue: Data4LifeFHIR.DocumentReference.resourceType.lowercased(),
                            TaggingService.Keys.fhirVersion.rawValue: Data4LifeFHIR.DocumentReference.fhirVersion.lowercased()]

        let tagGroup = taggingService.makeTagGroup(for: Data4LifeFHIR.DocumentReference.self, annotations: expectedAnnotations)

        XCTAssertEqual(tagGroup.tags, expectedTags, "Expected tags doesn't match the saved tags")
        XCTAssertEqual(tagGroup.annotations, expectedAnnotations.map { $0.lowercased() }, "Expected annotations doesn't match the saved annotations")
    }

    func testStu3DocumentReferenceUpdatedByClientTag() {
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let creator = "some-other-client"
        let oldTags = [TaggingService.Keys.resourceType.rawValue: type(of: document).resourceType.lowercased(),
                       TaggingService.Keys.client.rawValue: creator.lowercased()]
        let expectedAnnotations = ["example-annotation1", "example-annotation2"]

        let tagGroup = taggingService.makeTagGroup(for: document, oldTags: oldTags, annotations: expectedAnnotations)

        XCTAssertEqual(tagGroup.tags[TaggingService.Keys.updatedByClient.rawValue.lowercased()], self.clientId.lowercased())
        XCTAssertEqual(tagGroup.tags[TaggingService.Keys.client.rawValue.lowercased()], creator)
        XCTAssertEqual(tagGroup.annotations, expectedAnnotations, "Expected annotations doesn't match the saved annotations")

    }

    func testStu3DocumentReferenceUpdatedByPartnerTag() {
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let creator = "some-other-partner"
        let oldTags = [TaggingService.Keys.resourceType.rawValue: type(of: document).resourceType,
                       TaggingService.Keys.partner.rawValue: creator]
        let tagGroup = taggingService.makeTagGroup(for: document, oldTags: oldTags, annotations: nil)

        XCTAssertEqual(tagGroup.tags[TaggingService.Keys.updatedByPartner.rawValue.lowercased()], self.taggingService.partnerId.lowercased())
        XCTAssertEqual(tagGroup.tags[TaggingService.Keys.partner.rawValue.lowercased()], creator)

    }

    func testStu3DomainResourceTypeTag() {
        let expectedAnnotations = ["example-annotation1"]
        let expectedTags = [TaggingService.Keys.fhirVersion.rawValue: Data4LifeFHIR.DocumentReference.fhirVersion]
        let tagGroup = taggingService.makeTagGroup(for: FhirStu3Resource.self, annotations: expectedAnnotations)
        XCTAssertEqual(tagGroup.tags, expectedTags, "Expected tags doesn't match the saved tags")
        XCTAssertEqual(tagGroup.annotations, expectedAnnotations, "Expected annotations doesn't match the saved annotations")
    }
}

extension TaggingServiceTests {
    func testR4DocumentReferenceTags() {
        let document = FhirFactory.createR4DocumentReferenceResource()
        let expectedTags = [TaggingService.Keys.resourceType.rawValue: ModelsR4.DocumentReference.resourceType.rawValue.lowercased(),
                            TaggingService.Keys.fhirVersion.rawValue: ModelsR4.DocumentReference.fhirVersion.lowercased(),
                            TaggingService.Keys.client.rawValue: self.clientId.lowercased(),
                            TaggingService.Keys.partner.rawValue: self.taggingService.partnerId.lowercased()]
        let exampleAnnotations = ["ExampleAnnotation1", "ExampleAnnotation2"]
        let expectedAnnotations = ["exampleannotation1", "exampleannotation2"]
        let tagGroup = taggingService.makeTagGroup(for: document, oldTags: [:], annotations: exampleAnnotations)

        XCTAssertEqual(tagGroup.tags, expectedTags, "Expected tags doesn't match the saved tags")
        XCTAssertEqual(tagGroup.annotations, expectedAnnotations, "Expected annotations doesn't match the saved annotations")
    }

    func testR4DocumentReferenceTypeTag() {
        let expectedAnnotations = ["exampleAnnotation1"]
        let expectedTags = [TaggingService.Keys.resourceType.rawValue: ModelsR4.DocumentReference.resourceType.rawValue.lowercased(),
                            TaggingService.Keys.fhirVersion.rawValue:  ModelsR4.DocumentReference.fhirVersion.lowercased()]

        let tagGroup = taggingService.makeTagGroup(for: ModelsR4.DocumentReference.self, annotations: expectedAnnotations)
        XCTAssertEqual(tagGroup.tags, expectedTags, "Expected tags doesn't match the saved tags")
        XCTAssertEqual(tagGroup.annotations, expectedAnnotations.map { $0.lowercased() }, "Expected annotations doesn't match the saved annotations")

    }

    func testR4DomainResourceTypeTag() {
        let expectedAnnotations = ["example-annotation1"]
        let expectedTags = [TaggingService.Keys.fhirVersion.rawValue: ModelsR4.DocumentReference.fhirVersion.lowercased()]
        let tagGroup = taggingService.makeTagGroup(for: FhirR4Resource.self, annotations: expectedAnnotations)
        XCTAssertEqual(tagGroup.tags, expectedTags, "Expected tags doesn't match the saved tags")
        XCTAssertEqual(tagGroup.annotations, expectedAnnotations, "Expected annotations doesn't match the saved annotations")
    }
}

extension TaggingServiceTests {

    func testAppDataTag() {
        let appData = "test".data(using: .utf8)!
        let expectedTags = [TaggingService.Keys.client.rawValue: self.clientId.lowercased(),
                            TaggingService.Keys.partner.rawValue: self.taggingService.partnerId.lowercased(),
                            TaggingService.Keys.flag.rawValue : TaggingService.FlagKey.appData.rawValue.lowercased()]
        let expectedAnnotations = ["ExampleAnnotation1", "ExampleAnnotation2"]

        let tagGroup = taggingService.makeTagGroup(for: appData, annotations: expectedAnnotations)

        XCTAssertEqual(tagGroup.tags, expectedTags, "Expected tags doesn't match the saved tags")
        XCTAssertEqual(tagGroup.annotations, expectedAnnotations.map { $0.lowercased() }, "Expected annotations doesn't match the saved annotations")
    }

    func testAppDataTypeTag() {
        let expectedTags = [TaggingService.Keys.flag.rawValue : TaggingService.FlagKey.appData.rawValue.lowercased()]

        let tagGroup = taggingService.makeTagGroup(for: Data.self)
        XCTAssertEqual(tagGroup.tags, expectedTags, "Expected tags doesn't match the saved tags")
    }
}