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
import Data4LifeCrypto
import Data4LifeFHIR
import Then

class FhirStu3ServiceDocumentReferenceTests: XCTestCase {

    private var fhirService: FhirService!
    private var recordService: RecordServiceMock<DocumentReference, DecryptedFhirStu3Record<DocumentReference>>!
    private var keychainService: KeychainServiceMock!
    private var cryptoService: CryptoServiceMock!
    private var attachmentService: AttachmentServiceMock!

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        container.register(scope: .containerInstance) { (_) -> RecordServiceType in
            RecordServiceMock<DocumentReference, DecryptedFhirStu3Record<DocumentReference>>()
        }
        fhirService = FhirService(container: container)

        do {
            recordService = try container.resolve(as: RecordServiceType.self)
            keychainService = try container.resolve(as: KeychainServiceType.self)
            attachmentService = try container.resolve(as: AttachmentServiceType.self)
            cryptoService = try container.resolve(as: CryptoServiceType.self)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testCreateDocumentReferenceResource() {

        let userId = UUID().uuidString
        let fixtureDocumentReference = FhirFactory.createStu3DocumentReferenceResource()
        let fixtureAttachment = FhirFactory.createStu3AttachmentElement()
        fixtureDocumentReference.content = [DocumentReferenceContent(attachment: fixtureAttachment)]

        let additionalIds = [String]()

        let expectedDocumentReference = fixtureDocumentReference.copy() as! DocumentReference // swiftlint:disable:this force_cast
        expectedDocumentReference.setAdditionalIds(additionalIds)
        expectedDocumentReference.allAttachments?.forEach { $0.attachmentId = UUID().uuidString }

        //We expect that result of the uploadAttachments method return the uploaded attachments with an Id
        let uploadAttachmentResultWithId = expectedDocumentReference.content!.first!.attachment!.copy() as! Attachment // swiftlint:disable:this force_cast

        expectedDocumentReference.allAttachments?.forEach { $0.attachmentDataString = nil }

        let createdRecord = DecryptedRecordFactory.create(expectedDocumentReference)
        expectedDocumentReference.id = createdRecord.id
        fixtureDocumentReference.id = createdRecord.id

        keychainService[.userId] = userId
        attachmentService.uploadAttachmentsResult = Async.resolve([(uploadAttachmentResultWithId, additionalIds)])
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.createRecordResult = Async.resolve(createdRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(fixtureDocumentReference, decryptedRecordType: DecryptedFhirStu3Record<DocumentReference>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(expectedDocumentReference, result.fhirResource, "The result doesn't match the expected resource")
                XCTAssertEqual(result.id, createdRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "The used attachment key is different from the generated one")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.first?.testable, fixtureAttachment.testable, "The uploaded attachment is different from the expected")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.count, 1, "The size of uploaded attachments doesn't fit the expected size")

                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, fixtureDocumentReference, "The created record differs from the expected resource")
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCreateDocumentReferenceResourceWithSameDataAttachments() {

        let userId = UUID().uuidString
        let documentReference = FhirFactory.createStu3DocumentReferenceResource()
        let attachment = FhirFactory.createStu3AttachmentElement()
        let attachmentWithSameData = FhirFactory.createStu3AttachmentElement()

        XCTAssertEqual(attachment.attachmentDataString, attachmentWithSameData.attachmentDataString)
        XCTAssertNotNil(attachment.attachmentDataString)
        XCTAssertNotEqual(attachment, attachmentWithSameData)

        documentReference.content = [DocumentReferenceContent(attachment: attachment),
                                     DocumentReferenceContent(attachment: attachmentWithSameData)]
        let additionalIds = [String]()

        let expectedDocumentReference = documentReference.copy() as! DocumentReference // swiftlint:disable:this force_cast
        expectedDocumentReference.setAdditionalIds(additionalIds)
        expectedDocumentReference.allAttachments?.forEach { $0.attachmentId = UUID().uuidString }

        //We expect that result of the uploadAttachments method return the uploaded attachments with an Id
        let uploadAttachmentsResultWithId = expectedDocumentReference.allAttachments!.compactMap {
            ($0.copy() as! Attachment) // swiftlint:disable:this force_cast
        }
        //We expect that the parameter of the uploadAttachments method pass the attachments without an Id
        let expectedAttachmentsWithoutId = documentReference.allAttachments!.compactMap {
            ($0.copy() as! Attachment) // swiftlint:disable:this force_cast
        }

        expectedDocumentReference.allAttachments?.forEach { $0.attachmentDataString = nil }

        let createdRecord = DecryptedRecordFactory.create(expectedDocumentReference)
        expectedDocumentReference.id = createdRecord.id
        documentReference.id = createdRecord.id

        keychainService[.userId] = userId
        attachmentService.uploadAttachmentsResult = Async.resolve(uploadAttachmentsResultWithId.map { ($0, additionalIds)})
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.createRecordResult = Async.resolve(createdRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(documentReference, decryptedRecordType: DecryptedFhirStu3Record<DocumentReference>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(expectedDocumentReference, result.fhirResource, "The result doesn't match the expected resource")
                XCTAssertEqual(result.id, createdRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "The used attachment key is different from the generated one")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.map { $0.testable },
                               expectedAttachmentsWithoutId.map { $0.testable}, "The uploaded attachments are different from the expected")
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, documentReference, "The created record differs from the expected resource")
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCreateDocumentReferenceResourceWithoutAttachments() {
        let userId = UUID().uuidString
        let fhirResource = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(fhirResource)
        fhirResource.id = record.id

        keychainService[.userId] = userId
        recordService.createRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<DocumentReference>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(fhirResource, result.fhirResource, "The result doesn't match the expected resource")
                XCTAssertEqual(result.id, record.id, "The result id is different from the record id")
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, fhirResource, "The created record differs from the expected resource")

                XCTAssertNil(self.cryptoService.generateGCKeyCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCreateDocumentReferenceResourceFailInvalidContentSize() {
        let userId = UUID().uuidString
        let fhirResource = FhirFactory.createStu3DocumentReferenceResource()
        let attachment = FhirFactory.createStu3AttachmentElement()
        let blankData = [UInt8](repeating: 0x00, count: 21 * 1024 * 1024) // 21mb
        guard let currentData = attachment.attachmentData else { fatalError("Attachment should have data") }
        attachment.attachmentDataString = (currentData + blankData).base64EncodedString()
        fhirResource.content = [DocumentReferenceContent(attachment: attachment)]
        let record = DecryptedRecordFactory.create(fhirResource)

        keychainService[.userId] = userId
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.createRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<DocumentReference>.self)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.cryptoService.generateGCKeyCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.recordService.createRecordCalledWith, "This method shouldn't have been called")
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.invalidAttachmentPayloadSize, "Expected error didn't occur")
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCreateDocumentReferenceResourceFailInvalidContentType() {
        let userId = UUID().uuidString
        let fhirResource = FhirFactory.createStu3DocumentReferenceResource()
        let attachment = FhirFactory.createStu3AttachmentElement()
        attachment.attachmentDataString = Data([0x00]).base64EncodedString()
        fhirResource.content = [DocumentReferenceContent(attachment: attachment)]

        keychainService[.userId] = userId
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<DocumentReference>.self)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertNil(self.cryptoService.generateGCKeyCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.recordService.createRecordCalledWith, "This method shouldn't have been called")
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.invalidAttachmentPayloadType, "Expected error didn't occur")
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateDocumentReferenceResource() {

        let userId = UUID().uuidString
        let resourceId = UUID().uuidString

        let documentReference = FhirFactory.createStu3DocumentReferenceResource()
        let attachment = FhirFactory.createStu3AttachmentElement()
        documentReference.id = resourceId
        documentReference.content = [DocumentReferenceContent(attachment: attachment)]
        let additionalIds = [String]()
        let originalRecord = DecryptedRecordFactory.create(documentReference)

        let updatedDocumentReference = documentReference.copy() as! DocumentReference // swiftlint:disable:this force_cast

        let expectedDocumentReference = updatedDocumentReference.copy() as! DocumentReference // swiftlint:disable:this force_cast
        let newAttachmentId = UUID().uuidString
        let attachmentWithId = attachment.copyWithId(newAttachmentId)
        expectedDocumentReference.content = [DocumentReferenceContent(attachment: attachmentWithId)]
        expectedDocumentReference.content?.forEach { $0.attachment?.attachmentDataString = nil }
        let expectedUpdatedRecord = originalRecord.copy(with: expectedDocumentReference)

        keychainService[.userId] = userId
        attachmentService.uploadAttachmentsResult = Async.resolve([(attachmentWithId, additionalIds)])
        recordService.fetchRecordResult = Async.resolve(originalRecord)
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.updateRecordResult = Async.resolve(expectedUpdatedRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(documentReference, decryptedRecordType: DecryptedFhirStu3Record<DocumentReference>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(result.fhirResource, expectedDocumentReference, "The result doesn't match the expected resource")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0.resource, documentReference, "The updated record differs from the expected resource")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.2, userId, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.3, resourceId, "A param in the method doesn't match the expectation")
                XCTAssertNotNil(self.recordService.updateRecordCalledWith?.4, "A param in the method doesn't match the expectation")

                XCTAssertNil(result.fhirResource.allAttachments?.first?.attachmentDataString, "Data in the attachment is expected to be nil")

                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.first?.testable, attachment.testable, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.0, resourceId, "A param in the method doesn't match the expectation")
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testFailUpdateDocumentReferenceResourceMissingId() {
        let userId = UUID().uuidString
        let fhirResource = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(fhirResource)
        fhirResource.id = nil
        keychainService[.userId] = userId
        recordService.updateRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return an error")
        fhirService.updateFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<DocumentReference>.self)
            .then { _ in
                XCTFail("Should throw an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.invalidResourceMissingId, "Expected error didn't happen")
            }.finally {
                asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testFailUpdateDocumentReferenceInvalidContentType() {
        let userId = UUID().uuidString
        let fhirResource = FhirFactory.createStu3DocumentReferenceResource()
        let attachment = FhirFactory.createStu3AttachmentElement()
        attachment.attachmentDataString = Data([0x00]).base64EncodedString()
        fhirResource.content = [DocumentReferenceContent(attachment: attachment)]
        let record = DecryptedRecordFactory.create(fhirResource)
        fhirResource.id = record.id

        keychainService[.userId] = userId
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.fetchRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<DocumentReference>.self)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.recordService.createRecordCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.recordService.updateRecordCalledWith, "This method shouldn't have been called")
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.invalidAttachmentPayloadType, "Expected error didn't happen")
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFailUpdateDocumentReferenceInvalidContentSize() {
        let userId = UUID().uuidString
        let fhirResource = FhirFactory.createStu3DocumentReferenceResource()
        let attachment = FhirFactory.createStu3AttachmentElement()
        let blankData = [UInt8](repeating: 0x00, count: 21 * 1024 * 1024) // 21mb
        guard let currentData = attachment.attachmentData else { fatalError("Attachment should have data") }
        attachment.attachmentDataString = (currentData + blankData).base64EncodedString()
        fhirResource.content = [DocumentReferenceContent(attachment: attachment)]
        let record = DecryptedRecordFactory.create(fhirResource)
        fhirResource.id = record.id

        keychainService[.userId] = userId
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.fetchRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<DocumentReference>.self)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.recordService.createRecordCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.recordService.updateRecordCalledWith, "This method shouldn't have been called")
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.invalidAttachmentPayloadSize, "Expected error didn't happen")
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateDocumentReferenceExistingAttachment() {

        let userId = UUID().uuidString
        let resourceId = UUID().uuidString

        let attachment1 = FhirFactory.createStu3AttachmentElement()
        let attachment1Id = UUID().uuidString
        attachment1.id = attachment1Id

        let attachment2 = FhirFactory.createStu3AttachmentElement()
        attachment2.id = UUID().uuidString
        attachment2.attachmentDataString = nil

        let documentReference = FhirFactory.createStu3DocumentReferenceResource(with: [attachment1, attachment2])
        documentReference.id = resourceId

        let originalRecord = DecryptedRecordFactory.create(documentReference)

        let additionalIds = [String]()
        let updatedDocumentReference = documentReference.copy() as! DocumentReference // swiftlint:disable:this force_cast
        let newData = Data([0xFF, 0xD8, 0xFF, 0xDB, 0x01, 0x03, 0x03, 0x07, 0x01, 0x03, 0x03, 0x07])
        let updatedAttachment1 = updatedDocumentReference.allAttachments!.first! as! Attachment // swiftlint:disable:this force_cast
        updatedAttachment1.attachmentDataString = newData.base64EncodedString()
        updatedAttachment1.attachmentHash = newData.sha1Hash
        updatedAttachment1.attachmentSize = newData.byteCount

        let unmodifiedAttachment2 = updatedDocumentReference.content!.last!.attachment!

        let newAttachment = FhirFactory.createStu3AttachmentElement()
        let creationDate = DateTime.now
        newAttachment.creation = creationDate
        updatedDocumentReference.content = [DocumentReferenceContent(attachment: updatedAttachment1),
                                            DocumentReferenceContent(attachment: unmodifiedAttachment2),
                                            DocumentReferenceContent(attachment: newAttachment)]

        let uploadedNewAttachment = newAttachment.copyWithId(UUID().uuidString)
        let expectedUpdatedDocumentReference = updatedDocumentReference.copy() as! DocumentReference // swiftlint:disable:this force_cast
        expectedUpdatedDocumentReference.content = [DocumentReferenceContent(attachment: updatedAttachment1),
                                                    DocumentReferenceContent(attachment: unmodifiedAttachment2),
                                                    DocumentReferenceContent(attachment: uploadedNewAttachment)]
        let expectedUpdatedRecord = originalRecord.copy(with: expectedUpdatedDocumentReference)

        keychainService[.userId] = userId
        recordService.fetchRecordResult = Async.resolve(originalRecord)
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.updateRecordResult = Async.resolve(expectedUpdatedRecord)
        attachmentService.uploadAttachmentsResults = [Async.resolve([(updatedAttachment1, additionalIds),
                                                                     (uploadedNewAttachment, additionalIds)])]

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(updatedDocumentReference, decryptedRecordType: DecryptedFhirStu3Record<DocumentReference>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0.resource, updatedDocumentReference, "The result doesn't match the expected resource")
                let atts = self.attachmentService.uploadAttachmentsCalledWith!.0
                let newDataAtt = atts.first(where: { $0.attachmentId == attachment1Id })
                let newAtt = atts.first(where: { $0.creationDate == creationDate.nsDate })

                XCTAssertEqual(newDataAtt?.attachmentHash, newData.sha1Hash, "The attachment hash don't mach the expected one")
                XCTAssertEqual(newDataAtt?.attachmentSize, newData.count, "The size of attachment doesn't match the expected one")
                XCTAssertNotNil(newAtt, "The attachment shouldn't be nil")

                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.0, resourceId, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.1, userId, "A param in the method doesn't match the expectation")

        }.onError { error in
            XCTFail(error.localizedDescription)
        }.finally {
            asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testUpdateDocumentReferenceAttachmentWrongAttachmentHash() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let attachmentId = UUID().uuidString
        let fhirResource = FhirFactory.createStu3DocumentReferenceResource()
        let attachment = FhirFactory.createStu3AttachmentElement()
        let attachment2 = FhirFactory.createStu3AttachmentElement()
        attachment2.id = UUID().uuidString
        attachment2.attachmentDataString = nil
        fhirResource.id = resourceId
        attachment.attachmentId = attachmentId
        fhirResource.content = [DocumentReferenceContent(attachment: attachment), DocumentReferenceContent(attachment: attachment2)]
        let record = DecryptedRecordFactory.create(fhirResource)

        let additionalIds = [String]()

        let updatedResource = fhirResource.copy() as! DocumentReference // swiftlint:disable:this force_cast
        let newData = Data([0xFF, 0xD8, 0xFF, 0xDB, 0x01, 0x03, 0x03, 0x07, 0x01, 0x03, 0x03, 0x07])
        let updatedAttachment = updatedResource.allAttachments!.first! as! Attachment // swiftlint:disable:this force_cast
        updatedAttachment.attachmentDataString = newData.base64EncodedString()
        let newAttachment = FhirFactory.createStu3AttachmentElement()
        newAttachment.hash = "brokenHash"
        let newAttachmentWithId = FhirFactory.createStu3AttachmentElement()
        let language = UUID().uuidString
        newAttachmentWithId.language = language
        let noneExistingId = UUID().uuidString
        newAttachmentWithId.id = noneExistingId
        updatedResource.content = [DocumentReferenceContent(attachment: updatedAttachment),
                                   updatedResource.content!.last!,
                                   DocumentReferenceContent(attachment: newAttachment),
                                   DocumentReferenceContent(attachment: newAttachmentWithId)]

        let updatedRecord = record.copy(with: updatedResource)
        keychainService[.userId] = userId
        recordService.fetchRecordResult = Async.resolve(record)
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.updateRecordResult = Async.resolve(updatedRecord)
        attachmentService.uploadAttachmentsResults = [Async.resolve([(updatedAttachment, additionalIds)]),
                                                      Async.resolve([(newAttachment, additionalIds)]),
                                                      Async.resolve([(newAttachmentWithId, additionalIds)])]

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(updatedResource, decryptedRecordType: DecryptedFhirStu3Record<DocumentReference>.self)
            .then { _ in
                XCTFail("Error expected")
        }.onError { error in
            XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.invalidAttachmentPayloadHash, "Expected error didn't occur")
            XCTAssertNil(self.recordService.updateRecordCalledWith, "This method shouldn't have been called")
        }.finally {
            asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
}

// MARK: - Image Attachment tests
extension FhirStu3ServiceDocumentReferenceTests {
    func testCreateDocumentReferenceResourceWithAdditionalIds() {
        let partnerId = UUID().uuidString
        Resource.partnerId = partnerId

        let userId = UUID().uuidString
        let fixtureDocumentReference = FhirFactory.createStu3DocumentReferenceResource()
        let fixtureAttachment = FhirFactory.createStu3AttachmentElement()
        let attachmentId = UUID().uuidString
        fixtureAttachment.attachmentId = attachmentId
        fixtureDocumentReference.content = [DocumentReferenceContent(attachment: fixtureAttachment)]

        let additionalPayloadsIds = ["addId1", "addId2"]
        let expectedAdditionalId = ["d4l_f_p_t#\(attachmentId)#\(additionalPayloadsIds[0])#\(additionalPayloadsIds[1])"]

        let expectedDocumentReference = fixtureDocumentReference.copy() as! DocumentReference // swiftlint:disable:this force_cast
        expectedDocumentReference.setAdditionalIds(expectedAdditionalId)
        expectedDocumentReference.allAttachments?.forEach { $0.attachmentDataString = nil }

        let createdRecord = DecryptedRecordFactory.create(expectedDocumentReference)
        expectedDocumentReference.id = createdRecord.id
        fixtureDocumentReference.id = createdRecord.id

        keychainService[.userId] = userId
        recordService.createRecordResult = Async.resolve(createdRecord)
        attachmentService.uploadAttachmentsResult = Async.resolve([(fixtureAttachment, additionalPayloadsIds)])
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)

        let asyncExpectation = expectation(description: "should return record with additional id")
        fhirService.createFhirRecord(fixtureDocumentReference, decryptedRecordType: DecryptedFhirStu3Record<DocumentReference>.self)
            .then { result in
                XCTAssertNotNil(result, "The result should be not nil")
                XCTAssertEqual(expectedDocumentReference, result.fhirResource, "The expected resource doesn't match the result of the test")
                XCTAssertEqual(result.id, createdRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "The used attachment key is different from the generated one")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.first?.testable, fixtureAttachment.testable,
                               "The uploaded attachment is different from the expected")
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, expectedDocumentReference, "The created record differs from the expected resource")
                XCTAssertEqual(result.fhirResource.identifier!, expectedDocumentReference.identifier,  "The identifiers of the result differ from the expected resource exist")
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCreateDocumentReferenceResourceWithoutThumbnailsIds() {

        let userId = UUID().uuidString

        let fixtureDocumentReference = FhirFactory.createStu3DocumentReferenceResource()
        let fixtureAttachment = FhirFactory.createStu3AttachmentElement()
        fixtureDocumentReference.content = [DocumentReferenceContent(attachment: fixtureAttachment)]

        let additionalIds = ["addId1"]
        let expectedAdditionalIds = [String]()

        let attachmentId = UUID().uuidString
        let expectedAttachment = fixtureAttachment.copyWithId(attachmentId)
        let expectedDocumentReference = fixtureDocumentReference.copy() as! DocumentReference // swiftlint:disable:this force_cast
        expectedDocumentReference.setAdditionalIds(expectedAdditionalIds)
        expectedDocumentReference.content?.first?.attachment?.id = attachmentId
        let createdRecord = DecryptedRecordFactory.create(expectedDocumentReference)
        expectedDocumentReference.id = createdRecord.id
        fixtureDocumentReference.id = createdRecord.id

        keychainService[.userId] = userId
        recordService.createRecordResult = Async.resolve(createdRecord)
        attachmentService.uploadAttachmentsResult = Async.resolve([(expectedAttachment, additionalIds)])
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(fixtureDocumentReference, decryptedRecordType: DecryptedFhirStu3Record<DocumentReference>.self)
            .then { result in
                XCTAssertNotNil(result, "The result should be not nil")
                XCTAssertEqual(expectedDocumentReference, result.fhirResource, "The expected resource doesn't match the result of the test")
                XCTAssertEqual(result.id, createdRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "The used attachment key is different from the generated one")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.first?.testable, fixtureAttachment.testable, "The uploaded attachment is different from the expected")
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, fixtureDocumentReference, "The created record differs from the expected resource")
                XCTAssertEqual(result.fhirResource.identifier!, expectedDocumentReference.identifier, "The identifiers of the result differ from the expected resource exist")
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}

extension FhirStu3ServiceAttachmentOperationsTests {
    func testDownloadDocumentReferenceResource() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let attachmentId = UUID().uuidString
        let fhirResource = FhirFactory.createStu3DocumentReferenceResource()
        let attachment = FhirFactory.createStu3AttachmentElement()
        attachment.id = attachmentId

        fhirResource.id = resourceId
        fhirResource.content = [DocumentReferenceContent(attachment: attachment)]
        let record = DecryptedRecordFactory.create(fhirResource as FhirStu3Resource)

        keychainService[.userId] = userId
        recordService.fetchRecordResult = Async.resolve(record)
        attachmentService.fetchAttachmentsResult = Async.resolve([attachment])

        let asyncExpectation = expectation(description: "should return a record")
        fhirService.downloadFhirRecordWithAttachments(withId: resourceId, decryptedRecordType: DecryptedFhirStu3Record<FhirStu3Resource>.self)
            .then { result in
                XCTAssertNotNil(result, "The result should be not nil")
                XCTAssertEqual(fhirResource, result.fhirResource, "The expected resource doesn't match the result of the test")
                XCTAssertEqual((result.fhirResource as? HasAttachments)?.allAttachments?.first as? Attachment, attachment, "The resource's attachment doesn't match the result of expected one")
                XCTAssertEqual((result.fhirResource as? DocumentReference)?.content?.first?.attachment, attachment, "The resource's attachment doesn't match the result of expected one")
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.0, resourceId, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.1, userId, "A param in the method doesn't match the expectation")
                XCTAssertNotNil(self.attachmentService.fetchAttachmentsCalledWith?.0.allAttachments, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.attachmentService.fetchAttachmentsCalledWith?.0.allAttachments as? [Attachment],
                               fhirResource.allAttachments as? [Attachment],
                               "A param in the method doesn't match the expectation")
                XCTAssertEqual((self.attachmentService.fetchAttachmentsCalledWith?.0 as? CustomIdentifierProtocol)?.customIdentifiers as? [Identifier],
                               fhirResource.identifier, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.attachmentService.fetchAttachmentsCalledWith?.1,
                               [attachmentId], "A param in the method doesn't match the expectation")
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testDownloadDocumentReferenceResourceWithoutAttachments() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let fhirResource = FhirFactory.createStu3DocumentReferenceResource()
        fhirResource.id = resourceId
        var record = DecryptedRecordFactory.create(fhirResource as FhirStu3Resource)
        record.attachmentKey = nil

        keychainService[.userId] = userId
        recordService.fetchRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return a record")
        fhirService.downloadFhirRecordWithAttachments(withId: resourceId, decryptedRecordType: DecryptedFhirStu3Record<FhirStu3Resource>.self)
            .then { result in
                XCTAssertNotNil(result, "The result should be not nil")
                XCTAssertEqual(fhirResource, result.fhirResource, "The expected resource doesn't match the result of the test")
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.0, resourceId, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.1, userId, "A param in the method doesn't match the expectation")
                XCTAssertNil(self.attachmentService.fetchAttachmentsCalledWith, "A param in the method doesn't match the expectation")
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testDownloadDocumentReferenceResources() {
        let userId = UUID().uuidString
        let progress = Progress()

        let firstAttachmentId = UUID().uuidString
        let firstAttachment = FhirFactory.createStu3AttachmentElement()
        firstAttachment.id = firstAttachmentId

        let firstResourceId = UUID().uuidString
        let firstResource = FhirFactory.createStu3DocumentReferenceResource(with: [firstAttachment])
        firstResource.id = firstResourceId
        let firstRecord = DecryptedRecordFactory.create(firstResource as FhirStu3Resource)

        let secondAttachmentId = UUID().uuidString
        let secondAttachment = FhirFactory.createStu3AttachmentElement()
        secondAttachment.attachmentId = secondAttachmentId

        let secondResourceId = UUID().uuidString
        let secondResource = FhirFactory.createStu3DocumentReferenceResource(with: [secondAttachment])
        secondResource.id = secondResourceId

        keychainService[.userId] = userId
        recordService.fetchRecordResults = [Async.resolve(firstRecord)]
        attachmentService.fetchAttachmentsResult = Async.resolve([firstAttachment])

        let asyncExpectation = expectation(description: "should return a record")
        fhirService.downloadFhirRecordsWithAttachments(withIds: [firstResourceId, secondResourceId], decryptedRecordType: DecryptedFhirStu3Record<FhirStu3Resource>.self, parentProgress: progress)
            .then { result in
                XCTAssertNotNil(result, "The result should be not nil")
                XCTAssertEqual(result.success.first?.fhirResource, firstResource, "The expected resource doesn't match the result of the test")
                XCTAssertNotNil(result.failed.first, "Expected result to be not nil")
                XCTAssertEqual((result.success.first?.fhirResource as? DocumentReference)?.content?.first?.attachment, firstAttachment, "The expected attachment doesn't match the expected one")
                XCTAssertEqual((result.success.first?.fhirResource as? HasAttachments)?.allAttachments?.first as? Attachment, firstAttachment, "The expected attachment doesn't match the expected one")
                XCTAssertEqual(result.failed.first?.object, secondResourceId, "The expected resource was expected to fail")

                XCTAssertNotNil(self.attachmentService.fetchAttachmentsCalledWith?.0.allAttachments, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.attachmentService.fetchAttachmentsCalledWith?.0.allAttachments as? [Attachment],
                               firstResource.allAttachments as? [Attachment], "A param in the method doesn't match the expectation")
                XCTAssertEqual((self.attachmentService.fetchAttachmentsCalledWith?.0 as? CustomIdentifierProtocol)?.customIdentifiers as? [Identifier],
                               firstResource.identifier, "A param in the method doesn't match the expectation")

            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
}
