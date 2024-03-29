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

import Foundation

import XCTest
@testable import Data4LifeSDK
import Data4LifeCrypto
import Data4LifeFHIR
import Combine

// swiftlint:disable function_body_length
class FhirStu3ServiceQuestionnaireTests: XCTestCase {

    var recordService: RecordServiceMock<Questionnaire, DecryptedFhirStu3Record<Questionnaire>>!
    var keychainService: KeychainServiceMock!
    var cryptoService: CryptoServiceMock!
    var fhirService: FhirService!
    var attachmentService: AttachmentServiceMock!

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        container.register(scope: .containerInstance) { (_) -> RecordServiceType in
            RecordServiceMock<Questionnaire, DecryptedFhirStu3Record<Questionnaire>>()
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

    func testExpansionQuestionnaire() {
        let questionnaire = FhirFactory.createStu3ExpansionQuestionnaire()
        XCTAssertNotNil(questionnaire)
        let valueSet = questionnaire.contained?.first as? ValueSet
        XCTAssertEqual(valueSet?.expansion?.identifier, "urn:uuid:2c923b12-a4e9-4ba7-a8fd-5ba26da69808")
    }

    func testCreateQuestionnaireWithoutAttachments() {

        let resourceId = UUID().uuidString
        let questionnaire = FhirFactory.createStu3Questionnaire()
        questionnaire.id = resourceId
        let originalRecord = DecryptedRecordFactory.create(questionnaire)
        recordService.createRecordResult = Just(originalRecord).asyncFuture()

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(questionnaire, decryptedRecordType: DecryptedFhirStu3Record<Questionnaire>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(questionnaire, result.fhirResource, "The result doesn't match the expected resource")
                XCTAssertEqual(result.id, originalRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, questionnaire, "The created record differs from the expected resource")

                XCTAssertNil(self.cryptoService.generateGCKeyCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
            } onError: { error in
                XCTFail(error.localizedDescription)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testCreateQuestionnaireWithAttachments() {

        let userId = UUID().uuidString
        keychainService[.userId] = userId

        let resourceId = UUID().uuidString
        let questionnaire = FhirFactory.createStu3Questionnaire()
        questionnaire.id = resourceId
        let newAttachment0 =  FhirFactory.createStu3SampleImageAttachment()
        let questionnaireItem1 = FhirFactory.createStu3QuestionnaireItem(id: "first-item", initial: newAttachment0)

        let newAttachment1 = FhirFactory.createStu3AttachmentElement()
        let newAttachment2 = FhirFactory.createStu3ImageAttachmentElement()
        let newAttachment3 = newAttachment2.copyWithId()
        let questionnaireItem2 = FhirFactory.createStu3QuestionnaireItem(id: "first-new-answer", initial: newAttachment1)
        let questionnaireItem1Item1 = FhirFactory.createStu3QuestionnaireItem(id: "second-new-answer", initial: newAttachment2)
        let questionnaireItem1Item1Item1 = FhirFactory.createStu3QuestionnaireItem(id: "third-new-answer", initial: newAttachment3)

        questionnaire.item = [questionnaireItem1]
        questionnaire.item?.append(questionnaireItem2)
        questionnaire.item?.first?.item = [questionnaireItem1Item1]
        questionnaire.item?.first?.item?[0].item? = [questionnaireItem1Item1Item1]
        let originalRecord = DecryptedRecordFactory.create(questionnaire)

        // We expect that the parameter of the uploadAttachments method pass the attachments without an Id
        let expectedAttachmentsWithoutId = questionnaire.allAttachments!.compactMap {
            ($0.copy() as! Data4LifeFHIR.Attachment) // swiftlint:disable:this force_cast
        }

        let expectedQuestionnaire = questionnaire.copy() as! Questionnaire // swiftlint:disable:this force_cast
        expectedQuestionnaire.allAttachments?.forEach({$0.attachmentDataString = nil})

        let newAttachment0Id = UUID().uuidString
        let newAttachment1Id = UUID().uuidString
        let newAttachment2Id = UUID().uuidString
        let newAttachment3Id = UUID().uuidString
        expectedQuestionnaire.item?[0].initialAttachment?.id = newAttachment0Id
        expectedQuestionnaire.item?[1].initialAttachment?.id = newAttachment1Id
        expectedQuestionnaire.item?.first?.item?.first?.initialAttachment?.id = newAttachment2Id
        expectedQuestionnaire.item?.first?.item?.first?.item?.first?.initialAttachment?.id = newAttachment3Id
        let expectedRecord = originalRecord.copy(with: expectedQuestionnaire)

        let uploadedAttachment0 = newAttachment0.copyWithId(newAttachment0Id)
        let uploadedAttachment1 = newAttachment1.copyWithId(newAttachment1Id)
        let uploadedAttachment2 = newAttachment2.copyWithId(newAttachment2Id)
        let uploadedAttachment3 = newAttachment3.copyWithId(newAttachment3Id)
        let unmatchableAttachment = newAttachment3.copyWithId("you cant match me")
        unmatchableAttachment.attachmentDataString = Data([0x25, 0x50, 0x44, 0x46, 0x2d, 0x01]).base64EncodedString()
        unmatchableAttachment.hash = Data([0x25, 0x50, 0x44, 0x46, 0x2d, 0x01]).sha1Hash
        attachmentService.uploadAttachmentsResult = Just([AttachmentDocumentContext.make(uploadedAttachment0),
                                                          AttachmentDocumentContext.make(uploadedAttachment1),
                                                          AttachmentDocumentContext.make(uploadedAttachment2),
                                                          AttachmentDocumentContext.make(uploadedAttachment3),
                                                          AttachmentDocumentContext.make(unmatchableAttachment)]).asyncFuture()
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.createRecordResult = Just(expectedRecord).asyncFuture()

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(questionnaire, decryptedRecordType: DecryptedFhirStu3Record<Questionnaire>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(expectedQuestionnaire, result.fhirResource, "The result doesn't match the expected resource")
                XCTAssertEqual(expectedQuestionnaire.allAttachments as? [Attachment],
                               result.fhirResource.allAttachments as? [Attachment], "The result doesn't match the expected resource")
                XCTAssertEqual(result.id, expectedRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "The used attachment key is different from the generated one")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.first?.testable,
                               expectedAttachmentsWithoutId.first!.testable, "The uploaded attachment is different from the expected")

                XCTAssertEqual((self.recordService.createRecordCalledWith?.0.resource)?.allAttachments as? [Attachment],
                               questionnaire.allAttachments as? [Attachment])
                XCTAssertEqual((self.recordService.createRecordCalledWith?.0.resource),
                               questionnaire)
            } onError: { error in
                XCTFail(error.localizedDescription)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testCreateQuestionnaireFailInvalidContentSize() {

        let userId = UUID().uuidString
        keychainService[.userId] = userId

        let resourceId = UUID().uuidString
        let questionnaire = FhirFactory.createStu3Questionnaire()
        questionnaire.id = resourceId
        let attachment = FhirFactory.createStu3AttachmentElement()
        let blankData = [UInt8](repeating: 0x00, count: 21 * 1024 * 1024) // 21mb
        guard let currentData = attachment.attachmentData else { fatalError("Attachment should have data") }
        attachment.attachmentDataString = (currentData + blankData).base64EncodedString()
        questionnaire.item? = [FhirFactory.createStu3QuestionnaireItem(initial: attachment)]
        let originalRecord = DecryptedRecordFactory.create(questionnaire)

        recordService.createRecordResult = Just(originalRecord).asyncFuture()

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(questionnaire, decryptedRecordType: DecryptedFhirStu3Record<Questionnaire>.self)
            .then { _ in
                XCTFail("Should return an error")
            } onError: { error in
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.cryptoService.generateGCKeyCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.recordService.createRecordCalledWith, "This method shouldn't have been called")
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.invalidAttachmentPayloadSize, "Expected error didn't occur")
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testCreateQuestionnaireFailInvalidContentType() {

        let userId = UUID().uuidString
        keychainService[.userId] = userId

        let resourceId = UUID().uuidString
        let questionnaire = FhirFactory.createStu3Questionnaire()
        questionnaire.id = resourceId
        let attachment = FhirFactory.createStu3AttachmentElement()
        attachment.attachmentDataString = Data([0x00]).base64EncodedString()
        questionnaire.item? = [FhirFactory.createStu3QuestionnaireItem(initial: attachment)]
        let originalRecord = DecryptedRecordFactory.create(questionnaire)

        recordService.createRecordResult = Just(originalRecord).asyncFuture()

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(questionnaire, decryptedRecordType: DecryptedFhirStu3Record<Questionnaire>.self)
            .then { _ in
                XCTFail("Should return an error")
            } onError: { error in
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.cryptoService.generateGCKeyCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.recordService.createRecordCalledWith, "This method shouldn't have been called")
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.invalidAttachmentPayloadType, "Expected error didn't occur")
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testCreateQuestionnaireWithAttachmentsWithAdditionalIDs() {

        let userId = UUID().uuidString
        keychainService[.userId] = userId

        let resourceId = UUID().uuidString
        let questionnaire = FhirFactory.createStu3Questionnaire()
        questionnaire.id = resourceId
        let newAttachment0 =  FhirFactory.createStu3SampleImageAttachment()
        let questionnaireItem1 = FhirFactory.createStu3QuestionnaireItem(id: "first-item", initial: newAttachment0)

        let newAttachment1 = FhirFactory.createStu3AttachmentElement()
        let newAttachment2 = FhirFactory.createStu3ImageAttachmentElement()
        let newAttachment3 = newAttachment2.copyWithId()
        let questionnaireItem2 = FhirFactory.createStu3QuestionnaireItem(id: "first-new-answer", initial: newAttachment1)
        let questionnaireItem1Item1 = FhirFactory.createStu3QuestionnaireItem(id: "second-new-answer", initial: newAttachment2)
        let questionnaireItem1Item1Item1 = FhirFactory.createStu3QuestionnaireItem(id: "third-new-answer", initial: newAttachment3)

        questionnaire.item = [questionnaireItem1]
        questionnaire.item?.append(questionnaireItem2)
        questionnaire.item?.first?.item = [questionnaireItem1Item1]
        questionnaire.item?.first?.item?[0].item? = [questionnaireItem1Item1Item1]
        let originalRecord = DecryptedRecordFactory.create(questionnaire)

        // We expect that the parameter of the uploadAttachments method pass the attachments without an Id
        let expectedAttachmentsWithoutId = questionnaire.allAttachments!.compactMap {
            ($0.copy() as! Data4LifeFHIR.Attachment) // swiftlint:disable:this force_cast
        }

        let expectedQuestionnaire = questionnaire.copy() as! Questionnaire // swiftlint:disable:this force_cast
        expectedQuestionnaire.allAttachments?.forEach({$0.attachmentDataString = nil})

        let newAttachment0Id = UUID().uuidString
        let newAttachment1Id = UUID().uuidString
        let newAttachment2Id = UUID().uuidString
        let newAttachment3Id = UUID().uuidString
        expectedQuestionnaire.item?[0].initialAttachment?.id = newAttachment0Id
        expectedQuestionnaire.item?[1].initialAttachment?.id = newAttachment1Id
        expectedQuestionnaire.item?.first?.item?.first?.initialAttachment?.id = newAttachment2Id
        expectedQuestionnaire.item?.first?.item?.first?.item?.first?.initialAttachment?.id = newAttachment3Id
        let additionalPayloadsIds = [ThumbnailHeight.mediumHeight: "addId1", .smallHeight: "addId2"]
        let expected0AdditionalId = ["d4l_f_p_t#\(newAttachment0Id)#\(additionalPayloadsIds[.mediumHeight]!)#\(additionalPayloadsIds[.smallHeight]!)"]
        let expected1AdditionalId = ["d4l_f_p_t#\(newAttachment1Id)#\(additionalPayloadsIds[.mediumHeight]!)#\(additionalPayloadsIds[.smallHeight]!)"]
        let expected2AdditionalId = ["d4l_f_p_t#\(newAttachment2Id)#\(additionalPayloadsIds[.mediumHeight]!)#\(additionalPayloadsIds[.smallHeight]!)"]
        let expected3AdditionalId = ["d4l_f_p_t#\(newAttachment3Id)#\(additionalPayloadsIds[.mediumHeight]!)#\(additionalPayloadsIds[.smallHeight]!)"]
        expectedQuestionnaire.setAdditionalIds(expected0AdditionalId)
        expectedQuestionnaire.setAdditionalIds(expected1AdditionalId)
        expectedQuestionnaire.setAdditionalIds(expected2AdditionalId)
        expectedQuestionnaire.setAdditionalIds(expected3AdditionalId)
        let expectedRecord = originalRecord.copy(with: expectedQuestionnaire)

        let uploadedAttachment0 = newAttachment0.copyWithId(newAttachment0Id)
        let uploadedAttachment1 = newAttachment1.copyWithId(newAttachment1Id)
        let uploadedAttachment2 = newAttachment2.copyWithId(newAttachment2Id)
        let uploadedAttachment3 = newAttachment3.copyWithId(newAttachment3Id)
        let unmatchableAttachment = newAttachment3.copyWithId("you cant match me")
        unmatchableAttachment.attachmentDataString = Data([0x25, 0x50, 0x44, 0x46, 0x2d, 0x01]).base64EncodedString()
        unmatchableAttachment.hash = Data([0x25, 0x50, 0x44, 0x46, 0x2d, 0x01]).sha1Hash
        attachmentService.uploadAttachmentsResult = Just([AttachmentDocumentContext.make(uploadedAttachment0, ids: additionalPayloadsIds),
                                                          AttachmentDocumentContext.make(uploadedAttachment1, ids: additionalPayloadsIds),
                                                          AttachmentDocumentContext.make(uploadedAttachment2, ids: additionalPayloadsIds),
                                                          AttachmentDocumentContext.make(uploadedAttachment3, ids: additionalPayloadsIds),
                                                          AttachmentDocumentContext.make(unmatchableAttachment)]).asyncFuture()
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.createRecordResult = Just(expectedRecord).asyncFuture()

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(questionnaire, decryptedRecordType: DecryptedFhirStu3Record<Questionnaire>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(expectedQuestionnaire, result.fhirResource, "The result doesn't match the expected resource")
                XCTAssertEqual(expectedQuestionnaire.allAttachments as? [Attachment],
                               result.fhirResource.allAttachments as? [Attachment], "The result doesn't match the expected resource")
                XCTAssertEqual(result.id, expectedRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "The used attachment key is different from the generated one")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.first!.testable,
                               expectedAttachmentsWithoutId.first!.testable, "The uploaded attachment is different from the expected")

                XCTAssertEqual((self.recordService.createRecordCalledWith?.0.resource)?.allAttachments as? [Attachment],
                               questionnaire.allAttachments as? [Attachment])
                XCTAssertEqual((self.recordService.createRecordCalledWith?.0.resource),
                               questionnaire)
            } onError: { error in
                XCTFail(error.localizedDescription)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testUpdateQuestionnaireWithoutAttachments() {

        let resourceId = UUID().uuidString
        let questionnaire = FhirFactory.createStu3Questionnaire()
        questionnaire.id = resourceId
        let questionnaireItem1 = FhirFactory.createStu3QuestionnaireItem()
        questionnaire.item? = [questionnaireItem1]
        let originalRecord = DecryptedRecordFactory.create(questionnaire)

        let updatedQuestionnaire = questionnaire.copy() as! Questionnaire // swiftlint:disable:this force_cast
        let questionnaireItem2Item1 = FhirFactory.createStu3QuestionnaireItem(id: "first-new-answer", initial: nil)
        let questionnaireItem2 = FhirFactory.createStu3QuestionnaireItem(id: "third-new-item", items: [questionnaireItem2Item1])
        updatedQuestionnaire.item?.append(questionnaireItem2)

        let expectedQuestionnaire = updatedQuestionnaire.copy() as! Questionnaire // swiftlint:disable:this force_cast
        let expectedRecord = originalRecord.copy(with: expectedQuestionnaire)

        recordService.fetchRecordResult = Just(originalRecord).asyncFuture()
        recordService.updateRecordResult = Just(expectedRecord).asyncFuture()

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(updatedQuestionnaire, decryptedRecordType: DecryptedFhirStu3Record<Questionnaire>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(result.fhirResource, expectedQuestionnaire, "The result doesn't match the expected resource")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0.resource, updatedQuestionnaire, "The updated record differs from the expected resource")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.3, resourceId, "A param in the method doesn't match the expectation")
                XCTAssertNil(self.recordService.updateRecordCalledWith?.4, "A param in the method doesn't match the expectation")
                XCTAssertNil(result.fhirResource.allAttachments?.first?.attachmentDataString, "Data in the attachment is expected to be nil")
                XCTAssertNil(self.cryptoService.generateGCKeyCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
            } onError: { error in
                XCTFail(error.localizedDescription)
            } finally: {
                asyncExpectation.fulfill()
            }
        waitForExpectations(timeout: 5)
    }

    func testUpdateQuestionnaireWithAttachments() {

        let resourceId = UUID().uuidString
        let questionnaire = FhirFactory.createStu3Questionnaire()
        questionnaire.id = resourceId
        let existingAttachment =  FhirFactory.createStu3SampleImageAttachment()
        existingAttachment.id = UUID().uuidString
        existingAttachment.attachmentDataString = nil
        let questionnaireItem1 = FhirFactory.createStu3QuestionnaireItem(id: "existing-answer", initial: existingAttachment)
        questionnaire.item = [questionnaireItem1]
        let originalRecord = DecryptedRecordFactory.create(questionnaire)

        let updatedQuestionnaire = questionnaire.copy() as! Questionnaire // swiftlint:disable:this force_cast
        let newAttachment1 = FhirFactory.createStu3AttachmentElement()
        let newAttachment2 = FhirFactory.createStu3ImageAttachmentElement()
        let newAttachment3 = FhirFactory.createStu3ImageAttachmentElement()
        let questionnaireItem2 = FhirFactory.createStu3QuestionnaireItem(id: "first-new-answer", initial: newAttachment1)
        let questionnaireItem1Item1 = FhirFactory.createStu3QuestionnaireItem(id: "second-new-answer", initial: newAttachment2)
        let questionnaireItem1Item2Item1 = FhirFactory.createStu3QuestionnaireItem(id: "third-new-answer", initial: newAttachment3)
        let questionnaireItem1Item2 = FhirFactory.createStu3QuestionnaireItem(id: "third-new-item", items: [questionnaireItem1Item2Item1])

        updatedQuestionnaire.item?.append(questionnaireItem2)
        updatedQuestionnaire.item?.first?.item = [questionnaireItem1Item1]
        updatedQuestionnaire.item?.first?.item?.append(questionnaireItem1Item2)

        let expectedQuestionnaire = updatedQuestionnaire.copy() as! Questionnaire // swiftlint:disable:this force_cast
        let uploadedNewAttachmentId1 = UUID().uuidString
        let uploadedNewAttachmentId2 = UUID().uuidString
        let uploadedNewAttachmentId3 = UUID().uuidString
        expectedQuestionnaire.allAttachments?.forEach({$0.attachmentDataString = nil})

        expectedQuestionnaire.item?[1].initialAttachment?.id = uploadedNewAttachmentId1
        expectedQuestionnaire.item?.first?.item?.first?.initialAttachment?.id = uploadedNewAttachmentId2
        expectedQuestionnaire.item?.first?.item?[1].item?.first?.initialAttachment?.id = uploadedNewAttachmentId3
        let expectedRecord = originalRecord.copy(with: expectedQuestionnaire)

        let uploadedAttachment1 = newAttachment1.copyWithId(uploadedNewAttachmentId1)
        let uploadedAttachment2 = newAttachment2.copyWithId(uploadedNewAttachmentId2)
        let uploadedAttachment3 = newAttachment2.copyWithId(uploadedNewAttachmentId3)

        attachmentService.uploadAttachmentsResult = Just([AttachmentDocumentContext.make(uploadedAttachment1),
                                                          AttachmentDocumentContext.make(uploadedAttachment2),
                                                          AttachmentDocumentContext.make(uploadedAttachment3)]).asyncFuture()
        recordService.fetchRecordResult = Just(originalRecord).asyncFuture()
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.updateRecordResult = Just(expectedRecord).asyncFuture()

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(updatedQuestionnaire, decryptedRecordType: DecryptedFhirStu3Record<Questionnaire>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(result.fhirResource, expectedQuestionnaire, "The result doesn't match the expected resource")
                XCTAssertEqual(result.fhirResource.allAttachments?.count, 4)
                XCTAssertEqual(result.fhirResource.allAttachments?.count, updatedQuestionnaire.allAttachments?.count)
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0.resource, updatedQuestionnaire, "The updated record differs from the expected resource")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.3, resourceId, "A param in the method doesn't match the expectation")
                XCTAssertNotNil(self.recordService.updateRecordCalledWith?.4, "A param in the method doesn't match the expectation")
                XCTAssertNil(result.fhirResource.allAttachments?.first?.attachmentDataString, "Data in the attachment is expected to be nil")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.map { $0.testable },
                               [newAttachment2, newAttachment3, newAttachment1].map { $0.testable }, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.0, resourceId, "A param in the method doesn't match the expectation")
            } onError: { error in
                XCTFail(error.localizedDescription)
            } finally: {
                asyncExpectation.fulfill()
            }
        waitForExpectations(timeout: 5)
    }

    func testUpdateQuestionnaireFailInvalidContentSize() {

        let userId = UUID().uuidString

        let resourceId = UUID().uuidString
        let questionnaire = FhirFactory.createStu3Questionnaire()
        questionnaire.id = resourceId
        let attachment = FhirFactory.createStu3AttachmentElement()
        let blankData = [UInt8](repeating: 0x00, count: 21 * 1024 * 1024) // 21mb
        guard let currentData = attachment.attachmentData else { fatalError("Attachment should have data") }
        attachment.attachmentDataString = (currentData + blankData).base64EncodedString()
        questionnaire.item? = [FhirFactory.createStu3QuestionnaireItem(initial: attachment)]

        let updatedRecord = DecryptedRecordFactory.create(questionnaire)

        keychainService[.userId] = userId
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.fetchRecordResult = Just(updatedRecord).asyncFuture()

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(questionnaire, decryptedRecordType: DecryptedFhirStu3Record<Questionnaire>.self)
            .then { _ in
                XCTFail("Should return an error")
            } onError: { error in
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.recordService.createRecordCalledWith, "This method shouldn't have been called")
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.invalidAttachmentPayloadSize, "Expected error didn't occur")
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testUpdateQuestionnaireFailInvalidContentType() {

        let userId = UUID().uuidString

        let resourceId = UUID().uuidString
        let questionnaire = FhirFactory.createStu3Questionnaire()
        questionnaire.id = resourceId
        let attachment = FhirFactory.createStu3AttachmentElement()
        attachment.attachmentDataString = Data([0x00]).base64EncodedString()
        questionnaire.item? = [FhirFactory.createStu3QuestionnaireItem(initial: attachment)]

        let updatedRecord = DecryptedRecordFactory.create(questionnaire)

        keychainService[.userId] = userId
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.fetchRecordResult = Just(updatedRecord).asyncFuture()

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(questionnaire, decryptedRecordType: DecryptedFhirStu3Record<Questionnaire>.self)
            .then { _ in
                XCTFail("Should return an error")
            } onError: { error in
                XCTAssertNil(self.attachmentService.uploadAttachmentsCalledWith, "This method shouldn't have been called")
                XCTAssertNil(self.recordService.createRecordCalledWith, "This method shouldn't have been called")
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.invalidAttachmentPayloadType, "Expected error didn't occur")
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }
}
