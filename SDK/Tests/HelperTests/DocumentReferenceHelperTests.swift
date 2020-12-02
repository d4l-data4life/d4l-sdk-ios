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
import Data4LifeFHIR
@testable import Data4LifeFHIRProfiles

class DocumentReferenceHelperTests: XCTestCase {

    func testDocumentReferenceWithPractitionerFactory() throws {
        let indexedDate = Instant.now
        let practitioner = Practitioner.with(name: HumanName.with(firstname: "Human", lastname: "Humaoid"))
        let documentReference = try DocumentReference.with(title: "title",
                                                           indexed: indexedDate,
                                                           status: DocumentReferenceStatus.current,
                                                           attachments: [],
                                                           type: CodeableConcept(display: "type"),
                                                           author: practitioner,
                                                           practiceSpeciality: CodeableConcept(display: "practiceSpeciality"))
        XCTAssertEqual(documentReference.getTitle(), "title", "Title is different")
        XCTAssertEqual(documentReference.getIndexedDate(), indexedDate, "Indexed date is different")
        XCTAssertEqual(documentReference.getStatus(), .current, "Status is different")
        XCTAssertEqual(documentReference.getAttachments(), [], "Attachment is different")
        XCTAssertEqual(documentReference.getType(), CodeableConcept(display: "type"), "Type is different")
        XCTAssertEqual(documentReference.getPracticeSpeciality(), CodeableConcept(display: "practiceSpeciality"), "Speciality is different")
        XCTAssertEqual(documentReference.getAuthor(), practitioner, "Author is different")
        XCTAssertEqual(documentReference.getPractitioner(), practitioner, "Practitioner is different")
        XCTAssertEqual(documentReference.getOrganization(), nil, "Organization is set")
    }

    func testDocumentReferenceWithOrganizationFactory() throws {
        let indexedDate = Instant.now
        let organization = Organization.with(type: CodeableConcept(display: "org"), name: "orgname")
        let documentReference = try DocumentReference.with(title: "title",
                                                           indexed: indexedDate,
                                                           status: DocumentReferenceStatus.current,
                                                           attachments: [],
                                                           type: CodeableConcept(display: "type"),
                                                           author: organization,
                                                           practiceSpeciality: CodeableConcept(display: "practiceSpeciality"))
        XCTAssertEqual(documentReference.getTitle(), "title", "Title is different")
        XCTAssertEqual(documentReference.getIndexedDate(), indexedDate, "Indexed date is different")
        XCTAssertEqual(documentReference.getStatus(), .current, "Status is different")
        XCTAssertEqual(documentReference.getAttachments(), [], "Attachment is different")
        XCTAssertEqual(documentReference.getType(), CodeableConcept(display: "type"), "Type is different")
        XCTAssertEqual(documentReference.getPracticeSpeciality(), CodeableConcept(display: "practiceSpeciality"), "Speciality is different")
        XCTAssertEqual(documentReference.getAuthor(), organization, "Author is different")
        XCTAssertEqual(documentReference.getPractitioner(), nil, "Pratictioner is set")
        XCTAssertEqual(documentReference.getOrganization(), organization, "Organization is different")
    }

    func testDocumentReferenceWithInvalidAttachmentFactory() throws {
        let indexedDate = Instant.now
//        let attachment = try Attachment.with(title: "attachment", creationDate: DateTime.now, contentType: "mime", data: Data([0xFF, 0xD8, 0xFF, 0xDB, 0x01, 0x02]))
//        attachment.data_fhir = Data([0xFA, 0xD8, 0xFF, 0xDB, 0x01, 0x02]).base64EncodedString()
        let practitioner = Practitioner.with(name: HumanName.with(firstname: "Human", lastname: "Humaoid"))

        XCTAssertThrowsError(try DocumentReference.with(title: "title",
                                                        indexed: indexedDate,
                                                        status: DocumentReferenceStatus.current,
                                                        attachments: [],
                                                        type: CodeableConcept(display: "type"),
                                                        author: practitioner,
                                                        practiceSpeciality: CodeableConcept(display: "practiceSpeciality")), "Should throw an error") { (error) in
                                                            guard error is FHIRProfileError.Attachment else {
                                                                XCTFail("Throws the wrong error")
                                                                return
                                                            }
        }
    }

    func testDocumentReferenceWithInvalidAttachmentSizeFactory() throws {
        let indexedDate = Instant.now
//        let attachment = try Attachment.with(title: "attachment", creationDate: DateTime.now, contentType: "mime", data: Data([0xFF, 0xD8, 0xFF, 0xDB, 0x01, 0x02]))
//        attachment.size = 25 * 1024 * 1024
        let practitioner = Practitioner.with(name: HumanName.with(firstname: "Human", lastname: "Humaoid"))

        XCTAssertThrowsError(try DocumentReference.with(title: "title",
                                                        indexed: indexedDate,
                                                        status: DocumentReferenceStatus.current,
                                                        attachments: [],
                                                        type: CodeableConcept(display: "type"),
                                                        author: practitioner,
                                                        practiceSpeciality: CodeableConcept(display: "practiceSpeciality")), "Should throw an error") { (error) in
                                                            guard error is FHIRProfileError.Attachment else {
                                                                XCTFail("Throws the wrong error")
                                                                return
                                                            }
        }
    }
}
