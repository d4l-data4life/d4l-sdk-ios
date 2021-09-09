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
import Combine
@testable import Data4LifeSDK
import Data4LifeFHIR

extension Data4LifeClientFhirStu3Tests {
    func testDownloadAttachment() {
        let attachmentId = UUID().uuidString
        let recordId = UUID().uuidString
        let attachment = FhirFactory.createStu3AttachmentElement()
        attachment.id = attachmentId

        fhirService.downloadAttachmentResult = Just(attachment).asyncFuture()

        let asyncExpectation = expectation(description: "Should return a attachment")
        client.downloadFhirStu3Attachment(withId: attachmentId, recordId: recordId) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value, attachment)
            XCTAssertEqual(self.fhirService.downloadAttachmentCalledWith?.0, attachmentId)
            XCTAssertEqual(self.fhirService.downloadAttachmentCalledWith?.1, recordId)
        }

        waitForExpectations(timeout: 5)
    }

    func testDownloadAttachments() {
        let firstAttachmentId = UUID().uuidString
        let secondAttachmentId = UUID().uuidString
        let recordId = UUID().uuidString

        let firstAttachment = FhirFactory.createStu3AttachmentElement()
        let secondAttachment = FhirFactory.createStu3AttachmentElement()

        firstAttachment.id = firstAttachmentId
        secondAttachment.id = secondAttachmentId
        fhirService.downloadAttachmentsResult = Just([firstAttachment, secondAttachment]).asyncFuture()

        let ids = [firstAttachmentId, secondAttachmentId]
        let asyncExpectation = expectation(description: "Should return a attachment")
        client.downloadFhirStu3Attachments(withIds: ids, recordId: recordId) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.first, firstAttachment)
            XCTAssertEqual(result.value?.last, secondAttachment)
            XCTAssertEqual(self.fhirService.downloadAttachmentsCalledWith?.0, ids)
            XCTAssertEqual(self.fhirService.downloadAttachmentsCalledWith?.1, recordId)
        }

        waitForExpectations(timeout: 5)
    }
}
