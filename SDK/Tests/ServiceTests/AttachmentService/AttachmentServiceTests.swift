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
import Combine
import Data4LifeFHIR

final class AttachmentServiceTests: XCTestCase {

    private var bundle = Foundation.Bundle.current
    private var documentService: DocumentServiceMock!
    private var imageResizer: ImageResizerMock!
    private var attachmentService: AttachmentService!

    private let testSerialQueue = DispatchQueue(label: "test.serial.queue")
    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        attachmentService = AttachmentService(container: container)

        do {
            self.documentService = try container.resolve(as: DocumentServiceType.self)
            self.imageResizer = try container.resolve(as: ImageResizer.self)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetchAttachment() {
        let parentProgress = Progress()
        let attachment = FhirFactory.createUploadedAttachmentElement()
        let document = FhirFactory.createStu3DocumentReferenceResource(with: [attachment])
        let attachmentKey = KeyFactory.createKey()
        let payload = AttachmentDocument(id: attachment.attachmentId!, data: attachment.attachmentData!)

        documentService.fetchDocumentResult = Just(payload).asyncFuture()

        let asyncExpectation = expectation(description: "should fetch attachment")
        attachmentService.fetchAttachments(for: document,
                                           attachmentIds: [attachment.attachmentId!],
                                           downloadType: .full,
                                           key: attachmentKey,
                                           parentProgress: parentProgress)
            .then { result in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(self.documentService.fetchDocumentCalledWith?.0, attachment.attachmentId!)
                XCTAssertEqual(self.documentService.fetchDocumentCalledWith?.1, attachmentKey)
                XCTAssertEqual(result.first!.attachmentData, attachment.attachmentData)
            }

        waitForExpectations(timeout: 5)
    }

    func testFetchAttachmentWithThumbnailsIds() {
        let partnerId = UUID().uuidString
        Resource.partnerId = partnerId

        let parentProgress = Progress()
        let attachment = FhirFactory.createUploadedAttachmentElement()
        let originalAttachmentId = attachment.attachmentId!
        let resource = FhirFactory.createStu3DocumentReferenceResource(with: [attachment])
        let mediumAddId = "mediumAddId"
        let smallAddId = "smallAddId"
        let additionalId = "d4l_f_p_t#\(originalAttachmentId)#\(mediumAddId)#\(smallAddId)"
        resource.addAdditionalId(additionalId)

        let attachmentKey = KeyFactory.createKey()
        let payload = AttachmentDocument(id: attachment.attachmentId!, data: attachment.attachmentData!)

        documentService.fetchDocumentResult = Just(payload).asyncFuture()

        let asyncExpectation = expectation(description: "should fetch attachment")
        attachmentService.fetchAttachments(for: resource,
                                           attachmentIds: [originalAttachmentId],
                                           downloadType: .small,
                                           key: attachmentKey,
                                           parentProgress: parentProgress)
            .then { result in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(self.documentService.fetchDocumentCalledWith?.0, smallAddId)
                XCTAssertEqual(self.documentService.fetchDocumentCalledWith?.1, attachmentKey)
                let resultedAttachment = result.first!
                XCTAssertEqual(resultedAttachment.attachmentData, attachment.attachmentData)

                let expectedAttachmentId = "\(originalAttachmentId)#\(smallAddId)"
                XCTAssertEqual(resultedAttachment.attachmentId!, expectedAttachmentId)
            }

        waitForExpectations(timeout: 5)
    }

    func testUploadAttachment() {
        let attachment = FhirFactory.createStu3AttachmentElement()
        let document = FhirFactory.createStu3DocumentReferenceResource(with: [attachment])
        let record = DecryptedRecordFactory.create(document)
        let attachmentId = UUID().uuidString
        let payload = AttachmentDocument(id: attachmentId, data: attachment.attachmentData!)

        documentService.createDocumentResult = Just(payload).asyncFuture()

        let asyncExpectation = expectation(description: "should upload data and return document")
        attachmentService.uploadAttachments([attachment],
                                            key: record.attachmentKey!)
            .then { result in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(result.first?.attachment.attachmentId, attachmentId)
                XCTAssertEqual(result.first?.attachment.attachmentDataString, attachment.attachmentDataString)
                XCTAssertEqual(result.first?.thumbnailsIDs, [:])
                XCTAssertEqual(self.documentService.createDocumentCalledWith?.0.data, payload.data)
                XCTAssertEqual(self.documentService.createDocumentCalledWith?.1, record.attachmentKey)
                XCTAssertNil(self.imageResizer.resizedDataCalledWith)
            }

        waitForExpectations(timeout: 5)
    }

    func testUploadAttachmentWithThumbnailsIds() {
        let imageData = bundle.data(forResource: "sample", withExtension: "jpg")!
        let attachment = FhirFactory.createStu3ImageAttachmentElement(imageData: imageData)
        let document = FhirFactory.createStu3DocumentReferenceResource(with: [attachment])
        let attachmentKey = DecryptedRecordFactory.create(document).attachmentKey
        let attachmentId = UUID().uuidString

        imageResizer.isImageDataResult = true
        imageResizer.resizedDataResult = (imageData, nil)
        documentService.createDocumentResult = Just(AttachmentDocument(id: attachmentId, data: imageData)).asyncFuture()

        let expectedThumbnailsIds = [ThumbnailHeight.mediumHeight: attachmentId, .smallHeight: attachmentId]
        let asyncExpectation = expectation(description: "should upload data with thumbnails ids and return document")

        attachmentService.uploadAttachments([attachment], key: attachmentKey!).complete { result in
            switch result {
            case .success(let attachmentDocumentContexts):
                XCTAssertEqual(attachmentDocumentContexts.first?.attachment.attachmentId, attachmentId)
                XCTAssertEqual(attachmentDocumentContexts.first?.attachment.attachmentDataString, attachment.attachmentDataString)
                XCTAssertEqual(attachmentDocumentContexts.first?.thumbnailsIDs, expectedThumbnailsIds)
                XCTAssertEqual(self.documentService.createDocumentCalledWith?.0.data, imageData)
                XCTAssertEqual(self.documentService.createDocumentCalledWith?.1, attachmentKey)
                XCTAssert(self.imageResizer.resizedDataCalledWith?.1 == .smallHeight)
                asyncExpectation.fulfill()
            case .failure(let error):
                XCTFail("Expected value, instead received error: \(error)")
            }
        }

        waitForExpectations(timeout: 10)
    }

    // Test image saved as jpeg with an invalid format as image
    func testUploadAttachmentInvalidImageData() {
        let attachment = FhirFactory.createStu3ImageAttachmentElement()
        let document = FhirFactory.createStu3DocumentReferenceResource(with: [attachment])
        let record = DecryptedRecordFactory.create(document)
        let attachmentId = UUID().uuidString
        let payload = AttachmentDocument(id: attachmentId, data: attachment.attachmentData!)

        documentService.createDocumentResult = Just(payload).asyncFuture()
        imageResizer.isImageDataResult = true

        let asyncExpectation = expectation(description: "should upload data without additional id and return document")
        attachmentService.uploadAttachments([attachment],
                                            key: record.attachmentKey!)
            .then { result in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(result.first?.fullAttachmentId, attachmentId)
                XCTAssertEqual(result.first?.attachment.attachmentDataString, attachment.attachmentDataString)
                XCTAssertEqual(result.first?.thumbnailsIDs, [:])

                XCTAssertEqual(self.documentService.createDocumentCalledWith?.0.data, payload.data)
                XCTAssertEqual(self.documentService.createDocumentCalledWith?.1, record.attachmentKey)
                XCTAssertNil(self.imageResizer.resizedDataCalledWith)
            }

        waitForExpectations(timeout: 5)
    }

    func testUploadAttachmentWithThumbnailsIdsOriginalSmallerThanThumbnails() {
        let imageData = bundle.data(forResource: "sample", withExtension: "jpg")!
        let attachment = FhirFactory.createStu3ImageAttachmentElement(imageData: imageData)
        let document = FhirFactory.createStu3DocumentReferenceResource(with: [attachment])
        let record = DecryptedRecordFactory.create(document)
        let attachmentId = UUID().uuidString

        let payload = AttachmentDocument(id: attachmentId, data: attachment.attachmentData!)
        let expectedThumbnailsIds = [ThumbnailHeight: String]()
        let expectedError = Data4LifeSDKError.resizingImageSmallerThanOriginalOne

        documentService.createDocumentResult = Just(payload).asyncFuture()
        imageResizer.isImageDataResult = true
        imageResizer.resizedDataResults = [ (nil, expectedError),  (nil, expectedError),(nil, expectedError)]

        let asyncExpectation = expectation(description: "should upload data (1 payload - original) for thumbnails and return document")
        attachmentService.uploadAttachments([attachment],
                                            key: record.attachmentKey!)
            .then { result in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(result.first?.attachment.attachmentId, attachmentId)
                XCTAssertEqual(result.first?.attachment.attachmentDataString, attachment.attachmentDataString)
                XCTAssertEqual(result.first?.thumbnailsIDs, expectedThumbnailsIds)

                XCTAssertEqual(self.documentService.createDocumentCalledWith?.0.data, payload.data)
                XCTAssertEqual(self.documentService.createDocumentCalledWith?.1, record.attachmentKey)
                XCTAssert(self.imageResizer.resizedDataCalledWith?.1 == .smallHeight)
            }

        waitForExpectations(timeout: 5)
    }

    func testUploadAttachmentWithThumbnailsIdsOriginalSmallerThanSmallThumbnail() {
        let imageData = bundle.data(forResource: "sample", withExtension: "jpg")!
        let attachment = FhirFactory.createStu3ImageAttachmentElement(imageData: imageData)
        let document = FhirFactory.createStu3DocumentReferenceResource(with: [attachment])
        let record = DecryptedRecordFactory.create(document)
        let attachmentId = UUID().uuidString
        let payload = AttachmentDocument(id: attachmentId, data: attachment.attachmentData!)

        let mediumThumbnailId = UUID().uuidString
        let expectedThumbnailsIds = [ThumbnailHeight.mediumHeight: mediumThumbnailId]
        let thumbnailPayload = AttachmentDocument(id: mediumThumbnailId, data: imageData)
        let expectedError = Data4LifeSDKError.resizingImageSmallerThanOriginalOne

        documentService.createDocumentResults = [payload, thumbnailPayload].map { Just($0).asyncFuture() }
        imageResizer.isImageDataResult = true
        imageResizer.resizedDataResults = [(imageData, nil), (nil, expectedError)]

        let asyncExpectation = expectation(description:
                                            "should upload data (2 payload - original, medium) for thumbnails and return document")
        attachmentService.uploadAttachments([attachment],
                                            key: record.attachmentKey!)
            .then { result in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(result.first?.fullAttachmentId, attachmentId)
                XCTAssertEqual(result.first?.attachment.attachmentDataString, attachment.attachmentDataString)
                XCTAssertEqual(result.first?.thumbnailsIDs, expectedThumbnailsIds)

                XCTAssertEqual(self.documentService.createDocumentCalledWith?.0.data, thumbnailPayload.data)
                XCTAssertEqual(self.documentService.createDocumentCalledWith?.1, record.attachmentKey)
                XCTAssert(self.imageResizer.resizedDataCalledWith?.1 == .smallHeight)
            }

        waitForExpectations(timeout: 5)
    }

    func testUploadAttachmentsFailMissingData() {
        let attachment = FhirFactory.createStu3AttachmentElement()
        attachment.attachmentDataString = nil
        let key = KeyFactory.createKey()

        let expectedError = Data4LifeSDKError.invalidAttachmentMissingData
        let asyncExpectation = expectation(description: "should fail uploading attachment")
        attachmentService.uploadAttachments([attachment],
                                            key: key)
            .then { _ in
                XCTFail("Should fail with error")
            } onError: { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
                XCTAssertNil(self.documentService.createDocumentCalledWith)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testUploadAttachmentsFailInvalidDataPayload() {
        let key = KeyFactory.createKey()
        let attachment = FhirFactory.createStu3AttachmentElement()

        // inject evil exe data to bypass attachment helper validation
        let evilExe = Data([0x4D, 0x5A, 0x00, 0x01, 0x00, 0x00, 0x02])
        attachment.attachmentDataString = evilExe.base64EncodedString()

        let expectedError = Data4LifeSDKError.invalidAttachmentPayloadType
        let asyncExpectation = expectation(description: "should fail uploading attachment")
        attachmentService.uploadAttachments([attachment],
                                            key: key)
            .then { _ in
                XCTFail("Should fail with error")
            } onError: { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
                XCTAssertNil(self.documentService.createDocumentCalledWith)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testFetchAttachmentInvalidPayload() {
        let progress = Progress()
        let attachmentId = UUID().uuidString
        let attachment = FhirFactory.createStu3AttachmentElement()
        attachment.attachmentId = attachmentId

        // inject evil exe data to bypass attachment helper validation
        let evilExe = Data([0x4D, 0x5A, 0x00, 0x01, 0x00, 0x00, 0x02])
        attachment.attachmentDataString = evilExe.base64EncodedString()
        attachment.hash = evilExe.sha1Hash

        let document = FhirFactory.createStu3DocumentReferenceResource(with: [attachment])
        let attachmentKey = KeyFactory.createKey()
        let paylaod = AttachmentDocument(data: attachment.attachmentData!)

        documentService.fetchDocumentResult = Just(paylaod).asyncFuture()

        let expectedError = Data4LifeSDKError.invalidAttachmentPayloadType
        let asyncExpectation = expectation(description: "should throw error invalid payload")
        attachmentService.fetchAttachments(for: document,
                                           attachmentIds: [attachmentId],
                                           downloadType: .full,
                                           key: attachmentKey,
                                           parentProgress: progress)
            .then { _ in
                XCTFail("Should throw an error")
            } onError: { error in
                XCTAssertEqual(self.documentService.fetchDocumentCalledWith?.0, attachmentId)
                XCTAssertEqual(self.documentService.fetchDocumentCalledWith?.1, attachmentKey)
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testFetchAttachmentInvalidSize() {
        let progress = Progress()
        let attachmentId = UUID().uuidString
        let attachment = FhirFactory.createStu3AttachmentElement()
        attachment.attachmentId = attachmentId

        attachment.size = 21 * 1024 * 1024

        let document = FhirFactory.createStu3DocumentReferenceResource(with: [attachment])
        let attachmentKey = KeyFactory.createKey()
        let payload = AttachmentDocument(data: attachment.attachmentData!)

        documentService.fetchDocumentResult = Just(payload).asyncFuture()

        let asyncExpectation = expectation(description: "shoould return an empty array of attachments")
        attachmentService.fetchAttachments(for: document,
                                           attachmentIds: [attachmentId],
                                           downloadType: .full,
                                           key: attachmentKey,
                                           parentProgress: progress)
            .then { _ in
                XCTFail("Should throw an error")
            } onError: { error in
                XCTAssertEqual(error as? Data4LifeSDKError, .invalidAttachmentPayloadSize)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testFetchAttachmentWithInvalidThumbnailsIds() {
        let progress = Progress()
        let partnerId = UUID().uuidString
        Resource.partnerId = partnerId

        let attachment = FhirFactory.createUploadedAttachmentElement()
        let document = FhirFactory.createStu3DocumentReferenceResource(with: [attachment])
        let mediumAddId = "mediumAddId"
        let expectedAdditionalId = "d4l_f_p_t#\(attachment.attachmentId!)#\(mediumAddId)"
        document.addAdditionalId(expectedAdditionalId)

        let attachmentKey = KeyFactory.createKey()

        let expectedError = Data4LifeSDKError.malformedAttachmentAdditionalId
        let asyncExpectation = expectation(description: "should throw error invalid thumbnails format")

        attachmentService.fetchAttachments(for: document,
                                           attachmentIds: [attachment.attachmentId!],
                                           downloadType: .small,
                                           key: attachmentKey,
                                           parentProgress: progress)
            .then { _ in
                XCTFail("Should throw an error")
            } onError: { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testUploadTwoAttachmentsWithSameHash() {

        let imageData = bundle.data(forResource: "sample", withExtension: "jpg")!
        let attachment1 = FhirFactory.createStu3ImageAttachmentElement(imageData: imageData)
        let attachment2 = FhirFactory.createStu3ImageAttachmentElement(imageData: imageData)
        let documentReference = FhirFactory.createStu3DocumentReferenceResource(with: [attachment1, attachment2])
        let attachmentKey = DecryptedRecordFactory.create(documentReference).attachmentKey!

        let attachmentId = UUID().uuidString
        let expectedThumbnailsIds1 = [ThumbnailHeight.mediumHeight: attachmentId,
                                      ThumbnailHeight.smallHeight: attachmentId]

        let expectedThumbnailsIds2 = [ThumbnailHeight.mediumHeight: attachmentId,
                                      ThumbnailHeight.smallHeight: attachmentId]

        documentService.createDocumentResult = Just(AttachmentDocument(id: attachmentId, data: imageData)).asyncFuture()
        imageResizer.isImageDataResult = true
        imageResizer.resizedDataResult = (imageData, nil)

        let asyncExpectation = expectation(description: "should upload data with thumbnails ids and return document")
        attachmentService.uploadAttachments([attachment1, attachment2],
                                            key: attachmentKey)
            .complete ({ result in
                switch result {
                case .success(let result):
                    defer { asyncExpectation.fulfill() }

                    XCTAssertEqual(result.first!.attachment.attachmentId, attachmentId)
                    XCTAssertEqual(result.first!.attachment.attachmentDataString, attachment1.attachmentDataString)
                    XCTAssertEqual(result.first!.thumbnailsIDs, expectedThumbnailsIds1)
                    XCTAssertEqual(result[1].attachment.attachmentId, attachmentId)
                    XCTAssertEqual(result[1].attachment.attachmentDataString, attachment2.attachmentDataString)
                    XCTAssertEqual(result[1].thumbnailsIDs, expectedThumbnailsIds2)

                    XCTAssertEqual(self.documentService.createDocumentCalledWith?.0.data, imageData)
                    XCTAssertEqual(self.documentService.createDocumentCalledWith?.1, attachmentKey)
                    XCTAssert(self.imageResizer.resizedDataCalledWith?.1 == .smallHeight)
                case .failure(let error):
                    XCTFail("Expected value instead got error: \(error)")
                }
            })

        waitForExpectations(timeout: 5)
    }

    func testDownloadWrongHashAttachment() {
        let progress = Progress()
        let attachmentId = UUID().uuidString
        let attachment = FhirFactory.createStu3AttachmentElement()
        attachment.attachmentId = attachmentId

        attachment.hash = UUID().uuidString

        let document = FhirFactory.createStu3DocumentReferenceResource(with: [attachment])
        let attachmentKey = KeyFactory.createKey()
        let paylaod = AttachmentDocument(data: attachment.attachmentData!)

        documentService.fetchDocumentResult = Just(paylaod).asyncFuture()

        let expectedError = Data4LifeSDKError.invalidAttachmentPayloadHash
        let asyncExpectation = expectation(description: "should throw error invalid payload")
        attachmentService.fetchAttachments(for: document,
                                           attachmentIds: [attachmentId],
                                           downloadType: .full,
                                           key: attachmentKey, parentProgress: progress)
            .then { _ in
                XCTFail("Should throw an error")
            } onError: { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }
}