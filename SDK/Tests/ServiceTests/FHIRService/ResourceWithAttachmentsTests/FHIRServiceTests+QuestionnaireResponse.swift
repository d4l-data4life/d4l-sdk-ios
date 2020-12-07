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
import Data4LifeFHIR
import Then

// swiftlint:disable identifier_name
// swiftlint:disable type_name
class FhirStu3ServiceQuestionnaireResponseTests: XCTestCase {

    var recordService: RecordServiceMock<QuestionnaireResponse>!
    var keychainService: KeychainServiceMock!
    var cryptoService: CryptoServiceMock!
    var fhirService: FhirStu3Service!
    var attachmentService: AttachmentServiceMock!

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        container.register(scope: .containerInstance) { (_) -> RecordServiceType in
            RecordServiceMock<QuestionnaireResponse>()
        }
        fhirService = FhirStu3Service(container: container)

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
        let questionnaireResponse = FhirFactory.createQuestionnaireResponse()
        questionnaireResponse.id = resourceId
        let originalRecord = DecryptedRecordFactory.create(fhir: questionnaireResponse)

        recordService.createRecordResult = Async.resolve(originalRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirStu3Record(questionnaireResponse)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(questionnaireResponse, result.resource, "The result doesn't match the expected resource")
                XCTAssertEqual(result.id, originalRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0 as? QuestionnaireResponse, questionnaireResponse, "The created record differs from the expected resource")

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
        let questionnaireResponse = FhirFactory.createQuestionnaireResponse()
        questionnaireResponse.id = resourceId
        let newAttachment0 =  FhirFactory.createSampleImageAttachment()
        let questionnaireResponseItem1Answer1 = FhirFactory.createQuestionnaireResponseItemAnswer(id: "existing-answer", attachment: newAttachment0)
        questionnaireResponse.item?.first?.answer = [questionnaireResponseItem1Answer1]

        let newAttachment1 = FhirFactory.createAttachmentElement()
        let newAttachment2 = FhirFactory.createImageAttachmentElement()
        let newAttachment3 = newAttachment2.copyWithId()
        let questionnaireResponseItem1Answer2 = FhirFactory.createQuestionnaireResponseItemAnswer(id: "first-new-answer", attachment: newAttachment1)
        let questionnaireResponseItem1Item1Answer1 = FhirFactory.createQuestionnaireResponseItemAnswer(id: "second-new-answer", attachment: newAttachment2)

        let questionnaireResponseItem1Answer1Item1Answer1 = FhirFactory.createQuestionnaireResponseItemAnswer(id: "third-new-answer", attachment: newAttachment3)
        let questionnaireResponseItem1Answer1Item1 = FhirFactory.createQuestionnaireResponseItem(id: "third-new-item", answers: [questionnaireResponseItem1Answer1Item1Answer1])

        questionnaireResponse.item?.first?.answer?.append(questionnaireResponseItem1Answer2)
        questionnaireResponse.item?.first?.item?.first?.answer = [questionnaireResponseItem1Item1Answer1]
        questionnaireResponse.item?.first?.answer?.first?.item = [questionnaireResponseItem1Answer1Item1]
        let originalRecord = DecryptedRecordFactory.create(fhir: questionnaireResponse)

        //We expect that the parameter of the uploadAttachments method pass the attachments without an Id
        let expectedAttachmentsWithoutId = questionnaireResponse.allAttachments!.compactMap {
            ($0.copy() as! Attachment) // swiftlint:disable:this force_cast
        }

        let expectedQuestionnaireResponse = questionnaireResponse.copy() as! QuestionnaireResponse // swiftlint:disable:this force_cast
        expectedQuestionnaireResponse.allAttachments?.forEach({$0.attachmentData = nil})

        let newAttachment0Id = UUID().uuidString
        let newAttachment1Id = UUID().uuidString
        let newAttachment2Id = UUID().uuidString
        let newAttachment3Id = UUID().uuidString
        expectedQuestionnaireResponse.item?.first?.answer?.first?.valueAttachment?.id = newAttachment0Id
        expectedQuestionnaireResponse.item?.first?.answer?[1].valueAttachment?.id = newAttachment1Id
        expectedQuestionnaireResponse.item?.first?.item?.first?.answer?.first?.valueAttachment?.id = newAttachment2Id
        expectedQuestionnaireResponse.item?.first?.answer?.first?.item?.first?.answer?.first?.valueAttachment?.id = newAttachment3Id
        let expectedRecord = originalRecord.copy(with: expectedQuestionnaireResponse)

        let uploadedAttachment0 = newAttachment0.copyWithId(newAttachment0Id)
        let uploadedAttachment1 = newAttachment1.copyWithId(newAttachment1Id)
        let uploadedAttachment2 = newAttachment2.copyWithId(newAttachment2Id)
        let uploadedAttachment3 = newAttachment3.copyWithId(newAttachment3Id)
        let unmatchableAttachment = newAttachment3.copyWithId("you cant match me")
        unmatchableAttachment.id = "you cant match me"
        unmatchableAttachment.attachmentData = Data([0x25, 0x50, 0x44, 0x46, 0x2d, 0x01]).base64EncodedString()
        unmatchableAttachment.hash = Data([0x25, 0x50, 0x44, 0x46, 0x2d, 0x01]).sha1Hash
        attachmentService.uploadAttachmentsResult = Async.resolve([(uploadedAttachment0, []),
                                                                   (uploadedAttachment1, []),
                                                                   (uploadedAttachment2, []),
                                                                   (uploadedAttachment3, []),
                                                                   (unmatchableAttachment, [])])
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.createRecordResult = Async.resolve(expectedRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirStu3Record(questionnaireResponse)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(expectedQuestionnaireResponse, result.resource, "The result doesn't match the expected resource")
                XCTAssertEqual(expectedQuestionnaireResponse.allAttachments,
                               result.resource.allAttachments, "The result doesn't match the expected resource")
                XCTAssertEqual(result.id, expectedRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, GCKeyType.attachment, "The used attachment key is different from the generated one")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.first!,
                               expectedAttachmentsWithoutId.first!, "The uploaded attachment is different from the expected")

                XCTAssertEqual((self.recordService.createRecordCalledWith?.0 as? QuestionnaireResponse)?.allAttachments,
                               questionnaireResponse.allAttachments)
                XCTAssertEqual((self.recordService.createRecordCalledWith?.0 as? QuestionnaireResponse),
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
        let questionnaireResponse = FhirFactory.createQuestionnaireResponse()
        questionnaireResponse.id = resourceId
        let attachment = FhirFactory.createAttachmentElement()
        let blankData = [UInt8](repeating: 0x00, count: 21 * 1024 * 1024) // 21mb
        guard let currentData = attachment.attachmentData else { fatalError("Attachment should have data") }
        attachment.attachmentData = (currentData + blankData).base64EncodedString()
        questionnaireResponse.item? = [FhirFactory.createQuestionnaireResponseItem(answers: [
            FhirFactory.createQuestionnaireResponseItemAnswer(attachment: attachment)])]
        let originalRecord = DecryptedRecordFactory.create(fhir: questionnaireResponse)

        recordService.createRecordResult = Async.resolve(originalRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirStu3Record(questionnaireResponse)
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
        let questionnaireResponse = FhirFactory.createQuestionnaireResponse()
        questionnaireResponse.id = resourceId
        let attachment = FhirFactory.createAttachmentElement()
        attachment.attachmentData = Data([0x00]).base64EncodedString()
        questionnaireResponse.item? = [FhirFactory.createQuestionnaireResponseItem(answers: [
            FhirFactory.createQuestionnaireResponseItemAnswer(attachment: attachment)])]
        let originalRecord = DecryptedRecordFactory.create(fhir: questionnaireResponse)

        recordService.createRecordResult = Async.resolve(originalRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirStu3Record(questionnaireResponse)
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
        let questionnaireResponse = FhirFactory.createQuestionnaireResponse()
        questionnaireResponse.id = resourceId

        let existingQuestionnaireResponseItemAnswer = FhirFactory.createQuestionnaireResponseItemAnswer(id: "existing-answer", attachment: nil)
        questionnaireResponse.item?.first?.answer = [existingQuestionnaireResponseItemAnswer]
        let originalRecord = DecryptedRecordFactory.create(fhir: questionnaireResponse)

        let updatedQuestionnaireResponse = questionnaireResponse.copy() as! QuestionnaireResponse // swiftlint:disable:this force_cast
        let questionnaireResponseFirstItemAnswer = FhirFactory.createQuestionnaireResponseItemAnswer(id: "first-new-answer", attachment: nil)
        let questionnaireResponseSecondItemAnswer = FhirFactory.createQuestionnaireResponseItemAnswer(id: "second-new-answer", attachment: nil)
        let questionnaireResponseThirdItemAnswer = FhirFactory.createQuestionnaireResponseItemAnswer(id: "third-new-answer", attachment: nil)
        let questionnaireResponseThirdItem = FhirFactory.createQuestionnaireResponseItem(id: "third-new-item", answers: [questionnaireResponseThirdItemAnswer])

        updatedQuestionnaireResponse.item?.first?.answer?.append(questionnaireResponseFirstItemAnswer)
        updatedQuestionnaireResponse.item?.first?.item?.first?.answer = [questionnaireResponseSecondItemAnswer]
        updatedQuestionnaireResponse.item?.first?.answer?.first?.item = [questionnaireResponseThirdItem]

        let expectedQuestionnaireResponse = updatedQuestionnaireResponse.copy() as! QuestionnaireResponse // swiftlint:disable:this force_cast
        let expectedRecord = originalRecord.copy(with: expectedQuestionnaireResponse)

        recordService.fetchRecordResult = Async.resolve(originalRecord)
        recordService.updateRecordResult = Async.resolve(expectedRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirStu3Record(updatedQuestionnaireResponse)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(result.resource, expectedQuestionnaireResponse, "The result doesn't match the expected resource")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0 as? QuestionnaireResponse, updatedQuestionnaireResponse, "The updated record differs from the expected resource")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.1, userId, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.2, resourceId, "A param in the method doesn't match the expectation")
                XCTAssertNil(self.recordService.updateRecordCalledWith?.3, "A param in the method doesn't match the expectation")
                XCTAssertNil(result.resource.allAttachments?.first?.attachmentData, "Data in the attachment is expected to be nil")
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
        let questionnaireResponse = FhirFactory.createQuestionnaireResponse()
        questionnaireResponse.id = resourceId
        let existingAttachment =  FhirFactory.createSampleImageAttachment()
        existingAttachment.id = UUID().uuidString
        existingAttachment.attachmentData = nil
        let existingQuestionnaireResponseItemAnswer = FhirFactory.createQuestionnaireResponseItemAnswer(id: "existing-answer", attachment: existingAttachment)
        questionnaireResponse.item?.first?.answer = [existingQuestionnaireResponseItemAnswer]
        let originalRecord = DecryptedRecordFactory.create(fhir: questionnaireResponse)

        let updatedQuestionnaireResponse = questionnaireResponse.copy() as! QuestionnaireResponse // swiftlint:disable:this force_cast
        let newAttachment1 = FhirFactory.createAttachmentElement()
        let newAttachment2 = FhirFactory.createImageAttachmentElement()
        let questionnaireResponseFirstItemAnswer = FhirFactory.createQuestionnaireResponseItemAnswer(id: "first-new-answer", attachment: newAttachment1)
        let questionnaireResponseSecondItemAnswer = FhirFactory.createQuestionnaireResponseItemAnswer(id: "second-new-answer", attachment: newAttachment2)

        let questionnaireResponseThirdItemAnswer = FhirFactory.createQuestionnaireResponseItemAnswer(id: "third-new-answer", attachment: newAttachment2)
        let questionnaireResponseThirdItem = FhirFactory.createQuestionnaireResponseItem(id: "third-new-item", answers: [questionnaireResponseThirdItemAnswer])

        updatedQuestionnaireResponse.item?.first?.answer?.append(questionnaireResponseFirstItemAnswer)
        updatedQuestionnaireResponse.item?.first?.item?.first?.answer = [questionnaireResponseSecondItemAnswer]
        updatedQuestionnaireResponse.item?.first?.answer?.first?.item = [questionnaireResponseThirdItem]

        let expectedQuestionnaireResponse = updatedQuestionnaireResponse.copy() as! QuestionnaireResponse // swiftlint:disable:this force_cast
        let uploadedNewAttachmentId1 = UUID().uuidString
        let uploadedNewAttachmentId2 = UUID().uuidString
        let uploadedNewAttachmentId3 = UUID().uuidString
        expectedQuestionnaireResponse.allAttachments?.forEach({$0.attachmentData = nil})
        expectedQuestionnaireResponse.item?.first?.answer?.first?.valueAttachment?.id = uploadedNewAttachmentId1
        expectedQuestionnaireResponse.item?.first?.answer?.first?.item?.first?.answer?.first?.valueAttachment?.id = uploadedNewAttachmentId2
        expectedQuestionnaireResponse.item?.first?.item?.first?.answer?.first?.valueAttachment?.id = uploadedNewAttachmentId3
        let expectedRecord = originalRecord.copy(with: expectedQuestionnaireResponse)

        let uploadedAttachment1 = newAttachment1.copy() as! Attachment // swiftlint:disable:this force_cast
        uploadedAttachment1.id = uploadedNewAttachmentId1
        let uploadedAttachment2 = newAttachment2.copy() as! Attachment // swiftlint:disable:this force_cast
        uploadedAttachment2.id = uploadedNewAttachmentId2
        let uploadedAttachment3 = newAttachment2.copy() as! Attachment // swiftlint:disable:this force_cast
        uploadedAttachment3.id = uploadedNewAttachmentId3

        attachmentService.uploadAttachmentsResult = Async.resolve([(uploadedAttachment1, []), (uploadedAttachment2, []), (uploadedAttachment3, [])])
        recordService.fetchRecordResult = Async.resolve(originalRecord)
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.updateRecordResult = Async.resolve(expectedRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirStu3Record(updatedQuestionnaireResponse)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(result.resource, expectedQuestionnaireResponse, "The result doesn't match the expected resource")
                XCTAssertEqual(result.resource.allAttachments?.count, 4)
                XCTAssertEqual(result.resource.allAttachments?.count, updatedQuestionnaireResponse.allAttachments?.count)
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0 as? QuestionnaireResponse, updatedQuestionnaireResponse, "The updated record differs from the expected resource")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.1, userId, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.2, resourceId, "A param in the method doesn't match the expectation")
                XCTAssertNotNil(self.recordService.updateRecordCalledWith?.3, "A param in the method doesn't match the expectation")
                XCTAssertNil(result.resource.allAttachments?.first?.attachmentData, "Data in the attachment is expected to be nil")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0, [newAttachment2, newAttachment1, newAttachment2], "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, GCKeyType.attachment, "A param in the method doesn't match the expectation")
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
        let questionnaireResponse = FhirFactory.createQuestionnaireResponse()
        questionnaireResponse.id = resourceId
        let attachment = FhirFactory.createAttachmentElement()
        let blankData = [UInt8](repeating: 0x00, count: 21 * 1024 * 1024) // 21mb
        guard let currentData = attachment.attachmentData else { fatalError("Attachment should have data") }
        attachment.attachmentData = (currentData + blankData).base64EncodedString()
        questionnaireResponse.item? = [FhirFactory.createQuestionnaireResponseItem(answers: [
            FhirFactory.createQuestionnaireResponseItemAnswer(attachment: attachment)])]

        let updatedRecord = DecryptedRecordFactory.create(fhir: questionnaireResponse)

        keychainService[.userId] = userId
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.fetchRecordResult = Async.resolve(updatedRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirStu3Record(questionnaireResponse)
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
        let questionnaireResponse = FhirFactory.createQuestionnaireResponse()
        questionnaireResponse.id = resourceId
        let attachment = FhirFactory.createAttachmentElement()
        attachment.attachmentData = Data([0x00]).base64EncodedString()
        questionnaireResponse.item? = [FhirFactory.createQuestionnaireResponseItem(answers: [
            FhirFactory.createQuestionnaireResponseItemAnswer(attachment: attachment)])]

        let updatedRecord = DecryptedRecordFactory.create(fhir: questionnaireResponse)

        keychainService[.userId] = userId
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.fetchRecordResult = Async.resolve(updatedRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirStu3Record(questionnaireResponse)
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
