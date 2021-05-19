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
import Alamofire
import Combine
import Data4LifeFHIR

final class RecordServiceTests: XCTestCase { // swiftlint:disable:this type_body_length

    private(set) var encryptedRecordFactory: EncryptedRecordFactory!

    var recordService: RecordService!
    var keychain: KeychainServiceMock!
    var versionValidator: SDKVersionValidatorMock!
    var sessionService: SessionService!
    var cryptoService: CryptoServiceMock!
    var commonKeyService: CommonKeyServiceMock!
    var taggingService: TaggingServiceMock!
    var userService: UserServiceMock!
    var builder: RecordServiceParameterBuilderMock!

    var encoder: JSONEncoder!

    let commonKey = KeyFactory.createKey()
    let tagEncryptionKey = KeyFactory.createKey()
    let commonKeyId = UUID().uuidString

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        recordService = RecordService(container: container)

        do {
            versionValidator = try container.resolve(as: SDKVersionValidatorType.self)
            keychain = try container.resolve(as: KeychainServiceType.self)
            sessionService = try container.resolve()
            taggingService = try container.resolve(as: TaggingServiceType.self)
            cryptoService = try container.resolve(as: CryptoServiceType.self)
            commonKeyService = try container.resolve(as: CommonKeyServiceType.self)
            userService = try container.resolve(as: UserServiceType.self)
            builder = try container.resolve(as: RecordServiceParameterBuilderProtocol.self)
            encryptedRecordFactory = try container.resolve()
        } catch {
            XCTFail(error.localizedDescription)
        }

        Router.baseUrl = "http://example.com"

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(.with(format: .iso8601TimeZone))

        cryptoService.tagEncryptionKey = tagEncryptionKey
        commonKeyService.fetchKeyResult = Just(commonKey).asyncFuture
        versionValidator.fetchCurrentVersionStatusResult = Just(.supported).asyncFuture
    }

    func testCreateFhirStu3Record() {
        let userId = UUID().uuidString

        let resource = FhirFactory.createStu3DocumentReferenceResource()
        var record = DecryptedRecordFactory.create(resource)
        let annotations = ["example-annotation1"]
        record.annotations = annotations
        var encryptedRecord = encryptedRecordFactory.create(for: record, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        userService.fetchUserInfoResult = Just(()).asyncFuture

        // Common key
        commonKeyService.currentId = commonKeyId
        commonKeyService.currentKey = commonKey

        // encrypted body
        cryptoService.encryptValueResult = Just(encryptedRecord.encryptedBodyData).asyncFuture

        // encrypted tags
        taggingService.tagResourceResult = TagGroup(tags: record.tags, annotations: record.annotations)
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData, encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData, encryptedRecord.encryptedBodyData)

        let inputs = [dataInput, bodyInput]

        cryptoService.generateGCKeyResult = record.dataKey
        cryptoService.encryptDataForInput = inputs
        cryptoService.decryptDataForInput = inputs

        stub("POST", "/users/\(userId)/records", with: encryptedRecord.data)

        let asyncExpectation = expectation(description: "should create record")
        let createdRecord: SDKFuture<DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>> = recordService.createRecord(forResource: resource, annotations: annotations, userId: userId)
        createdRecord.then { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNotNil(result)
            XCTAssertNotNil(result.resource)

            XCTAssertEqual(result.id, record.id)
            XCTAssertEqual(result.metadata.updatedDate.ISO8601FormattedString(),
                           record.metadata.updatedDate.ISO8601FormattedString())
            XCTAssertEqual(result.tags, record.tags)
            XCTAssertEqual(result.dataKey, record.dataKey)

            XCTAssertTrue(self.userService.fetchUserInfoCalled)
            XCTAssertEqual(result.resource, resource)

            XCTAssertEqual(self.taggingService.tagResourceCalledWith?.2, annotations)
            XCTAssertEqual(result.annotations, annotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateFhirStu3RecordWithAttachment() {
        let userId = UUID().uuidString
        let oldDocument = FhirFactory.createStu3DocumentReferenceResource()
        let oldRecord = DecryptedRecordFactory.create(oldDocument)
        oldDocument.id = oldRecord.id
        var oldEncryptedRecord = encryptedRecordFactory.create(for: oldRecord, commonKeyId: commonKeyId)
        oldEncryptedRecord.encryptedAttachmentKey = nil
        let document = oldDocument.copy() as! Data4LifeFHIR.DocumentReference // swiftlint:disable:this force_cast
        let updatedTitle = UUID().uuidString
        document.description_fhir = updatedTitle
        var record = DecryptedRecordFactory.create(document)
        record.id = oldRecord.id
        let encryptedRecord = encryptedRecordFactory.create(for: record)

        stub("GET", "/users/\(userId)/records/\(oldRecord.id)", with: oldEncryptedRecord.data)

        userService.fetchUserInfoResult = Just(()).asyncFuture

        // Common key
        commonKeyService.currentId = commonKeyId
        commonKeyService.currentKey = commonKey

        // encrypted body
        cryptoService.encryptValueResult = Just(encryptedRecord.encryptedBodyData).asyncFuture

        // encrypted tags
        taggingService.tagResourceResult = TagGroup(tags: record.tags, annotations: record.annotations)
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        cryptoService.generateGCKeyResult = record.dataKey
        // decrypt values for data key and body
        let attachmentInput: (Data?, Data?) = (encryptedRecord.encryptedAttachmentKeyData,
                                               encryptedRecord.encryptedAttachmentKeyData)
        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData,
                                       encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData,
                                       encryptedRecord.encryptedBodyData)

        let oldDataInput: (Data, Data) = (oldEncryptedRecord.encryptedDataKeyData,
                                          oldEncryptedRecord.encryptedDataKeyData)
        let oldBodyInput: (Data, Data) = (oldEncryptedRecord.encryptedBodyData,
                                          oldEncryptedRecord.encryptedBodyData)

        let inputs = [dataInput, bodyInput, oldDataInput, oldBodyInput, attachmentInput]
        cryptoService.encryptDataForInput = inputs
        cryptoService.decryptDataForInput = inputs

        stub("PUT", "/users/\(userId)/records/\(record.id)", with: encryptedRecord.data)

        let asyncExpectation = expectation(description: "should update record")
        let updatedRecord: SDKFuture<DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>> = recordService.updateRecord(forResource: document,
                                                                                                            userId: userId,
                                                                                                          recordId: record.id,
                                                                                                          attachmentKey: record.attachmentKey)
        updatedRecord.then { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNotNil(result)
            XCTAssertEqual(result.id, record.id)
            XCTAssertEqual(result.metadata.updatedDate.ISO8601FormattedString(), record.metadata.updatedDate.ISO8601FormattedString())
            XCTAssertEqual(result.tags, record.tags)
            XCTAssertEqual(result.dataKey, record.dataKey)
            XCTAssertEqual(result.attachmentKey, result.attachmentKey)
            XCTAssertEqual(result.annotations, record.annotations)

            XCTAssertTrue(self.userService.fetchUserInfoCalled)
            XCTAssertEqual(result.resource, document)
            XCTAssertNotEqual(result.resource.description_fhir, oldDocument.description_fhir)
            XCTAssertEqual(result.resource.description_fhir, updatedTitle)

            XCTAssertEqual(self.taggingService.tagResourceCalledWith?.2, result.annotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateFhirStu3RecordWithAttachmentMaintainingOldAnnotations() {
        let userId = UUID().uuidString
        let oldDocument = FhirFactory.createStu3DocumentReferenceResource()
        var oldRecord = DecryptedRecordFactory.create(oldDocument)
        let oldAnnotations = ["old-annotation"]
        oldRecord.annotations = oldAnnotations
        oldDocument.id = oldRecord.id
        var oldEncryptedRecord = encryptedRecordFactory.create(for: oldRecord, commonKeyId: commonKeyId)
        oldEncryptedRecord.encryptedAttachmentKey = nil
        let document = oldDocument.copy() as! Data4LifeFHIR.DocumentReference // swiftlint:disable:this force_cast
        let updatedTitle = UUID().uuidString
        document.description_fhir = updatedTitle
        var record = DecryptedRecordFactory.create(document)
        record.annotations = oldAnnotations
        record.id = oldRecord.id
        let encryptedRecord = encryptedRecordFactory.create(for: record)

        stub("GET", "/users/\(userId)/records/\(oldRecord.id)", with: oldEncryptedRecord.data)

        userService.fetchUserInfoResult = Just(()).asyncFuture

        // Common key
        commonKeyService.currentId = commonKeyId
        commonKeyService.currentKey = commonKey

        // encrypted body
        cryptoService.encryptValueResult = Just(encryptedRecord.encryptedBodyData).asyncFuture

        // encrypted tags
        taggingService.tagResourceResult = TagGroup(tags: record.tags, annotations: record.annotations)
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        cryptoService.generateGCKeyResult = record.dataKey

        // decrypt values for data key and body
        let attachmentInput: (Data?, Data?) = (encryptedRecord.encryptedAttachmentKeyData,
                                               encryptedRecord.encryptedAttachmentKeyData)
        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData,
                                       encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData,
                                       encryptedRecord.encryptedBodyData)

        let oldDataInput: (Data, Data) = (oldEncryptedRecord.encryptedDataKeyData,
                                          oldEncryptedRecord.encryptedDataKeyData)
        let oldBodyInput: (Data, Data) = (oldEncryptedRecord.encryptedBodyData,
                                          oldEncryptedRecord.encryptedBodyData)

        let inputs = [dataInput, bodyInput, oldDataInput, oldBodyInput, attachmentInput]
        cryptoService.encryptDataForInput = inputs
        cryptoService.decryptDataForInput = inputs

        stub("PUT", "/users/\(userId)/records/\(record.id)", with: encryptedRecord.data)

        let asyncExpectation = expectation(description: "should update record")
        let updatedRecord: SDKFuture<DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>> = recordService.updateRecord(forResource: document,
                                                                                                          userId: userId,
                                                                                                          recordId: record.id,
                                                                                                          attachmentKey: record.attachmentKey)
        updatedRecord.then { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNotNil(result)
            XCTAssertEqual(result.id, record.id)
            XCTAssertEqual(result.metadata.updatedDate.ISO8601FormattedString(), record.metadata.updatedDate.ISO8601FormattedString())
            XCTAssertEqual(result.tags, record.tags)
            XCTAssertEqual(result.dataKey, record.dataKey)
            XCTAssertEqual(result.attachmentKey, result.attachmentKey)
            XCTAssertEqual(result.annotations, oldAnnotations)

            XCTAssertTrue(self.userService.fetchUserInfoCalled)
            XCTAssertEqual(result.resource, document)
            XCTAssertNotEqual(result.resource.description_fhir, oldDocument.description_fhir)
            XCTAssertEqual(result.resource.description_fhir, updatedTitle)

            XCTAssertEqual(self.taggingService.tagResourceCalledWith?.2, oldAnnotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateFhirStu3RecordWithAttachmentUpdatingAnnotations() {
        let userId = UUID().uuidString
        let oldDocument = FhirFactory.createStu3DocumentReferenceResource()
        var oldRecord = DecryptedRecordFactory.create(oldDocument)
        let oldAnnotations = ["old-annotation"]
        oldRecord.annotations = oldAnnotations
        oldDocument.id = oldRecord.id
        var oldEncryptedRecord = encryptedRecordFactory.create(for: oldRecord, commonKeyId: commonKeyId)
        oldEncryptedRecord.encryptedAttachmentKey = nil
        let document = oldDocument.copy() as! Data4LifeFHIR.DocumentReference // swiftlint:disable:this force_cast
        let updatedTitle = UUID().uuidString
        document.description_fhir = updatedTitle
        let annotations = ["new-annotation"]
        var record = DecryptedRecordFactory.create(document)
        record.annotations = annotations
        record.id = oldRecord.id
        let encryptedRecord = encryptedRecordFactory.create(for: record)

        stub("GET", "/users/\(userId)/records/\(oldRecord.id)", with: oldEncryptedRecord.data)

        userService.fetchUserInfoResult = Just(()).asyncFuture

        // Common key
        commonKeyService.currentId = commonKeyId
        commonKeyService.currentKey = commonKey

        // encrypted body
        cryptoService.encryptValueResult = Just(encryptedRecord.encryptedBodyData).asyncFuture

        // encrypted tags
        taggingService.tagResourceResult = TagGroup(tags: record.tags, annotations: record.annotations)
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        cryptoService.generateGCKeyResult = record.dataKey
        // decrypt values for data key and body
        let attachmentInput: (Data?, Data?) = (encryptedRecord.encryptedAttachmentKeyData,
                                               encryptedRecord.encryptedAttachmentKeyData)
        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData,
                                       encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData,
                                       encryptedRecord.encryptedBodyData)

        let oldDataInput: (Data, Data) = (oldEncryptedRecord.encryptedDataKeyData,
                                          oldEncryptedRecord.encryptedDataKeyData)
        let oldBodyInput: (Data, Data) = (oldEncryptedRecord.encryptedBodyData,
                                          oldEncryptedRecord.encryptedBodyData)

        let inputs = [dataInput, bodyInput, oldDataInput, oldBodyInput, attachmentInput]
        cryptoService.encryptDataForInput = inputs
        cryptoService.decryptDataForInput = inputs

        stub("PUT", "/users/\(userId)/records/\(record.id)", with: encryptedRecord.data)

        let asyncExpectation = expectation(description: "should update record")
        let updatedRecord: SDKFuture<DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>> = recordService.updateRecord(forResource: document,
                                                                                                          annotations: annotations,
                                                                                                          userId: userId,
                                                                                                          recordId: record.id,
                                                                                                          attachmentKey: record.attachmentKey)
        updatedRecord.then { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNotNil(result)
            XCTAssertEqual(result.id, record.id)
            XCTAssertEqual(result.metadata.updatedDate.ISO8601FormattedString(), record.metadata.updatedDate.ISO8601FormattedString())
            XCTAssertEqual(result.tags, record.tags)
            XCTAssertEqual(result.dataKey, record.dataKey)
            XCTAssertEqual(result.attachmentKey, result.attachmentKey)
            XCTAssertEqual(result.annotations, record.annotations)

            XCTAssertTrue(self.userService.fetchUserInfoCalled)
            XCTAssertEqual(result.resource, document)
            XCTAssertNotEqual(result.resource.description_fhir, oldDocument.description_fhir)
            XCTAssertEqual(result.resource.description_fhir, updatedTitle)

            XCTAssertEqual(self.taggingService.tagResourceCalledWith?.2, annotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchFhirStu3Record() {
        let userId = UUID().uuidString

        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document, dataKey: commonKey)
        var encryptedRecord = encryptedRecordFactory.create(for: record, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        // Common key
        commonKeyService.fetchKeyResult = Just(commonKey).asyncFuture

        // encrypted body
        cryptoService.encryptValueResult = Just(encryptedRecord.encryptedBodyData).asyncFuture

        // encrypted tags
        taggingService.tagResourceResult = TagGroup(tags: record.tags, annotations: record.annotations)
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        // encrypted data key
        cryptoService.encryptDataResult = encryptedRecord.encryptedDataKeyData
        cryptoService.generateGCKeyResult = record.dataKey

        // decrypt values for data key and body
        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData, encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData, encryptedRecord.encryptedBodyData)
        cryptoService.decryptDataForInput = [dataInput, bodyInput]

        stub("GET", "/users/\(userId)/records/\(record.id)", with: encryptedRecord.data)

        let asyncExpectation = expectation(description: "should return a record")
        recordService.fetchRecord(recordId: record.id, userId: userId, decryptedRecordType: DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>.self)
            .then { record in
                defer { asyncExpectation.fulfill() }

                XCTAssertNotNil(record)
                XCTAssertEqual(record.id, record.id)
                XCTAssertEqual(record.metadata.updatedDate, record.metadata.updatedDate)
                XCTAssertEqual(record.tags, record.tags)
                XCTAssertEqual(record.dataKey, record.dataKey)
                XCTAssertEqual(record.attachmentKey, record.attachmentKey)
            }

        waitForExpectations(timeout: 5)
    }

    func testSearchFhirStu3RecordsWithNonPercentEncodableTags() {
        let annotations = ["exampleannotation1"]
        let userId = UUID().uuidString
        let startDate = Date()
        let endDate = Date()
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document, annotations: annotations)
        var encryptedRecord = encryptedRecordFactory.create(for: record, resource: document, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        taggingService.tagTypeResult = TagGroup(tags: ["resourcetype": "documentreference"], annotations: annotations)
        taggingService.tagResourceResult = TagGroup(tags: record.tags, annotations: record.annotations)
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        // Common key
        commonKeyService.fetchKeyResult = Just(commonKey).asyncFuture

        // encrypted body
        cryptoService.encryptValueResult = Just(encryptedRecord.encryptedBodyData).asyncFuture

        // encrypted data key
        cryptoService.encryptDataResult = encryptedRecord.encryptedDataKeyData
        cryptoService.generateGCKeyResult = record.dataKey

        // decrypt values for data key and body
        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData, encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData, encryptedRecord.encryptedBodyData)
        cryptoService.decryptDataForInput = [dataInput, bodyInput]

        stub("GET", "/users/\(userId)/records", with: [encryptedRecord.json])

        let asyncExpectation = expectation(description: "should return a list of records")
        recordService.searchRecords(for: userId,
                                    from: startDate,
                                    to: endDate,
                                    pageSize: 10,
                                    offset: 0,
                                    annotations: annotations,
                                    decryptedRecordType: DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>.self)
            .then { records in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(records.count, 1)
                XCTAssertEqual(record.resource, document)

                XCTAssertEqual(self.taggingService.tagTypeCalledWith?.1, annotations)
                XCTAssertEqual(record.annotations, annotations)
            }

        waitForExpectations(timeout: 5)
    }

    func testSearchFhirStu3RecordsWithPercentEncodableTags() {
        let annotations = ["example-annotation1"]
        let userId = UUID().uuidString
        let startDate = Date()
        let endDate = Date()
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document, annotations: annotations)
        var encryptedRecord = encryptedRecordFactory.create(for: record, resource: document, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        taggingService.tagTypeResult = TagGroup(tags: ["resourcetype": "documentreference"], annotations: annotations)
        taggingService.tagResourceResult = TagGroup(tags: record.tags, annotations: record.annotations)
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        // Common key
        commonKeyService.fetchKeyResult = Just(commonKey).asyncFuture

        // encrypted body
        cryptoService.encryptValueResult = Just(encryptedRecord.encryptedBodyData).asyncFuture

        // encrypted data key
        cryptoService.encryptDataResult = encryptedRecord.encryptedDataKeyData
        cryptoService.generateGCKeyResult = record.dataKey

        // decrypt values for data key and body
        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData, encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData, encryptedRecord.encryptedBodyData)
        cryptoService.decryptDataForInput = [dataInput, bodyInput]

        stub("GET", "/users/\(userId)/records", with: [encryptedRecord.json])

        let asyncExpectation = expectation(description: "should return a list of records")
        recordService.searchRecords(for: userId,
                                    from: startDate,
                                    to: endDate,
                                    pageSize: 10,
                                    offset: 0,
                                    annotations: annotations,
                                    decryptedRecordType: DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>.self)
            .then { records in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(records.count, 1)
                XCTAssertEqual(record.resource, document)

                XCTAssertEqual(self.taggingService.tagTypeCalledWith?.1, annotations)
                XCTAssertEqual(record.annotations, annotations)
            }

        waitForExpectations(timeout: 5)
    }

    func testSearchFhirStu3NoResults() {
        let userId = UUID().uuidString
        let startDate = Date()
        let endDate = Date()
        stub("GET", "/users/\(userId)/records", with: [])

        taggingService.tagTypeResult = TagGroup(tags: [:])
        cryptoService.encryptValuesResult = []
        cryptoService.decryptValuesResult = []

        let asyncExpectation = expectation(description: "should return an empty list of records")
        recordService.searchRecords(for: userId,
                                    from: startDate,
                                    to: endDate,
                                    pageSize: 10,
                                    offset: 0,
                                    decryptedRecordType: DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>.self)
            .then { records in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(records.count, 0)
            }

        waitForExpectations(timeout: 5)
    }

    func testCountFhirStu3RecordsWithNonPercentEncodableTags() {
        let annotations = ["exampleannotation1"]
        let userId = UUID().uuidString
        let recordCount = 101

        stub("HEAD", "/users/\(userId)/records", with: Data(), headers: ["x-total-count" : "\(recordCount)"], code: 200)

        taggingService.tagTypeResult = TagGroup(tags: [:], annotations: annotations)
        cryptoService.encryptValuesResult = []
        cryptoService.decryptValuesResult = []

        let asyncExpectation = expectation(description: "should return header containg record count")
        recordService.countRecords(userId: userId, resourceType: Data4LifeFHIR.DocumentReference.self, annotations: annotations)
            .then { count in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(count, recordCount)
                XCTAssertEqual(self.taggingService.tagTypeCalledWith?.1, annotations)
            }

        waitForExpectations(timeout: 5)
    }

    func testCountFhirStu3RecordsWithPercentEncodableTags() {
        let annotations = ["example-annotation1"]
        let userId = UUID().uuidString
        let recordCount = 101

        stub("HEAD", "/users/\(userId)/records", with: Data(), headers: ["x-total-count" : "\(recordCount)"], code: 200)

        taggingService.tagTypeResult = TagGroup(tags: [:], annotations: annotations)
        cryptoService.encryptValuesResult = []
        cryptoService.decryptValuesResult = []

        let asyncExpectation = expectation(description: "should return header containg record count")
        recordService.countRecords(userId: userId, resourceType: Data4LifeFHIR.DocumentReference.self, annotations: annotations)
            .then { count in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(count, recordCount)
                XCTAssertEqual(self.taggingService.tagTypeCalledWith?.1, annotations)
            }

        waitForExpectations(timeout: 5)
    }

    func testCountFhirStu3RecordsFail() {
        let userId = UUID().uuidString
        let expectedError = Data4LifeSDKError.keyMissingInSerialization(key: "`x-total-count`")

        stub("HEAD", "/users/\(userId)/records", with: Data(), headers: ["x-count" : "\(0)"], code: 200)

        taggingService.tagTypeResult = TagGroup(tags: [:])
        cryptoService.encryptValuesResult = []
        cryptoService.decryptValuesResult = []

        let asyncExpectation = expectation(description: "should fail counting records")
        recordService.countRecords(userId: userId, resourceType: Data4LifeFHIR.DocumentReference.self)
            .then { _ in
                XCTFail("Should return an error")
            } onError: { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testDeleteRecord() {
        let recordId = UUID().uuidString
        let userId = UUID().uuidString

        stub("DELETE", "/users/\(userId)/records/\(recordId)", with: [:])

        let asyncExpectation = expectation(description: "should return")
        recordService.deleteRecord(recordId: recordId, userId: userId).then({
            defer { asyncExpectation.fulfill() }
            XCTAssertRouteCalled("DELETE", "/users/\(userId)/records/\(recordId)")
        })

        waitForExpectations(timeout: 5)
    }

    func testFailBuildingFhirStu3SearchParamsMissingTek() {
        let userId = UUID().uuidString

        taggingService.tagTypeResult = TagGroup(tags: [:], annotations: [])
        cryptoService.tagEncryptionKey = nil
        builder.searchParametersError = Data4LifeSDKError.missingTagKey

        let expectedError = Data4LifeSDKError.missingTagKey

        let asyncExpectation = expectation(description: "should fail building params")
        recordService.searchRecords(for: userId,
                                    from: Date(),
                                    to: Date(),
                                    pageSize: 10,
                                    offset: 0,
                                    decryptedRecordType: DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>.self)
            .then { _ in
                XCTFail("Should return an error")
            } onError: { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testFailBuildingFhirStu3UploadParamsMissingTek() {

        let userId = UUID().uuidString
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document)

        let expectedError = Data4LifeSDKError.missingTagKey
        let asyncExpectation = expectation(description: "should fail loading tek")

        taggingService.tagResourceResult = TagGroup(tags: record.tags, annotations: record.annotations)
        cryptoService.generateGCKeyResult = record.dataKey
        cryptoService.tagEncryptionKey = nil
        builder.uploadParametersError = Data4LifeSDKError.missingTagKey
        userService.fetchUserInfoResult = Just(()).asyncFuture
        commonKeyService.currentKey = record.dataKey

        let createdRecord: SDKFuture<DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>> = recordService.createRecord(forResource: document, userId: userId)
        createdRecord.then { _ in
            XCTFail("Should return an error")
        } onError: { error in
            XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
        } finally: {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFailUploadFhirStu3RecordMissingCommonKey() {
        let userId = UUID().uuidString
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document)

        let expectedError = Data4LifeSDKError.missingCommonKey
        let asyncExpectation = expectation(description: "should fail loading common key")

        taggingService.tagResourceResult = TagGroup(tags: record.tags, annotations: record.annotations)
        userService.fetchUserInfoResult = Just(()).asyncFuture
        cryptoService.generateGCKeyResult = record.dataKey

        commonKeyService.currentKey = nil
        let createdRecord: SDKFuture<DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>> = recordService.createRecord(forResource: document, userId: userId)
        createdRecord.then { _ in
            XCTFail("Should return an error")
        } onError: { error in
            XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
        } finally: {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchFhirStu3RecordsFailsUnsupportedVersion() {
        let userId = UUID().uuidString

        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document, dataKey: commonKey)
        var encryptedRecord = encryptedRecordFactory.create(for: record, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        // Common key
        commonKeyService.fetchKeyResult = Just(commonKey).asyncFuture

        // Validator
        versionValidator.fetchCurrentVersionStatusResult = Just(.unsupported).asyncFuture
        let expectedError = Data4LifeSDKError.unsupportedVersionRunning

        let asyncExpectation = expectation(description: "should return a record")
        recordService.fetchRecord(recordId: record.id, userId: userId, decryptedRecordType: type(of: record))
            .then { _ in
                XCTFail("Should return an error")
            } onError: { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            } finally: {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }
}
