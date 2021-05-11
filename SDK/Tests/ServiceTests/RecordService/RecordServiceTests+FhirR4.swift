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
import Then
import ModelsR4

extension RecordServiceTests {

    func testCreateFhirR4Record() {
        let userId = UUID().uuidString

        let resource = FhirFactory.createR4DocumentReferenceResource()
        var record = DecryptedRecordFactory.create(resource)
        let annotations = ["example-annotation1"]
        record.annotations = annotations
        var encryptedRecord = EncryptedRecordFactory.create(for: record, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        userService.fetchUserInfoResult = Async.resolve()

        // Common key
        commonKeyService.currentId = commonKeyId
        commonKeyService.currentKey = commonKey

        // encrypted body
        cryptoService.encryptValueResult = Async.resolve(encryptedRecord.encryptedBodyData)

        // encrypted tags
        taggingService.tagResourceResult = Async.resolve(TagGroup(tags: record.tags, annotations: record.annotations))
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData, encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData, encryptedRecord.encryptedBodyData)

        let inputs = [dataInput, bodyInput]

        cryptoService.generateGCKeyResult = record.dataKey
        cryptoService.encryptDataForInput = inputs
        cryptoService.decryptDataForInput = inputs
        cryptoService.encryptStringResult = "encrypted"
        stub("POST", "/users/\(userId)/records", with: encryptedRecord.data)

        let asyncExpectation = expectation(description: "should create record")
        let createdRecord: Async<DecryptedFhirR4Record<ModelsR4.DocumentReference>> = recordService.createRecord(forResource: resource, annotations: annotations, userId: userId)
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

    func testUpdateFhirR4RecordWithAttachment() {
        let userId = UUID().uuidString
        let oldDocument = FhirFactory.createR4DocumentReferenceResource()
        let oldRecord = DecryptedRecordFactory.create(oldDocument)
        oldDocument.id = oldRecord.id.asFHIRStringPrimitive()
        var oldEncryptedRecord = EncryptedRecordFactory.create(for: oldRecord, commonKeyId: commonKeyId)
        oldEncryptedRecord.encryptedAttachmentKey = nil
        let document = oldDocument.copy() as! ModelsR4.DocumentReference // swiftlint:disable:this force_cast
        let updatedTitle = UUID().uuidString
        document.description_fhir = updatedTitle.asFHIRStringPrimitive()
        var record = DecryptedRecordFactory.create(document)
        record.id = oldRecord.id
        let encryptedRecord = EncryptedRecordFactory.create(for: record)

        stub("GET", "/users/\(userId)/records/\(oldRecord.id)", with: oldEncryptedRecord.data)

        userService.fetchUserInfoResult = Async.resolve()

        // Common key
        commonKeyService.currentId = commonKeyId
        commonKeyService.currentKey = commonKey

        // encrypted body
        cryptoService.encryptValueResult = Async.resolve(encryptedRecord.encryptedBodyData)

        // encrypted tags
        taggingService.tagResourceResult = Async.resolve(TagGroup(tags: record.tags, annotations: record.annotations))
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        cryptoService.generateGCKeyResult = record.dataKey
        cryptoService.encryptStringResult = "encrypted"
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
        let updatedRecord: Async<DecryptedFhirR4Record<ModelsR4.DocumentReference>> = recordService.updateRecord(forResource: document,
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
            XCTAssertEqual(result.resource.description_fhir?.value?.string, updatedTitle)

            XCTAssertEqual(self.taggingService.tagResourceCalledWith?.2, result.annotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateFhirR4RecordWithAttachmentMaintainingOldAnnotations() {
        let userId = UUID().uuidString
        let oldDocument = FhirFactory.createR4DocumentReferenceResource()
        var oldRecord = DecryptedRecordFactory.create(oldDocument)
        let oldAnnotations = ["old-annotation"]
        oldRecord.annotations = oldAnnotations
        oldDocument.id = oldRecord.id.asFHIRStringPrimitive()
        var oldEncryptedRecord = EncryptedRecordFactory.create(for: oldRecord, commonKeyId: commonKeyId)
        oldEncryptedRecord.encryptedAttachmentKey = nil
        let document = oldDocument.copy() as! ModelsR4.DocumentReference // swiftlint:disable:this force_cast
        let updatedTitle = UUID().uuidString
        document.description_fhir = updatedTitle.asFHIRStringPrimitive()
        var record = DecryptedRecordFactory.create(document)
        record.annotations = oldAnnotations
        record.id = oldRecord.id
        let encryptedRecord = EncryptedRecordFactory.create(for: record)

        stub("GET", "/users/\(userId)/records/\(oldRecord.id)", with: oldEncryptedRecord.data)

        userService.fetchUserInfoResult = Async.resolve()

        // Common key
        commonKeyService.currentId = commonKeyId
        commonKeyService.currentKey = commonKey

        // encrypted body
        cryptoService.encryptValueResult = Async.resolve(encryptedRecord.encryptedBodyData)

        // encrypted tags
        taggingService.tagResourceResult = Async.resolve(TagGroup(tags: record.tags, annotations: record.annotations))
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        cryptoService.generateGCKeyResult = record.dataKey
        cryptoService.encryptStringResult = "encrypted"
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
        let updatedRecord: Async<DecryptedFhirR4Record<ModelsR4.DocumentReference>> = recordService.updateRecord(forResource: document,
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
            XCTAssertEqual(result.resource.description_fhir?.value?.string, updatedTitle)

            XCTAssertEqual(self.taggingService.tagResourceCalledWith?.2, oldAnnotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateFhirR4RecordWithAttachmentUpdatingAnnotations() {
        let userId = UUID().uuidString
        let oldDocument = FhirFactory.createR4DocumentReferenceResource()
        var oldRecord = DecryptedRecordFactory.create(oldDocument)
        let oldAnnotations = ["old-annotation"]
        oldRecord.annotations = oldAnnotations
        oldDocument.id = oldRecord.id.asFHIRStringPrimitive()
        var oldEncryptedRecord = EncryptedRecordFactory.create(for: oldRecord, commonKeyId: commonKeyId)
        oldEncryptedRecord.encryptedAttachmentKey = nil
        let document = oldDocument.copy() as! ModelsR4.DocumentReference // swiftlint:disable:this force_cast
        let updatedTitle = UUID().uuidString
        document.description_fhir = updatedTitle.asFHIRStringPrimitive()
        let annotations = ["new-annotation"]
        var record = DecryptedRecordFactory.create(document)
        record.annotations = annotations
        record.id = oldRecord.id
        let encryptedRecord = EncryptedRecordFactory.create(for: record)

        stub("GET", "/users/\(userId)/records/\(oldRecord.id)", with: oldEncryptedRecord.data)

        userService.fetchUserInfoResult = Async.resolve()

        // Common key
        commonKeyService.currentId = commonKeyId
        commonKeyService.currentKey = commonKey

        // encrypted body
        cryptoService.encryptValueResult = Async.resolve(encryptedRecord.encryptedBodyData)

        // encrypted tags
        taggingService.tagResourceResult = Async.resolve(TagGroup(tags: record.tags, annotations: record.annotations))
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        cryptoService.generateGCKeyResult = record.dataKey
        cryptoService.encryptStringResult = "encrypted"
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
        let updatedRecord: Async<DecryptedFhirR4Record<ModelsR4.DocumentReference>> = recordService.updateRecord(forResource: document,
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
            XCTAssertEqual(result.resource.description_fhir, updatedTitle.asFHIRStringPrimitive())

            XCTAssertEqual(self.taggingService.tagResourceCalledWith?.2, annotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchFhirR4Record() {
        let userId = UUID().uuidString

        let document = FhirFactory.createR4DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document, dataKey: commonKey)
        var encryptedRecord = EncryptedRecordFactory.create(for: record, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        // Common key
        commonKeyService.fetchKeyResult = Promise.resolve(commonKey)

        // encrypted body
        cryptoService.encryptValueResult = Async.resolve(encryptedRecord.encryptedBodyData)

        // encrypted tags
        taggingService.tagResourceResult = Async.resolve(TagGroup(tags: record.tags, annotations: record.annotations))
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
        recordService.fetchRecord(recordId: record.id, userId: userId, decryptedRecordType: DecryptedFhirR4Record<ModelsR4.DocumentReference>.self)
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

    func testSearchFhirR4RecordsWithNonPercentEncodableTags() {
        let annotations = ["exampleannotation1"]
        let userId = UUID().uuidString
        let startDate = Date()
        let endDate = Date()
        let document = FhirFactory.createR4DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document, annotations: annotations)
        var encryptedRecord = EncryptedRecordFactory.create(for: record, resource: document, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        taggingService.tagTypeResult = Async.resolve(TagGroup(tags: ["resourcetype": "documentreference"], annotations: annotations))
        taggingService.tagResourceResult = Async.resolve(TagGroup(tags: record.tags, annotations: record.annotations))
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        // Common key
        commonKeyService.fetchKeyResult = Promise.resolve(commonKey)

        // encrypted body
        cryptoService.encryptValueResult = Async.resolve(encryptedRecord.encryptedBodyData)

        // encrypted data key
        cryptoService.encryptDataResult = encryptedRecord.encryptedDataKeyData
        cryptoService.generateGCKeyResult = record.dataKey

        // decrypt values for data key and body
        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData, encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData, encryptedRecord.encryptedBodyData)
        cryptoService.decryptDataForInput = [dataInput, bodyInput]
        cryptoService.encryptStringResult = "encrypted"
        stub("GET", "/users/\(userId)/records", with: [encryptedRecord.json])

        let asyncExpectation = expectation(description: "should return a list of records")
        recordService.searchRecords(for: userId,
                                    from: startDate,
                                    to: endDate,
                                    pageSize: 10,
                                    offset: 0,
                                    annotations: annotations,
                                    decryptedRecordType: DecryptedFhirR4Record<ModelsR4.DocumentReference>.self)
            .then { records in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(records.count, 1)
                XCTAssertEqual(record.resource, document)

                XCTAssertEqual(self.taggingService.tagTypeCalledWith?.1, annotations)
                XCTAssertEqual(record.annotations, annotations)
            }

        waitForExpectations(timeout: 5)
    }

    func testSearchFhirR4RecordsWithPercentEncodableTags() {
        let annotations = ["example-annotation1"]
        let userId = UUID().uuidString
        let startDate = Date()
        let endDate = Date()
        let document = FhirFactory.createR4DocumentReferenceResource()
        var record = DecryptedRecordFactory.create(document, annotations: annotations)
        record.annotations = annotations
        var encryptedRecord = EncryptedRecordFactory.create(for: record, resource: document, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        taggingService.tagTypeResult = Async.resolve(TagGroup(tags: ["resourcetype": "documentreference"], annotations: annotations))
        taggingService.tagResourceResult = Async.resolve(TagGroup(tags: record.tags, annotations: record.annotations))
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        // Common key
        commonKeyService.fetchKeyResult = Promise.resolve(commonKey)

        // encrypted body
        cryptoService.encryptValueResult = Async.resolve(encryptedRecord.encryptedBodyData)

        // encrypted data key
        cryptoService.encryptDataResult = encryptedRecord.encryptedDataKeyData
        cryptoService.generateGCKeyResult = record.dataKey
        cryptoService.encryptStringResult = "encrypted"
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
                                    decryptedRecordType: DecryptedFhirR4Record<ModelsR4.DocumentReference>.self)
            .then { records in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(records.count, 1)
                XCTAssertEqual(record.resource, document)

                XCTAssertEqual(self.taggingService.tagTypeCalledWith?.1, annotations)
                XCTAssertEqual(record.annotations, annotations)
            }

        waitForExpectations(timeout: 5)
    }

    func testSearchFhirR4NoResults() {
        let userId = UUID().uuidString
        let startDate = Date()
        let endDate = Date()
        stub("GET", "/users/\(userId)/records", with: [])

        taggingService.tagTypeResult = Async.resolve(TagGroup(tags: [:]))
        cryptoService.encryptValuesResult = []
        cryptoService.decryptValuesResult = []

        let asyncExpectation = expectation(description: "should return an empty list of records")
        recordService.searchRecords(for: userId,
                                    from: startDate,
                                    to: endDate,
                                    pageSize: 10,
                                    offset: 0,
                                    decryptedRecordType: DecryptedFhirR4Record<ModelsR4.DocumentReference>.self)
            .then { records in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(records.count, 0)
            }

        waitForExpectations(timeout: 5)
    }

    func testCountFhirR4RecordsWithNoPercentEncodableTags() {
        let annotations = ["hello"]
        let userId = UUID().uuidString
        let recordCount = 101

        stub("HEAD", "/users/\(userId)/records", with: Data(), headers: ["x-total-count" : "\(recordCount)"], code: 200)

        taggingService.tagTypeResult = Async.resolve(TagGroup(tags: [:], annotations: annotations))
        cryptoService.encryptValuesResult = []
        cryptoService.decryptValuesResult = []
        cryptoService.encryptStringResult = "encrypted"

        let asyncExpectation = expectation(description: "should return header containg record count")
        recordService.countRecords(userId: userId, resourceType: ModelsR4.DocumentReference.self, annotations: annotations)
            .then { count in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(count, recordCount)
                XCTAssertEqual(self.taggingService.tagTypeCalledWith?.1, annotations)
            }

        waitForExpectations(timeout: 5)
    }

    func testCountFhirR4RecordsWithPercentEncodableTags() {
        let annotations = ["example-annotation1"]
        let userId = UUID().uuidString
        let recordCount = 101

        stub("HEAD", "/users/\(userId)/records", with: Data(), headers: ["x-total-count" : "\(recordCount)"], code: 200)

        taggingService.tagTypeResult = Async.resolve(TagGroup(tags: [:], annotations: annotations))
        cryptoService.encryptValuesResult = []
        cryptoService.decryptValuesResult = []
        cryptoService.encryptStringResult = "encrypted"

        let asyncExpectation = expectation(description: "should return header containg record count")
        recordService.countRecords(userId: userId, resourceType: ModelsR4.DocumentReference.self, annotations: annotations)
            .then { count in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(count, recordCount)
                XCTAssertEqual(self.taggingService.tagTypeCalledWith?.1, annotations)
            }

        waitForExpectations(timeout: 5)
    }

    func testCountFhirR4RecordsFail() {
        let userId = UUID().uuidString
        let expectedError = Data4LifeSDKError.keyMissingInSerialization(key: "`x-total-count`")

        stub("HEAD", "/users/\(userId)/records", with: Data(), headers: ["x-count" : "\(0)"], code: 200)

        taggingService.tagTypeResult = Async.resolve(TagGroup(tags: [:]))
        cryptoService.encryptValuesResult = []
        cryptoService.decryptValuesResult = []

        let asyncExpectation = expectation(description: "should fail counting records")
        recordService.countRecords(userId: userId, resourceType: ModelsR4.DocumentReference.self)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testDeleteFhirR4Record() {
        let recordId = UUID().uuidString
        let userId = UUID().uuidString

        stub("DELETE", "/users/\(userId)/records/\(recordId)", with: [:])

        let asyncExpectation = expectation(description: "should return")
        recordService.deleteRecord(recordId: recordId, userId: userId).then {
            defer { asyncExpectation.fulfill() }
            XCTAssertRouteCalled("DELETE", "/users/\(userId)/records/\(recordId)")
        }

        waitForExpectations(timeout: 5)
    }

    func testFailFhirR4BuildingParamsMissingTek() {
        let userId = UUID().uuidString
        cryptoService.tek = nil
        let expectedError = Data4LifeSDKError.notLoggedIn
        taggingService.tagTypeResult = Async.resolve(TagGroup(tags: [:]))

        let asyncExpectation = expectation(description: "should fail building params")
        recordService.searchRecords(for: userId,
                                    from: Date(),
                                    to: Date(),
                                    pageSize: 10,
                                    offset: 0,
                                    decryptedRecordType: DecryptedFhirR4Record<ModelsR4.DocumentReference>.self)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }

    func testFailUploadFhirR4RecordMissingTek() {
        let userId = UUID().uuidString
        let document = FhirFactory.createR4DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document)

        let expectedError = Data4LifeSDKError.missingTagKey
        let asyncExpectation = expectation(description: "should fail loading tek")

        taggingService.tagResourceResult = Async.resolve(TagGroup(tags: record.tags, annotations: record.annotations))
        cryptoService.generateGCKeyResult = record.dataKey
        cryptoService.tek = nil
        let createdRecord: Async<DecryptedFhirR4Record<ModelsR4.DocumentReference>> = recordService.createRecord(forResource: document, userId: userId)
        createdRecord.then { _ in
            XCTFail("Should return an error")
        }.onError { error in
            XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
        }.finally {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFailUploadFhirR4RecordMissingCommonKey() {
        let userId = UUID().uuidString
        let document = FhirFactory.createR4DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document)

        let expectedError = Data4LifeSDKError.missingCommonKey
        let asyncExpectation = expectation(description: "should fail loading common key")

        taggingService.tagResourceResult = Async.resolve(TagGroup(tags: record.tags, annotations: record.annotations))
        userService.fetchUserInfoResult = Async.resolve()
        cryptoService.generateGCKeyResult = record.dataKey

        commonKeyService.currentKey = nil
        let createdRecord: Async<DecryptedFhirR4Record<ModelsR4.DocumentReference>> = recordService.createRecord(forResource: document, userId: userId)
        createdRecord.then { _ in
            XCTFail("Should return an error")
        }.onError { error in
            XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
        }.finally {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchFhirR4RecordsFailsUnsupportedVersion() {
        let userId = UUID().uuidString

        let document = FhirFactory.createR4DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document, dataKey: commonKey)
        var encryptedRecord = EncryptedRecordFactory.create(for: record, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        // Common key
        commonKeyService.fetchKeyResult = Promise.resolve(commonKey)

        // Validator
        versionValidator.fetchCurrentVersionStatusResult = Async.resolve(.unsupported)
        let expectedError = Data4LifeSDKError.unsupportedVersionRunning

        let asyncExpectation = expectation(description: "should return a record")
        recordService.fetchRecord(recordId: record.id, userId: userId, decryptedRecordType: type(of: record))
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
            }

        waitForExpectations(timeout: 5)
    }
}
