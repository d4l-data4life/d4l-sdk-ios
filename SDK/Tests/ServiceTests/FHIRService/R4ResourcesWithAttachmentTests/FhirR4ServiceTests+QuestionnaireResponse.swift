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

import Foundation

import XCTest
@testable import Data4LifeSDK
import Data4LifeCrypto
import ModelsR4
import Then

// swiftlint:disable identifier_name
class FhirR4ServiceQuestionnaireResponseTests: XCTestCase {

    var recordService: RecordServiceMock<ModelsR4.QuestionnaireResponse, DecryptedFhirR4Record<ModelsR4.QuestionnaireResponse>>!
    var keychainService: KeychainServiceMock!
    var cryptoService: CryptoServiceMock!
    var fhirService: FhirService!
    var attachmentService: AttachmentServiceMock!

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        container.register(scope: .containerInstance) { (_) -> RecordServiceType in
            RecordServiceMock<ModelsR4.QuestionnaireResponse, DecryptedFhirR4Record<ModelsR4.QuestionnaireResponse>>()
        }
        fhirService = FhirService(container: container)

        do {
            recordService = try container.resolve(as: RecordServiceType.self)
            keychainService = try container.resolve(as: KeychainServiceType.self)
            attachmentService = try container.resolve(as: AttachmentServiceType.self)
            cryptoService = try container.resolve(as: CryptoServiceType.self)

            let userId = UUID().uuidString
            keychainService[.userId] = userId
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testCreateQuestionnaireResponseWithoutAttachments() {

        let resourceId = UUID().uuidString
        let questionnaireResponse = FhirFactory.createR4QuestionnaireResponse()
        questionnaireResponse.id = resourceId.asFHIRStringPrimitive()
        let originalRecord = DecryptedRecordFactory.create(questionnaireResponse)

        recordService.createRecordResult = Async.resolve(originalRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(questionnaireResponse, decryptedRecordType: DecryptedFhirR4Record<ModelsR4.QuestionnaireResponse>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(questionnaireResponse, result.resource, "The result doesn't match the expected resource")
                XCTAssertEqual(result.id, originalRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, questionnaireResponse, "The created record differs from the expected resource")

                XCTAssertNil(self.cryptoService.generateGCKeyCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testCreateQuestionnaireResponseWithAttachments() {

        let userId = UUID().uuidString
        keychainService[.userId] = userId

        let resourceId = UUID().uuidString
        let questionnaireResponse = FhirFactory.createR4QuestionnaireResponse()
        questionnaireResponse.id = resourceId.asFHIRStringPrimitive()
        let newAttachment0 =  FhirFactory.createR4SampleImageAttachment()
        let questionnaireResponseItem1Answer1 = FhirFactory.createR4QuestionnaireResponseItemAnswer(id: "existing-answer", attachment: newAttachment0)
        questionnaireResponse.item?.first?.answer = [questionnaireResponseItem1Answer1]

        let newAttachment1 = FhirFactory.createR4AttachmentElement()
        let newAttachment2 = FhirFactory.createR4ImageAttachmentElement()
        let newAttachment3 = newAttachment2.copyWithId()
        let questionnaireResponseItem1Answer2 = FhirFactory.createR4QuestionnaireResponseItemAnswer(id: "first-new-answer", attachment: newAttachment1)
        let questionnaireResponseItem1Item1Answer1 = FhirFactory.createR4QuestionnaireResponseItemAnswer(id: "second-new-answer", attachment: newAttachment2)

        let questionnaireResponseItem1Answer1Item1Answer1 = FhirFactory.createR4QuestionnaireResponseItemAnswer(id: "third-new-answer", attachment: newAttachment3)
        let questionnaireResponseItem1Answer1Item1 = FhirFactory.createR4QuestionnaireResponseItem(id: "third-new-item", answers: [questionnaireResponseItem1Answer1Item1Answer1])

        questionnaireResponse.item?.first?.answer?.append(questionnaireResponseItem1Answer2)
        questionnaireResponse.item?.first?.item?.first?.answer = [questionnaireResponseItem1Item1Answer1]
        questionnaireResponse.item?.first?.answer?.first?.item = [questionnaireResponseItem1Answer1Item1]
        let originalRecord = DecryptedRecordFactory.create(questionnaireResponse)

        //We expect that the parameter of the uploadAttachments method pass the attachments without an Id
        let expectedAttachmentsWithoutId = questionnaireResponse.allAttachments!.compactMap {
            ($0.copy() as! ModelsR4.Attachment) // swiftlint:disable:this force_cast
        }

        let expectedQuestionnaireResponse = questionnaireResponse.copy() as! ModelsR4.QuestionnaireResponse // swiftlint:disable:this force_cast
        expectedQuestionnaireResponse.allAttachments?.forEach({$0.attachmentDataString = nil})

        let newAttachment0Id = UUID().uuidString
        let newAttachment1Id = UUID().uuidString
        let newAttachment2Id = UUID().uuidString
        let newAttachment3Id = UUID().uuidString
        expectedQuestionnaireResponse.item?.first?.answer?.first?.valueAttachment?.id = newAttachment0Id.asFHIRStringPrimitive()
        expectedQuestionnaireResponse.item?.first?.answer?[1].valueAttachment?.id = newAttachment1Id.asFHIRStringPrimitive()
        expectedQuestionnaireResponse.item?.first?.item?.first?.answer?.first?.valueAttachment?.id = newAttachment2Id.asFHIRStringPrimitive()
        expectedQuestionnaireResponse.item?.first?.answer?.first?.item?.first?.answer?.first?.valueAttachment?.id = newAttachment3Id.asFHIRStringPrimitive()
        let expectedRecord = originalRecord.copy(with: expectedQuestionnaireResponse)

        let uploadedAttachment0 = newAttachment0.copyWithId(newAttachment0Id)
        let uploadedAttachment1 = newAttachment1.copyWithId(newAttachment1Id)
        let uploadedAttachment2 = newAttachment2.copyWithId(newAttachment2Id)
        let uploadedAttachment3 = newAttachment3.copyWithId(newAttachment3Id)
        let unmatchableAttachment = newAttachment3.copyWithId("you cant match me")
        unmatchableAttachment.id = "you cant match me"
        unmatchableAttachment.attachmentDataString = Data([0x25, 0x50, 0x44, 0x46, 0x2d, 0x01]).base64EncodedString()
        unmatchableAttachment.attachmentHash = Data([0x25, 0x50, 0x44, 0x46, 0x2d, 0x01]).sha1Hash
        attachmentService.uploadAttachmentsResult = Async.resolve([(uploadedAttachment0, []),
                                                                   (uploadedAttachment1, []),
                                                                   (uploadedAttachment2, []),
                                                                   (uploadedAttachment3, []),
                                                                   (unmatchableAttachment, [])])
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.createRecordResult = Async.resolve(expectedRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(questionnaireResponse, decryptedRecordType: DecryptedFhirR4Record<ModelsR4.QuestionnaireResponse>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(expectedQuestionnaireResponse, result.resource, "The result doesn't match the expected resource")
                XCTAssertEqual(expectedQuestionnaireResponse.allAttachments?.map {$0.testable},
                               result.resource.allAttachments?.map {$0.testable}, "The result doesn't match the expected resource")
                XCTAssertEqual(result.id, expectedRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "The used attachment key is different from the generated one")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.first!.testable,
                               expectedAttachmentsWithoutId.first!.testable, "The uploaded attachment is different from the expected")

                XCTAssertEqual((self.recordService.createRecordCalledWith?.0.resource)?.allAttachments?.map { $0.testable },
                               questionnaireResponse.allAttachments?.map { $0.testable })
                XCTAssertEqual((self.recordService.createRecordCalledWith?.0.resource),
                               questionnaireResponse)
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testCreateQuestionnaireResponseFailInvalidContentSize() {

        let userId = UUID().uuidString
        keychainService[.userId] = userId

        let resourceId = UUID().uuidString
        let questionnaireResponse = FhirFactory.createR4QuestionnaireResponse()
        questionnaireResponse.id = resourceId.asFHIRStringPrimitive()
        let attachment = FhirFactory.createR4AttachmentElement()
        let blankData = [UInt8](repeating: 0x00, count: 21 * 1024 * 1024) // 21mb
        guard let currentData = attachment.attachmentData else { fatalError("Attachment should have data") }
        attachment.attachmentDataString = (currentData + blankData).base64EncodedString()
        questionnaireResponse.item? = [FhirFactory.createR4QuestionnaireResponseItem(answers: [
                                                                                    FhirFactory.createR4QuestionnaireResponseItemAnswer(attachment: attachment)])]
        let originalRecord = DecryptedRecordFactory.create(questionnaireResponse)

        recordService.createRecordResult = Async.resolve(originalRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(questionnaireResponse, decryptedRecordType: DecryptedFhirR4Record<ModelsR4.QuestionnaireResponse>.self)
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

    func testCreateQuestionnaireResponseFailInvalidContentType() {

        let userId = UUID().uuidString
        keychainService[.userId] = userId

        let resourceId = UUID().uuidString
        let questionnaireResponse = FhirFactory.createR4QuestionnaireResponse()
        questionnaireResponse.id = resourceId.asFHIRStringPrimitive()
        let attachment = FhirFactory.createR4AttachmentElement()
        attachment.attachmentDataString = Data([0x00]).base64EncodedString()
        questionnaireResponse.item? = [FhirFactory.createR4QuestionnaireResponseItem(answers: [
                                                                                    FhirFactory.createR4QuestionnaireResponseItemAnswer(attachment: attachment)])]
        let originalRecord = DecryptedRecordFactory.create(questionnaireResponse)

        recordService.createRecordResult = Async.resolve(originalRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(questionnaireResponse, decryptedRecordType: DecryptedFhirR4Record<ModelsR4.QuestionnaireResponse>.self)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.cryptoService.generateGCKeyCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.recordService.createRecordCalledWith, "This method shouldn't have been called")
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.invalidAttachmentPayloadType, "Expected error didn't occur")
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testUpdateQuestionnaireResponseWithoutAttachments() {

        let userId = UUID().uuidString
        keychainService[.userId] = userId

        let resourceId = UUID().uuidString
        let questionnaireResponse = FhirFactory.createR4QuestionnaireResponse(items: [])
        questionnaireResponse.id = resourceId.asFHIRStringPrimitive()

        let existingQuestionnaireResponseItemAnswer = FhirFactory.createR4QuestionnaireResponseItemAnswer(id: "existing-answer", attachment: nil)
        questionnaireResponse.item?.first?.answer = [existingQuestionnaireResponseItemAnswer]
        let originalRecord = DecryptedRecordFactory.create(questionnaireResponse)

        let updatedQuestionnaireResponse = questionnaireResponse.copy() as! ModelsR4.QuestionnaireResponse // swiftlint:disable:this force_cast
        let questionnaireResponseFirstItemAnswer = FhirFactory.createR4QuestionnaireResponseItemAnswer(id: "first-new-answer", attachment: nil)
        let questionnaireResponseSecondItemAnswer = FhirFactory.createR4QuestionnaireResponseItemAnswer(id: "second-new-answer", attachment: nil)
        let questionnaireResponseThirdItemAnswer = FhirFactory.createR4QuestionnaireResponseItemAnswer(id: "third-new-answer", attachment: nil)
        let questionnaireResponseThirdItem = FhirFactory.createR4QuestionnaireResponseItem(id: "third-new-item", answers: [questionnaireResponseThirdItemAnswer])

        updatedQuestionnaireResponse.item?.first?.answer?.append(questionnaireResponseFirstItemAnswer)
        updatedQuestionnaireResponse.item?.first?.item?.first?.answer = [questionnaireResponseSecondItemAnswer]
        updatedQuestionnaireResponse.item?.first?.answer?.first?.item = [questionnaireResponseThirdItem]

        let expectedQuestionnaireResponse = updatedQuestionnaireResponse.copy() as! ModelsR4.QuestionnaireResponse // swiftlint:disable:this force_cast
        let expectedRecord = originalRecord.copy(with: expectedQuestionnaireResponse)

        recordService.fetchRecordResult = Async.resolve(originalRecord)
        recordService.updateRecordResult = Async.resolve(expectedRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(updatedQuestionnaireResponse, decryptedRecordType: DecryptedFhirR4Record<ModelsR4.QuestionnaireResponse>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(result.resource, expectedQuestionnaireResponse, "The result doesn't match the expected resource")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0.resource, updatedQuestionnaireResponse, "The updated record differs from the expected resource")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.2, userId, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.3, resourceId, "A param in the method doesn't match the expectation")
                XCTAssertNil(self.recordService.updateRecordCalledWith?.4, "A param in the method doesn't match the expectation")
                XCTAssertNil(result.resource.allAttachments?.first?.attachmentDataString, "Data in the attachment is expected to be nil")
                XCTAssertNil(self.cryptoService.generateGCKeyCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
            }
        waitForExpectations(timeout: 5)
    }

    func testUpdateQuestionnaireResponseWithAttachments() {

        let userId = UUID().uuidString
        keychainService[.userId] = userId

        let resourceId = UUID().uuidString
        let questionnaireResponseItemNestedInFirstItem = FhirFactory.createR4QuestionnaireResponseItem(id: UUID().uuidString, answers: [], nestedItems: [])
        let questionnaireResponseItem = FhirFactory.createR4QuestionnaireResponseItem(id: UUID().uuidString, answers: [], nestedItems: [questionnaireResponseItemNestedInFirstItem])
        let questionnaireResponse = FhirFactory.createR4QuestionnaireResponse(items: [questionnaireResponseItem])
        questionnaireResponse.id = resourceId.asFHIRStringPrimitive()
        let existingAttachment =  FhirFactory.createR4SampleImageAttachment()
        existingAttachment.id = UUID().uuidString.asFHIRStringPrimitive()
        existingAttachment.attachmentDataString = nil
        let existingQuestionnaireResponseItemAnswer = FhirFactory.createR4QuestionnaireResponseItemAnswer(id: "existing-answer", attachment: existingAttachment)
        questionnaireResponse.item?.first?.answer = [existingQuestionnaireResponseItemAnswer]
        let originalRecord = DecryptedRecordFactory.create(questionnaireResponse)

        let updatedQuestionnaireResponse = questionnaireResponse.copy() as! ModelsR4.QuestionnaireResponse // swiftlint:disable:this force_cast
        let newAttachment1 = FhirFactory.createR4AttachmentElement()
        let newAttachment2 = FhirFactory.createR4ImageAttachmentElement()
        let questionnaireResponseFirstItemAnswer = FhirFactory.createR4QuestionnaireResponseItemAnswer(id: "first-new-answer", attachment: newAttachment1)
        let questionnaireResponseSecondItemAnswer = FhirFactory.createR4QuestionnaireResponseItemAnswer(id: "second-new-answer", attachment: newAttachment2)

        let questionnaireResponseThirdItemAnswer = FhirFactory.createR4QuestionnaireResponseItemAnswer(id: "third-new-answer", attachment: newAttachment2)
        let questionnaireResponseThirdItem = FhirFactory.createR4QuestionnaireResponseItem(id: "third-new-item", answers: [questionnaireResponseThirdItemAnswer])

        updatedQuestionnaireResponse.item?.first?.answer?.append(questionnaireResponseFirstItemAnswer)
        updatedQuestionnaireResponse.item?.first?.item?.first?.answer = [questionnaireResponseSecondItemAnswer]
        updatedQuestionnaireResponse.item?.first?.answer?.first?.item = [questionnaireResponseThirdItem]

        let expectedQuestionnaireResponse = updatedQuestionnaireResponse.copy() as! ModelsR4.QuestionnaireResponse // swiftlint:disable:this force_cast
        let uploadedNewAttachmentId1 = UUID().uuidString
        let uploadedNewAttachmentId2 = UUID().uuidString
        let uploadedNewAttachmentId3 = UUID().uuidString
        expectedQuestionnaireResponse.allAttachments?.forEach { $0.attachmentDataString = nil }
        expectedQuestionnaireResponse.item?.first?.answer?.first?.valueAttachment?.id = uploadedNewAttachmentId1.asFHIRStringPrimitive()
        expectedQuestionnaireResponse.item?.first?.answer?.first?.item?.first?.answer?.first?.valueAttachment?.id = uploadedNewAttachmentId2.asFHIRStringPrimitive()
        expectedQuestionnaireResponse.item?.first?.item?.first?.answer?.first?.valueAttachment?.id = uploadedNewAttachmentId3.asFHIRStringPrimitive()
        let expectedRecord = originalRecord.copy(with: expectedQuestionnaireResponse)

        let uploadedAttachment1 = newAttachment1.copy() as! ModelsR4.Attachment // swiftlint:disable:this force_cast
        uploadedAttachment1.id = uploadedNewAttachmentId1.asFHIRStringPrimitive()
        let uploadedAttachment2 = newAttachment2.copy() as! ModelsR4.Attachment // swiftlint:disable:this force_cast
        uploadedAttachment2.id = uploadedNewAttachmentId2.asFHIRStringPrimitive()
        let uploadedAttachment3 = newAttachment2.copy() as! ModelsR4.Attachment // swiftlint:disable:this force_cast
        uploadedAttachment3.id = uploadedNewAttachmentId3.asFHIRStringPrimitive()

        attachmentService.uploadAttachmentsResult = Async.resolve([(uploadedAttachment1, []), (uploadedAttachment2, []), (uploadedAttachment3, [])])
        recordService.fetchRecordResult = Async.resolve(originalRecord)
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.updateRecordResult = Async.resolve(expectedRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(updatedQuestionnaireResponse, decryptedRecordType: DecryptedFhirR4Record<ModelsR4.QuestionnaireResponse>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(result.resource, expectedQuestionnaireResponse, "The result doesn't match the expected resource")
                XCTAssertEqual(result.resource.allAttachments?.count, 4)
                XCTAssertEqual(result.resource.allAttachments?.count, updatedQuestionnaireResponse.allAttachments?.count)
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0.resource, updatedQuestionnaireResponse, "The updated record differs from the expected resource")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.2, userId, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.3, resourceId, "A param in the method doesn't match the expectation")
                XCTAssertNotNil(self.recordService.updateRecordCalledWith?.4, "A param in the method doesn't match the expectation")
                XCTAssertNil(result.resource.allAttachments?.first?.attachmentData, "Data in the attachment is expected to be nil")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.map { $0.testable },
                               [newAttachment2, newAttachment1, newAttachment2].map { $0.testable }, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.0, resourceId, "A param in the method doesn't match the expectation")
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
            }
        waitForExpectations(timeout: 5)
    }

    func testUpdateQuestionnaireResponseFailInvalidContentSize() {

        let userId = UUID().uuidString

        let resourceId = UUID().uuidString
        let questionnaireResponse = FhirFactory.createR4QuestionnaireResponse()
        questionnaireResponse.id = resourceId.asFHIRStringPrimitive()
        let attachment = FhirFactory.createR4AttachmentElement()
        let blankData = [UInt8](repeating: 0x00, count: 21 * 1024 * 1024) // 21mb
        guard let currentData = attachment.attachmentData else { fatalError("Attachment should have data") }
        attachment.attachmentDataString = (currentData + blankData).base64EncodedString()
        questionnaireResponse.item? = [FhirFactory.createR4QuestionnaireResponseItem(answers: [
                                                                                    FhirFactory.createR4QuestionnaireResponseItemAnswer(attachment: attachment)])]

        let updatedRecord = DecryptedRecordFactory.create(questionnaireResponse)

        keychainService[.userId] = userId
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.fetchRecordResult = Async.resolve(updatedRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(questionnaireResponse, decryptedRecordType: DecryptedFhirR4Record<ModelsR4.QuestionnaireResponse>.self)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.recordService.createRecordCalledWith, "This method shouldn't have been called")
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.invalidAttachmentPayloadSize, "Expected error didn't occur")
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testUpdateQuestionnaireResponseFailInvalidContentType() {

        let userId = UUID().uuidString

        let resourceId = UUID().uuidString
        let questionnaireResponse = FhirFactory.createR4QuestionnaireResponse()
        questionnaireResponse.id = resourceId.asFHIRStringPrimitive()
        let attachment = FhirFactory.createR4AttachmentElement()
        attachment.attachmentDataString = Data([0x00]).base64EncodedString()
        questionnaireResponse.item? = [FhirFactory.createR4QuestionnaireResponseItem(answers: [
                                                                                    FhirFactory.createR4QuestionnaireResponseItemAnswer(attachment: attachment)])]

        let updatedRecord = DecryptedRecordFactory.create(questionnaireResponse)

        keychainService[.userId] = userId
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.fetchRecordResult = Async.resolve(updatedRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(questionnaireResponse, decryptedRecordType: DecryptedFhirR4Record<ModelsR4.QuestionnaireResponse>.self)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.recordService.createRecordCalledWith, "This method shouldn't have been called")
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.invalidAttachmentPayloadType, "Expected error didn't occur")
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }
}
