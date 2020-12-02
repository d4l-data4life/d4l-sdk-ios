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

class ThumbnailsIdFactoryTests: XCTestCase {
    let splitChar: Character = "#"
    let downscaledAttachmentIdsFormat = "d4l_f_p_t"

    func testCreateAdditionalIdImageAttachment() {
        let attachmentId = UUID().uuidString
        let attachment = FhirFactory.createImageAttachmentElement()
        attachment.id = attachmentId
        let ids = ["addId1", "addId2"]
        let attWidhIds = (attachment, ids)

        let result = ThumbnailsIdFactory.createAdditionalId(from: attWidhIds)

        XCTAssertNotNil(result)

        let finalAdditionalId = "\(downscaledAttachmentIdsFormat)\(splitChar)\(attachmentId)\(splitChar)\(ids[0])\(splitChar)\(ids[1])"
        XCTAssert(result == finalAdditionalId)
    }

    func testCreateAdditionalIdFailsBuildingId() {
        let attachment = FhirFactory.createAttachmentElement()
        attachment.id = UUID().uuidString

        let ids = ["testId"]
        let attWidhIds = (attachment, ids)

        let result = ThumbnailsIdFactory.createAdditionalId(from: attWidhIds)

        XCTAssertNil(result)
    }

    func testSetDocumentIdForDownloadTypeFull() {
        let attachmentId = UUID().uuidString
        let attachment = FhirFactory.createAttachmentElement()
        attachment.id = attachmentId
        let thumbnailsId = ["addId1", "addId2"]
        let additionalId =
        "\(downscaledAttachmentIdsFormat)\(splitChar)\(attachmentId)\(splitChar)\(thumbnailsId[0])\(splitChar)\(thumbnailsId[1])"

        let result = try! ThumbnailsIdFactory.setDocumentId(additionalId: additionalId, for: .full)

        XCTAssert(result == attachmentId)
    }

    func testSetDocumentIddForDownloadTypeMedium() {
        let attachmentId = UUID().uuidString
        let attachment = FhirFactory.createAttachmentElement()
        attachment.id = attachmentId
        let thumbnailsId = ["addId1", "addId2"]
        let additionalId =
        "\(downscaledAttachmentIdsFormat)\(splitChar)\(attachmentId)\(splitChar)\(thumbnailsId[0])\(splitChar)\(thumbnailsId[1])"

        let result = try! ThumbnailsIdFactory.setDocumentId(additionalId: additionalId, for: .medium)

        XCTAssertEqual(result, thumbnailsId[0])
    }

    func testSetDocumentIdForDownloadTypeSmall() {
        let attachmentId = UUID().uuidString
        let attachment = FhirFactory.createAttachmentElement()
        attachment.id = attachmentId
        let thumbnailsId = ["addId1", "addId2"]
        let additionalId =
        "\(downscaledAttachmentIdsFormat)\(splitChar)\(attachmentId)\(splitChar)\(thumbnailsId[0])\(splitChar)\(thumbnailsId[1])"

        let result = try! ThumbnailsIdFactory.setDocumentId(additionalId: additionalId, for: .small)

        XCTAssertEqual(result, thumbnailsId[1])
    }

    func testSetDocumentIdForDownloadInvalidFormatAccordingFormat() {
        let attachmentId = UUID().uuidString
        let attachment = FhirFactory.createAttachmentElement()
        attachment.id = attachmentId
        let thumbnailsId = ["addId1", "addId2"]
        let additionalId = "\(downscaledAttachmentIdsFormat)\(attachmentId)\(splitChar)\(thumbnailsId[0])\(splitChar)\(thumbnailsId[1])"
        let expectedError = Data4LifeSDKError.malformedAttachmentAdditionalId
        do {
            _ = try ThumbnailsIdFactory.setDocumentId(additionalId: additionalId, for: .small)
            XCTFail("Should fail setting the attachment Id")
        } catch let error as Data4LifeSDKError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Should be an SDK error")
        }
    }

    func testSetDocumentIdForDownload3PartAdditionalId() {
        let attachmentId = UUID().uuidString
        let attachment = FhirFactory.createAttachmentElement()
        attachment.id = attachmentId
        let thumbnailsId = ["addId1", "addId2"]
        let additionalId = "\(splitChar)\(attachmentId)\(splitChar)\(thumbnailsId[0])\(splitChar)\(thumbnailsId[1])"

        let result = try! ThumbnailsIdFactory.setDocumentId(additionalId: additionalId, for: .small)

        XCTAssertNil(result)
    }

    func testCleanObsoleteAdditionalIdentifiers() {
        let partnerId = UUID().uuidString
        Resource.partnerId = partnerId

        let fhirResource = FhirFactory.createDocumentReferenceResource()
        let attachment = FhirFactory.createAttachmentElement()
        let attachmentId = UUID().uuidString
        attachment.id = attachmentId
        fhirResource.content = [DocumentReferenceContent(attachment: attachment)]
        let expectedResource = fhirResource.copy() as! DocumentReference // swiftlint:disable:this force_cast

        let additionalIdToUpdate = "d4l_f_p_t#\(attachmentId)#addId1#addId2"
        let additionalIdToRemove = "d4l_f_p_t#\(UUID().uuidString)#addId1#addId2"
        let additionalIdToMaintain = UUID().uuidString

        let expectedAdditionalId = [additionalIdToUpdate, additionalIdToMaintain]
        fhirResource.setAdditionalIds([additionalIdToUpdate, additionalIdToRemove, additionalIdToMaintain])

        expectedResource.setAdditionalIds(expectedAdditionalId)

        let resultResource = try! ThumbnailsIdFactory.cleanObsoleteAdditionalIdentifiers(fhirResource)

        XCTAssertEqual(expectedResource, resultResource)
    }

    func testCleanObsoleteAdditionalIdentifiersInvalidAdditionalIdFormat() {
        //Create resource with identifiers and attachments
        let partnerId = UUID().uuidString
        Resource.partnerId = partnerId

        let fhirResourceId = UUID().uuidString
        let fhirResource = FhirFactory.createDocumentReferenceResource()
        fhirResource.id = fhirResourceId
        let attachment = FhirFactory.createAttachmentElement()
        let attachmentId = UUID().uuidString
        attachment.id = attachmentId
        fhirResource.content = [DocumentReferenceContent()]

        let invalidAdditionalId = ["d4l_f_p_t#\(attachmentId)#addId2"]
        fhirResource.setAdditionalIds(invalidAdditionalId)

        do {
            _ = try ThumbnailsIdFactory.cleanObsoleteAdditionalIdentifiers(fhirResource)
            XCTFail("Should throw an error")
        } catch {
            guard let sdkError = error as? Data4LifeSDKError else { XCTFail("Expecting SDK error"); return }
            XCTAssertEqual(sdkError, Data4LifeSDKError.invalidAttachmentAdditionalId("Resource Id: \(fhirResourceId)"))
        }
    }

    func testDisplayAttachmentId() {
        let id1 = "attachmentId"
        let id2 = "additionalId"

        let result = ThumbnailsIdFactory.displayAttachmentId(id1, for: id2)

        XCTAssertEqual(result, "\(id1)\(splitChar)\(id2)")
    }

    func testDisplayAttachmentIdWithNilAddId() {
        let id1 = "attachmentId"
        let result = ThumbnailsIdFactory.displayAttachmentId(id1, for: nil)

        XCTAssertEqual(result, id1)
    }
}
