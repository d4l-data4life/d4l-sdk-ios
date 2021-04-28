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
import Data4LifeSDK

class AttachmentHelperTests: XCTestCase {

    func testAttachmentFactorySuccess() throws {
        let creationDate = DateTime.now
        let attachment = try Attachment.with(title: "title",
                                         creationDate: creationDate,
                                         contentType: "mime",
                                         data: Data([0xFF, 0xD8, 0xFF, 0xDB, 0x01, 0x02]))
        XCTAssertEqual(attachment.getTitle(), "title", "Title is different")
        XCTAssertEqual(attachment.getData(),  Data([0xFF, 0xD8, 0xFF, 0xDB, 0x01, 0x02]), "Data is different")
        XCTAssertEqual(attachment.getContentType(), "mime", "Content type is different")
        XCTAssertEqual(attachment.getCreationDate(), creationDate, "Creation date is different")
    }

    func testAttachmentFactoryInvalidPayloadType() throws {
        let creationDate = DateTime.now
        XCTAssertThrowsError(try Attachment.with(title: "title",
                                                 creationDate: creationDate,
                                                 contentType: "mime",
                                                 data: Data(count: 24)), "Should throw invalid payload type error") { (error) in
                                                    guard let error = error as? FHIRProfileError.Attachment else {
                                                        XCTFail("Thrown wrong error")
                                                        return
                                                    }
                                                    XCTAssertEqual(error, FHIRProfileError.Attachment.invalidPayloadType)
        }
    }

    func testAttachmentFactoryInvalidPayloadSize() throws {
        let creationDate = DateTime.now
        var bigData = Data(count: (Limit.maximumForUpload + 1) * 1024 * 1024)
        bigData.insert(contentsOf: [0xFF, 0xD8, 0xFF, 0xDB, 0x01, 0x02], at: 0)
        XCTAssertThrowsError(try Attachment.with(title: "title",
                                                 creationDate: creationDate,
                                                 contentType: "mime",
                                                 data: bigData), "Should throw invalid payload size error") { (error) in
                                                    guard let error = error as? FHIRProfileError.Attachment else {
                                                        XCTFail("Thrown wrong error")
                                                        return
                                                    }
                                                    XCTAssertEqual(error, FHIRProfileError.Attachment.invalidPayloadSize)
        }
    }
}
