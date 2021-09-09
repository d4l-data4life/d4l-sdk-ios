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

class DocumentReferenceUseCase: XCTestCase {

    func testAttachmentValidContentSize() {
        do {
            let title = UUID().uuidString
            let contentType = UUID().uuidString
            let byteCount = 10 * 1024 * 1024
            let bytes = [UInt8](repeating: 0x00, count: byteCount - 4)
            let data = Data(bytes)
            let header = Data([0xFF, 0xD8, 0xFF, 0xDB])
            let payload = header + data
            _ = try Attachment.with(title: title, creationDate: .now, contentType: contentType, data: payload)
        } catch {
            XCTFail("Should not throw an error")
        }
    }

    func testAttachmentHelpers() {
        do {
            // Initial values
            let title = UUID().uuidString
            let contentType = UUID().uuidString
            let data = Data([0xFF, 0xD8, 0xFF, 0xDB,  0x00, 0x01])
            let creationDate = DateTime.now

            // Create resource
            let attachment = try! Data4LifeFHIR.Attachment.with(title: title, creationDate: creationDate, contentType: contentType, data: data)

            // Encode & Decode
            let resourceData = try JSONEncoder().encode(attachment)
            let decodedResource = try JSONDecoder().decode(Data4LifeFHIR.Attachment.self, from: resourceData)

            // Assert decoded resources contains initial properties
            XCTAssertEqual(decodedResource.getTitle(), title)
            XCTAssertEqual(decodedResource.getContentType(), contentType)
            XCTAssertEqual(decodedResource.getData(), data)
            XCTAssertEqual(decodedResource.getCreationDate(), creationDate)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAttachmentHelpersIsHashValidValidatingDate() {
        // Initial values
        let title = UUID().uuidString
        let contentType = UUID().uuidString
        let data = Data([0xFF, 0xD8, 0xFF, 0xDB,  0x00, 0x01])
        let creationDate = DateTime(string: "2020-03-13")!

        // Create resource
        let attachment = try! Data4LifeFHIR.Attachment.with(title: title, creationDate: creationDate, contentType: contentType, data: data)
        attachment.hash = "WrongHash"

        XCTAssertEqual(attachment.hashValidity, .unknown, "Attachment hash should be unknown")

        attachment.creation = DateTime(string: "2020-03-15")
        XCTAssertEqual(attachment.hashValidity, .notValid, "Attachment hash should be invalid")

        attachment.hash = attachment.attachmentData!.sha1Hash
        XCTAssertEqual(attachment.hashValidity, .valid, "Attachment hash should be valid")
    }

    func testvalidatePayloadHashDateBeforeValidationDoesntFail() {
        // Initial values
        let title = UUID().uuidString
        let contentType = UUID().uuidString
        let data = Data([0xFF, 0xD8, 0xFF, 0xDB,  0x00, 0x01])
        let creationDate = DateTime(string: "2020-03-13")!

        // Create resource
        let attachment = try! Data4LifeFHIR.Attachment.with(title: title, creationDate: creationDate, contentType: contentType, data: data)
        attachment.hash = "WrongHash"

        do {
            try attachment.validatePayloadHash()
        } catch {
            XCTFail("Should haven't sent an error")
        }
    }
}