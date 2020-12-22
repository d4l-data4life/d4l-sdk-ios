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
import Then
import ModelsR4

class FhirR4ServiceAttachmentOperationsTests: XCTestCase {

    var recordService: RecordServiceMock<FhirR4Resource, DecryptedFhirR4Record<FhirR4Resource>>!
    var keychainService: KeychainServiceMock!
    var cryptoService: CryptoServiceMock!
    var fhirService: FhirService!
    var attachmentService: AttachmentServiceMock!

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        container.register(scope: .containerInstance) { (_) -> RecordServiceType in
            RecordServiceMock<FhirR4Resource, DecryptedFhirR4Record<FhirR4Resource>>()
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

    func testDownloadDocumentReferenceAttachment() {
        let progress = Progress()
        let userId = UUID().uuidString
        let attachmentId = UUID().uuidString
        let attachment = FhirFactory.createR4AttachmentElement()
        attachment.id = attachmentId.asFHIRStringPrimitive()
        let recordId = UUID().uuidString
        let documentReference = FhirFactory.createR4DocumentReferenceResource(with: [attachment])
        documentReference.id = recordId.asFHIRStringPrimitive()
        let record = DecryptedRecordFactory.create(documentReference as FhirR4Resource)
        documentReference.id = record.id.asFHIRStringPrimitive()
        let expectedDownloadType: DownloadType = .full

        keychainService[.userId] = userId
        recordService.fetchRecordResult = Promise.resolve(record)
        attachmentService.fetchAttachmentsResult = Promise.resolve([attachment])

        let asyncExpectation = expectation(description: "should return a resource")
        fhirService.downloadAttachment(of: ModelsR4.Attachment.self,
                                       decryptedRecordType: DecryptedFhirR4Record<FhirR4Resource>.self,
                                       withId: attachmentId,
                                       recordId: record.id,
                                       downloadType: .full,
                                       parentProgress: progress)
            .then { result in
                XCTAssertNotNil(result)
                XCTAssertEqual(result.id?.value?.string, attachmentId)
                XCTAssertEqual(attachment, result)

                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.0, recordId)
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.1, userId)

                XCTAssertNotNil(self.attachmentService.fetchAttachmentsCalledWith?.0.allAttachments)
                XCTAssertEqual(self.attachmentService.fetchAttachmentsCalledWith?.0.allAttachments as? [ModelsR4.Attachment], documentReference.allAttachments as? [ModelsR4.Attachment])
                XCTAssertEqual((self.attachmentService.fetchAttachmentsCalledWith?.0 as? CustomIdentifierProtocol)?.customIdentifiers as? [ModelsR4.Identifier],
                               documentReference.identifier)

                XCTAssertEqual(self.attachmentService.fetchAttachmentsCalledWith?.1, [attachmentId])
                XCTAssertEqual(self.attachmentService.fetchAttachmentsCalledWith?.2, expectedDownloadType)
                XCTAssertEqual(self.attachmentService.fetchAttachmentsCalledWith?.3, record.attachmentKey)
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testDownloadPatientAttachment() {
        let progress = Progress()
        let userId = UUID().uuidString
        let attachmentId = UUID().uuidString
        let attachment = FhirFactory.createR4AttachmentElement()
        attachment.id = attachmentId.asFHIRStringPrimitive()
        let recordId = UUID().uuidString
        let fixturePatient = FhirFactory.createR4PatientResource(with: [attachment])
        fixturePatient.id = recordId.asFHIRStringPrimitive()
        let record = DecryptedRecordFactory.create(fixturePatient as FhirR4Resource)
        fixturePatient.id = record.id.asFHIRStringPrimitive()
        let expectedDownloadType: DownloadType = .full

        keychainService[.userId] = userId
        recordService.fetchRecordResult = Promise.resolve(record)
        attachmentService.fetchAttachmentsResult = Promise.resolve([attachment])

        let asyncExpectation = expectation(description: "should return a resource")
        fhirService.downloadAttachment(of: ModelsR4.Attachment.self,
                                       decryptedRecordType: DecryptedFhirR4Record<FhirR4Resource>.self,
                                       withId: attachmentId,
                                       recordId: record.id,
                                       downloadType: .full,
                                       parentProgress: progress)
            .then { result in
                XCTAssertNotNil(result)
                XCTAssertEqual(result.id?.value?.string, attachmentId)
                XCTAssertEqual(attachment, result)

                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.0, recordId)
                XCTAssertEqual(self.recordService.fetchRecordCalledWith?.1, userId)

                XCTAssertNotNil(self.attachmentService.fetchAttachmentsCalledWith?.0.allAttachments)
                XCTAssertEqual(self.attachmentService.fetchAttachmentsCalledWith?.0.allAttachments as? [ModelsR4.Attachment], fixturePatient.allAttachments as? [ModelsR4.Attachment])
                XCTAssertEqual((self.attachmentService.fetchAttachmentsCalledWith?.0 as? CustomIdentifierProtocol)?.customIdentifiers as? [ModelsR4.Identifier],
                               fixturePatient.identifier)

                XCTAssertEqual(self.attachmentService.fetchAttachmentsCalledWith?.1, [attachmentId])
                XCTAssertEqual(self.attachmentService.fetchAttachmentsCalledWith?.2, expectedDownloadType)
                XCTAssertEqual(self.attachmentService.fetchAttachmentsCalledWith?.3, record.attachmentKey)
            }.onError { error in
                XCTFail(error.localizedDescription)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testDownloadNonExistingAttachment() {
        let progress = Progress()
        let userId = UUID().uuidString
        let recordId = UUID().uuidString
        let attachmentId = UUID().uuidString

        let documentReference = FhirFactory.createR4DocumentReferenceResource()
        documentReference.id = recordId.asFHIRStringPrimitive()
        let record = DecryptedRecordFactory.create(documentReference as FhirR4Resource, attachmentKey: nil)
        documentReference.id = record.id.asFHIRStringPrimitive()

        keychainService[.userId] = userId
        recordService.fetchRecordResult = Promise.resolve(record)

        let asyncExpectation = expectation(description: "should fail loading attachment")
        fhirService.downloadAttachment(of: Data4LifeFHIR.Attachment.self,
                                       decryptedRecordType: DecryptedFhirR4Record<FhirR4Resource>.self,
                                       withId: attachmentId,
                                       recordId: record.id,
                                       downloadType: .full,
                                       parentProgress: progress)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.couldNotFindAttachment)
            }.finally {
                asyncExpectation.fulfill()
            }
        waitForExpectations(timeout: 5)
    }

    func testDownloadWrongAttachment() {
        let userId = UUID().uuidString
        let progress = Progress()

        let firstAttachmentId = UUID().uuidString
        let firstAttachment = FhirFactory.createR4AttachmentElement()
        firstAttachment.id = firstAttachmentId.asFHIRStringPrimitive()

        let secondAttachmentId = UUID().uuidString
        let secondAttachment = FhirFactory.createR4AttachmentElement()
        secondAttachment.id = secondAttachmentId.asFHIRStringPrimitive()

        let recordId = UUID().uuidString
        let documentReference = FhirFactory.createR4DocumentReferenceResource(with: [firstAttachment, secondAttachment])
        documentReference.id = recordId.asFHIRStringPrimitive()

        let record = DecryptedRecordFactory.create(documentReference as FhirR4Resource)
        documentReference.id = record.id.asFHIRStringPrimitive()

        keychainService[.userId] = userId
        recordService.fetchRecordResult = Promise.resolve(record)
        attachmentService.fetchAttachmentsResult = Promise.resolve([secondAttachment])

        let asyncExpectation = expectation(description: "should fail loading attachment")
        fhirService.downloadAttachment(of: Data4LifeFHIR.Attachment.self,
                                       decryptedRecordType: DecryptedFhirR4Record<FhirR4Resource>.self,
                                       withId: firstAttachmentId,
                                       recordId: record.id,
                                       downloadType: .full,
                                       parentProgress: progress)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.couldNotFindAttachment)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testDownloadAttachmentWasCancelled() {
        let userId = UUID().uuidString
        let progress = Progress()

        let firstAttachmentId = UUID().uuidString
        let firstAttachment = FhirFactory.createR4AttachmentElement()
        firstAttachment.id = firstAttachmentId.asFHIRStringPrimitive()

        let secondAttachmentId = UUID().uuidString
        let secondAttachment = FhirFactory.createR4AttachmentElement()
        secondAttachment.id = secondAttachmentId.asFHIRStringPrimitive()

        let recordId = UUID().uuidString
        let documentReference = FhirFactory.createR4DocumentReferenceResource(with: [firstAttachment, secondAttachment])
        documentReference.id = recordId.asFHIRStringPrimitive()

        let record = DecryptedRecordFactory.create(documentReference as FhirR4Resource)
        documentReference.id = record.id.asFHIRStringPrimitive()

        keychainService[.userId] = userId
        recordService.fetchRecordResult = Promise.resolve(record)

        let urlError = URLError.init(.cancelled)
        attachmentService.fetchAttachmentsResult = Promise.reject(urlError)

        let asyncExpectation = expectation(description: "Should throw error cancelled download")

        fhirService.downloadAttachment(of: Data4LifeFHIR.Attachment.self,
                                       decryptedRecordType: DecryptedFhirR4Record<FhirR4Resource>.self,
                                       withId: firstAttachmentId,
                                       recordId: record.id,
                                       downloadType: .full,
                                       parentProgress: progress)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, Data4LifeSDKError.downloadActionWasCancelled)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }
}
