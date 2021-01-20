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

class FhirStu3ServiceObservationTests: XCTestCase { // swiftlint:disable:this type_body_length

    var recordService: RecordServiceMock<Observation, DecryptedFhirStu3Record<Observation>>!
    var keychainService: KeychainServiceMock!
    var cryptoService: CryptoServiceMock!
    var fhirService: FhirService!
    var attachmentService: AttachmentServiceMock<Attachment>!

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        container.register(scope: .containerInstance) { (_) -> RecordServiceType in
            RecordServiceMock<Observation, DecryptedFhirStu3Record<Observation>>()
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

    func testCreateObservationResource() {
        let userId = UUID().uuidString
        let fixtureAttachment = FhirFactory.createAttachmentElement()
        let fixtureComponentAttachment1 = FhirFactory.createUploadedAttachmentElement()
        fixtureComponentAttachment1.id = nil
        let fixtureComponentAttachment2 = FhirFactory.createSampleImageAttachment()

        let fixtureComponent1 = FhirFactory.createObservationComponentResource(valueAttachment: fixtureComponentAttachment1)
        let fixtureComponent2 = FhirFactory.createObservationComponentResource(valueAttachment: fixtureComponentAttachment2)

        let fixtureObservation = FhirFactory.createObservationResource(valueAttachment: fixtureAttachment, components: [fixtureComponent1, fixtureComponent2])

        let additionalIds = [String]()

        let expectedObservation = fixtureObservation.copy() as! Observation // swiftlint:disable:this force_cast
        expectedObservation.allAttachments?.forEach { $0.attachmentId = UUID().uuidString }

        // We expect that result of the uploadAttachments method return the uploaded attachments with an Id
        let uploadAttachmentsResultWithId = expectedObservation.allAttachments!.compactMap {
            ($0.copy() as! Attachment) // swiftlint:disable:this force_cast
        }
        // We expect that the parameter of the uploadAttachments method pass the attachments without an Id
        let expectedAttachmentsWithoutId = fixtureObservation.allAttachments!.compactMap {
            ($0.copy() as! Attachment) // swiftlint:disable:this force_cast
        }

        expectedObservation.allAttachments?.forEach { $0.attachmentData = nil }

        let createdRecord = DecryptedRecordFactory.create(expectedObservation)
        expectedObservation.id = createdRecord.id
        fixtureObservation.id = createdRecord.id

        keychainService[.userId] = userId
        attachmentService.uploadAttachmentsResult = Async.resolve(uploadAttachmentsResultWithId.map { ($0, additionalIds) })
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.createRecordResult = Async.resolve(createdRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(fixtureObservation, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(expectedObservation, result.fhirResource, "The result doesn't match the expected resource")
                XCTAssertEqual(result.id, createdRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "The used attachment key is different from the generated one")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.first!,
                               expectedAttachmentsWithoutId.first!, "The uploaded attachment is different from the expected")

                XCTAssertEqual((self.recordService.createRecordCalledWith?.0.resource)?.allAttachments as? [Attachment], expectedObservation.allAttachments as? [Attachment])
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, expectedObservation, "The created record differs from the expected resource")
        }.onError { error in
            XCTFail(error.localizedDescription)
        }.finally {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCreateObservationResourceWithSameDataAttachments() {

        let userId = UUID().uuidString

        let observationAttachment = FhirFactory.createAttachmentElement()
        let observationComponentAttachment1 = FhirFactory.createAttachmentElement()
        let observationComponentAttachment2 = FhirFactory.createAttachmentElement()

        XCTAssertEqual(observationAttachment.attachmentData, observationComponentAttachment2.attachmentData)
        XCTAssertNotEqual(observationAttachment, observationComponentAttachment2)

        let observationComponent1 = FhirFactory.createObservationComponentResource(valueAttachment: observationComponentAttachment1)
        let observationComponent2 = FhirFactory.createObservationComponentResource(valueAttachment: observationComponentAttachment2)

        let observation = FhirFactory.createObservationResource(valueAttachment: observationAttachment,
                                                                components: [observationComponent1,
                                                                             observationComponent2])

        let additionalIds = [String]()

        let expectedObservation = observation.copy() as! Observation // swiftlint:disable:this force_cast
        expectedObservation.allAttachments?.forEach { $0.attachmentId = UUID().uuidString }

        // We expect that result of the uploadAttachments method return the uploaded attachments with an Id
        let uploadAttachmentsResult = expectedObservation.allAttachments!.compactMap {
            ($0.copy() as! Attachment) // swiftlint:disable:this force_cast
        }
        // We expect that the parameter of the uploadAttachments method pass the attachments without an Id
        let expectedAttachmentsWithoutId = observation.allAttachments!.compactMap {
            ($0.copy() as! Attachment) // swiftlint:disable:this force_cast
        }

        // expectedObservation.allAttachments?.forEach { $0.attachmentData = nil }

        let expectedRecord = DecryptedRecordFactory.create(expectedObservation)
        expectedObservation.id = expectedRecord.id
        observation.id = expectedRecord.id

        keychainService[.userId] = userId
        attachmentService.uploadAttachmentsResult = Async.resolve(uploadAttachmentsResult.map { ($0, additionalIds) })
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.createRecordResult = Async.resolve(expectedRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(observation, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(expectedObservation, result.fhirResource, "The result doesn't match the expected resource")
                XCTAssertEqual(expectedObservation.allAttachments as? [Attachment],
                               result.fhirResource.allAttachments as? [Attachment], "The result doesn't match the expected resource")
                XCTAssertEqual(result.id, expectedRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "The used attachment key is different from the generated one")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.first!,
                               expectedAttachmentsWithoutId.first!, "The uploaded attachment is different from the expected")

                XCTAssertEqual((self.recordService.createRecordCalledWith?.0.resource)?.allAttachments as? [Attachment],
                               observation.allAttachments as? [Attachment])
                XCTAssertEqual((self.recordService.createRecordCalledWith?.0.resource),
                               observation)
        }.onError { error in
            XCTFail(error.localizedDescription)
        }.finally {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCreateObservationResourceWithSomeComponentsWithoutAttachments() {

        let userId = UUID().uuidString
        let fixtureAttachment = FhirFactory.createAttachmentElement()
        let fixtureComponentAttachment1 = FhirFactory.createUploadedAttachmentElement()
        fixtureComponentAttachment1.id = nil
        let fixtureComponentAttachment2 = FhirFactory.createSampleImageAttachment()

        let fixtureComponent1 = FhirFactory.createObservationComponentResource(valueAttachment: fixtureComponentAttachment1)
        let fixtureComponent2 = FhirFactory.createObservationComponentResource(valueAttachment: fixtureComponentAttachment2)
        let fixtureComponent3 = FhirFactory.createObservationComponentResource(valueAttachment: nil)
        let fixtureObservation = FhirFactory.createObservationResource(valueAttachment: fixtureAttachment, components: [fixtureComponent1, fixtureComponent2, fixtureComponent3])

        let additionalIds = [String]()

        let expectedObservation = fixtureObservation.copy() as! Observation // swiftlint:disable:this force_cast
        expectedObservation.allAttachments?.forEach { $0.attachmentId = UUID().uuidString }

        // We expect that result of the uploadAttachments method return the uploaded attachments with an Id
        let uploadAttachmentsResultWithId = expectedObservation.allAttachments!.compactMap {
            ($0.copy() as! Attachment) // swiftlint:disable:this force_cast
        }
        // We expect that the parameter of the uploadAttachments method pass the attachments without an Id
        let expectedAttachmentsWithoutId = fixtureObservation.allAttachments!.compactMap {
            ($0.copy() as! Attachment) // swiftlint:disable:this force_cast
        }

        expectedObservation.allAttachments?.forEach { $0.attachmentData = nil }

        let createdRecord = DecryptedRecordFactory.create(expectedObservation)
        expectedObservation.id = createdRecord.id
        fixtureObservation.id = createdRecord.id

        keychainService[.userId] = userId
        attachmentService.uploadAttachmentsResult = Async.resolve(uploadAttachmentsResultWithId.map { ($0, additionalIds) })
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.createRecordResult = Async.resolve(createdRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(fixtureObservation, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(expectedObservation, result.fhirResource, "The result doesn't match the expected resource")
                XCTAssertEqual(result.id, createdRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "The used attachment key is different from the generated one")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.first!,
                               expectedAttachmentsWithoutId.first!, "The uploaded attachment is different from the expected")

                XCTAssertEqual((self.recordService.createRecordCalledWith?.0.resource)?.allAttachments as? [Attachment], expectedObservation.allAttachments as? [Attachment])
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, expectedObservation, "The created record differs from the expected resource")
        }.onError { error in
            XCTFail(error.localizedDescription)
        }.finally {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCreateObservationResourceWithoutAttachments() {
        let userId = UUID().uuidString
        let fhirResource = FhirFactory.createObservationResource()
        let record = DecryptedRecordFactory.create(fhirResource)
        fhirResource.id = record.id

        keychainService[.userId] = userId
        recordService.createRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
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

    func testCreateObservationResourceFailInvalidContentSize() {
        let userId = UUID().uuidString
        let fhirResource = FhirFactory.createObservationResource()
        let attachment = FhirFactory.createAttachmentElement()
        let blankData = [UInt8](repeating: 0x00, count: 21 * 1024 * 1024) // 21mb
        guard let currentData = attachment.getData() else { fatalError("Attachment should have data") }
        attachment.attachmentData = (currentData + blankData).base64EncodedString()
        fhirResource.valueAttachment = attachment
        let record = DecryptedRecordFactory.create(fhirResource)

        keychainService[.userId] = userId
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.createRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
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

    func testCreateObservationResourceFailInvalidContentType() {
        let userId = UUID().uuidString
        let attachment = FhirFactory.createAttachmentElement()
        let fhirResource = FhirFactory.createObservationResource(valueAttachment: attachment)
        attachment.attachmentData = Data([0x00]).base64EncodedString()

        keychainService[.userId] = userId
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
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

    func testUpdateObservationResource() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let attachment = FhirFactory.createAttachmentElement()
        let fhirResource = FhirFactory.createObservationResource(valueAttachment: attachment)
        fhirResource.id = resourceId

        let additionalIds = [String]()
        let record = DecryptedRecordFactory.create(fhirResource)
        let updatedResource = fhirResource.copy() as! Observation // swiftlint:disable:this force_cast
        updatedResource.allAttachments?.forEach { $0.attachmentData = nil }
        let updatedRecord = record.copy(with: updatedResource)

        keychainService[.userId] = userId
        let uploadedAttachment = attachment.copy() as! Attachment // swiftlint:disable:this force_cast
        uploadedAttachment.id = UUID().uuidString
        attachmentService.uploadAttachmentsResult = Async.resolve([(uploadedAttachment, additionalIds)])
        recordService.fetchRecordResult = Async.resolve(record)
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.updateRecordResult = Async.resolve(updatedRecord)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(result.fhirResource, updatedResource, "The result doesn't match the expected resource")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0.resource, fhirResource, "The updated record differs from the expected resource")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.2, userId, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.3, resourceId, "A param in the method doesn't match the expectation")
                XCTAssertNotNil(self.recordService.updateRecordCalledWith?.4, "A param in the method doesn't match the expectation")

                XCTAssertNil(result.fhirResource.allAttachments?.first?.attachmentData, "Data in the attachment is expected to be nil")

                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.first, attachment, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.0, resourceId, "A param in the method doesn't match the expectation")
        }.onError { error in
            XCTFail(error.localizedDescription)
        }.finally {
            asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testFailUpdateObservationResourceMissingId() {
        let userId = UUID().uuidString
        let fhirResource = FhirFactory.createObservationResource()
        let record = DecryptedRecordFactory.create(fhirResource)
        fhirResource.id = nil

        keychainService[.userId] = userId
        recordService.updateRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return an error")
        fhirService.updateFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
            .then { _ in
                XCTFail("Should throw an error")
        }.onError { error in
            XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.invalidResourceMissingId, "Expected error didn't happen")
        }.finally {
            asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testFailUpdateObservationInvalidContentType() {
        let userId = UUID().uuidString
        let attachment = FhirFactory.createAttachmentElement()
        attachment.attachmentData = Data([0x00]).base64EncodedString()
        let fhirResource = FhirFactory.createObservationResource(valueAttachment: attachment)
        let record = DecryptedRecordFactory.create(fhirResource)
        fhirResource.id = record.id

        keychainService[.userId] = userId
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.fetchRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
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

    func testFailUpdateObservationInvalidContentSize() {
        let userId = UUID().uuidString
        let attachment = FhirFactory.createAttachmentElement()
        let blankData = [UInt8](repeating: 0x00, count: 21 * 1024 * 1024) // 21mb
        guard let currentData = attachment.getData() else { fatalError("Attachment should have data") }
        attachment.attachmentData = (currentData + blankData).base64EncodedString()
        let fhirResource = FhirFactory.createObservationResource(valueAttachment: attachment)
        let record = DecryptedRecordFactory.create(fhirResource)
        fhirResource.id = record.id

        keychainService[.userId] = userId
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.fetchRecordResult = Async.resolve(record)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(fhirResource, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
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

    func testUpdateObservationExistingAttachment() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let attachment1Id = UUID().uuidString
        let attachment1 = FhirFactory.createAttachmentElement()
        let attachment2 = FhirFactory.createSampleImageAttachment()
        attachment1.id = attachment1Id
        attachment2.id = UUID().uuidString
        let component = FhirFactory.createObservationComponentResource(valueAttachment: attachment2)
        let fhirResource = FhirFactory.createObservationResource(valueAttachment: attachment1, components: [component])

        fhirResource.id = resourceId
        let record = DecryptedRecordFactory.create(fhirResource)

        let additionalIds = [String]()

        let updatedResource = fhirResource.copy() as! Observation // swiftlint:disable:this force_cast
        let newData = Data([0xFF, 0xD8, 0xFF, 0xDB, 0x01, 0x03, 0x03, 0x07, 0x01, 0x03, 0x03, 0x07])
        let updatedAttachment = updatedResource.allAttachments!.first! as? Attachment
        updatedAttachment!.attachmentData = newData.base64EncodedString()
        updatedAttachment!.attachmentHash = newData.sha1Hash
        updatedAttachment!.attachmentSize = newData.byteCount

        let newAttachment = FhirFactory.createAttachmentElement()
        let creationDate = DateTime.now
        newAttachment.creation = creationDate
        let newAttachmentWithId = FhirFactory.createAttachmentElement()
        let language = UUID().uuidString
        newAttachmentWithId.language = language
        let noneExistingId = UUID().uuidString
        newAttachmentWithId.id = noneExistingId

        updatedResource.valueAttachment = updatedAttachment
        let newComponent1 = FhirFactory.createObservationComponentResource(valueAttachment: newAttachment)
        let newComponent2 = FhirFactory.createObservationComponentResource(valueAttachment: newAttachmentWithId)

        updatedResource.component?.append(contentsOf: [newComponent1, newComponent2])

        let updatedRecord = record.copy(with: updatedResource)
        keychainService[.userId] = userId
        recordService.fetchRecordResult = Async.resolve(record)
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.updateRecordResult = Async.resolve(updatedRecord)
        attachmentService.uploadAttachmentsResults = [Async.resolve([
            (updatedAttachment!, additionalIds),
            (newAttachment, additionalIds),
            (newAttachmentWithId, additionalIds)])]

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(updatedResource, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0.resource, updatedResource, "The result doesn't match the expected resource")
                let attachments = self.attachmentService.uploadAttachmentsCalledWith!.0
                let newDataAtt = attachments.first(where: { $0.attachmentId == attachment1Id })
                let newAtt = attachments.first(where: { $0.creationDate == creationDate.nsDate })

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

    func testUpdateObservationWithSomeComponentsWithoutAttachments() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let attachment1Id = UUID().uuidString
        let attachment1 = FhirFactory.createAttachmentElement()
        let attachment2 = FhirFactory.createSampleImageAttachment()
        attachment1.id = attachment1Id
        attachment2.id = UUID().uuidString
        let component = FhirFactory.createObservationComponentResource(valueAttachment: attachment2)
        let component2 = FhirFactory.createObservationComponentResource(valueAttachment: nil)
        let component3 = FhirFactory.createObservationComponentResource(valueAttachment: nil)
        let fhirResource = FhirFactory.createObservationResource(valueAttachment: attachment1, components: [component2, component, component3])

        fhirResource.id = resourceId
        let record = DecryptedRecordFactory.create(fhirResource)

        let additionalIds = [String]()

        let updatedResource = fhirResource.copy() as! Observation // swiftlint:disable:this force_cast
        let newData = Data([0xFF, 0xD8, 0xFF, 0xDB, 0x01, 0x03, 0x03, 0x07, 0x01, 0x03, 0x03, 0x07])
        let updatedAttachment = updatedResource.allAttachments!.first! as? Attachment
        updatedAttachment?.attachmentData = newData.base64EncodedString()
        updatedAttachment?.attachmentHash = newData.sha1Hash
        updatedAttachment?.attachmentSize = newData.byteCount

        let newAttachment = FhirFactory.createAttachmentElement()
        let creationDate = DateTime.now
        newAttachment.creation = creationDate
        let newAttachmentWithId = FhirFactory.createAttachmentElement()
        let language = UUID().uuidString
        newAttachmentWithId.language = language
        let noneExistingId = UUID().uuidString
        newAttachmentWithId.id = noneExistingId

        updatedResource.valueAttachment = updatedAttachment
        let newComponent1 = FhirFactory.createObservationComponentResource(valueAttachment: newAttachment)
        let newComponent2 = FhirFactory.createObservationComponentResource(valueAttachment: newAttachmentWithId)

        updatedResource.component?.append(contentsOf: [newComponent1, newComponent2])

        let updatedRecord = record.copy(with: updatedResource)
        keychainService[.userId] = userId
        recordService.fetchRecordResult = Async.resolve(record)
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.updateRecordResult = Async.resolve(updatedRecord)
        attachmentService.uploadAttachmentsResults = [Async.resolve([
            (updatedAttachment!, additionalIds),
            (newAttachment, additionalIds),
            (newAttachmentWithId, additionalIds)])]

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(updatedResource, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
            .then { result in
                XCTAssertNotNil(result, "The result shouldn't be nil")
                XCTAssertEqual(self.recordService.updateRecordCalledWith?.0.resource, updatedResource, "The result doesn't match the expected resource")
                let attachments = self.attachmentService.uploadAttachmentsCalledWith!.0
                let newDataAtt = attachments.first(where: { $0.attachmentId == attachment1Id })
                let newAtt = attachments.first(where: { $0.creationDate == creationDate.nsDate })

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

    func testUpdateObservationAttachmentWrongAttachmentHash() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let attachment1Id = UUID().uuidString
        let attachment1 = FhirFactory.createAttachmentElement()
        let attachment2 = FhirFactory.createSampleImageAttachment()
        attachment1.id = attachment1Id
        attachment2.id = UUID().uuidString
        let component = FhirFactory.createObservationComponentResource(valueAttachment: attachment2)
        let fhirResource = FhirFactory.createObservationResource(valueAttachment: attachment1, components: [component])
        fhirResource.id = resourceId
        let record = DecryptedRecordFactory.create(fhirResource)

        let additionalIds = [String]()

        let updatedResource = fhirResource.copy() as! Observation // swiftlint:disable:this force_cast
        let newData = Data([0xFF, 0xD8, 0xFF, 0xDB, 0x01, 0x03, 0x03, 0x07, 0x01, 0x03, 0x03, 0x07])
        let updatedAttachment = updatedResource.allAttachments!.first! as? Attachment
        updatedAttachment!.attachmentData = newData.base64EncodedString()
        let newAttachment = FhirFactory.createAttachmentElement()
        newAttachment.hash = "brokenHash"
        let newAttachmentWithId = FhirFactory.createAttachmentElement()
        let language = UUID().uuidString
        newAttachmentWithId.language = language
        let noneExistingId = UUID().uuidString
        newAttachmentWithId.id = noneExistingId

        updatedResource.valueAttachment = updatedAttachment
        let newComponent1 = FhirFactory.createObservationComponentResource(valueAttachment: newAttachment)
        let newComponent2 = FhirFactory.createObservationComponentResource(valueAttachment: newAttachmentWithId)

        updatedResource.component?.append(contentsOf: [newComponent1, newComponent2])

        let updatedRecord = record.copy(with: updatedResource)
        keychainService[.userId] = userId
        recordService.fetchRecordResult = Async.resolve(record)
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)
        recordService.updateRecordResult = Async.resolve(updatedRecord)
        attachmentService.uploadAttachmentsResults = [Async.resolve([(updatedAttachment!, additionalIds)]),
                                                      Async.resolve([(newAttachment, additionalIds)]),
                                                      Async.resolve([(newAttachmentWithId, additionalIds)])]

        let asyncExpectation = expectation(description: "should return record")
        fhirService.updateFhirRecord(updatedResource, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
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
extension FhirStu3ServiceObservationTests {
    func testCreateObservationResourceWithAdditionalIds() {
        let partnerId = UUID().uuidString
        Resource.partnerId = partnerId

        let userId = UUID().uuidString
        let fixtureAttachment = FhirFactory.createAttachmentElement()
        let attachmentId = UUID().uuidString
        fixtureAttachment.id = attachmentId
        let fixtureResource = FhirFactory.createObservationResource(valueAttachment: fixtureAttachment, components: nil)

        let additionalPayloadsIds = ["addId1", "addId2"]
        let expectedAdditionalId = ["d4l_f_p_t#\(attachmentId)#\(additionalPayloadsIds[0])#\(additionalPayloadsIds[1])"]

        let expectedResource = fixtureResource.copy() as! Observation // swiftlint:disable:this force_cast
        expectedResource.setAdditionalIds(expectedAdditionalId)
        expectedResource.allAttachments?.forEach { $0.attachmentData = nil }

        let createdRecord = DecryptedRecordFactory.create(expectedResource)
        fixtureResource.id = createdRecord.id
        fixtureResource.id = createdRecord.id

        keychainService[.userId] = userId
        recordService.createRecordResult = Async.resolve(createdRecord)
        attachmentService.uploadAttachmentsResult = Async.resolve([(fixtureAttachment, additionalPayloadsIds)])
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)

        let asyncExpectation = expectation(description: "should return record with additional id")
        fhirService.createFhirRecord(fixtureResource, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
            .then { result in
                XCTAssertNotNil(result, "The result should be not nil")
                XCTAssertEqual(expectedResource, result.fhirResource, "The expected resource doesn't match the result of the test")
                XCTAssertEqual(result.id, createdRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "The used attachment key is different from the generated one")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.first, fixtureAttachment,
                               "The uploaded attachment is different from the expected")
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, expectedResource, "The created record differs from the expected resource")
                XCTAssertEqual(result.fhirResource.identifier!, expectedResource.identifier,  "The identifiers of the result differ from the expected resource exist")
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCreateObservationResourceWithoutThumbnailsIds() {
        let userId = UUID().uuidString
        let fixtureAttachment = FhirFactory.createAttachmentElement()
        let expectedAttachmentId = UUID().uuidString
        let fixtureResource = FhirFactory.createObservationResource(valueAttachment: fixtureAttachment, components: nil)

        let additionalIds = ["addId1"]
        let expectedAdditionalIds = [String]()

        let expectedResource = fixtureResource.copy() as! Observation // swiftlint:disable:this force_cast
        expectedResource.setAdditionalIds(expectedAdditionalIds)
        expectedResource.valueAttachment?.id = expectedAttachmentId

        let createdRecord = DecryptedRecordFactory.create(expectedResource)
        expectedResource.id = createdRecord.id
        fixtureResource.id = createdRecord.id

        let uploadedAttachment = fixtureAttachment.copy() as! Attachment // swiftlint:disable:this force_cast
        uploadedAttachment.id = expectedAttachmentId
        keychainService[.userId] = userId
        recordService.createRecordResult = Async.resolve(createdRecord)
        attachmentService.uploadAttachmentsResult = Async.resolve([(uploadedAttachment, additionalIds)])
        cryptoService.generateGCKeyResult = KeyFactory.createKey(.attachment)

        let asyncExpectation = expectation(description: "should return record")
        fhirService.createFhirRecord(fixtureResource, decryptedRecordType: DecryptedFhirStu3Record<Observation>.self)
            .then { result in
                XCTAssertNotNil(result, "The result should be not nil")
                XCTAssertEqual(expectedResource, result.fhirResource, "The expected resource doesn't match the result of the test")
                XCTAssertEqual(result.id, createdRecord.id, "The result id is different from the record id")
                XCTAssertEqual(self.cryptoService.generateGCKeyCalledWith, KeyType.attachment, "The used attachment key is different from the generated one")
                XCTAssertEqual(self.attachmentService.uploadAttachmentsCalledWith?.0.first, fixtureAttachment, "The uploaded attachment is different from the expected")
                XCTAssertEqual(self.recordService.createRecordCalledWith?.0.resource, fixtureResource, "The created record differs from the expected resource")
                XCTAssertEqual(result.fhirResource.identifier!, expectedResource.identifier, "The identifiers of the result differ from the expected resource exist")
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}

extension FhirStu3ServiceAttachmentOperationsTests {

    func testDownloadObservationResource() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let attachmentId = UUID().uuidString
        let attachment = FhirFactory.createAttachmentElement()
        attachment.id = attachmentId
        let fhirResource = FhirFactory.createObservationResource(valueAttachment: attachment, components: nil)

        fhirResource.id = resourceId
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
                XCTAssertEqual((result.fhirResource as? HasAttachments)?.allAttachments?.first as? Attachment, attachment, "The resource's attachment doesn't match the result of expected one")
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.0, resourceId, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.1, userId, "A param in the method doesn't match the expectation")
                XCTAssertNotNil(self.attachmentService.fetchAttachmentsCalledWith?.0.allAttachments, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.attachmentService.fetchAttachmentsCalledWith?.0.allAttachments as? [Attachment],
                               fhirResource.allAttachments as? [Attachment], "A param in the method doesn't match the expectation")
                XCTAssertEqual((self.attachmentService.fetchAttachmentsCalledWith?.0 as? HasIdentifiableAttachments)?.customIdentifiers as? [Identifier],
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

    func testDownloadObservationResourceWithoutAttachments() {
        let userId = UUID().uuidString
        let resourceId = UUID().uuidString
        let fhirResource = FhirFactory.createObservationResource()
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

    func testDownloadObservationResources() {
        let userId = UUID().uuidString
        let progress = Progress()

        let firstAttachmentId = UUID().uuidString
        let firstAttachment = FhirFactory.createAttachmentElement()
        firstAttachment.id = firstAttachmentId

        let firstResourceId = UUID().uuidString
        let firstResource = FhirFactory.createObservationResource(valueAttachment: firstAttachment, components: nil)
        firstResource.id = firstResourceId
        let firstRecord = DecryptedRecordFactory.create(firstResource as FhirStu3Resource)

        let secondAttachmentId = UUID().uuidString
        let secondAttachment = FhirFactory.createAttachmentElement()
        secondAttachment.id = secondAttachmentId

        let secondResourceId = UUID().uuidString
        let secondResource = FhirFactory.createObservationResource(valueAttachment: secondAttachment, components: nil)
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
                XCTAssertEqual((result.success.first?.fhirResource as? HasAttachments)?.allAttachments?.first as? Attachment, firstAttachment, "The expected attachment doesn't match the expected one")
                XCTAssertEqual((result.success.first?.fhirResource as? HasAttachments)?.allAttachments?.first as? Attachment, firstAttachment, "The expected attachment doesn't match the expected one")
                XCTAssertEqual(result.failed.first?.object, secondResourceId, "The expected resource was expected to fail")

                XCTAssertNotNil(self.attachmentService.fetchAttachmentsCalledWith?.0.allAttachments, "A param in the method doesn't match the expectation")
                XCTAssertEqual(self.attachmentService.fetchAttachmentsCalledWith?.0.allAttachments as? [Attachment],
                               firstResource.allAttachments as? [Attachment], "A param in the method doesn't match the expectation")
                XCTAssertEqual((self.attachmentService.fetchAttachmentsCalledWith?.0 as? HasIdentifiableAttachments)?.customIdentifiers as? [Identifier],
                               firstResource.identifier, "A param in the method doesn't match the expectation")

        }.onError { error in
            XCTFail(error.localizedDescription)
        }.finally {
            asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
} // swiftlint:disable:this file_length
